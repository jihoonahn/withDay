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
    }
    
    // MARK: - App State Observer
    private func setupAppStateObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAlarmMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
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
        
        // Notification 권한 확인
        let authStatus = await notificationCenter.notificationSettings()
        if authStatus.authorizationStatus != .authorized {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                throw AlarmServiceError.notificationAuthorizationDenied
            }
        }
        
        // Live Activity 권한 확인
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw AlarmServiceError.liveActivitiesNotEnabled
        }
        

        cachedEntities[alarm.id] = alarm

        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            throw AlarmServiceError.invalidTimeFormat
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
                throw AlarmServiceError.dateCreationFailed
            }
            
            if todayAlarmDate > now {
                nextAlarmTime = todayAlarmDate
            } else {
                guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else {
                    throw AlarmServiceError.dateCalculationFailed
                }
                nextAlarmTime = tomorrowAlarmDate
            }
         } else {
            // 반복 알람
            nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        }

        
        try await scheduleNotification(alarmId: alarm.id, time: nextAlarmTime, label: alarm.label)
        
        try await startLiveActivity(alarm: alarm, scheduledTime: nextAlarmTime)
        
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
        content.sound = .defaultRingtone
        
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
        
    }
    
    // MARK: - Live Activity 시작
    private func startLiveActivity(alarm: AlarmEntity, scheduledTime: Date) async throws {
        
        // ActivityKit 권한 확인
        let authInfo = ActivityAuthorizationInfo()
        
        guard authInfo.areActivitiesEnabled else {
            throw AlarmServiceError.liveActivitiesNotEnabled
        }
        
        // 현재 활성화된 모든 Live Activity 확인
        let allActivities = Activity<AlarmAttributes>.activities
        let now = Date()
        
        // 모든 활성화된 알람의 다음 시간을 계산하여 가장 가까운 알람 찾기
        var alarmTimes: [(alarmId: UUID, time: Date)] = []
        
        // 현재 스케줄링하려는 알람 추가
        if scheduledTime > now {
            alarmTimes.append((alarm.id, scheduledTime))
        }
        
        // 기존 활성화된 Live Activity들의 시간 추가
        for activity in allActivities {
            let activityScheduledTime = activity.attributes.scheduledTime
            if activityScheduledTime > now {
                alarmTimes.append((activity.attributes.alarmId, activityScheduledTime))
            }
        }
        
        // cachedEntities에서도 확인 (스케줄링되었지만 Live Activity가 아직 시작되지 않은 알람들)
        for (alarmId, cachedAlarm) in cachedEntities {
            // 이미 Live Activity가 있는 알람은 제외
            if activeActivities[alarmId] != nil { continue }
            
            // 활성화된 알람만 확인
            guard cachedAlarm.isEnabled else { continue }
            
            // 다음 알람 시간 계산
            let comps = cachedAlarm.time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else { continue }
            let hour = comps[0], minute = comps[1]
            
            let calendar = Calendar.current
            let nextAlarmTime: Date
            if cachedAlarm.repeatDays.isEmpty {
                var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                todayComponents.hour = hour
                todayComponents.minute = minute
                todayComponents.second = 0
                todayComponents.nanosecond = 0
                
                guard let todayAlarmDate = calendar.date(from: todayComponents) else { continue }
                
                if todayAlarmDate > now {
                    nextAlarmTime = todayAlarmDate
                } else {
                    guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else { continue }
                    nextAlarmTime = tomorrowAlarmDate
                }
            } else {
                nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: cachedAlarm.repeatDays)
            }
            
            if nextAlarmTime > now {
                alarmTimes.append((alarmId, nextAlarmTime))
            }
        }
        
        // 가장 가까운 알람 찾기
        guard let closestAlarm = alarmTimes.min(by: { $0.time < $1.time }) else {
            // 활성화된 알람이 없으면 Live Activity를 시작하지 않음
            await endLiveActivity(for: alarm.id)
            return
        }
        
        // 현재 스케줄링하려는 알람이 가장 가까운 알람이 아니면 Live Activity를 시작하지 않음
        if closestAlarm.alarmId != alarm.id {
            // 기존 Live Activity만 제거 (현재 알람의)
            await endLiveActivity(for: alarm.id)
            return
        }
        
        // 가장 가까운 알람이므로, 다른 모든 Live Activity 종료
        for activity in allActivities {
            if activity.attributes.alarmId != alarm.id {
                await endLiveActivity(for: activity.attributes.alarmId)
            }
        }
        
        // 기존 Live Activity 제거 (현재 알람의)
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
        
        
        do {
            
            // Activity 요청 전에 Widget Extension이 등록되었는지 확인
            // Activity.request 호출 시 시스템이 자동으로 Widget Extension을 찾습니다
            let activity = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                content: activityContent
            )
            
            activeActivities[alarm.id] = activity
            
            
            // 활성 Live Activity 확인 (약간의 지연 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let allActivities = Activity<AlarmAttributes>.activities
                
                // Dynamic Island 확인
                
                if allActivities.isEmpty {
                } else {
                }
            }
        } catch {

            throw error
        }
    }
    
    // MARK: - Live Activity 업데이트
    private func updateLiveActivity(for alarmId: UUID, contentState: AlarmAttributes.ContentState) async {
        
        // 활성 Live Activity 확인
        if let activity = activeActivities[alarmId] {
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            await activity.update(activityContent)
        } else {
            // Live Activity가 없으면 현재 활성 Activity 확인
            let activities = Activity<AlarmAttributes>.activities
            
            if let activity = activities.first(where: { $0.attributes.alarmId == alarmId }) {
                activeActivities[alarmId] = activity
                
                let activityContent = ActivityContent(state: contentState, staleDate: nil)
                await activity.update(activityContent)
            } else {
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
    }

    // MARK: - cancel
    public func cancelAlarm(_ alarmId: UUID) async throws {
        // 알림 제거 (pending과 delivered 모두)
        if let notificationId = scheduledNotifications[alarmId] {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId])
            scheduledNotifications.removeValue(forKey: alarmId)
        }
        
        // Live Activity 종료
        await endLiveActivity(for: alarmId)
        
        // 모니터링 중지
        if monitoringAlarmIds.contains(alarmId) {
            monitoringAlarmIds.remove(alarmId)
            stopMonitoringMotion(for: alarmId)
        }
        
        // cachedEntities에서 제거 (가장 마지막에 제거하여 동시성 문제 방지)
        cachedEntities.removeValue(forKey: alarmId)
        
        // 모든 알람이 중지되었으면 사운드 루프도 중지
        if monitoringAlarmIds.isEmpty {
            stopSoundLoop()
            endBackgroundTask()
        }
        
        // 다음으로 가까운 알람 찾아서 Live Activity 시작
        await startNextClosestAlarmLiveActivity()
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
                throw AlarmServiceError.entityNotFound
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
        
        // cachedEntities의 복사본을 사용하여 동시성 문제 방지
        let cachedAlarmIds = Array(cachedEntities.keys)
        
        for alarmId in cachedAlarmIds {
            // 삭제된 알람인지 다시 확인 (동시성 문제 방지)
            guard cachedEntities[alarmId] != nil else { continue }
            
            guard let activity = activeActivities[alarmId] else { continue }
            
            let scheduledTime = activity.attributes.scheduledTime
            let timeRemaining = scheduledTime.timeIntervalSince(now)
            
            if now >= scheduledTime && !activity.content.state.isAlerting {
                // 트리거 전에 다시 확인 (삭제된 알람이 아닌지)
                guard cachedEntities[alarmId] != nil else { continue }
                await triggerAlarm(alarmId: alarmId)
            } else if !activity.content.state.isAlerting {
                let lastUpdate = activity.content.state.lastUpdateTime
                let timeSinceLastUpdate = now.timeIntervalSince(lastUpdate)
                
                // 5분 이내: 매번 업데이트 (1초마다 정확히 줄어들도록)
                if timeRemaining <= 300 {
                    let newState = AlarmAttributes.ContentState(
                        isAlerting: false,
                        motionCount: activity.content.state.motionCount,
                        requiredMotionCount: activity.content.state.requiredMotionCount,
                        lastUpdateTime: now
                    )
                    await updateLiveActivity(for: alarmId, contentState: newState)
                } else if timeRemaining <= 600 {
                    if timeSinceLastUpdate >= 5.0 {
                        let newState = AlarmAttributes.ContentState(
                            isAlerting: false,
                            motionCount: activity.content.state.motionCount,
                            requiredMotionCount: activity.content.state.requiredMotionCount,
                            lastUpdateTime: now
                        )
                        await updateLiveActivity(for: alarmId, contentState: newState)
                    }
                } else if timeRemaining <= 3600 {
                    if timeSinceLastUpdate >= 10.0 {
                        let newState = AlarmAttributes.ContentState(
                            isAlerting: false,
                            motionCount: activity.content.state.motionCount,
                            requiredMotionCount: activity.content.state.requiredMotionCount,
                            lastUpdateTime: now
                        )
                        await updateLiveActivity(for: alarmId, contentState: newState)
                    }
                } else {
                    // 1시간 이상: 1분마다 업데이트
                    if timeSinceLastUpdate >= 60.0 {
                        let newState = AlarmAttributes.ContentState(
                            isAlerting: false,
                            motionCount: activity.content.state.motionCount,
                            requiredMotionCount: activity.content.state.requiredMotionCount,
                            lastUpdateTime: now
                        )
                        await updateLiveActivity(for: alarmId, contentState: newState)
                    }
                }
            }
        }
    }
    
    // MARK: - 알람 트리거
    func triggerAlarm(alarmId: UUID) async {
        guard let entity = cachedEntities[alarmId] else {
            return
        }
        
        
        // Live Activity가 없으면 생성
        if activeActivities[alarmId] == nil {
            do {
                try await startLiveActivity(alarm: entity, scheduledTime: Date())
            } catch {
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
                    
                    // 알람이 계속 울리면 새로운 태스크 시작 (최대 30초)
                    if !self.monitoringAlarmIds.isEmpty {
                        self.startBackgroundTask()
                    }
                }
            )
            
            if self.backgroundTaskId != .invalid {
            } else {
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
        }
    }
    
    // MARK: - 모션 감지
    public func startMonitoringMotion(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else {
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

        
        let queue = OperationQueue()
        queue.name = "com.withday.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive  // 백그라운드에서도 우선순위 높게
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
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
                
                
                // Live Activity 업데이트 (모션 횟수 표시)
                Task { @MainActor in
                    await self.updateLiveActivityMotionCount(executionId, count: c)
                }
                
                // 감지 후 잠시 대기 (연속 감지 방지)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    if c >= self.requiredMotionCount {
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
            } else {
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
        
        // 다음으로 가까운 알람 찾아서 Live Activity 시작
        await startNextClosestAlarmLiveActivity()
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
                
            
            Task {
                // 현재 알람 중지
                await self.stopAlarm(alarmId)
                
                // 10분 후 다시 울리도록 스케줄
                let snoozeTime = Date().addingTimeInterval(10 * 60) // 10분
                do {
                    try await self.scheduleAlarm(entity)
                } catch {
                }
            }
        }
    }
    
    // MARK: - 다음 가까운 알람 Live Activity 시작
    private func startNextClosestAlarmLiveActivity() async {
        let now = Date()
        
        // 모든 활성화된 알람의 다음 시간을 계산하여 가장 가까운 알람 찾기
        var alarmTimes: [(alarm: AlarmEntity, time: Date)] = []
        
        // cachedEntities에서 활성화된 알람들 확인
        for (alarmId, cachedAlarm) in cachedEntities {
            // 이미 Live Activity가 있는 알람은 제외
            if activeActivities[alarmId] != nil { continue }
            
            // 활성화된 알람만 확인
            guard cachedAlarm.isEnabled else { continue }
            
            // 다음 알람 시간 계산
            let comps = cachedAlarm.time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else { continue }
            let hour = comps[0], minute = comps[1]
            
            let calendar = Calendar.current
            let nextAlarmTime: Date
            if cachedAlarm.repeatDays.isEmpty {
                var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                todayComponents.hour = hour
                todayComponents.minute = minute
                todayComponents.second = 0
                todayComponents.nanosecond = 0
                
                guard let todayAlarmDate = calendar.date(from: todayComponents) else { continue }
                
                if todayAlarmDate > now {
                    nextAlarmTime = todayAlarmDate
                } else {
                    guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else { continue }
                    nextAlarmTime = tomorrowAlarmDate
                }
            } else {
                nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: cachedAlarm.repeatDays)
            }
            
            if nextAlarmTime > now {
                alarmTimes.append((cachedAlarm, nextAlarmTime))
            }
        }
        
        // 가장 가까운 알람 찾기
        guard let closestAlarm = alarmTimes.min(by: { $0.time < $1.time }) else {
            return
        }
        
        // 가장 가까운 알람의 Live Activity 시작
        do {
            try await startLiveActivity(alarm: closestAlarm.alarm, scheduledTime: closestAlarm.time)
            print("🔔 [AlarmServiceImpl] 다음 가까운 알람 Live Activity 시작: \(closestAlarm.alarm.id)")
        } catch {
            print("❌ [AlarmServiceImpl] 다음 가까운 알람 Live Activity 시작 실패: \(error)")
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
        completionHandler([.banner, .sound, .badge])
        
        // 알람 트리거
        if let alarmIdString = notification.request.content.userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            Task { @MainActor in
                await self.alarmService?.triggerAlarm(alarmId: alarmId)
            }
        }
    }
}
