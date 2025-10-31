import Foundation
import SwiftUI
import UIKit
import AlarmKit
import CoreMotion
import AlarmCoreInterface
import AlarmDomainInterface
import Utility
import AppIntents

public final class AlarmServiceImpl: AlarmSchedulerService {

    private let alarmManager = AlarmManager.shared
    private let motionManager = CMMotionManager()

    private var cachedEntities: [UUID: AlarmEntity] = [:]
    private var cachedAlarms: [UUID: Alarm] = [:]
    private var cachedSchedules: [UUID: Alarm.Schedule] = [:]

    private var motionMonitorTask: Task<Void, Never>?
    private var alarmStateMonitorTask: Task<Void, Never>?
    private var motionDetectionCount: [UUID: Int] = [:]
    private let motionThreshold: Double = 2.0
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
            print("📱 [AppState] 앱이 포그라운드로 진입")
            self?.refreshAlarmMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 [AppState] 앱이 활성화됨")
            self?.refreshAlarmMonitoring()
        }
    }
    
    private func refreshAlarmMonitoring() {
        // 알람 상태를 즉시 확인
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let alarms = try await alarmManager.alarms
                
                for alarm in alarms {
                    if alarm.state == .alerting {
                        if !monitoringAlarmIds.contains(alarm.id) {
                            monitoringAlarmIds.insert(alarm.id)
                            startMonitoringMotion(for: alarm.id)
                        }
                    }
                }
            } catch {
                print("❌ [AppState] 알람 상태 확인 실패: \(error)")
            }
        }
    }

    // MARK: - schedule
    public func scheduleAlarm(_ alarm: AlarmEntity) async throws {
        print("🔔 [AlarmKit] ========== 알람 스케줄링 시작 ==========")
        print("   - 알람 ID: \(alarm.id)")
        print("   - 시간: \(alarm.time)")
        
        // 권한 확인
        let authStatus = alarmManager.authorizationState
        print("📋 [AlarmKit] 현재 권한 상태: \(authStatus)")
        
        guard await checkAutorization() else {
            print("❌ [AlarmKit] 권한이 거부되었습니다!")
            throw NSError(domain: "AlarmService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Authorization denied"])
        }
        
        print("✅ [AlarmKit] 권한 확인 완료")

        // 캐시 엔티티 저장 (toggle/update에서 사용)
        cachedEntities[alarm.id] = alarm

        // 시간 파싱
        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            throw NSError(domain: "AlarmService", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid time format"])
        }
        let hour = comps[0], minute = comps[1]

        let schedule: Alarm.Schedule
         if alarm.repeatDays.isEmpty {
            // 오늘의 알람 시간 계산
            var todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            
            guard let todayAlarmDate = Calendar.current.date(from: todayComponents) else {
                throw NSError(domain: "AlarmService", code: 401, userInfo: nil)
            }
            
            // 오늘 알람 시간이 이미 지났으면 내일로 설정, 아니면 오늘로 설정
            let alarmDate = todayAlarmDate > Date.now ? todayAlarmDate : Calendar.current.date(byAdding: .day, value: 1, to: todayAlarmDate) ?? todayAlarmDate
            
            schedule = .fixed(alarmDate)
         } else {
            print("🔔 [AlarmKit] 반복 알람 설정 시작")
            print("   - 입력 요일: \(alarm.repeatDays) (0=일, 1=월, ..., 6=토)")
            
            let weekdays = alarm.repeatDays.compactMap { day -> Locale.Weekday? in
                let calendarWeekday = day + 1  // 0->1(일), 1->2(월), ..., 6->7(토)
                print("   🔄 요일 변환 시도: \(day) -> Calendar weekday \(calendarWeekday)")
                
                let localeWeekday: Locale.Weekday?
                
                localeWeekday = Weekday(rawValue: calendarWeekday)?.localeWeekday ?? nil

                guard let finalWeekday = localeWeekday else { return nil }
                
                print("   ✅ Locale.Weekday 변환 성공: \(finalWeekday)")
                return finalWeekday
            }
            
            print("   📊 최종 변환 결과: \(weekdays.count)개 요일")
            
             guard !weekdays.isEmpty else {
                print("❌ [AlarmKit] 요일 변환 실패: 빈 배열")
                throw NSError(domain: "AlarmService", code: 402, 
                              userInfo: [NSLocalizedDescriptionKey: "Invalid repeat days"])
            }
            
            print("✅ [AlarmKit] 요일 변환 완료: \(weekdays)")
            
            let relTime = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
            let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
            schedule = .relative(.init(time: relTime, repeats: recurrence))
        }

        let alarmLabel = LocalizedStringResource(stringLiteral: alarm.label ?? "Alarm")
        
        let alert = AlarmPresentation.Alert(
            title: alarmLabel,
            stopButton: .stopButton,
            secondaryButton: .openAppButton,
            secondaryButtonBehavior: .custom
        )
        let presentation = AlarmPresentation(alert: alert)
        
        let metadata = AlarmData(alarmId: alarm.id)
        let attributes = AlarmAttributes<AlarmData>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.accentColor
        )
        
        let stopIntent = StopAlarmIntent(alarmID: alarm.id.uuidString)
        let secondaryIntent = OpenAlarmAppIntent(alarmID: alarm.id.uuidString)
        let configuration = AlarmManager.AlarmConfiguration<AlarmData>(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: secondaryIntent
        )

        do {
            try await alarmManager.schedule(id: alarm.id, configuration: configuration)
        } catch {
            print("❌ [AlarmKit] alarmManager.schedule() 실패: \(error)")
            throw error
        }

        cachedSchedules[alarm.id] = schedule
        
        do {
            let registeredAlarms = try alarmManager.alarms
            if let registeredAlarm = registeredAlarms.first(where: { $0.id == alarm.id }) {
                cachedAlarms[alarm.id] = registeredAlarm
            } else {
                print("⚠️ [AlarmKit] 경고: 알람이 등록되지 않음!")
            }
        } catch {
            print("⚠️ [AlarmKit] 알람 목록 조회 실패: \(error)")
        }
        
        print("✅ [AlarmKit] 알람 스케줄 완료: \(alarm.id)")
        print("   - 시간: \(alarm.time)")
        print("   - 레이블: \(alarm.label ?? "알람")")
        if alarm.repeatDays.isEmpty {
            print("   - 반복: 없음 (일회성 알람)")
        } else {
            let dayNames = ["일", "월", "화", "수", "목", "금", "토"]
            let dayString = alarm.repeatDays.sorted().map { dayNames[$0] }.joined(separator: ", ")
            print("   - 반복: \(dayString)")
        }
        print("   - 활성화: \(alarm.isEnabled)")
    }

    // MARK: - cancel
    public func cancelAlarm(_ alarmId: UUID) async throws {
        try await alarmManager.cancel(id: alarmId)
        cachedEntities.removeValue(forKey: alarmId)
        cachedSchedules.removeValue(forKey: alarmId)
        cachedAlarms.removeValue(forKey: alarmId)
        // AlarmKit이 시스템 알람으로 사운드를 관리하므로 우리는 아무것도 하지 않음
    }

    // MARK: - update
    public func updateAlarm(_ alarm: AlarmEntity) async throws {
        try await cancelAlarm(alarm.id)
        try await scheduleAlarm(alarm)
    }
    
    // MARK: - toggle
    public func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws {
        if isEnabled {
            // 켜기: 도메인 엔티티 있어야 재스케줄링 가능
            guard let entity = cachedEntities[alarmId] else {
                // 없다면 앱 DB(SwiftData/Supabase)에서 불러와야 함
                throw NSError(domain: "AlarmService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Entity not found; load from DB first"])
            }
            try await scheduleAlarm(entity) // scheduleAlarm이 캐시에 저장함
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
        // 알람이 울릴 때 실행되는 Intent 알림
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmTriggered"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let alarmId = userInfo["alarmId"] as? UUID else {
                return
            }
            
            print("🔔 [AppIntent] 알람 Intent로부터 알림 수신: \(alarmId)")
            
            // 모션 감지 시작
            if !self.monitoringAlarmIds.contains(alarmId) {
                self.monitoringAlarmIds.insert(alarmId)
                self.startMonitoringMotion(for: alarmId)
            }
        }
        
        // 알람이 멈출 때 실행되는 Intent 알림 (stopIntent)
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
            
            print("🔕 [AppIntent] 알람 멈춤 Intent로부터 알림 수신: \(alarmId)")
            
            // 모션 감지 중지
            if self.monitoringAlarmIds.contains(alarmId) {
                self.monitoringAlarmIds.remove(alarmId)
                self.stopMonitoringMotion(for: alarmId)
            }
        }
    }
    
    // MARK: - alarm state monitoring
    private func startAlarmStateMonitoring() {
        // AlarmKit의 alarmUpdates를 사용하여 알람 상태 변경을 실시간으로 감지
        // 이것은 백그라운드에서도 작동합니다 (시스템 알람이므로)
        alarmStateMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            
            // alarmUpdates를 통해 알람 상태 변경을 구독 (백그라운드에서도 작동)
            for await alarms in alarmManager.alarmUpdates {
                await self.handleAlarmUpdates(alarms)
            }
        }
        
        // 초기 알람 상태 로드
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let alarms = try await alarmManager.alarms
                await self.handleAlarmUpdates(alarms)
            } catch {
                print("⚠️ [AlarmKit] 초기 알람 상태 로드 실패: \(error)")
            }
        }
    }
    
    @MainActor
    private func handleAlarmUpdates(_ alarms: [Alarm]) {
        // 알람이 울리는 중인지 확인
        for alarm in alarms {
            if alarm.state == .alerting {
                // 알람이 울리는 중이면 모션 감지 시작
                if !monitoringAlarmIds.contains(alarm.id) {
                    print("🔔 [AlarmKit] 알람이 울리고 있습니다! 모션 감지 시작: \(alarm.id)")
                    print("   - 상태: \(alarm.state)")
                    print("   - 현재 시간: \(Date())")
                    
                    monitoringAlarmIds.insert(alarm.id)
                    startMonitoringMotion(for: alarm.id)
                    
                    // 백그라운드에서 AppIntent 실행 시도 (iOS 18+)
                    if #available(iOS 18.0, *) {
                        Task {
                            do {
                                let intent = AlarmAppIntent(alarmId: alarm.id)
                                _ = try await intent.perform()
                                print("✅ [AppIntent] 알람 Intent 실행 성공: \(alarm.id)")
                            } catch {
                                print("⚠️ [AppIntent] 알람 Intent 실행 실패: \(error)")
                                // AppIntent 실행 실패해도 모션 감지는 이미 시작되었으므로 문제없음
                            }
                        }
                    }
                    
                    // AlarmKit이 시스템 알람으로 사운드를 자동 재생하므로 우리는 모션 감지만 함
                }
            } else {
                // 알람이 꺼졌으면 모션 감지 중지
                if monitoringAlarmIds.contains(alarm.id) {
                    print("🔕 [AlarmKit] 알람이 꺼졌습니다. 모션 감지 중지: \(alarm.id)")
                    monitoringAlarmIds.remove(alarm.id)
                    stopMonitoringMotion(for: alarm.id)
                    // AlarmKit이 시스템 알람으로 사운드를 관리하므로 우리는 아무것도 하지 않음
                }
            }
        }
        
        // 모니터링 중인 알람이 사라졌는지 확인
        let activeAlarmIds = Set(alarms.map { $0.id })
        let removedIds = monitoringAlarmIds.subtracting(activeAlarmIds)
        for id in removedIds {
            print("🔕 [AlarmKit] 알람이 제거되었습니다. 모션 감지 중지: \(id)")
            monitoringAlarmIds.remove(id)
            stopMonitoringMotion(for: id)
            // AlarmKit이 시스템 알람으로 사운드를 관리하므로 우리는 아무것도 하지 않음
        }
    }

    // MARK: - motion detection (use handler approach)
    public func startMonitoringMotion(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ [Motion] 가속도계를 사용할 수 없습니다")
            return
        }
        
        // 이미 모니터링 중이면 중지 후 재시작
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        
        motionDetectionCount[executionId] = 0
        motionManager.accelerometerUpdateInterval = 0.2

        print("📱 [Motion] 모션 감지 시작: \(executionId)")
        
        // start with handler on main queue
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [Motion] 가속도계 오류: \(error)")
                return
            }
            
            guard let d = data else { return }
            
            // 중력 제거 및 가속도 계산
            let accel = sqrt(d.acceleration.x * d.acceleration.x +
                             d.acceleration.y * d.acceleration.y +
                             d.acceleration.z * d.acceleration.z)
            let net = abs(accel - 1.0)
            
            if net > self.motionThreshold {
                let c = (self.motionDetectionCount[executionId] ?? 0) + 1
                self.motionDetectionCount[executionId] = c
                
                print("📱 [Motion] 흔들림 감지: \(c)/\(self.requiredMotionCount) (가속도: \(String(format: "%.2f", net)))")
                
                if c >= self.requiredMotionCount {
                    print("✅ [Motion] 충분한 흔들림 감지! 알람 끄기: \(executionId)")
                    Task {
                        do {
                            try await self.cancelAlarm(executionId)
                            print("✅ [Motion] 알람 종료 성공")
                        } catch {
                            print("❌ [Motion] 알람 종료 실패: \(error)")
                        }
                    }
                    self.stopMonitoringMotion(for: executionId)
                }
            }
        }
    }
    
    public func stopMonitoringMotion(for executionId: UUID) {
        if motionDetectionCount[executionId] != nil {
            print("🔕 [Motion] 모션 감지 중지: \(executionId)")
            motionDetectionCount.removeValue(forKey: executionId)
            
            // 다른 알람이 모니터링 중이 아니면 가속도계 중지
            if motionDetectionCount.isEmpty {
                motionManager.stopAccelerometerUpdates()
                print("🔕 [Motion] 가속도계 완전 중지")
            }
        }
    }

    // AlarmKit이 시스템 알람으로 사운드를 자동 재생하므로
    // 우리는 오디오 재생 코드가 필요 없습니다

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
}
