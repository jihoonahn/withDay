import Foundation
import SwiftUI
import UIKit
import CoreMotion
import UserNotifications
import AudioToolbox
import AVFoundation
import AlarmCoreInterface
import AlarmDomainInterface
import Utility
import AppIntents
import ActivityKit

public final class AlarmServiceImpl: AlarmSchedulerService {

    private let notificationCenter = UNUserNotificationCenter.current()
    private let motionManager = CMMotionManager()

    private var cachedEntities: [UUID: AlarmEntity] = [:]
    private var activeActivities: [UUID: Activity<AlarmAttributes>] = [:]
    private var scheduledNotifications: [UUID: String] = [:]

    private var motionMonitorTask: Task<Void, Never>?
    private var alarmCheckTask: Task<Void, Never>?
    private var motionDetectionCount: [UUID: Int] = [:]
    private let motionThreshold: Double = 0.8
    private let motionChangeThreshold: Double = 0.3
    private let requiredMotionCount: Int = 3
    private var monitoringAlarmIds: Set<UUID> = []
    private var lastAccel: [UUID: Double] = [:]
    private var lastLogTime: [UUID: TimeInterval] = [:]
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var soundLoopTask: Task<Void, Never>?

    public init() {
        setupAppStateObserver()
        startAlarmCheckTask()
        setupNotificationDelegate()
        setupAppIntentObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        motionMonitorTask?.cancel()
        alarmCheckTask?.cancel()
        soundLoopTask?.cancel()
        
        // 모든 모션 감지 태스크 취소
        for task in motionMonitorTasks.values {
            task.cancel()
        }
        motionMonitorTasks.removeAll()
        
        stopSoundLoop()
        endBackgroundTask()
    }
    
    // MARK: - Notification Delegate
    private func setupNotificationDelegate() {
        NotificationDelegate.shared.alarmService = self
        notificationCenter.delegate = NotificationDelegate.shared
        print("📱 [AlarmService] Notification delegate setup complete")
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
            await self.checkActiveAlarms()
        }
    }

    // MARK: - schedule
    public func scheduleAlarm(_ alarm: AlarmEntity) async throws {
        print("🔔 [AlarmService] ========== Starting alarm scheduling ==========")
        print("   - Alarm ID: \(alarm.id)")
        print("   - Time: \(alarm.time)")
        
        // Notification 권한 확인
        let authStatus = await notificationCenter.notificationSettings()
        if authStatus.authorizationStatus != .authorized {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                throw NSError(domain: "AlarmService", code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "Notification authorization denied"])
            }
        }
        
        // Live Activity 권한 확인
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw NSError(domain: "AlarmService", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Live Activities not enabled"])
        }
        
        print("✅ [AlarmService] Authorizations confirmed")

        cachedEntities[alarm.id] = alarm

        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            throw NSError(domain: "AlarmService", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid time format"])
        }
        let hour = comps[0], minute = comps[1]

        let calendar = Calendar.current
        let now = Date()
        
        // 다음 알람 시간 계산
        let nextAlarmTime: Date
         if alarm.repeatDays.isEmpty {
            // 일회성 알람
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            todayComponents.nanosecond = 0
            
            guard let todayAlarmDate = calendar.date(from: todayComponents) else {
                throw NSError(domain: "AlarmService", code: 401, userInfo: nil)
            }
            
            if todayAlarmDate > now {
                nextAlarmTime = todayAlarmDate
            } else {
                guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else {
                    throw NSError(domain: "AlarmService", code: 402, userInfo: nil)
                }
                nextAlarmTime = tomorrowAlarmDate
            }
         } else {
            // 반복 알람
            nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        }

        print("📅 [AlarmService] Alarm scheduled:")
        print("   - Input time: \(hour):\(String(format: "%02d", minute))")
        print("   - Next alarm time: \(nextAlarmTime)")
        print("   - Time until alarm: \(String(format: "%.1f", nextAlarmTime.timeIntervalSince(now) / 60)) minutes")
        
        // 1. UNNotification 스케줄링 (백그라운드에서 알람 트리거)
        try await scheduleNotification(alarmId: alarm.id, time: nextAlarmTime, label: alarm.label)
        
        // 2. Live Activity 시작 (알람 설정 시점부터 Dynamic Island 표시)
        try await startLiveActivity(alarm: alarm, scheduledTime: nextAlarmTime)
        
        print("✅ [AlarmService] Alarm scheduled successfully: \(alarm.id)")
    }
    
    // MARK: - UNNotification 스케줄링
    private func scheduleNotification(alarmId: UUID, time: Date, label: String?) async throws {
        // 기존 알림 제거
        if let existingId = scheduledNotifications[alarmId] {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [existingId])
        }
        
        let content = UNMutableNotificationContent()
        content.title = label ?? "Alarm"
        content.body = "Alarm time"
        
        // 알람 사운드 설정 - 백그라운드에서도 사운드 재생되도록
        content.sound = .default
        
        // InterruptionLevel을 timeSensitive로 설정하여 백그라운드에서도 사운드 재생
        // critical은 특별한 권한이 필요하므로 timeSensitive 사용
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // Badge 설정
        content.badge = 1
        
        content.categoryIdentifier = "ALARM"
        content.userInfo = [
            "alarmId": alarmId.uuidString,
            "type": "alarm"
        ]
        
        // 정확한 시간으로 트리거
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alarmId.uuidString,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        scheduledNotifications[alarmId] = alarmId.uuidString
        
        print("📬 [AlarmService] Notification scheduled: \(alarmId.uuidString)")
    }
    
    // MARK: - Live Activity 시작
    private func startLiveActivity(alarm: AlarmEntity, scheduledTime: Date) async throws {
        print("📱 [AlarmService] ========== Starting Live Activity ==========")
        print("   - Alarm ID: \(alarm.id)")
        print("   - Scheduled Time: \(scheduledTime)")
        
        // ActivityKit 권한 확인
        let authInfo = ActivityAuthorizationInfo()
        print("   - Activities Enabled: \(authInfo.areActivitiesEnabled)")
        print("   - Frequent Pushes Enabled: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            let error = NSError(domain: "AlarmService", code: 401,
                              userInfo: [NSLocalizedDescriptionKey: "Live Activities not enabled. Please enable in Settings."])
            print("❌ [AlarmService] Live Activities not enabled")
            throw error
        }
        
        // 기존 Live Activity 제거
        await endLiveActivity(for: alarm.id)
        
        let attributes = AlarmAttributes(
            alarmId: alarm.id,
            alarmLabel: alarm.label,
            scheduledTime: scheduledTime
        )
        
        let initialContentState = AlarmAttributes.ContentState(
            isAlerting: false,
            motionCount: 0,
            requiredMotionCount: requiredMotionCount,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(state: initialContentState, staleDate: nil)
        
        print("📱 [AlarmService] Requesting Live Activity...")
        print("   - Attributes: alarmId=\(attributes.alarmId), scheduledTime=\(attributes.scheduledTime)")
        print("   - ContentState: isAlerting=\(initialContentState.isAlerting), motionCount=\(initialContentState.motionCount)")
        
        do {
            print("📱 [AlarmService] Attempting to request Activity...")
            print("   - Checking for existing ActivityConfiguration...")
            
            // Activity 요청 전에 Widget Extension이 등록되었는지 확인
            // Activity.request 호출 시 시스템이 자동으로 Widget Extension을 찾습니다
            let activity = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                content: activityContent
            )
            
            activeActivities[alarm.id] = activity
            
            print("✅ [AlarmService] Activity requested successfully: \(alarm.id)")
            print("   - Activity ID: \(activity.id)")
            print("   - Activity attributes: alarmId=\(activity.attributes.alarmId), scheduledTime=\(activity.attributes.scheduledTime)")
            print("   - Activity state: isAlerting=\(activity.content.state.isAlerting), motionCount=\(activity.content.state.motionCount)")
            
            // 활성 Live Activity 확인 (약간의 지연 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let allActivities = Activity<AlarmAttributes>.activities
                print("📱 [AlarmService] Checking active activities after request...")
                print("   - Total active activities: \(allActivities.count)")
                print("   - Activity IDs: \(allActivities.map { $0.attributes.alarmId })")
                
                // Dynamic Island 확인
                print("📱 [AlarmService] Dynamic Island configuration check:")
                print("   - Widget Extension should be registered for AlarmAttributes")
                print("   - Dynamic Island requires iPhone 14 Pro or later")
                print("   - ActivityConfiguration should be in AlarmWidget")
                
                if allActivities.isEmpty {
                    print("⚠️ [AlarmService] Warning: No activities found after request.")
                    print("   - Widget Extension may not be properly configured")
                    print("   - Check that NSSupportsLiveActivities is set to true in Widget Extension Info.plist")
                    print("   - Check that ActivityConfiguration is properly registered in AlarmWidget")
                    print("   - Make sure Widget Extension is included in app target")
                } else {
                    print("✅ [AlarmService] Activity is active - Dynamic Island should appear if device supports it")
                    print("   - If Dynamic Island doesn't appear, check device model (iPhone 14 Pro or later)")
                    print("   - Also check that Widget Extension is properly installed")
                    print("   - Widget Extension logs are in separate process - check system logs")
                    print("   - Use: log stream --predicate 'subsystem == \"me.jihoon.WithDay\"' --level debug")
                    print("")
                    print("📱 [AlarmService] ========== Widget Extension Loading Check ==========")
                    print("   - Live Activity started successfully")
                    print("   - Widget Extension should now be loading...")
                    print("   - Widget Extension logs should appear in system logs")
                    print("   - If Widget Extension logs don't appear, check:")
                    print("     1. Widget Extension is built and included in app bundle")
                    print("     2. Widget Extension is in PlugIns folder")
                    print("     3. Widget Extension Info.plist is correct")
                    print("     4. ActivityConfiguration is properly registered")
                }
            }
        } catch {
            print("❌ [AlarmService] Failed to start Live Activity: \(error)")
            print("   - Error domain: \((error as NSError).domain)")
            print("   - Error code: \((error as NSError).code)")
            print("   - Error description: \(error.localizedDescription)")
            print("   - Error userInfo: \((error as NSError).userInfo)")

            throw error
        }
    }
    
    // MARK: - Live Activity 업데이트
    private func updateLiveActivity(for alarmId: UUID, contentState: AlarmAttributes.ContentState) async {
        print("📱 [AlarmService] updateLiveActivity called:")
        print("   - alarmId: \(alarmId)")
        print("   - contentState.isAlerting: \(contentState.isAlerting)")
        print("   - contentState.motionCount: \(contentState.motionCount)")
        
        // 활성 Live Activity 확인
        if let activity = activeActivities[alarmId] {
            print("✅ [AlarmService] Found activity in activeActivities")
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            await activity.update(activityContent)
            print("✅ [AlarmService] Activity updated successfully")
        } else {
            // Live Activity가 없으면 현재 활성 Activity 확인
            let activities = Activity<AlarmAttributes>.activities
            print("📱 [AlarmService] Checking system activities...")
            print("   - Total activities: \(activities.count)")
            
            if let activity = activities.first(where: { $0.attributes.alarmId == alarmId }) {
                print("✅ [AlarmService] Found Live Activity in system, updating: \(alarmId)")
                activeActivities[alarmId] = activity
                
                let activityContent = ActivityContent(state: contentState, staleDate: nil)
                await activity.update(activityContent)
                print("✅ [AlarmService] Activity updated successfully from system")
            } else {
                print("⚠️ [AlarmService] Live Activity not found: \(alarmId)")
                print("   - Active activities: \(activities.map { $0.attributes.alarmId })")
                print("   - This may cause Dynamic Island to not update")
            }
        }
    }
    
    // MARK: - Live Activity 종료
    private func endLiveActivity(for alarmId: UUID) async {
        guard let activity = activeActivities[alarmId] else { return }
        
        // Provide final content per iOS 16.2+ API
        let finalState = activity.content.state
        let finalContent = ActivityContent(state: finalState, staleDate: nil)
        await activity.end(finalContent, dismissalPolicy: .immediate)
        
        activeActivities.removeValue(forKey: alarmId)
        print("🔕 [AlarmService] Live Activity ended: \(alarmId)")
    }

    // MARK: - cancel
    public func cancelAlarm(_ alarmId: UUID) async throws {
        // 알림 제거
        if let notificationId = scheduledNotifications[alarmId] {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
            scheduledNotifications.removeValue(forKey: alarmId)
        }
        
        // Live Activity 종료
        await endLiveActivity(for: alarmId)
        
        // 모니터링 중지
        if monitoringAlarmIds.contains(alarmId) {
            monitoringAlarmIds.remove(alarmId)
            stopMonitoringMotion(for: alarmId)
        }
        
        cachedEntities.removeValue(forKey: alarmId)
        print("✅ [AlarmService] Alarm cancelled: \(alarmId)")
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
                throw NSError(domain: "AlarmService", code: 404,
                             userInfo: [NSLocalizedDescriptionKey: "Entity not found; load from DB first"])
            }
            try await scheduleAlarm(entity)
        } else {
            try await cancelAlarm(alarmId)
        }
    }
    
    // MARK: - status
    public func getAlarmStatus(alarmId: UUID) async throws -> AlarmStatus? {
        // Live Activity 상태 확인
        if let activity = activeActivities[alarmId] {
            let contentState = activity.content.state
            if contentState.isAlerting {
                return .alerting
            } else {
                return .scheduled
            }
        }
        
        // 알림이 스케줄되어 있는지 확인
        if scheduledNotifications[alarmId] != nil {
            return .scheduled
        }
        
        return nil
    }
    
    // MARK: - 백그라운드 알람 체크
    private func startAlarmCheckTask() {
        alarmCheckTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                await self.checkActiveAlarms()
                
                // 1초마다 체크
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func checkActiveAlarms() async {
        let now = Date()
        
        for (alarmId, _) in cachedEntities {
            guard let activity = activeActivities[alarmId] else { continue }
            
            let scheduledTime = activity.attributes.scheduledTime
            
            // 알람 시간이 되었는지 확인
            if now >= scheduledTime && !activity.content.state.isAlerting {
                print("🔔 [AlarmService] Alarm time reached: \(alarmId)")
                await triggerAlarm(alarmId: alarmId)
            }
        }
    }
    
    // MARK: - 알람 트리거
    func triggerAlarm(alarmId: UUID) async {
        guard let entity = cachedEntities[alarmId] else {
            print("⚠️ [AlarmService] Entity not found for alarm: \(alarmId)")
            return
        }
        
        print("🔔 [AlarmService] Triggering alarm: \(alarmId)")
        
        // Live Activity가 없으면 생성
        if activeActivities[alarmId] == nil {
            print("⚠️ [AlarmService] Live Activity not found, creating new one: \(alarmId)")
            do {
                try await startLiveActivity(alarm: entity, scheduledTime: Date())
            } catch {
                print("❌ [AlarmService] Failed to create Live Activity: \(error)")
            }
        }
        
        // Live Activity를 알람 모드로 전환
        let alertingState = AlarmAttributes.ContentState(
            isAlerting: true,
            motionCount: 0,
            requiredMotionCount: requiredMotionCount,
            lastUpdateTime: Date()
        )
        
        await updateLiveActivity(for: alarmId, contentState: alertingState)
        
        // 모션 감지 시작
        if !monitoringAlarmIds.contains(alarmId) {
            monitoringAlarmIds.insert(alarmId)
            startMonitoringMotion(for: alarmId)
        }
        
        // 진동 재생 (반복)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // 사운드 재생을 위한 시스템 사운드
        // 백그라운드에서도 재생되도록 AVAudioSession 사용
        playAlarmSound()
        
        print("✅ [AlarmService] Alarm triggered successfully: \(alarmId)")
    }
    
    // MARK: - 사운드 재생
    private func playAlarmSound() {
        // 백그라운드 태스크 시작 (백그라운드에서 지속적인 재생을 위해)
        startBackgroundTask()
        
        // AudioServicesPlaySystemSound는 오디오 세션 활성화가 필요 없음
        // 오디오 세션 활성화를 제거하여 HALC 에러 방지
        
        // 진동 재생
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // 시스템 알람 사운드 재생
        // 1005: 알람 사운드, 1007: 알람 벨 사운드
        AudioServicesPlaySystemSound(1005)
        
        // 추가 진동 및 사운드 (반복 효과)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            AudioServicesPlaySystemSound(1007)
        }
        
        // 지속적인 반복 재생 시작 (백그라운드에서도 작동)
        startSoundLoop()
        
        print("🔊 [AlarmService] Alarm sound played")
    }
    
    // MARK: - 사운드 반복 재생
    private var soundLoopTimer: Timer?
    
    private func startSoundLoop() {
        soundLoopTimer?.invalidate()
        soundLoopTask?.cancel()
        soundLoopTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                if self.monitoringAlarmIds.isEmpty {
                    break
                }
                
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                AudioServicesPlaySystemSound(1005)
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        // 포그라운드에서도 작동하도록 Timer 사용 (백업) - 메인 스레드에서 체크
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if UIApplication.shared.applicationState == .active {
                self.soundLoopTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // 모니터링 중인 알람이 없으면 타이머 중지
                    if self.monitoringAlarmIds.isEmpty {
                        self.soundLoopTimer?.invalidate()
                        self.soundLoopTimer = nil
                        return
                    }
                    
                    // 진동 및 사운드 재생
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    AudioServicesPlaySystemSound(1005)
                }
            }
        }
    }
    
    private func stopSoundLoop() {
        soundLoopTimer?.invalidate()
        soundLoopTimer = nil
        soundLoopTask?.cancel()
        soundLoopTask = nil
    }
    
    // MARK: - 백그라운드 태스크 관리
    private func startBackgroundTask() {
        // 이미 실행 중이면 시작하지 않음
        guard backgroundTaskId == .invalid else { return }
        
        // 메인 스레드에서 백그라운드 태스크 시작
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 백그라운드 태스크는 최대 30초만 실행 가능
            // 30초 이내에 종료하거나 재시작해야 함
            self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                withName: "AlarmPlayback",
                expirationHandler: { [weak self] in
                    // 백그라운드 시간이 만료되면 종료
                    guard let self = self else { return }
                    let expiredTaskId = self.backgroundTaskId
                    self.backgroundTaskId = .invalid
                    
                    // 만료된 태스크 종료
                    UIApplication.shared.endBackgroundTask(expiredTaskId)
                    print("⚠️ [AlarmService] Background task expired: \(expiredTaskId.rawValue)")
                    
                    // 알람이 계속 울리면 새로운 태스크 시작 (최대 30초)
                    if !self.monitoringAlarmIds.isEmpty {
                        print("🔊 [AlarmService] Restarting background task for ongoing alarm")
                        self.startBackgroundTask()
                    }
                }
            )
            
            if self.backgroundTaskId != .invalid {
                print("🔊 [AlarmService] Background task started: \(self.backgroundTaskId.rawValue)")
            } else {
                print("⚠️ [AlarmService] Failed to start background task")
            }
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskId != .invalid else { return }
        
        let taskId = backgroundTaskId
        backgroundTaskId = .invalid
        
        // 메인 스레드에서 백그라운드 태스크 종료
        DispatchQueue.main.async {
            UIApplication.shared.endBackgroundTask(taskId)
            print("🔊 [AlarmService] Background task ended: \(taskId.rawValue)")
        }
    }
    
    // MARK: - 모션 감지
    public func startMonitoringMotion(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ [Motion] Accelerometer not available")
            return
        }
        
        // 모션 감지 시작 (재시작 로직 포함)
        startMotionUpdates(for: executionId)
        
        // 백그라운드에서도 지속적으로 모션 감지 유지
        // 잠금 화면에서 중단되면 재시작
        let motionMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                // 모니터링 중인 알람이 없으면 종료
                guard self.monitoringAlarmIds.contains(executionId) else {
                    break
                }
                
                // 모션 업데이트가 중단되었는지 확인하고 재시작
                if !self.motionManager.isAccelerometerActive {
                    print("⚠️ [Motion] Accelerometer stopped, restarting: \(executionId)")
                    await Task { @MainActor in
                        self.startMotionUpdates(for: executionId)
                    }.value
                }
                
                // 1초마다 확인
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        // 기존 태스크 취소 후 새 태스크 저장
        if let existingTask = motionMonitorTasks[executionId] {
            existingTask.cancel()
        }
        motionMonitorTasks[executionId] = motionMonitorTask
    }
    
    private var motionMonitorTasks: [UUID: Task<Void, Never>] = [:]
    
    private func startMotionUpdates(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else {
            return
        }
        
        // 기존 업데이트 중지
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        
        // 초기화
        if motionDetectionCount[executionId] == nil {
            motionDetectionCount[executionId] = 0
        }
        lastAccel[executionId] = nil
        lastLogTime[executionId] = nil
        motionManager.accelerometerUpdateInterval = 0.05  // 더 빠른 업데이트 (0.1초 -> 0.05초)

        print("📱 [Motion] Starting motion detection: \(executionId)")
        
        let queue = OperationQueue()
        queue.name = "com.withday.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive  // 백그라운드에서도 우선순위 높게
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [Motion] Accelerometer error: \(error)")
                // 에러 발생 시 재시작 시도
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self.monitoringAlarmIds.contains(executionId) {
                        self.startMotionUpdates(for: executionId)
                    }
                }
                return
            }
            
            guard let d = data else { return }
            
            // 전체 가속도 벡터 크기 계산
            let accel = sqrt(d.acceleration.x * d.acceleration.x +
                             d.acceleration.y * d.acceleration.y +
                             d.acceleration.z * d.acceleration.z)
            
            // 중력 기준으로부터의 차이 (정지 상태에서는 약 1.0G)
            let delta = abs(accel - 1.0)
            
            // 이전 값과의 변화량 계산
            var change: Double = 0.0
            if let last = self.lastAccel[executionId] {
                change = abs(accel - last)
            }
            self.lastAccel[executionId] = accel
            
            // 디버깅: 주기적으로 현재 값 출력 (1초마다)
            let currentTime = Date().timeIntervalSince1970
            let lastLogTime = self.lastLogTime[executionId] ?? 0
            if currentTime - lastLogTime > 1.0 {
                // 메인 스레드에서 앱 상태 확인 (값들을 먼저 캡처)
                let accelValue = accel
                let deltaValue = delta
                let changeValue = change
                DispatchQueue.main.async {
                    let appState = UIApplication.shared.applicationState
                    print("📱 [Motion] Accel: \(String(format: "%.2f", accelValue)), Delta: \(String(format: "%.2f", deltaValue)), Change: \(String(format: "%.2f", changeValue)), State: \(appState.rawValue)")
                }
                self.lastLogTime[executionId] = currentTime
            }
            
            // 모션 감지: 두 조건 중 하나만 만족해도 감지 (더 민감하게)
            // 방법 1: 가속도 변화가 임계값 이상
            // 방법 2: 연속적인 변화가 임계값 이상
            let isMotionDetected = delta > self.motionThreshold || change > self.motionChangeThreshold
            
            if isMotionDetected {
                let c = (self.motionDetectionCount[executionId] ?? 0) + 1
                self.motionDetectionCount[executionId] = c
                
                print("📱 [Motion] Shake detected: \(c)/\(self.requiredMotionCount) (delta: \(String(format: "%.2f", delta)), change: \(String(format: "%.2f", change)))")
                
                // Live Activity 업데이트 (모션 횟수 표시)
                Task { @MainActor in
                    await self.updateLiveActivityMotionCount(executionId, count: c)
                    print("📱 [Motion] Live Activity updated with motion count: \(c)")
                }
                
                // 감지 후 잠시 대기 (연속 감지 방지)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    if c >= self.requiredMotionCount {
                        print("✅ [Motion] Sufficient shake detected! Stopping alarm: \(executionId)")
                        Task {
                            await self.stopAlarm(executionId)
                        }
                        self.stopMonitoringMotion(for: executionId)
                        return
                    }
                }
            }
        }
    }
    
    private func updateLiveActivityMotionCount(_ alarmId: UUID, count: Int) async {
        // 활성 Live Activity 확인
        var activity = activeActivities[alarmId]
        
        // 없으면 시스템에서 찾기
        if activity == nil {
            let activities = Activity<AlarmAttributes>.activities
            if let foundActivity = activities.first(where: { $0.attributes.alarmId == alarmId }) {
                activity = foundActivity
                activeActivities[alarmId] = foundActivity
                print("📱 [Motion] Found Live Activity in system: \(alarmId)")
            } else {
                print("⚠️ [Motion] Live Activity not found for motion update: \(alarmId)")
                return
            }
        }
        
        guard let currentActivity = activity else { return }
        
        let newState = AlarmAttributes.ContentState(
            isAlerting: currentActivity.content.state.isAlerting,
            motionCount: count,
            requiredMotionCount: requiredMotionCount,
            lastUpdateTime: Date()
        )
        
        await updateLiveActivity(for: alarmId, contentState: newState)
        print("✅ [Motion] Live Activity motion count updated: \(count)/\(requiredMotionCount)")
    }
    
    private func stopAlarm(_ alarmId: UUID) async {
        // Live Activity 종료
        await endLiveActivity(for: alarmId)
        
        // 알림 제거
        if let notificationId = scheduledNotifications[alarmId] {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId])
        }
        
        // 모니터링 중지
        if monitoringAlarmIds.contains(alarmId) {
            monitoringAlarmIds.remove(alarmId)
            stopMonitoringMotion(for: alarmId)
        }
        
        // 모든 알람이 중지되었으면 사운드 루프도 중지
        if monitoringAlarmIds.isEmpty {
            stopSoundLoop()
            endBackgroundTask()
        }
        
        print("✅ [AlarmService] Alarm stopped: \(alarmId)")
    }
    
    public func stopMonitoringMotion(for executionId: UUID) {
        // 모션 감지 태스크 취소
        if let task = motionMonitorTasks[executionId] {
            task.cancel()
            motionMonitorTasks.removeValue(forKey: executionId)
        }
        
        if motionDetectionCount[executionId] != nil {
            motionDetectionCount.removeValue(forKey: executionId)
            lastAccel.removeValue(forKey: executionId)
            lastLogTime.removeValue(forKey: executionId)
            
            if motionDetectionCount.isEmpty {
                motionManager.stopAccelerometerUpdates()
                print("📱 [Motion] Stopped all motion monitoring")
            }
        }
    }

    // MARK: - AppIntent Observer
    private func setupAppIntentObserver() {
        // 알람 끄기 Intent
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
            
            Task {
                await self.stopAlarm(alarmId)
            }
        }
        
        // 알람 스누즈 Intent
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmSnoozed"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let alarmId = userInfo["alarmId"] as? UUID,
                  let entity = self.cachedEntities[alarmId] else {
                return
            }
                
            print("⏰ [AppIntent] Notification received from alarm snooze Intent: \(alarmId)")
            
            Task {
                // 현재 알람 중지
                await self.stopAlarm(alarmId)
                
                // 10분 후 다시 울리도록 스케줄
                let snoozeTime = Date().addingTimeInterval(10 * 60) // 10분
                do {
                    try await self.scheduleAlarm(entity)
                    print("✅ [AppIntent] Alarm snoozed for 10 minutes: \(alarmId)")
                } catch {
                    print("❌ [AppIntent] Failed to snooze alarm: \(error)")
                }
            }
        }
    }
    
    // MARK: - helpers
    private func calculateNextAlarmTime(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        var candidates: [Date] = []
        
        for day in repeatDays {
            let targetWeekday = day + 1
            
            var daysToAdd = (targetWeekday - currentWeekday + 7) % 7
            if daysToAdd == 0 {
                let testComponents = calendar.dateComponents([.year, .month, .day], from: now)
                var testAlarmComponents = testComponents
                testAlarmComponents.hour = hour
                testAlarmComponents.minute = minute
                testAlarmComponents.second = 0
                testAlarmComponents.nanosecond = 0
                
                if let testAlarmDate = calendar.date(from: testAlarmComponents),
                   testAlarmDate <= now {
                    daysToAdd = 7
                }
            }
            
            guard let baseDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                continue
            }
            
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.second = 0
            dateComponents.nanosecond = 0
            
            guard let alarmDate = calendar.date(from: dateComponents), alarmDate > now else {
                continue
            }
            
            candidates.append(alarmDate)
        }
        
        return candidates.sorted().first ?? now
    }
}

// MARK: - Notification Delegate
private class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var alarmService: AlarmServiceImpl?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 백그라운드에서도 알림 표시
        completionHandler([.banner, .sound, .badge])
        
        // 알람 트리거
        if let alarmIdString = notification.request.content.userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            print("🔔 [NotificationDelegate] Alarm notification received: \(alarmId)")
            Task { @MainActor in
                await self.alarmService?.triggerAlarm(alarmId: alarmId)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        if let alarmIdString = response.notification.request.content.userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            print("📱 [NotificationDelegate] Alarm notification tapped: \(alarmId)")
        }
        completionHandler()
    }
}

