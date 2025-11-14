import Foundation
import SwiftUI
import UIKit
import UserNotifications
import AudioToolbox
import AlarmScheduleCoreInterface
import AlarmScheduleDomainInterface
import Utility
import AppIntents
import ActivityKit
import BaseFeature

public final class AlarmScheduleServiceImpl: AlarmScheduleService {

    private let notificationCenter = UNUserNotificationCenter.current()

    private var cachedEntities: [UUID: AlarmScheduleEntity] = [:]
    private var activeActivities: [UUID: Activity<AlarmAttributes>] = [:]
    private var lastActivityUpdateTime: [UUID: Date] = [:]
    private var triggeredAlarmIds: Set<UUID> = [] // isAlerting이 true로 설정된 알람 ID들

    private var alarmCheckTask: Task<Void, Never>?
    private var activityMonitorTask: Task<Void, Never>?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var soundLoopTask: Task<Void, Never>?

    public init() {
        setupAppStateObserver()
        startAlarmCheckTask()
        setupAppIntentObserver()
        startActivityMonitoringTask()
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
            
            if todayAlarmDate > now {
                nextAlarmTime = todayAlarmDate
            } else {
                guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else {
                    throw AlarmServiceError.dateCalculationFailed
                }
                nextAlarmTime = tomorrowAlarmDate
            }
         } else {
            nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: alarm.repeatDays)
        }
        
        try await startLiveActivity(alarm: alarm, scheduledTime: nextAlarmTime)
    }
    
    // MARK: - Live Activity 시작
    private func startLiveActivity(alarm: AlarmScheduleEntity, scheduledTime: Date) async throws {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("❌ [AlarmService] Live Activities가 활성화되지 않음")
            throw AlarmServiceError.liveActivitiesNotEnabled
        }
        
        let now = Date()
        let allActivities = Activity<AlarmAttributes>.activities
        
        // 먼저 활성화된 Activity 확인
        var activeAlarmIds: Set<UUID> = []
        for activity in allActivities {
            activeAlarmIds.insert(activity.attributes.alarmId)
        }
        
        print("🔍 [AlarmService] 활성화된 Activity: \(activeAlarmIds.count)개")
        print("🔍 [AlarmService] cachedEntities 확인: \(cachedEntities.count)개")
        
        // 모든 활성화된 알람의 다음 시간 계산
        var alarmTimes: [(alarmId: UUID, alarm: AlarmScheduleEntity, time: Date)] = []
        
        for (alarmId, cachedAlarm) in cachedEntities {
            guard cachedAlarm.isEnabled else {
                print("  - 알람 \(alarmId): 비활성화됨")
                continue
            }
            
            let comps = cachedAlarm.time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else {
                print("  - 알람 \(alarmId): 잘못된 시간 형식")
                continue
            }
            let hour = comps[0], minute = comps[1]
            
            let calendar = Calendar.current
            let nextAlarmTime: Date
            if cachedAlarm.repeatDays.isEmpty {
                var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                todayComponents.hour = hour
                todayComponents.minute = minute
                todayComponents.second = 0
                todayComponents.nanosecond = 0
                
                guard let todayAlarmDate = calendar.date(from: todayComponents) else {
                    print("  - 알람 \(alarmId): 날짜 생성 실패")
                    continue
                }
                
                if todayAlarmDate > now {
                    nextAlarmTime = todayAlarmDate
                } else {
                    guard let tomorrowAlarmDate = calendar.date(byAdding: .day, value: 1, to: todayAlarmDate) else {
                        print("  - 알람 \(alarmId): 내일 날짜 계산 실패")
                        continue
                    }
                    nextAlarmTime = tomorrowAlarmDate
                }
            } else {
                nextAlarmTime = calculateNextAlarmTime(hour: hour, minute: minute, repeatDays: cachedAlarm.repeatDays)
            }
            
            if nextAlarmTime > now {
                alarmTimes.append((alarmId, cachedAlarm, nextAlarmTime))
                let isActive = activeAlarmIds.contains(alarmId)
                print("  \(isActive ? "🟢" : "✅") 알람 \(alarmId): \(nextAlarmTime) \(isActive ? "(활성화됨)" : "")")
            } else {
                print("  - 알람 \(alarmId): 과거 시간 (\(nextAlarmTime))")
            }
        }
        
        print("📋 [AlarmService] 총 \(alarmTimes.count)개 알람 후보 발견")
        
        // 활성화된 Activity가 있으면 그 중에서 가장 가까운 것 선택, 없으면 모든 알람 중에서 선택
        let closestAlarm: (alarmId: UUID, alarm: AlarmScheduleEntity, time: Date)?
        if !activeAlarmIds.isEmpty {
            // 활성화된 Activity 중에서 가장 가까운 것 선택
            let activeAlarmTimes = alarmTimes.filter { activeAlarmIds.contains($0.alarmId) }
            if let activeClosest = activeAlarmTimes.min(by: { $0.time < $1.time }) {
                closestAlarm = activeClosest
                print("🎯 [AlarmService] 활성화된 Activity 중 가장 가까운 알람: \(closestAlarm!.alarmId) at \(closestAlarm!.time)")
            } else {
                // 활성화된 Activity가 있지만 cachedEntities에 없으면 모든 알람 중에서 선택
                closestAlarm = alarmTimes.min(by: { $0.time < $1.time })
                print("🎯 [AlarmService] 활성화된 Activity가 cachedEntities에 없음 - 모든 알람 중 가장 가까운 것: \(closestAlarm?.alarmId ?? UUID()) at \(closestAlarm?.time ?? Date())")
            }
        } else {
            // 활성화된 Activity가 없으면 모든 알람 중에서 가장 가까운 것 선택
            closestAlarm = alarmTimes.min(by: { $0.time < $1.time })
            print("🎯 [AlarmService] 활성화된 Activity 없음 - 모든 알람 중 가장 가까운 것: \(closestAlarm?.alarmId ?? UUID()) at \(closestAlarm?.time ?? Date())")
        }
        
        guard let closestAlarm = closestAlarm else {
            print("❌ [AlarmService] 활성화된 알람이 없음")
            return
        }
        
        // 가장 가까운 알람의 다음 알람 찾기
        var nextAlarm: (alarmId: UUID, time: Date)? = nil
        for (alarmId, _, alarmTime) in alarmTimes {
            if alarmId != closestAlarm.alarmId && alarmTime > closestAlarm.time {
                if nextAlarm == nil || alarmTime < nextAlarm!.time {
                    nextAlarm = (alarmId, alarmTime)
                }
            }
        }
        
        let attributes = AlarmAttributes(
            alarmId: closestAlarm.alarmId,
            alarmLabel: closestAlarm.alarm.label,
            scheduledTime: closestAlarm.time,
            nextAlarmId: nextAlarm?.alarmId,
            nextAlarmTime: nextAlarm?.time
        )
        
        let initialContentState = AlarmAttributes.ContentState(
            isAlerting: false,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(state: initialContentState, staleDate: nil)
        
        // 실제 시스템의 Activity 목록 다시 확인 (최신 상태)
        let currentActivities = Activity<AlarmAttributes>.activities
        
        // 기존 Activity 확인 (실제 시스템에서 확인)
        // 1. 가장 가까운 알람의 Activity 확인
        // 2. 없으면 다른 알람의 Activity 확인 (재사용)
        var existingActivity = currentActivities.first(where: { $0.attributes.alarmId == closestAlarm.alarmId })
        
        // 가장 가까운 알람의 Activity가 없으면 다른 Activity 재사용
        if existingActivity == nil && !currentActivities.isEmpty {
            // 기존 Activity 중 하나를 재사용
            existingActivity = currentActivities.first
            print("🔄 [AlarmService] 다른 알람의 Activity 재사용: \(existingActivity!.attributes.alarmId) -> \(closestAlarm.alarmId)")
        }
        
        // 기존 Activity가 있으면 content만 업데이트 (재사용)
        if let existingActivity = existingActivity {
            print("🔄 [AlarmService] 기존 Activity 재사용 및 업데이트: \(closestAlarm.alarmId)")
            activeActivities[closestAlarm.alarmId] = existingActivity
            await existingActivity.update(activityContent)
            lastActivityUpdateTime[closestAlarm.alarmId] = Date()
            
            // 다른 알람의 Activity는 모두 종료 (가장 가까운 알람의 Activity만 유지)
            for activity in currentActivities {
                if activity.attributes.alarmId != closestAlarm.alarmId && activity.id != existingActivity.id {
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
            // 백그라운드에서는 Activity 생성 불가 (포그라운드로 돌아왔을 때 자동 생성됨)
            let appState = await MainActor.run { UIApplication.shared.applicationState }
            if appState != .active {
                print("⏸️ [AlarmService] 앱이 백그라운드 상태 - Activity 생성 건너뜀 (포그라운드 진입 시 자동 생성)")
                return
            }
            
            print("🆕 [AlarmService] 새 Activity 생성 시도: \(closestAlarm.alarmId)")
            
            do {
            let activity = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                content: activityContent
            )
            
                activeActivities[closestAlarm.alarmId] = activity
                lastActivityUpdateTime[closestAlarm.alarmId] = Date()
                print("✅ [AlarmService] Activity 생성 성공: \(closestAlarm.alarmId)")
            } catch {
                let errorDescription = error.localizedDescription
                print("❌ [AlarmService] Live Activity 생성 실패: \(errorDescription)")
                
                // visibility 에러나 foreground 에러는 나중에 다시 시도됨 (포그라운드 진입 시)
                if errorDescription.contains("visibility") || errorDescription.contains("Target is not foreground") {
                    print("⚠️ [AlarmService] Activity 생성 실패 (백그라운드) - 포그라운드 진입 시 자동 재시도")
                    return
                } else {
                    // 다른 에러는 throw
                    throw error
                }
            }
        }
    }
    
    // MARK: - Live Activity 업데이트
    private func updateLiveActivity(for alarmId: UUID, contentState: AlarmAttributes.ContentState) async {
        // 먼저 activeActivities에서 찾기
        if let activity = activeActivities[alarmId] {
            // 현재 Activity의 상태 확인
            let currentState = activity.content.state
            print("🔄 [AlarmService] Live Activity 업데이트 전: \(alarmId), 현재 isAlerting: \(currentState.isAlerting), 업데이트할 isAlerting: \(contentState.isAlerting)")
            
            // isAlerting 상태가 같고 isAlerting이 true면 업데이트 스킵 (Wake Up 화면은 시간 업데이트 불필요)
            // 단, isAlerting이 false인 경우(시간 업데이트)에는 lastUpdateTime이 다르면 업데이트
            if currentState.isAlerting == contentState.isAlerting {
                if contentState.isAlerting == true {
                    // Wake Up 화면은 업데이트 스킵
                    print("⏭️ [AlarmService] Live Activity 상태 변경 없음 (Wake Up 화면), 업데이트 스킵: \(alarmId)")
                    return
                } else {
                    // 시간 업데이트는 lastUpdateTime이 0.9초 이상 차이나면 업데이트
                    let timeDifference = abs(contentState.lastUpdateTime.timeIntervalSince(currentState.lastUpdateTime))
                    if timeDifference < 0.9 {
                        // 1초 이내의 업데이트는 스킵 (너무 빈번한 업데이트 방지)
                        return
                    }
                }
            }
            
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            
            // Activity 업데이트 시도
            do {
                try await activity.update(activityContent)
                print("✅ [AlarmService] Live Activity 업데이트 성공: \(alarmId), isAlerting: \(contentState.isAlerting)")
            } catch {
                print("❌ [AlarmService] Live Activity 업데이트 실패: \(alarmId), error: \(error)")
            }
        } else {
            // activeActivities에 없으면 전체 Activity 목록에서 찾기
            let activities = Activity<AlarmAttributes>.activities
            
            if let activity = activities.first(where: { $0.attributes.alarmId == alarmId }) {
                // 캐시에 추가
                activeActivities[alarmId] = activity
                
                let currentState = activity.content.state
                print("🔄 [AlarmService] Live Activity 업데이트 전 (재활성화): \(alarmId), 현재 isAlerting: \(currentState.isAlerting), 업데이트할 isAlerting: \(contentState.isAlerting)")
                
                let activityContent = ActivityContent(state: contentState, staleDate: nil)
                
                do {
                    try await activity.update(activityContent)
                    print("✅ [AlarmService] Live Activity 업데이트 성공 (재활성화): \(alarmId), isAlerting: \(contentState.isAlerting)")
            } catch {
                    print("❌ [AlarmService] Live Activity 업데이트 실패 (재활성화): \(alarmId), error: \(error)")
                }
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
            userInfo: ["alarmId": alarmId]
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
        
        // 알람 트리거는 먼저 처리
        for alarmId in cachedAlarmIds {
            guard cachedEntities[alarmId] != nil else { continue }
            guard let activity = activeActivities[alarmId] else { continue }
            
            let scheduledTime = activity.attributes.scheduledTime
            let currentIsAlerting = activity.content.state.isAlerting
            
            // 알람 시간이 되었고 아직 실행되지 않은 경우에만 트리거
            if now >= scheduledTime && !currentIsAlerting {
                guard cachedEntities[alarmId] != nil else { continue }
                print("⏰ [AlarmService] 알람 시간 도달: \(alarmId), scheduledTime: \(scheduledTime), now: \(now)")
                triggeredAlarmIds.insert(alarmId) // 트리거된 알람 ID 기록
                await triggerAlarm(alarmId: alarmId)
            }
        }
        
        // Widget 타이머 업데이트는 병렬로 처리하여 성능 향상
        // isAlerting이 true인 알람은 시간 업데이트를 하지 않음 (이미 Wake Up 화면이므로)
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
                    // isAlerting이 true면 위젯 업데이트 스킵 (Wake Up 화면)
                    continue 
                }
                
                // lastActivityUpdateTime이 없으면 초기화 (첫 업데이트를 위해)
                if lastActivityUpdateTime[alarmId] == nil {
                    lastActivityUpdateTime[alarmId] = Date.distantPast
                }
                
                let lastUpdate = lastActivityUpdateTime[alarmId] ?? Date.distantPast
                let timeSinceLastUpdate = now.timeIntervalSince(lastUpdate)
                
                // 1초 이상 경과했을 때만 업데이트 (Widget이 1초마다 리렌더링되도록)
                if timeSinceLastUpdate >= 1.0 {
                    group.addTask { [weak self] in
                        guard let self = self else { return }
                let newState = AlarmAttributes.ContentState(
                    isAlerting: false,
                    lastUpdateTime: now
                )
                        await self.updateLiveActivity(for: alarmId, contentState: newState)
                        await MainActor.run {
                            self.lastActivityUpdateTime[alarmId] = now
                        }
                        print("⏱️ [AlarmService] 위젯 시간 업데이트: \(alarmId), timeSinceLastUpdate: \(String(format: "%.1f", timeSinceLastUpdate))s")
                    }
                }
            }
        }
    }
    
    // MARK: - 알람 트리거
    func triggerAlarm(alarmId: UUID) async {
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
                // Activity가 없으면 생성
            do {
                try await startLiveActivity(alarm: entity, scheduledTime: Date())
                    activity = activeActivities[alarmId]
                    print("✅ [AlarmService] Live Activity 생성 완료: \(alarmId)")
            } catch {
                print("❌ [AlarmService] Live Activity 생성 실패: \(error)")
                    return
                }
            }
        }
        
        guard let activity = activity else {
            print("⚠️ [AlarmService] 알람 트리거: Activity를 찾을 수 없음: \(alarmId)")
            return
        }
        
        // isAlerting을 true로 업데이트
        let now = Date()
        let alertingState = AlarmAttributes.ContentState(
            isAlerting: true,
            lastUpdateTime: now
        )
        
        print("🔔 [AlarmService] 알람 트리거: \(alarmId), isAlerting: true, 현재 Activity 상태: \(activity.content.state.isAlerting)")
        await updateLiveActivity(for: alarmId, contentState: alertingState)
        
        // lastActivityUpdateTime 업데이트하여 위젯 업데이트 로직이 덮어쓰지 않도록 방지
        lastActivityUpdateTime[alarmId] = now
        
        // 모션 감지는 AlarmFeature에서 처리
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmTriggered"),
            object: nil,
            userInfo: ["alarmId": alarmId]
        )
        
        // GlobalEventBus로 AlarmEvent 전송
        Task {
            await GlobalEventBus.shared.publish(AlarmEvent.triggered(alarmId: alarmId))
        }
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        playAlarmSound()
    }
    
    // MARK: - 사운드 재생
    private func playAlarmSound() {
        startBackgroundTask()
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1005)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            AudioServicesPlaySystemSound(1007)
        }
        
        startSoundLoop()
    }
    
    // MARK: - 사운드 반복 재생
    private func startSoundLoop() {
        soundLoopTask?.cancel()
        soundLoopTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                AudioServicesPlaySystemSound(1005)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func stopSoundLoop() {
        soundLoopTask?.cancel()
        soundLoopTask = nil
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
        
        // 사운드 중지
        stopSoundLoop()
        endBackgroundTask()
        
        // GlobalEventBus로 AlarmEvent 전송
        Task {
            await GlobalEventBus.shared.publish(AlarmEvent.stopped(alarmId: alarmId))
        }
        
        // 알람 중지 notification 발송
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmStopped"),
            object: nil,
            userInfo: ["alarmId": alarmId]
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
                
            // 모션 감지 중지는 AlarmFeature에서 처리
            NotificationCenter.default.post(
                name: NSNotification.Name("AlarmStoppedFromIntent"),
                object: nil,
                userInfo: ["alarmId": alarmId]
            )
        }
        
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
                await self.stopAlarm(alarmId)
                
                do {
                    try await self.scheduleAlarm(entity)
                } catch {
                    print("❌ [AlarmService] 스누즈 재스케줄 실패: \(error)")
                }
            }
        }
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
