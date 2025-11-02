import Foundation
import SwiftUI
import UIKit
import AlarmKit
import CoreMotion
import AlarmCoreInterface
import AlarmDomainInterface
import Utility
import AppIntents
import ActivityKit

public final class AlarmServiceImpl: AlarmSchedulerService {

    private let alarmManager = AlarmManager.shared
    private let motionManager = CMMotionManager()

    private var cachedEntities: [UUID: AlarmEntity] = [:]
    private var cachedAlarms: [UUID: Alarm] = [:]
    private var cachedSchedules: [UUID: Alarm.Schedule] = [:]

    private var motionMonitorTask: Task<Void, Never>?
    private var alarmStateMonitorTask: Task<Void, Never>?
    private var motionDetectionCount: [UUID: Int] = [:]
    private let motionThreshold: Double = 4.0  // 중력 기준값과의 차이 임계값 (더 엄격하게)
    private let motionChangeThreshold: Double = 1.5  // 연속 샘플 간 변화량 임계값 (더 엄격하게)
    private let requiredMotionCount: Int = 3
    private var monitoringAlarmIds: Set<UUID> = []

    public init() {
        setupAppStateObserver()
        startAlarmStateMonitoring()
        setupAppIntentObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        alarmStateMonitorTask?.cancel()
        motionMonitorTask?.cancel()
    }
    
    // MARK: - App State Observer
    private func setupAppStateObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 [AppState] App entered foreground")
            self?.refreshAlarmMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 [AppState] App became active")
            self?.refreshAlarmMonitoring()
        }
    }
    
    private func refreshAlarmMonitoring() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let alarms = try alarmManager.alarms
                
                for alarm in alarms {
                    if alarm.state == .alerting {
                        if !monitoringAlarmIds.contains(alarm.id) {
                            monitoringAlarmIds.insert(alarm.id)
                            startMonitoringMotion(for: alarm.id)
                        }
                    }
                }
            } catch {
                print("❌ [AppState] Failed to check alarm status: \(error)")
            }
        }
    }

    // MARK: - schedule
    public func scheduleAlarm(_ alarm: AlarmEntity) async throws {
        print("🔔 [AlarmKit] ========== Starting alarm scheduling ==========")
        print("   - Alarm ID: \(alarm.id)")
        print("   - Time: \(alarm.time)")
        
        let authStatus = alarmManager.authorizationState
        print("📋 [AlarmKit] Current authorization status: \(authStatus)")
        
        guard await checkAutorization() else {
            print("❌ [AlarmKit] Authorization denied!")
            throw NSError(domain: "AlarmService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Authorization denied"])
        }
        
        print("✅ [AlarmKit] Authorization confirmed")

        cachedEntities[alarm.id] = alarm

        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            throw NSError(domain: "AlarmService", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid time format"])
        }
        let hour = comps[0], minute = comps[1]

        let schedule: Alarm.Schedule
        let nextAlarmTime: Date
        
         if alarm.repeatDays.isEmpty {
            let calendar = Calendar.current
            let now = Date()
            
            // 오늘 해당 시간으로 날짜 생성
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            todayComponents.nanosecond = 0  // 정확성을 위해 nanosecond도 0으로 설정
            
            guard let todayAlarmDate = calendar.date(from: todayComponents) else {
                throw NSError(domain: "AlarmService", code: 401, userInfo: nil)
            }
            
            // 오늘 시간이 이미 지났으면 내일로 설정
            let alarmDate: Date
            if todayAlarmDate > now {
                alarmDate = todayAlarmDate
            } else {
                // 내일 같은 시간
                guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else {
                    throw NSError(domain: "AlarmService", code: 402, userInfo: nil)
                }
                alarmDate = tomorrowAlarmDate
            }
            
            nextAlarmTime = alarmDate
            
            print("📅 [AlarmKit] One-time alarm scheduled:")
            print("   - Input time: \(hour):\(String(format: "%02d", minute))")
            print("   - Today's alarm time: \(todayAlarmDate)")
            print("   - Current time: \(now)")
            print("   - Final alarm date: \(alarmDate)")
            print("   - Time until alarm: \(String(format: "%.1f", alarmDate.timeIntervalSince(now) / 60)) minutes")
            
            schedule = .fixed(alarmDate)
         } else {
            print("🔔 [AlarmKit] Starting recurring alarm setup")
            print("   - Input days: \(alarm.repeatDays) (0=Sun, 1=Mon, ..., 6=Sat)")
            
            let weekdays = alarm.repeatDays.compactMap { day -> Locale.Weekday? in
                let calendarWeekday = day + 1
                print("   🔄 Day conversion attempt: \(day) -> Calendar weekday \(calendarWeekday)")
                
                let localeWeekday: Locale.Weekday?
                
                localeWeekday = Weekday(rawValue: calendarWeekday)?.localeWeekday ?? nil

                guard let finalWeekday = localeWeekday else { return nil }
                
                print("   ✅ Locale.Weekday conversion successful: \(finalWeekday)")
                return finalWeekday
            }
            
            print("   📊 Final conversion result: \(weekdays.count) weekdays")
            
             guard !weekdays.isEmpty else {
                print("❌ [AlarmKit] Day conversion failed: empty array")
                throw NSError(domain: "AlarmService", code: 402, 
                              userInfo: [NSLocalizedDescriptionKey: "Invalid repeat days"])
            }
            
            print("✅ [AlarmKit] Day conversion completed: \(weekdays)")
            
            let relTime = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
            let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
            schedule = .relative(.init(time: relTime, repeats: recurrence))
            
            nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        }

        let alarmLabel = LocalizedStringResource(stringLiteral: alarm.label ?? "Alarm")
        
        // 알람이 설정될 때부터 Dynamic Island에 표시되도록 countdownDuration 설정
        let timeUntilAlarm = nextAlarmTime.timeIntervalSinceNow
        
        // Dynamic Island 중심으로 사용하기 위해 Alert를 최소화
        // Alert는 시스템이 필수로 표시하지만, Dynamic Island에서 모든 인터랙션 처리
        // secondaryButton이 nil이면 secondaryButtonBehavior는 .default여야 함
        let alert = AlarmPresentation.Alert(
            title: alarmLabel,
            stopButton: .stopButton,  // Dynamic Island에서 처리
            secondaryButton: .openAppButton,  // Dynamic Island와 함께 사용
            secondaryButtonBehavior: .custom
        )
        
        // countdownDuration이 있을 때만 countdown과 paused 추가
        // 모든 상태에서 Dynamic Island가 표시되도록 설정
        var presentation: AlarmPresentation
        if timeUntilAlarm > 0 && timeUntilAlarm <= 24 * 60 * 60 {  // 24시간 이내
            let countdown = AlarmPresentation.Countdown(
                title: alarmLabel,
                pauseButton: .openAppButton  // Dynamic Island에서 처리
            )
            let paused = AlarmPresentation.Paused(
                title: "Paused",
                resumeButton: .openAppButton  // Dynamic Island에서 처리
            )
            presentation = AlarmPresentation(
                alert: alert,
                countdown: countdown,
                paused: paused
            )
        } else {
            // countdownDuration 없이 alert만 사용
            // Dynamic Island를 최대한 활용하도록 설정
            presentation = AlarmPresentation(alert: alert)
        }
        
        let metadata = AlarmData(
            alarmId: alarm.id,
            nextAlarmTime: nextAlarmTime,
            alarmLabel: alarm.label,
            isAlerting: false,
            motionCount: 0,
            requiredMotionCount: requiredMotionCount
        )
        let attributes = AlarmAttributes<AlarmData>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.accentColor
        )
        
        let stopIntent = StopAlarmIntent(alarmID: alarm.id.uuidString)
        let secondaryIntent = OpenAlarmAppIntent(alarmID: alarm.id.uuidString)
        
        // countdownDuration 계산: 정확한 초 단위로 계산 (정수 변환으로 인한 오차 방지)
        // timeUntilAlarm을 정확하게 사용하여 알람 시간과 동기화
        let timeUntilAlarmSeconds = timeUntilAlarm
        
        // countdownDuration: 알람이 설정될 때부터 표시되도록 (최대 24시간)
        let maxCountdownSeconds = 24 * 60 * 60
        let preAlertSeconds = min(timeUntilAlarmSeconds, Double(maxCountdownSeconds))
        
        // countdownDuration은 예제 코드처럼 .init() 형태로 직접 전달
        var configuration: AlarmManager.AlarmConfiguration<AlarmData>
        
        // 알람이 24시간 이내이고 시간이 남아있는 경우만 countdownDuration 설정
        if timeUntilAlarm > 0 && timeUntilAlarm <= Double(maxCountdownSeconds) {
            // countdownDuration이 있는 경우
            // preAlert는 정확한 알람 시간까지의 시간으로 설정
            configuration = AlarmManager.AlarmConfiguration<AlarmData>(
                countdownDuration: .init(
                    preAlert: preAlertSeconds,  // 정확한 초 단위
                    postAlert: 15 * 60  // 알람 후 15분
                ),
                schedule: schedule,
                attributes: attributes,
                stopIntent: stopIntent,
                secondaryIntent: secondaryIntent
            )
            
            print("⏰ [AlarmKit] Countdown duration configured:")
            print("   - Time until alarm: \(String(format: "%.2f", timeUntilAlarmSeconds)) seconds")
            print("   - Pre-alert duration: \(String(format: "%.2f", preAlertSeconds)) seconds")
            print("   - Alarm scheduled time: \(nextAlarmTime)")
        } else {
            // countdownDuration이 없는 경우 (24시간 이상)
            configuration = AlarmManager.AlarmConfiguration<AlarmData>(
                countdownDuration: nil,
                schedule: schedule,
                attributes: attributes,
                stopIntent: stopIntent,
                secondaryIntent: secondaryIntent
            )
            
            print("⏰ [AlarmKit] No countdown duration (beyond 24 hours)")
            print("   - Time until alarm: \(String(format: "%.2f", timeUntilAlarmSeconds)) seconds")
            print("   - Alarm scheduled time: \(nextAlarmTime)")
        }

        // 권한 확인
        let isAuthorized = await checkAutorization()
        guard isAuthorized else {
            print("❌ [AlarmKit] Alarm authorization failed")
            throw NSError(domain: "AlarmService", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "Alarm authorization denied"])
        }
        
        do {
            _ = try await alarmManager.schedule(id: alarm.id, configuration: configuration)
            print("✅ [AlarmKit] Alarm scheduled successfully: \(alarm.id)")
            print("   - Scheduled time: \(nextAlarmTime)")
            print("   - Time until alarm: \(String(format: "%.1f", timeUntilAlarm / 60)) minutes")
            print("   - Schedule type: \(schedule)")
            print("   - Live Activity should start immediately with countdown")
        } catch {
            print("❌ [AlarmKit] Failed to schedule alarm: \(error)")
            print("   - Error domain: \((error as NSError).domain)")
            print("   - Error code: \((error as NSError).code)")
            print("   - Error description: \(error.localizedDescription)")
            print("   - Alarm ID: \(alarm.id)")
            print("   - Schedule: \(schedule)")
            throw error
        }

        cachedSchedules[alarm.id] = schedule
        
        // Update cached alarm from AlarmManager and verify registration
        do {
            let registeredAlarms = try alarmManager.alarms
            print("📋 [AlarmKit] Total registered alarms: \(registeredAlarms.count)")
            
            if let registeredAlarm = registeredAlarms.first(where: { $0.id == alarm.id }) {
                cachedAlarms[alarm.id] = registeredAlarm
                print("✅ [AlarmKit] Alarm verified in AlarmManager:")
                print("   - Alarm ID: \(registeredAlarm.id)")
                print("   - State: \(registeredAlarm.state)")
                print("   - Schedule: \(registeredAlarm.schedule)")
            } else {
                print("⚠️ [AlarmKit] Alarm scheduled but not found in AlarmManager!")
                print("   - Expected ID: \(alarm.id)")
                print("   - Registered IDs: \(registeredAlarms.map { $0.id })")
            }
        } catch {
            print("⚠️ [AlarmKit] Failed to fetch alarm list: \(error)")
        }
    }

    // MARK: - cancel
    public func cancelAlarm(_ alarmId: UUID) async throws {
        do {
            try alarmManager.cancel(id: alarmId)
        } catch {
            print("⚠️ [AlarmKit] Error during alarm cancellation (ignored): \(alarmId) - \(error)")
        }
        cachedEntities.removeValue(forKey: alarmId)
        cachedSchedules.removeValue(forKey: alarmId)
        cachedAlarms.removeValue(forKey: alarmId)
    }

    // MARK: - update
    public func updateAlarm(_ alarm: AlarmEntity) async throws {
        try await cancelAlarm(alarm.id)
        try await scheduleAlarm(alarm)
    }
    
    // MARK: - toggle
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        if isEnabled {
            guard let entity = cachedEntities[alarmId] else {
                throw NSError(domain: "AlarmService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Entity not found; load from DB first"])
            }
            try await scheduleAlarm(entity)
        } else {
            try await cancelAlarm(alarmId)
        }
    }
    
    // MARK: - status
    public func getAlarmStatus(alarmId: UUID) async throws -> AlarmStatus? {
        let alarms = try alarmManager.alarms
        guard let ak = alarms.first(where: { $0.id == alarmId }) else { return nil }
        switch ak.state {
        case .scheduled: return .scheduled
        case .countdown: return .scheduled
        case .paused: return .paused
        case .alerting: return .alerting
        @unknown default: return .unknown
        }
    }

    // MARK: - AppIntent Observer
    private func setupAppIntentObserver() {
        // AlarmKit이 자동으로 Intent를 실행하므로,
        // handleAlarmUpdates에서 이미 모션 감지를 시작하므로
        // Notification observer는 필요 없음
        // StopIntent는 사용자 액션이므로 유지
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmStopped"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let alarmId = userInfo["alarmId"] as? UUID else {
                return
            }
            
            print("🔕 [AppIntent] Notification received from alarm stop Intent: \(alarmId)")
            
            if self.monitoringAlarmIds.contains(alarmId) {
                self.monitoringAlarmIds.remove(alarmId)
                self.stopMonitoringMotion(for: alarmId)
            }
        }
    }
    
    // MARK: - alarm state monitoring
    private func startAlarmStateMonitoring() {
        print("🔍 [AlarmKit] Starting alarm state monitoring...")
        
        alarmStateMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            
            print("🔍 [AlarmKit] Listening to alarmUpdates stream...")
            for await alarms in alarmManager.alarmUpdates {
                print("🔍 [AlarmKit] Received alarm updates: \(alarms.count) alarms")
                for alarm in alarms {
                    print("   - Alarm \(alarm.id): state=\(alarm.state), schedule=\(alarm.schedule)")
                }
                self.handleAlarmUpdates(alarms)
            }
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let alarms = try alarmManager.alarms
                print("🔍 [AlarmKit] Initial alarm status loaded: \(alarms.count) alarms")
                for alarm in alarms {
                    print("   - Alarm \(alarm.id): state=\(alarm.state), schedule=\(alarm.schedule)")
                }
                self.handleAlarmUpdates(alarms)
            } catch {
                print("⚠️ [AlarmKit] Failed to load initial alarm status: \(error)")
            }
        }
    }
    
    private func handleAlarmUpdates(_ alarms: [Alarm]) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            for alarm in alarms {
                if alarm.state == .alerting {
                    if !monitoringAlarmIds.contains(alarm.id) {
                        print("🔔 [AlarmKit] Alarm is alerting! Starting motion detection: \(alarm.id)")
                        print("   - State: \(alarm.state)")
                        print("   - Current time: \(Date())")
                        print("   - Dynamic Island will be the main interface")
                        
                        monitoringAlarmIds.insert(alarm.id)
                        startMonitoringMotion(for: alarm.id)
                        
                        // Dynamic Island를 강조하기 위해 Live Activity 업데이트
                        await updateLiveActivityForAlarm(alarm.id, isAlerting: true)
                    }
                } else {
                    if monitoringAlarmIds.contains(alarm.id) {
                        print("🔕 [AlarmKit] Alarm stopped. Stopping motion detection: \(alarm.id)")
                        monitoringAlarmIds.remove(alarm.id)
                        stopMonitoringMotion(for: alarm.id)
                        await updateLiveActivityForAlarm(alarm.id, isAlerting: false)
                    }
                }
            }
            
            let activeAlarmIds = Set(alarms.map { $0.id })
            let removedIds = monitoringAlarmIds.subtracting(activeAlarmIds)
            for id in removedIds {
                print("🔕 [AlarmKit] Alarm removed. Stopping motion detection: \(id)")
                monitoringAlarmIds.remove(id)
                stopMonitoringMotion(for: id)
            }
        }
    }

    // MARK: - motion detection (use handler approach)
    public func startMonitoringMotion(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ [Motion] Accelerometer not available")
            return
        }
        
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        
        motionDetectionCount[executionId] = 0
        motionManager.accelerometerUpdateInterval = 0.1

        print("📱 [Motion] Starting motion detection: \(executionId)")
        
        // 백그라운드에서도 작동하도록 메인 스레드가 아닌 다른 큐 사용
        let queue = OperationQueue()
        queue.name = "com.withday.motion"
        queue.maxConcurrentOperationCount = 1
        
        var lastAccel: Double? = nil
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [Motion] Accelerometer error: \(error)")
                return
            }
            
            guard let d = data else { return }
            
            let accel = sqrt(d.acceleration.x * d.acceleration.x +
                             d.acceleration.y * d.acceleration.y +
                             d.acceleration.z * d.acceleration.z)
            
            // 기준값(중력: 1.0)과의 차이
            let delta = abs(accel - 1.0)
            
            // 이전 값과의 변화량도 확인
            var change: Double = 0.0
            if let last = lastAccel {
                change = abs(accel - last)
            }
            lastAccel = accel
            
            // 변화량이 임계값을 넘으면 흔들림으로 인식
            // 두 조건 모두 만족해야 진짜 흔들림으로 인식 (AND 조건으로 더 엄격하게)
            if delta > self.motionThreshold && change > self.motionChangeThreshold {
                let c = (self.motionDetectionCount[executionId] ?? 0) + 1
                self.motionDetectionCount[executionId] = c
                
                print("📱 [Motion] Shake detected: \(c)/\(self.requiredMotionCount) (delta: \(String(format: "%.2f", delta)), change: \(String(format: "%.2f", change)))")
                
                // Dynamic Island 업데이트를 위한 Live Activity 업데이트
                Task { @MainActor in
                    await self.updateLiveActivityForMotion(executionId, motionCount: c)
                }
                
                if c >= self.requiredMotionCount {
                    print("✅ [Motion] Sufficient shake detected! Canceling alarm: \(executionId)")
                    Task {
                        do {
                            try await self.cancelAlarm(executionId)
                            print("✅ [Motion] Alarm cancellation successful")
                        } catch {
                            print("❌ [Motion] Alarm cancellation failed: \(error)")
                        }
                    }
                    self.stopMonitoringMotion(for: executionId)
                    return
                }
            }
        }
    }
    
    public func stopMonitoringMotion(for executionId: UUID) {
        if motionDetectionCount[executionId] != nil {
            motionDetectionCount.removeValue(forKey: executionId)
            
            if motionDetectionCount.isEmpty {
                motionManager.stopAccelerometerUpdates()
            }
        }
    }

    // MARK: - Live Activity Updates for Dynamic Island
    @MainActor
    private func updateLiveActivityForAlarm(_ alarmId: UUID, isAlerting: Bool) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ [DynamicIsland] Live Activities not enabled")
            return
        }
        
        // AlarmKit이 자동으로 Live Activity를 관리하므로
        // 여기서는 metadata만 업데이트하면 됨
        // AlarmKit이 자동으로 동기화하므로 별도 업데이트 불필요
        print("📱 [DynamicIsland] Alarm state changed: \(alarmId) - isAlerting: \(isAlerting)")
    }
    
    @MainActor
    private func updateLiveActivityForMotion(_ alarmId: UUID, motionCount: Int) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        // AlarmKit이 자동으로 Live Activity를 관리하므로
        // metadata는 AlarmKit이 자동으로 동기화함
        // 하지만 모션 카운트는 AlarmKit이 자동으로 업데이트하지 않으므로
        // 필요한 경우 직접 업데이트할 수 있음
        // 현재는 AlarmKit의 자동 관리를 사용하므로 별도 업데이트 불필요
        print("📱 [DynamicIsland] Motion count updated: \(alarmId) - \(motionCount)/\(requiredMotionCount)")
    }
    
    // MARK: - helpers
    private func checkAutorization() async -> Bool {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let s = try await alarmManager.requestAuthorization()
                return s == .authorized
            } catch { return false }
        case .authorized: return true
        case .denied: return false
        @unknown default: return false
        }
    }
    
    private func calculateNextAlarmTime(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Calendar의 weekday: 1=일요일, 2=월요일, ..., 7=토요일
        // repeatDays: 0=일요일, 1=월요일, ..., 6=토요일
        let currentWeekday = calendar.component(.weekday, from: now)  // 1~7
        
        var candidates: [Date] = []
        
        for day in repeatDays {
            // repeatDays의 day를 Calendar의 weekday로 변환 (day+1)
            let targetWeekday = day + 1  // 1~7
            
            // 오늘부터 다음 주까지의 해당 요일 찾기
            var daysToAdd = (targetWeekday - currentWeekday + 7) % 7
            // 같은 요일이고 시간이 이미 지났으면 다음 주로
            if daysToAdd == 0 {
                let testComponents = calendar.dateComponents([.year, .month, .day], from: now)
                var testAlarmComponents = testComponents
                testAlarmComponents.hour = hour
                testAlarmComponents.minute = minute
                testAlarmComponents.second = 0
                testAlarmComponents.nanosecond = 0
                
                if let testAlarmDate = calendar.date(from: testAlarmComponents),
                   testAlarmDate <= now {
                    daysToAdd = 7  // 다음 주로
                }
            }
            
            // 날짜 계산
            guard let baseDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                continue
            }
            
            // 해당 날짜의 정확한 시간 설정
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.second = 0
            dateComponents.nanosecond = 0  // 정확성을 위해 nanosecond도 0으로 설정
            
            guard let alarmDate = calendar.date(from: dateComponents) else {
                continue
            }
            
            // 현재 시간보다 미래인 경우만 추가
            if alarmDate > now {
                candidates.append(alarmDate)
            }
        }
        
        // 가장 가까운 시간 반환
        let result = candidates.sorted().first ?? now
        print("📅 [AlarmKit] Recurring alarm next time calculated:")
        print("   - Input time: \(hour):\(String(format: "%02d", minute))")
        print("   - Repeat days: \(repeatDays)")
        print("   - Current weekday: \(currentWeekday)")
        print("   - Candidates: \(candidates.count)")
        print("   - Next alarm date: \(result)")
        print("   - Time until alarm: \(String(format: "%.1f", result.timeIntervalSince(now) / 60)) minutes")
        
        return result
    }
}
