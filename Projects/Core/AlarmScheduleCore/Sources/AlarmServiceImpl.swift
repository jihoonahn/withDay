import Foundation
import SwiftUI
import UIKit
import UserNotifications
import AudioToolbox
import AVFoundation
import AlarmScheduleCoreInterface
import AlarmScheduleDomainInterface
import AlarmExecutionDomainInterface
import UserDomainInterface
import Utility
import AppIntents
import ActivityKit
import BaseFeature

public final class AlarmScheduleServiceImpl: AlarmScheduleService {

    private let notificationCenter = UNUserNotificationCenter.current()
    private let alarmExecutionUseCase: AlarmExecutionUseCase
    private let userUseCase: UserUseCase

    private var cachedEntities: [UUID: AlarmScheduleEntity] = [:]
    private var activeActivities: [UUID: Activity<AlarmAttributes>] = [:]
    private var lastActivityUpdateTime: [UUID: Date] = [:]
    private var triggeredAlarmIds: Set<UUID> = []
    private var recentlyHandledAlarmIds: [UUID: Date] = [:]
    private let recentlyHandledWindow: TimeInterval = 90
    private var alarmExecutionIds: [UUID: UUID] = [:]
    private var alarmExecutionCreatedAt: [UUID: Date] = [:]

    private var alarmCheckTask: Task<Void, Never>?
    private var activityMonitorTask: Task<Void, Never>?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var soundLoopTask: Task<Void, Never>?
    private var audioPlayer: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()

    public init(
        alarmExecutionUseCase: AlarmExecutionUseCase,
        userUseCase: UserUseCase
    ) {
        self.alarmExecutionUseCase = alarmExecutionUseCase
        self.userUseCase = userUseCase
        print("🚀 [AlarmService] AlarmScheduleServiceImpl 초기화")
        setupAppStateObserver()
        startAlarmCheckTask()
        setupAppIntentObserver()
        startActivityMonitoringTask()
        setupEventBusObserver()
    }
    
    // MARK: - EventBus Observer
    private func setupEventBusObserver() {
        Task {
            print("🔔 [AlarmService] AlarmEvent 구독 시작")
            // GlobalEventBus를 통해 알람 트리거 이벤트 수신 (Local Notification에서 발행됨)
            await GlobalEventBus.shared.subscribe(AlarmEvent.self) { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .triggered(let alarmId, let executionId):
                    print("🔔 [AlarmService] AlarmEvent.triggered 수신: \(alarmId), executionId: \(executionId?.uuidString ?? "nil")")
                    // executionId가 nil이면 스케줄 시점에 생성된 것을 찾거나 새로 생성
                    let finalExecutionId: UUID
                    if let providedExecutionId = executionId {
                        finalExecutionId = providedExecutionId
                        self.alarmExecutionIds[alarmId] = providedExecutionId
                        self.triggeredAlarmIds.remove(alarmId)
                        print("✅ [AlarmService] executionId 제공됨 - triggeredAlarmIds에서 제거하여 재트리거 허용: \(alarmId)")
                    } else {
                        // 스케줄 시점에 생성된 executionId가 있으면 사용, 없으면 새로 생성
                        if let scheduledExecutionId = self.alarmExecutionIds[alarmId] {
                            finalExecutionId = scheduledExecutionId
                            print("✅ [AlarmService] 스케줄 시점 executionId 사용: \(scheduledExecutionId)")
                        } else {
                            finalExecutionId = UUID()
                            self.alarmExecutionIds[alarmId] = finalExecutionId
                            print("⚠️ [AlarmService] executionId가 nil - 새로 생성: \(finalExecutionId)")
                        }
                        // 이미 트리거된 알람이어도 다시 트리거해야 함 (triggeredAlarmIds에서 제거)
                        self.triggeredAlarmIds.remove(alarmId)
                    }
                    // Local Notification이 알람을 트리거했을 때 처리
                    Task {
                        await self.triggerAlarm(alarmId: alarmId, executionId: finalExecutionId)
                    }
                case .stopped(let alarmId):
                    print("🔔 [AlarmService] AlarmEvent.stopped 수신: \(alarmId)")
                    // 알람 중지는 stopAlarm에서 처리
                    break
                }
            }
            print("✅ [AlarmService] AlarmEvent 구독 완료")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        alarmCheckTask?.cancel()
        activityMonitorTask?.cancel()
        soundLoopTask?.cancel()
        
        stopSoundLoop()
        endBackgroundTask()
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
            
            // 포그라운드로 돌아왔을 때 Activity가 없으면 자동 생성
            let allActivities = Activity<AlarmAttributes>.activities
            if allActivities.isEmpty && !self.cachedEntities.isEmpty {
                await self.startNextClosestAlarmLiveActivity()
            }
        }
    }

    // MARK: - schedule
    public func scheduleAlarm(_ alarm: AlarmScheduleEntity) async throws {
        print("🔧 [AlarmService] scheduleAlarm 시작: id=\(alarm.id), time=\(alarm.time), repeatDays=\(alarm.repeatDays)")
        
        // Notification 권한 확인 및 요청
        let settings = await notificationCenter.notificationSettings()
        print("🔎 [AlarmService] NotificationSettings - authorization=\(settings.authorizationStatus.rawValue), alert=\(settings.alertSetting.rawValue), sound=\(settings.soundSetting.rawValue), critical=\(settings.criticalAlertSetting.rawValue)")
        
        if settings.authorizationStatus != .authorized {
            let granted = try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert])
            if granted != true {
                print("❌ [AlarmService] 알람 권한 거부됨")
                throw AlarmServiceError.notificationAuthorizationDenied
            }
            print("✅ [AlarmService] 알람 권한 허용됨")
        }

        cachedEntities[alarm.id] = alarm

        let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else {
            throw AlarmServiceError.invalidTimeFormat
        }
        let hour = comps[0], minute = comps[1]

        let calendar = Calendar.current
        let now = Date()
        
        let nextAlarmTime: Date
         if alarm.repeatDays.isEmpty {
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            todayComponents.nanosecond = 0
            
            guard let todayAlarmDate = calendar.date(from: todayComponents) else {
                throw AlarmServiceError.dateCreationFailed
            }
            
            if todayAlarmDate <= now {
                guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else {
                    throw AlarmServiceError.dateCalculationFailed
                }
                nextAlarmTime = tomorrowAlarmDate
            } else {
                nextAlarmTime = todayAlarmDate
            }
            print("⏰ [AlarmService] 단일 알람 nextAlarmTime=\(nextAlarmTime)")
         } else {
            nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
            print("⏰ [AlarmService] 반복 알람 nextAlarmTime=\(nextAlarmTime)")
        }
        
        // Local Notification 스케줄링
        try await scheduleLocalNotification(alarm: alarm, scheduledTime: nextAlarmTime)
        
        // Live Activity도 함께 시작 (UI 표시용)
        do {
            try await startLiveActivity(alarm: alarm, scheduledTime: nextAlarmTime)
        } catch {
            print("⚠️ [AlarmService] Live Activity 시작 실패: \(error) - 알람 스케줄링은 계속 진행")
            // Live Activity 실패해도 알람 스케줄링은 계속 진행
        }
    }
    
    // MARK: - Local Notification 스케줄링
    private func scheduleLocalNotification(alarm: AlarmScheduleEntity, scheduledTime: Date) async throws {
        let notificationIdentifier = "alarm-\(alarm.id.uuidString)"
        
        // 기존 알람 Notification 제거
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        
        // Notification Content 생성
        let content = UNMutableNotificationContent()
        content.title = alarm.label ?? "알람"
        content.body = "알람 시간입니다"
        
        // 알람용 사운드 설정 - defaultCritical로 설정하여 더 큰 소리로 재생
        // 커스텀 사운드 파일이 있으면 사용, 없으면 defaultCritical 사용
        if let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "caf") ?? 
            Bundle.main.url(forResource: "alarm", withExtension: "mp3") ??
            Bundle.main.url(forResource: "alarm", withExtension: "wav") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
            print("✅ [AlarmService] 커스텀 사운드 파일 사용: \(soundURL.lastPathComponent)")
        } else {
            // 커스텀 사운드가 없으면 defaultCritical 사용 (더 큰 소리)
            if #available(iOS 15.0, *) {
                content.sound = .defaultCritical
                print("✅ [AlarmService] 기본 크리티컬 사운드 사용 (.defaultCritical)")
            } else {
                content.sound = .default
                print("✅ [AlarmService] 기본 사운드 사용 (.default)")
            }
        }
        
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // interruptionLevel 설정 (.timeSensitive 또는 .critical)
        // critical은 특별한 권한이 필요하므로 우선 timeSensitive 사용
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            print("🔔 [AlarmService] interruptionLevel = .timeSensitive 설정")
        }
        
        // executionId 미리 생성 및 AlarmExecution 생성 (알람 내역 확인용)
        let executionId = UUID()
        let createdAt = Date.now // createdAt을 미리 저장
        var executionSaved = false // 저장 성공 여부 추적
        
        // AlarmExecution을 "scheduled" 상태로 미리 생성
        do {
            guard let user = try await userUseCase.getCurrentUser() else {
                print("⚠️ [AlarmService] 사용자를 찾을 수 없어 AlarmExecution 생성 스킵")
                // 생성 실패 시 executionId를 userInfo에 포함하지 않음 (FK 제약 위반 방지)
                return
            }
            
            let execution = AlarmExecutionEntity(
                id: executionId,
                userId: user.id,
                alarmId: alarm.id,
                scheduledTime: scheduledTime,
                triggeredTime: nil,
                motionDetectedTime: nil,
                completedTime: nil,
                motionCompleted: false,
                motionAttempts: 0,
                motionData: Data(),
                wakeConfidence: nil,
                postureChanges: nil,
                snoozeCount: 0,
                totalWakeDuration: nil,
                status: "scheduled",
                viewedMemoIds: [],
                createdAt: createdAt,
                isMoving: false
            )
            
            try await alarmExecutionUseCase.saveExecution(execution)
            // 알람 ID와 executionId 매핑 저장
            alarmExecutionIds[alarm.id] = executionId
            // createdAt도 저장 (업데이트 시 사용)
            alarmExecutionCreatedAt[alarm.id] = createdAt
            executionSaved = true
            print("✅ [AlarmService] AlarmExecution 생성 완료 (scheduled): \(executionId)")

        } catch {
            print("❌ [AlarmService] AlarmExecution 생성 실패 (스케줄 시점): \(error)")
            // 생성 실패 시 executionId를 userInfo에 포함하지 않음 (FK 제약 위반 방지)
            // triggerAlarm에서 새로 생성하도록 함
        }
        
        // userInfo에 알람 ID와 executionId 저장 (저장 성공한 경우에만)
        if executionSaved {
            content.userInfo = [
                "alarmId": alarm.id.uuidString,
                "scheduledTime": scheduledTime.timeIntervalSince1970,
                "executionId": executionId.uuidString
            ]
            print("✅ [AlarmService] Local Notification 스케줄: alarmId=\(alarm.id), executionId=\(executionId)")
        } else {
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "scheduledTime": scheduledTime.timeIntervalSince1970
        ]
            print("⚠️ [AlarmService] Local Notification 스케줄 (executionId 없음): alarmId=\(alarm.id) - triggerAlarm에서 생성 예정")
        }
        
        print("✅ [AlarmService] Local Notification 스케줄: alarmId=\(alarm.id), executionId=\(executionId)")
        
        // Notification Trigger 생성 (반복 알람 처리)
        let calendar = Calendar.current
        let components: DateComponents
        if alarm.repeatDays.isEmpty {
            // 일회성 알람
            components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
            try await notificationCenter.add(request)
            print("✅ [AlarmService] Local Notification 스케줄 완료: \(alarm.id), 시간: \(scheduledTime)")
        } else {
            // 반복 알람 - 각 요일별로 Notification 생성
            for repeatDay in alarm.repeatDays {
                var weekdayComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
                weekdayComponents.weekday = repeatDay + 1 // Calendar의 weekday는 1-7 (일-토)
                weekdayComponents.weekdayOrdinal = 1
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: weekdayComponents, repeats: true)
                let identifier = "\(notificationIdentifier)-\(repeatDay)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try await notificationCenter.add(request)
            }
            print("✅ [AlarmService] 반복 Local Notification 스케줄 완료: \(alarm.id), 요일: \(alarm.repeatDays)")
        }
    }

    // MARK: - 테스트용 알람 스케줄 (디버그 전용)
    /// 앱 상태와 무관하게 10초 뒤 로컬 알림이 울리는지 확인하기 위한 테스트용 알람
    /// - Parameters:
    ///   - secondsFromNow: 지금으로부터 몇 초 뒤에 울릴지 (기본 10초)
    public func scheduleTestAlarm(secondsFromNow: TimeInterval = 10) async {
        let id = UUID().uuidString
        let identifier = "test-alarm-\(id)"
        print("🧪 [AlarmService] 테스트 알람 스케줄 시작: id=\(identifier), +\(secondsFromNow)s")
        
        let settings = await notificationCenter.notificationSettings()
        print("🧪 [AlarmService] 테스트 알람 NotificationSettings - authorization=\(settings.authorizationStatus.rawValue), alert=\(settings.alertSetting.rawValue), sound=\(settings.soundSetting.rawValue), critical=\(settings.criticalAlertSetting.rawValue)")
        
        let content = UNMutableNotificationContent()
        content.title = "Test Alarm"
        content.body = "이 알람이 울리면 알림/사운드 설정은 정상입니다."
        
        if #available(iOS 15.0, *) {
            content.sound = .defaultCritical
            content.interruptionLevel = .timeSensitive
            print("🧪 [AlarmService] 테스트 알람 사운드: .defaultCritical, interruptionLevel: .timeSensitive")
        } else {
            content.sound = .default
            print("🧪 [AlarmService] 테스트 알람 사운드: .default")
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, secondsFromNow), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ [AlarmService] 테스트 알람 스케줄 완료: \(identifier)")
        } catch {
            print("❌ [AlarmService] 테스트 알람 스케줄 실패: \(error)")
        }
    }
    
    // MARK: - Live Activity 시작
    private func startLiveActivity(alarm: AlarmScheduleEntity, scheduledTime: Date) async throws {
        let authInfo = ActivityAuthorizationInfo()
        let existingActivitiesBefore = Activity<AlarmAttributes>.activities
        
        guard authInfo.areActivitiesEnabled else {
            throw AlarmServiceError.liveActivitiesNotEnabled
        }
        
        // 전달받은 알람을 사용
        let targetAlarm = (alarmId: alarm.id, alarm: alarm, time: scheduledTime)
        
        let attributes = AlarmAttributes(
            alarmId: targetAlarm.alarmId,
            alarmLabel: targetAlarm.alarm.label,
            scheduledTime: targetAlarm.time
        )
        
        let initialContentState = AlarmAttributes.ContentState(
            isAlerting: false,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(state: initialContentState, staleDate: nil)
        let currentActivities = Activity<AlarmAttributes>.activities
        
        // 기존 Activity 확인
        var existingActivity = currentActivities.first(where: { $0.attributes.alarmId == targetAlarm.alarmId })
        
        // 같은 알람의 Activity가 없으면 다른 Activity 재사용
        if existingActivity == nil && !currentActivities.isEmpty {
            existingActivity = currentActivities.first
            print("🔄 [AlarmService] 다른 알람의 Activity 재사용: \(existingActivity!.attributes.alarmId) -> \(targetAlarm.alarmId)")
        }
        
        // 기존 Activity가 있으면 content만 업데이트 (재사용)
        if let existingActivity = existingActivity {
            print("🔄 [AlarmService] 기존 Activity 재사용 및 업데이트: \(targetAlarm.alarmId)")
            activeActivities[targetAlarm.alarmId] = existingActivity

            await existingActivity.update(activityContent)
            lastActivityUpdateTime[targetAlarm.alarmId] = Date()
            
            // 다른 알람의 Activity는 모두 종료 (현재 알람의 Activity만 유지)
            for activity in currentActivities {
                if activity.attributes.alarmId != targetAlarm.alarmId && activity.id != existingActivity.id {
                    print("🔔 [AlarmService] 다른 알람의 Activity 종료: \(activity.attributes.alarmId)")
                    let finalState = activity.content.state
                    let finalContent = ActivityContent(state: finalState, staleDate: nil)
                    await activity.end(finalContent, dismissalPolicy: .immediate)
                    activeActivities.removeValue(forKey: activity.attributes.alarmId)
                    lastActivityUpdateTime.removeValue(forKey: activity.attributes.alarmId)
                }
            }
        } else {
            // 기존 Activity가 없으면 새로 생성
            let appState = await MainActor.run { UIApplication.shared.applicationState }
            print("🔍 [AlarmService] 앱 상태: \(appState == .active ? "active" : appState == .background ? "background" : "inactive")")
            
            if appState != .active {
                print("⏸️ [AlarmService] 앱이 백그라운드 상태 - Activity 생성 건너뜀 (포그라운드 진입 시 자동 생성)")
                return
            }
            
            print("🆕 [AlarmService] 새 Activity 생성 시도: alarmId=\(targetAlarm.alarmId), scheduledTime=\(targetAlarm.time)")
            
            do {
            let activity = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                content: activityContent
            )
            
                // Activity 상태 확인
                let activityState = activity.activityState
                print("📊 [AlarmService] Activity 상태: \(activityState)")
                print("📊 [AlarmService] Activity ID: \(activity.id)")
                
                // Activity가 실제로 시작되었는지 확인
                if activityState == .active {
                    print("✅ [AlarmService] Activity 활성화됨: \(targetAlarm.alarmId)")
                } else {
                    print("⚠️ [AlarmService] Activity 생성되었지만 활성화되지 않음: state=\(activityState)")
                }
                
                activeActivities[targetAlarm.alarmId] = activity
                lastActivityUpdateTime[targetAlarm.alarmId] = Date()
                print("✅ [AlarmService] Activity 생성 성공: \(targetAlarm.alarmId), activityId=\(activity.id), state=\(activityState)")
                
                // Activity가 active 상태이면 성공적으로 생성된 것입니다
                if activityState == .active {
                    print("✅ [AlarmService] Activity가 활성 상태입니다")
                    print("   💡 Lock Screen을 내려서 Live Activity를 확인하세요")
                    print("   💡 iPhone 14 Pro 이상은 Dynamic Island도 확인하세요")
                    print("   💡 Live Activities가 설정에서 활성화되어 있는지 확인하세요")
                    
                    // 시스템에 등록된 Activity 확인 (약간의 지연 후 확인)
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                    let registeredActivities = Activity<AlarmAttributes>.activities
                    print("📋 [AlarmService] 시스템에 등록된 Activity 개수: \(registeredActivities.count)")
                    
                    if registeredActivities.isEmpty {
                        print("⚠️ [AlarmService] 시스템 목록에 Activity가 나타나지 않음")
                        print("   💡 이는 정상일 수 있습니다 - Activity는 생성되었지만 시스템 목록에 즉시 나타나지 않을 수 있습니다")
                        print("   💡 Lock Screen을 직접 확인해보세요")
                    } else {
                        for registeredActivity in registeredActivities {
                            print("  📌 Activity: \(registeredActivity.id)")
                            print("    - alarmId: \(registeredActivity.attributes.alarmId)")
                            print("    - state: \(registeredActivity.activityState)")
                            print("    - isAlerting: \(registeredActivity.content.state.isAlerting)")
                        }
                    }
                } else {
                    print("⚠️ [AlarmService] Activity 상태가 active가 아닙니다: \(activityState)")
                }
            } catch {
                let errorDescription = error.localizedDescription
                print("❌ [AlarmService] Live Activity 생성 실패: \(error)")
                print("❌ [AlarmService] Error description: \(errorDescription)")
                print("❌ [AlarmService] Error type: \(type(of: error))")
                
                if errorDescription.contains("visibility") || errorDescription.contains("Target is not foreground") {
                    print("⚠️ [AlarmService] Activity 생성 실패 (백그라운드) - 포그라운드 진입 시 자동 재시도")
                    return
                } else {
                    throw error
                }
            }
        }
    }
    
    // MARK: - Live Activity 업데이트
    
    /// Live Activity 시간 업데이트 전용 (1초마다 호출, 5초 체크 없음)
    private func updateLiveActivityForTimeUpdate(for alarmId: UUID, contentState: AlarmAttributes.ContentState) async {
        guard let activity = activeActivities[alarmId] else { return }
        
        let activityContent = ActivityContent(state: contentState, staleDate: nil)
        await activity.update(activityContent)
    }
    
    /// Live Activity 업데이트 (상태 변경 시 사용, 스마트 체크 포함)
    private func updateLiveActivity(for alarmId: UUID, contentState: AlarmAttributes.ContentState) async {
        // 먼저 activeActivities에서 찾기
        if let activity = activeActivities[alarmId] {
            // 현재 Activity의 상태 확인
            let currentState = activity.content.state
            print("🔄 [AlarmService] Live Activity 업데이트 전: \(alarmId), 현재 isAlerting: \(currentState.isAlerting), 업데이트할 isAlerting: \(contentState.isAlerting)")
            
            // isAlerting 상태 변경이 있는 경우 무조건 업데이트
            if currentState.isAlerting != contentState.isAlerting {
                print("🔄 [AlarmService] isAlerting 상태 변경: \(currentState.isAlerting) -> \(contentState.isAlerting), 업데이트 진행")
            } else if currentState.isAlerting == contentState.isAlerting {
                // 상태가 같을 때만 스킵 로직 적용
                if contentState.isAlerting == true {
                    // Wake Up 화면은 시간 업데이트 불필요하므로 스킵
                    print("⏭️ [AlarmService] Live Activity 상태 변경 없음 (Wake Up 화면), 업데이트 스킵: \(alarmId)")
                    return
                } else {
                    // 시간 업데이트는 lastUpdateTime이 5초 이상 차이나면 업데이트 (macOS Activity 안정성 향상)
                    let timeDifference = abs(contentState.lastUpdateTime.timeIntervalSince(currentState.lastUpdateTime))
                    if timeDifference < 5.0 {
                        // 5초 이내의 업데이트는 스킵 (너무 빈번한 업데이트 방지, 특히 macOS에서)
                        return
                    }
                }
            }
            
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            
            await activity.update(activityContent)
        } else {
            // activeActivities에 없으면 전체 Activ헤ity 목록에서 찾기
            let activities = Activity<AlarmAttributes>.activities
            
            if let activity = activities.first(where: { $0.attributes.alarmId == alarmId }) {
                // 캐시에 추가
                activeActivities[alarmId] = activity
                
                let currentState = activity.content.state
                let activityContent = ActivityContent(state: contentState, staleDate: nil)
                await activity.update(activityContent)
            } else {
                print("⚠️ [AlarmService] Live Activity를 찾을 수 없음: \(alarmId)")
                // 활성 Activity 목록 확인
                let allActivities = Activity<AlarmAttributes>.activities
                print("📋 [AlarmService] 현재 활성 Activity 개수: \(allActivities.count)")
                for activeActivity in allActivities {
                    print("   - Activity: \(activeActivity.attributes.alarmId), isAlerting: \(activeActivity.content.state.isAlerting)")
                }
            }
        }
    }
    

    // MARK: - cancel
    public func cancelAlarm(_ alarmId: UUID) async throws {
        // Local Notification 제거
        let notificationIdentifier = "alarm-\(alarmId.uuidString)"
        var identifiersToRemove = [notificationIdentifier]
        
        // 반복 알람의 경우 모든 요일별 Notification 제거
        if let alarm = cachedEntities[alarmId] {
            for repeatDay in alarm.repeatDays {
                identifiersToRemove.append("\(notificationIdentifier)-\(repeatDay)")
            }
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        print("✅ [AlarmService] Local Notification 취소: \(alarmId)")
        
        // 알람 취소 시 Activity 종료 (다음 알람이 있어도 취소된 알람의 Activity는 종료)
        let currentActivities = Activity<AlarmAttributes>.activities
        if let activity = currentActivities.first(where: { $0.attributes.alarmId == alarmId }) {
            let finalState = activity.content.state
            let finalContent = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
            activeActivities.removeValue(forKey: alarmId)
            lastActivityUpdateTime.removeValue(forKey: alarmId)
        }
        
        // 모션 감지 중지는 AlarmFeature에서 처리
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmCancelled"),
            object: nil,
            userInfo: ["alarmId": alarmId.uuidString]  // String으로 저장
        )
        
        cachedEntities.removeValue(forKey: alarmId)
        
        // 사운드 및 백그라운드 태스크 정리
        stopSoundLoop()
        endBackgroundTask()
        
        // 다음 알람 시작
        await startNextClosestAlarmLiveActivity()
    }

    // MARK: - update
    public func updateAlarm(_ alarm: AlarmScheduleEntity) async throws {
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
        if let activity = activeActivities[alarmId] {
            let contentState = activity.content.state
            if contentState.isAlerting {
                return .alerting
            } else {
                return .scheduled
            }
        }
        
        return nil
    }
    
    // MARK: - 백그라운드 알람 체크
    private func startAlarmCheckTask() {
        alarmCheckTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                await self.checkActiveAlarms()
                // 정확히 1초마다 실행 (Task.sleep은 정확한 타이밍을 보장하지 않으므로 다시 호출)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    // MARK: - Activity 모니터링
    private func startActivityMonitoringTask() {
        activityMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                await self.monitorActivities()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    private func monitorActivities() async {
        let allActivities = Activity<AlarmAttributes>.activities
        
        for activity in allActivities {
            let alarmId = activity.attributes.alarmId
            
            if activeActivities[alarmId] == nil {
                activeActivities[alarmId] = activity
            }
        }
        
        let activeAlarmIds = Set(allActivities.map { $0.attributes.alarmId })
        
        for (alarmId, _) in activeActivities {
            if !activeAlarmIds.contains(alarmId) {
                activeActivities.removeValue(forKey: alarmId)
            }
        }
    }
    
    private func checkActiveAlarms() async {
        let now = Date()
        let cachedAlarmIds = Array(cachedEntities.keys)
        let calendar = Calendar.current
        
        // 최근 처리된 알람 정리
        recentlyHandledAlarmIds = recentlyHandledAlarmIds.filter { now.timeIntervalSince($0.value) < recentlyHandledWindow }
        
        // 1. 먼저 알람 시간 체크 및 자동 트리거
        for alarmId in cachedAlarmIds {
            // 이미 트리거된 알람은 스킵
            guard !triggeredAlarmIds.contains(alarmId) else { continue }
            
            // 최근에 처리된 알람은 스킵 (stopAlarm 후 재트리거 방지) - 먼저 체크
            if let lastHandled = recentlyHandledAlarmIds[alarmId],
               now.timeIntervalSince(lastHandled) < recentlyHandledWindow {
                continue
            }
            
            guard let alarm = cachedEntities[alarmId] else { continue }
            
            // 알람 시간 파싱
            let comps = alarm.time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else { continue }
            let hour = comps[0], minute = comps[1]
            
            // 오늘 알람 시간 계산
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            todayComponents.nanosecond = 0
            
            guard let todayAlarmDate = calendar.date(from: todayComponents) else { continue }
            
            // 알람 시간이 지났는지 확인 (1분 이내 여유 시간 포함)
            let timeSinceAlarm = now.timeIntervalSince(todayAlarmDate)
            
            // 오늘 알람 시간이 지났고, 1분 이내면 트리거
            if timeSinceAlarm >= 0 && timeSinceAlarm <= 60 {
                // 반복 알람인 경우, 오늘이 반복 요일에 포함되는지 확인
                if !alarm.repeatDays.isEmpty {
                    let currentWeekday = calendar.component(.weekday, from: now)
                    let targetWeekday = currentWeekday - 1  // 1(일)~7(토) -> 0(일)~6(토)로 변환
                    guard alarm.repeatDays.contains(targetWeekday) else {
                        // 오늘이 반복 요일에 포함되지 않으면 스킵
                        continue
                    }
                }
                
                print("⏰ [AlarmService] 알람 시간 도달 감지: \(alarmId), 시간: \(alarm.time), 현재: \(now), timeSinceAlarm: \(String(format: "%.1f", timeSinceAlarm))s")
                
                // 중복 트리거 방지: 이미 트리거된 알람이면 스킵
                if triggeredAlarmIds.contains(alarmId) {
                    print("⏭️ [AlarmService] checkActiveAlarms: 이미 트리거된 알람, 무시: \(alarmId)")
                    continue
                }
                
                // executionId 찾기 (스케줄 시점에 생성된 것 또는 새로 생성)
                let executionId: UUID
                if let scheduledExecutionId = alarmExecutionIds[alarmId] {
                    executionId = scheduledExecutionId
                    print("✅ [AlarmService] 스케줄 시점 executionId 사용: \(scheduledExecutionId)")
                } else {
                    // 스케줄 시점에 생성되지 않았으면 새로 생성하고 AlarmExecution 생성
                    executionId = UUID()
                    alarmExecutionIds[alarmId] = executionId
                    print("⚠️ [AlarmService] 스케줄 시점 executionId 없음 - 새로 생성: \(executionId)")
                    
                    // AlarmExecution을 "scheduled" 상태로 생성
                    do {
                        if let user = try await userUseCase.getCurrentUser() {
                            let calendar = Calendar.current
                            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                            todayComponents.hour = hour
                            todayComponents.minute = minute
                            todayComponents.second = 0
                            todayComponents.nanosecond = 0
                            let scheduledTime = calendar.date(from: todayComponents) ?? now
                            
                            let execution = AlarmExecutionEntity(
                                id: executionId,
                                userId: user.id,
                                alarmId: alarmId,
                                scheduledTime: scheduledTime,
                                triggeredTime: nil,
                                motionDetectedTime: nil,
                                completedTime: nil,
                                motionCompleted: false,
                                motionAttempts: 0,
                                motionData: Data(),
                                wakeConfidence: nil,
                                postureChanges: nil,
                                snoozeCount: 0,
                                totalWakeDuration: nil,
                                status: "scheduled",
                                viewedMemoIds: [],
                                createdAt: now,
                                isMoving: false
                            )
                            
                            try await alarmExecutionUseCase.saveExecution(execution)
                            alarmExecutionCreatedAt[alarmId] = execution.createdAt
                            print("✅ [AlarmService] AlarmExecution 생성 완료 (scheduled): \(executionId)")
                        } else {
                            print("⚠️ [AlarmService] 사용자를 찾을 수 없어 AlarmExecution 생성 스킵")
                        }
                    } catch {
                        print("⚠️ [AlarmService] AlarmExecution 생성 실패: \(error)")
                    }
                }
                await triggerAlarm(alarmId: alarmId, executionId: executionId)
                continue
            }
        }
        
        // 2. 위젯 시간 업데이트 (1초마다 실행)
        await withTaskGroup(of: Void.self) { group in
            for alarmId in cachedAlarmIds {
                guard cachedEntities[alarmId] != nil else { continue }
                guard let activity = activeActivities[alarmId] else { continue }
                
                // 트리거된 알람이거나 실행 중인 알람은 시간 업데이트 스킵 (Wake Up 화면)
                if triggeredAlarmIds.contains(alarmId) {
                    continue
                }
                
                // 알람이 실행 중이 아닐 때만 시간 업데이트
                guard !activity.content.state.isAlerting else { 
                    continue 
                }
                
                // lastActivityUpdateTime이 없으면 초기화 (첫 업데이트를 위해)
                if lastActivityUpdateTime[alarmId] == nil {
                    lastActivityUpdateTime[alarmId] = Date.distantPast
                }
                
                let lastUpdate = lastActivityUpdateTime[alarmId] ?? Date.distantPast
                let timeSinceLastUpdate = now.timeIntervalSince(lastUpdate)
                
                // 1초 이상 경과했을 때만 업데이트
                if timeSinceLastUpdate >= 1.0 {
                    // lastActivityUpdateTime을 먼저 업데이트 (다음 체크 시점 계산을 위해)
                    lastActivityUpdateTime[alarmId] = now
                    
                    group.addTask { [weak self] in
                        guard let self = self else { return }
                let newState = AlarmAttributes.ContentState(
                    isAlerting: false,
                    lastUpdateTime: now
                )
                        await self.updateLiveActivityForTimeUpdate(for: alarmId, contentState: newState)
                        print("⏱️ [AlarmService] 위젯 시간 업데이트: \(alarmId), timeSinceLastUpdate: \(String(format: "%.1f", timeSinceLastUpdate))s")
                    }
                }
            }
        }
    }
    
    // MARK: - 알람 트리거 (내부)
    private func triggerAlarm(alarmId: UUID, executionId: UUID) async {
        let now = Date.now
        
        // 최근에 처리된 알람은 먼저 체크 (stopAlarm 후 재트리거 방지)
        if let lastHandled = recentlyHandledAlarmIds[alarmId],
           now.timeIntervalSince(lastHandled) < recentlyHandledWindow {
            print("⏭️ [AlarmService] 최근에 처리된 알람, 무시: \(alarmId)")
            return
        }
        
        // 중복 트리거 방지: triggeredAlarmIds에 먼저 추가 (동시 실행 방지)
        let wasAlreadyTriggered = triggeredAlarmIds.contains(alarmId)
        triggeredAlarmIds.insert(alarmId)
        
        if wasAlreadyTriggered {
            print("⏭️ [AlarmService] 이미 트리거된 알람, 무시: \(alarmId)")
            return
        }
        guard let entity = cachedEntities[alarmId] else { 
            print("⚠️ [AlarmService] 알람 엔티티 없음: \(alarmId)")
            return 
        }
        
        // Activity 확인 및 재활성화
        var activity = activeActivities[alarmId]
        if activity == nil {
            // activeActivities에 없으면 전체 Activity 목록에서 찾기
            let allActivities = Activity<AlarmAttributes>.activities
            if let foundActivity = allActivities.first(where: { $0.attributes.alarmId == alarmId }) {
                activeActivities[alarmId] = foundActivity
                activity = foundActivity
                print("✅ [AlarmService] Activity 재활성화: \(alarmId)")
            } else {
                // Activity가 없으면 생성 (실제 알람 시간 계산)
                do {
                    // 알람 시간 파싱
                    let comps = entity.time.split(separator: ":").compactMap { Int($0) }
                    guard comps.count == 2 else {
                        print("❌ [AlarmService] 알람 시간 파싱 실패: \(entity.time)")
                        return
                    }
                    let hour = comps[0], minute = comps[1]
                    
                    // 다음 알람 시간 계산
                    let calendar = Calendar.current
                    var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                    todayComponents.hour = hour
                    todayComponents.minute = minute
                    todayComponents.second = 0
                    todayComponents.nanosecond = 0
                    
                    let scheduledTime: Date
                    if let todayAlarmDate = calendar.date(from: todayComponents) {
                        if todayAlarmDate > now {
                            scheduledTime = todayAlarmDate
                        } else {
                            // 오늘 알람 시간이 지났으면 내일로
                            scheduledTime = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) ?? todayAlarmDate
                        }
                    } else {
                        scheduledTime = now
                    }
                    
                    try await startLiveActivity(alarm: entity, scheduledTime: scheduledTime)
                    activity = activeActivities[alarmId]
                    print("✅ [AlarmService] Live Activity 생성 완료: \(alarmId), scheduledTime=\(scheduledTime)")
            } catch {
                print("❌ [AlarmService] Live Activity 생성 실패: \(error)")
                    return
                }
            }
        }
        
        guard let activity = activity else {
            print("⚠️ [AlarmService] 알람 트리거: Activity를 찾을 수 없음: \(alarmId)")
            // Activity를 찾을 수 없으면 triggeredAlarmIds에서 제거
            triggeredAlarmIds.remove(alarmId)
            return
        }
        
        print("✅ [AlarmService] 알람 트리거 시작: \(alarmId), executionId: \(executionId)")
        
        // isAlerting을 true로 업데이트
        let alertingState = AlarmAttributes.ContentState(
            isAlerting: true,
            lastUpdateTime: now
        )
        
        let currentIsAlerting = activity.content.state.isAlerting
        print("🔔 [AlarmService] 알람 트리거: \(alarmId), 현재 isAlerting: \(currentIsAlerting) -> true")
        
        // isAlerting이 false에서 true로 변경되는 경우 무조건 업데이트
        if !currentIsAlerting {
            print("🔄 [AlarmService] isAlerting 업데이트 시작: false -> true")
        await updateLiveActivity(for: alarmId, contentState: alertingState)
            print("✅ [AlarmService] isAlerting 업데이트 완료: true")
        } else {
            print("⚠️ [AlarmService] isAlerting이 이미 true, 업데이트 스킵")
        }
        
        // lastActivityUpdateTime 업데이트하여 위젯 업데이트 로직이 덮어쓰지 않도록 방지
        lastActivityUpdateTime[alarmId] = now
        
        // AlarmExecution 업데이트 - 기존 execution을 불러와서 필요한 필드만 업데이트
        do {
            // Repository에서 직접 fetch (UseCase에 fetch 메서드가 없음)
            // UseCase를 통해 가져오거나, status만 업데이트하거나, 전체 데이터 보존해야 함
            // 현재는 status만 업데이트 (다른 메서드는 완료 시나 모션 감지 시 호출됨)
            // 하지만 scheduledTime은 업데이트할 수 있으므로 기존 execution을 불러와야 함
            
            // 간단한 방법: status만 업데이트하고, 나머지는 다른 메서드에서 처리
            // 하지만 scheduledTime은 계산해야 하므로, 기존 execution을 불러와서 업데이트
            
            // 임시 해결책: getExecutions로 찾기 (비효율적이지만 UseCase에 fetch 메서드가 없음)
            guard let user = try await userUseCase.getCurrentUser() else {
                print("❌ [AlarmService] 사용자를 찾을 수 없어 AlarmExecution 업데이트 실패 - 알람 처리 중단")
                return
            }
            
            // 오늘 날짜로 모든 execution 가져오기
            let executions = try await alarmExecutionUseCase.getExecutions(userId: user.id, date: now)
            guard var existingExecution = executions.first(where: { $0.id == executionId }) else {
                // execution을 찾을 수 없으면 새로 생성 (스케줄 시점에 생성되지 않은 경우)
            let calendar = Calendar.current
            let comps = entity.time.split(separator: ":").compactMap { Int($0) }
            var scheduledTime = now
            if comps.count == 2 {
                let hour = comps[0], minute = comps[1]
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = hour
                components.minute = minute
                components.second = 0
                components.nanosecond = 0
                scheduledTime = calendar.date(from: components) ?? now
            }
            
                let newExecution = AlarmExecutionEntity(
                id: executionId,
                userId: user.id,
                alarmId: alarmId,
                scheduledTime: scheduledTime,
                triggeredTime: now,
                motionDetectedTime: nil,
                completedTime: nil,
                motionCompleted: false,
                motionAttempts: 0,
                motionData: Data(),
                wakeConfidence: nil,
                postureChanges: nil,
                snoozeCount: 0,
                totalWakeDuration: nil,
                status: "triggered",
                viewedMemoIds: [],
                    createdAt: now,
                isMoving: false
            )
                try await alarmExecutionUseCase.saveExecution(newExecution)
                print("✅ [AlarmService] AlarmExecution 새로 생성 (triggered): \(executionId)")
                return
            }
            
            // 기존 execution의 모든 데이터를 보존하면서 필요한 필드만 업데이트
            existingExecution.triggeredTime = now
            existingExecution.status = "triggered"
            // scheduledTime도 업데이트 (알람 시간이 변경되었을 수 있음)
            let calendar = Calendar.current
            let comps = entity.time.split(separator: ":").compactMap { Int($0) }
            if comps.count == 2 {
                let hour = comps[0], minute = comps[1]
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = hour
                components.minute = minute
                components.second = 0
                components.nanosecond = 0
                if let scheduledTime = calendar.date(from: components) {
                    existingExecution.scheduledTime = scheduledTime
                }
            }
            
            try await alarmExecutionUseCase.saveExecution(existingExecution)
            print("✅ [AlarmService] AlarmExecution 업데이트 완료 (triggered): \(executionId), 기존 데이터 보존됨")
        } catch {
            print("❌ [AlarmService] AlarmExecution 업데이트 실패: \(error) - 알람 처리 중단")
            return
        }
        
        // 모션 감지는 AlarmFeature에서 처리 (executionId 필수)
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmTriggered"),
            object: nil,
            userInfo: [
                "alarmId": alarmId.uuidString,
                "executionId": executionId.uuidString
            ]
        )
        
        // GlobalEventBus로 AlarmEvent 전송 (executionId 포함)
        Task {
            await GlobalEventBus.shared.publish(AlarmEvent.triggered(alarmId: alarmId, executionId: executionId))
        }
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        playAlarmSound()
    }
    
    // MARK: - 사운드 재생
    private func playAlarmSound() {
        startBackgroundTask()
        setupAudioSession()
        
        // 진동
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // AVAudioPlayer로 사운드 재생 (백그라운드에서도 재생 가능)
        playAlarmSoundWithAVAudioPlayer()
        
        // 시스템 사운드도 함께 재생 (즉시 재생)
        AudioServicesPlaySystemSound(1005)
        
        // 사운드 루프 시작
        startSoundLoop()
    }
    
    // MARK: - AVAudioSession 설정
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            print("✅ [AlarmService] AVAudioSession 설정 완료")
        } catch {
            print("❌ [AlarmService] AVAudioSession 설정 실패: \(error)")
        }
    }
    
    // MARK: - AVAudioPlayer로 사운드 재생
    private func playAlarmSoundWithAVAudioPlayer() {
        // 커스텀 사운드 파일 찾기
        let soundFiles = ["alarm.caf", "alarm.mp3", "alarm.wav", "alarm.m4a"]
        var soundURL: URL?
        
        for soundFile in soundFiles {
            let components = soundFile.components(separatedBy: ".")
            guard components.count == 2 else { continue }
            let name = components[0]
            let ext = components[1]
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                soundURL = url
                break
            }
        }
        
        // 커스텀 사운드 파일이 없으면 시스템 사운드 사용 (AVAudioPlayer는 .caf/.mp3/.wav만 지원)
        if soundURL == nil {
            // 시스템 사운드를 사용하거나, 기본 알람 사운드 파일 경로 시도
            if let defaultAlarm = Bundle.main.url(forResource: "default_alarm", withExtension: "caf") {
                soundURL = defaultAlarm
            }
        }
        
        guard let url = soundURL else {
            print("⚠️ [AlarmService] 사운드 파일을 찾을 수 없음, 시스템 사운드만 사용")
            return
        }
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // 무한 반복
            audioPlayer?.volume = 1.0 // 최대 볼륨
            audioPlayer?.play()
            print("✅ [AlarmService] AVAudioPlayer로 사운드 재생 시작: \(url.lastPathComponent)")
        } catch {
            print("❌ [AlarmService] AVAudioPlayer 사운드 재생 실패: \(error)")
        }
    }
    
    // MARK: - 사운드 반복 재생
    private func startSoundLoop() {
        soundLoopTask?.cancel()
        soundLoopTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                // 진동 반복
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                
                // 시스템 사운드도 주기적으로 재생 (AVAudioPlayer와 함께)
                AudioServicesPlaySystemSound(1005)
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func stopSoundLoop() {
        print("🔇 [AlarmService] 사운드 중지 시작")
        
        // Task 취소
        soundLoopTask?.cancel()
        soundLoopTask = nil
        
        // AVAudioPlayer 정지
        if let player = audioPlayer {
            player.stop()
            print("🔇 [AlarmService] AVAudioPlayer 정지")
        }
        audioPlayer = nil
        
        // AVAudioSession 비활성화
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ [AlarmService] AVAudioSession 비활성화 완료")
        } catch {
            print("❌ [AlarmService] AVAudioSession 비활성화 실패: \(error)")
        }
        
        print("✅ [AlarmService] 사운드 재생 중지 완료")
    }
    
    // MARK: - 백그라운드 태스크 관리
    private func startBackgroundTask() {
        guard backgroundTaskId == .invalid else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                withName: "AlarmPlayback",
                expirationHandler: { [weak self] in
                    guard let self = self else { return }
                    let expiredTaskId = self.backgroundTaskId
                    self.backgroundTaskId = .invalid
                    UIApplication.shared.endBackgroundTask(expiredTaskId)
                    // 만료 시 새로운 백그라운드 태스크 시작
                        self.startBackgroundTask()
                }
            )
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskId != .invalid else { return }
        
        let taskId = backgroundTaskId
        backgroundTaskId = .invalid
        
        DispatchQueue.main.async {
            UIApplication.shared.endBackgroundTask(taskId)
        }
    }
    
    // MARK: - 알람 중지 (앱에서 Stop 기능 호출 시 Activity 종료)
    public func stopAlarm(_ alarmId: UUID) async {
        print("🛑 [AlarmService] stopAlarm 호출됨: \(alarmId)")
        
        // 트리거된 알람 목록에서 제거
        triggeredAlarmIds.remove(alarmId)
        print("🛑 [AlarmService] 알람 중지: \(alarmId), triggeredAlarmIds에서 제거")
        recentlyHandledAlarmIds[alarmId] = Date()
        
        // 모든 알람의 사운드 중지 (여러 알람이 동시에 재생 중일 수 있음)
        stopSoundLoop()
        endBackgroundTask()
        
        // 모든 트리거된 알람이 중지되었는지 확인
        if triggeredAlarmIds.isEmpty {
            print("✅ [AlarmService] 모든 알람 중지됨 - 사운드 완전 중지")
        }
        
        // GlobalEventBus로 AlarmEvent 전송
        Task {
            await GlobalEventBus.shared.publish(AlarmEvent.stopped(alarmId: alarmId))
        }
        
        // 알람 중지 notification 발송
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmStopped"),
            object: nil,
            userInfo: ["alarmId": alarmId.uuidString]  // String으로 저장
        )
        
        // Activity 종료
        let currentActivities = Activity<AlarmAttributes>.activities
        if let currentActivity = currentActivities.first(where: { $0.attributes.alarmId == alarmId }) {
            print("🔔 [AlarmService] Activity 종료: \(alarmId)")
                let finalState = currentActivity.content.state
                let finalContent = ActivityContent(state: finalState, staleDate: nil)
                await currentActivity.end(finalContent, dismissalPolicy: .immediate)
                activeActivities.removeValue(forKey: alarmId)
            lastActivityUpdateTime.removeValue(forKey: alarmId)
            } else {
            print("⚠️ [AlarmService] Activity를 찾을 수 없음: \(alarmId)")
        }
        
        // 다음 알람 시작
        await startNextClosestAlarmLiveActivity()
    }
    
    // MARK: - 활성화된 알람 정보 조회 (foreground에서)
    public func getActiveAlarms() async -> [(attributes: AlarmAttributes, state: AlarmAttributes.ContentState)] {
        let allActivities = Activity<AlarmAttributes>.activities
        var activeAlarms: [(attributes: AlarmAttributes, state: AlarmAttributes.ContentState)] = []
        
        for activity in allActivities {
            activeAlarms.append((attributes: activity.attributes, state: activity.content.state))
        }
        
        print("📋 [AlarmService] 활성화된 알람 \(activeAlarms.count)개 발견")
        return activeAlarms
    }
    

    // MARK: - AppIntent Observer
    private func setupAppIntentObserver() {
        // AlarmSnoozed: Widget Extension에서 스누즈 요청 시 처리
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmSnoozed"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let alarmId = self.extractAlarmId(from: userInfo),
                  let entity = self.cachedEntities[alarmId] else {
                return
            }
            
            Task {
                await self.stopAlarm(alarmId)
                try? await self.scheduleAlarm(entity)
            }
        }
    }
    
    private func extractAlarmId(from userInfo: [AnyHashable: Any]) -> UUID? {
            if let uuid = userInfo["alarmId"] as? UUID {
            return uuid
            } else if let uuidString = userInfo["alarmId"] as? String,
                      let uuid = UUID(uuidString: uuidString) {
            return uuid
        }
        return nil
    }
    
    // MARK: - 다음 가까운 알람 Live Activity 시작
    private func startNextClosestAlarmLiveActivity() async {
        let now = Date.now
        var alarmTimes: [(alarm: AlarmScheduleEntity, time: Date)] = []
        
        for (alarmId, cachedAlarm) in cachedEntities {
            if activeActivities[alarmId] != nil { continue }
            guard cachedAlarm.isEnabled else { continue }
            
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
                
                // 현재 시간과 비교하여 다음 알람 시간 결정
                // todayAlarmDate가 현재 시간보다 작거나 같으면 이미 지난 시간이므로 내일로
                if todayAlarmDate <= now {
                    guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else { continue }
                    nextAlarmTime = tomorrowAlarmDate
                } else {
                    nextAlarmTime = todayAlarmDate
                }
            } else {
                nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: cachedAlarm.repeatDays)
            }
            
            if nextAlarmTime > now {
                alarmTimes.append((cachedAlarm, nextAlarmTime))
            }
        }
        
        guard let closestAlarm = alarmTimes.min(by: { $0.time < $1.time }) else {
            return
        }
        
        do {
            try await startLiveActivity(alarm: closestAlarm.alarm, scheduledTime: closestAlarm.time)
        } catch {
            print("❌ [AlarmService] 다음 알람 Live Activity 시작 실패: \(error)")
        }
    }
    
    private func calculateNextAlarmTime(hour: Int, minute: Int, repeatDays: [Int]) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        var candidates: [Date] = []
        
        // repeatDays에 있는 각 요일에 대해
        for day in repeatDays {
            let targetWeekday = day + 1  // 0(일)~6(토) -> 1(일)~7(토)로 변환
            
            // 현재 요일에서 목표 요일까지 며칠 남았는지 계산
            var daysToAdd = (targetWeekday - currentWeekday + 7) % 7
            
            // 오늘이 목표 요일이면, 시간이 지났는지 확인
            if daysToAdd == 0 {
                let testComponents = calendar.dateComponents([.year, .month, .day], from: now)
                var testAlarmComponents = testComponents
                testAlarmComponents.hour = hour
                testAlarmComponents.minute = minute
                testAlarmComponents.second = 0
                testAlarmComponents.nanosecond = 0
                
                if let testAlarmDate = calendar.date(from: testAlarmComponents),
                   testAlarmDate <= now {
                    // 오늘 알람 시간이 지났으면 다음 주로
                    daysToAdd = 7
                }
            }
            
            // 목표 날짜 계산
            guard let baseDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                continue
            }
            
            // 해당 날짜의 지정된 시간으로 설정
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
        
        // 후보 중 가장 가까운 시간 반환
        return candidates.sorted().first ?? now
    }
}
