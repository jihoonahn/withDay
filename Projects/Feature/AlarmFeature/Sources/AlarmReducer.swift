import Foundation
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import UserDomainInterface
import SwiftDataCoreInterface
import AlarmCoreInterface
import Dependency
import Localization

public struct AlarmReducer: Reducer {
    private let remoteRepository: AlarmRepository  // Supabase (원격)
    private let localService: SwiftDataCoreInterface.AlarmService?  // SwiftData (로컬)
    private let userUseCase: UserUseCase
    private let alarmScheduler: AlarmSchedulerService?
    
    public init(
        remoteRepository: AlarmRepository,
        localService: SwiftDataCoreInterface.AlarmService? = nil,
        userUseCase: UserUseCase
    ) {
        self.remoteRepository = remoteRepository
        self.localService = localService
        self.userUseCase = userUseCase
        self.alarmScheduler = DIContainer.shared.isRegistered(AlarmSchedulerService.self) 
            ? DIContainer.shared.resolve(AlarmSchedulerService.self) 
            : nil
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await userUseCase.getCurrentUser() else {
            throw AlarmError.userNotFound
        }
        return user.id
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) -> String {
        if let alarmServiceError = error as? AlarmServiceError {
            switch alarmServiceError {
            case .notificationAuthorizationDenied:
                return "AlarmErrorNotificationPermissionDenied".localized()
            case .liveActivitiesNotEnabled:
                return "AlarmErrorLiveActivitiesDisabled".localized()
            case .invalidTimeFormat:
                return "AlarmErrorInvalidTimeFormat".localized()
            case .dateCreationFailed:
                return "AlarmErrorDateCreationFailed".localized()
            case .dateCalculationFailed:
                return "AlarmErrorDateCalculationFailed".localized()
            case .entityNotFound:
                return "AlarmErrorEntityNotFound".localized()
            }
        } else if let alarmError = error as? AlarmError {
            return alarmError.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
    
    private func formatErrorMessage(_ key: String, detail: String) -> String {
        String(
            format: key.localized(),
            locale: Locale.appLocale,
            detail
        )
    }
    
    public func reduce(state: inout AlarmState, action: AlarmAction) -> [Effect<AlarmAction>] {
        switch action {
        case .loadAlarms:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        
                        if let localService = self.localService {
                            let localModels = try await localService.fetchAlarms(userId: userId)
                            let localAlarms = localModels.map { model in
                                AlarmEntity(
                                    id: model.id,
                                    userId: model.userId,
                                    label: model.label.isEmpty ? nil : model.label,
                                    time: model.time,
                                    repeatDays: model.repeatDays,
                                    snoozeEnabled: model.snoozeEnabled,
                                    snoozeInterval: model.snoozeInterval,
                                    snoozeLimit: model.snoozeLimit,
                                    soundName: model.soundName,
                                    soundURL: model.soundURL,
                                    vibrationPattern: model.vibrationPattern,
                                    volumeOverride: model.volumeOverride,
                                    linkedMemoIds: model.linkedMemoIds,
                                    showMemosOnAlarm: model.showMemosOnAlarm,
                                    isEnabled: model.isEnabled,
                                    createdAt: model.createdAt,
                                    updatedAt: model.updatedAt
                                )
                            }
                            emitter.send(.setAlarms(localAlarms))
                            
                            // 백그라운드에서 원격 동기화
                            Task {
                                let remoteAlarms = try? await remoteRepository.fetchAlarms(userId: userId)
                                if let remoteAlarms = remoteAlarms {
                                    emitter.send(.setAlarms(remoteAlarms))
                                }
                            }
                        } else {
                            // 로컬 서비스가 없으면 원격만 사용
                            let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                            emitter.send(.setAlarms(alarms))
                        }
                    } catch {
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorLoadFailed",
                                detail: handleError(error)
                            )
                        ))
                    }
                }
            ]
            
        case .setAlarms(let alarms):
            state.isLoading = false
            state.alarms = alarms.sorted { $0.time < $1.time }            
            return [
                Effect { [self] emitter in
                    guard let scheduler = self.alarmScheduler else { return }                    
                    let currentAlarmIds = Set(alarms.map { $0.id })

                    for alarm in alarms where alarm.isEnabled {
                        do {
                            // 기존 알람 취소 후 재스케줄링 (중복 방지)
                            try await scheduler.cancelAlarm(alarm.id)
                            print("🔔 [AlarmReducer] 알람 스케줄링: \(alarm.id)")
                            try await scheduler.scheduleAlarm(alarm)
                        } catch {
                            print("❌ [AlarmReducer] 알람 스케줄링 실패: \(alarm.id), \(error)")
                        }
                    }
                    
                    // 비활성화된 알람들 취소
                    for alarm in alarms where !alarm.isEnabled {
                        do {
                            try await scheduler.cancelAlarm(alarm.id)
                            print("🔕 [AlarmReducer] 비활성화된 알람 취소: \(alarm.id)")
                        } catch {
                            print("❌ [AlarmReducer] 알람 취소 실패: \(alarm.id), \(error)")
                        }
                    }
                }
            ]
            
        case .createAlarm(let time, let label, let repeatDays):
            // 비즈니스 로직: AlarmEntity 생성 및 추가
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        
                        let newAlarm = AlarmEntity(
                            id: UUID(),
                            userId: userId,
                            label: label?.isEmpty == false ? label : nil,
                            time: time,
                            repeatDays: repeatDays,
                            snoozeEnabled: true,
                            snoozeInterval: 5,
                            snoozeLimit: 3,
                            soundName: "default",
                            soundURL: nil,
                            vibrationPattern: nil,
                            volumeOverride: nil,
                            linkedMemoIds: [],
                            showMemosOnAlarm: false,
                            isEnabled: true,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        
                        // addAlarm 액션으로 전달하여 처리
                        emitter.send(.addAlarm(newAlarm))
                    } catch {
                        print("❌ [AlarmReducer] 알람 생성 실패: \(error)")
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorCreateFailed",
                                detail: handleError(error)
                            )
                        ))
                    }
                }
            ]
            
        case .addAlarm(let alarm):
            // 중복 체크: 같은 ID의 알람이 이미 있으면 추가하지 않음
            if state.alarms.contains(where: { $0.id == alarm.id }) {
                print("⚠️ [AlarmReducer] 이미 존재하는 알람입니다: \(alarm.id)")
                return []
            }
            
            // 낙관적 업데이트: UI에서 즉시 추가
            state.alarms.append(alarm)
            state.alarms.sort { $0.time < $1.time }
            state.errorMessage = nil
            
            return [
                Effect { [self] emitter in
                    do {
                        // 1. 로컬에 저장
                        if let localService = self.localService {
                            let model = AlarmModel(
                                id: alarm.id,
                                userId: alarm.userId,
                                label: alarm.label ?? "",
                                time: alarm.time,
                                repeatDays: alarm.repeatDays,
                                snoozeEnabled: alarm.snoozeEnabled,
                                snoozeInterval: alarm.snoozeInterval,
                                snoozeLimit: alarm.snoozeLimit,
                                soundName: alarm.soundName,
                                soundURL: alarm.soundURL,
                                vibrationPattern: alarm.vibrationPattern,
                                volumeOverride: alarm.volumeOverride,
                                linkedMemoIds: alarm.linkedMemoIds,
                                showMemosOnAlarm: alarm.showMemosOnAlarm,
                                isEnabled: alarm.isEnabled,
                                createdAt: alarm.createdAt,
                                updatedAt: alarm.updatedAt
                            )
                            try await localService.saveAlarm(model)
                        }
                        
                        // 2. 원격에 저장
                        try await remoteRepository.createAlarm(alarm)
                        
                        // 3. 알람 스케줄링
                        if alarm.isEnabled {
                            print("🔔 [AlarmReducer] 알람 스케줄링 시작: \(alarm.id)")
                            try await self.alarmScheduler?.scheduleAlarm(alarm)
                        }
                        
                        print("✅ [AlarmReducer] 알람 추가 완료: \(alarm.id)")
                        
                        // 4. 성공 후 로컬에서 최신 상태 다시 로드하여 UI 동기화
                        if let localService = self.localService {
                            let userId = try await getCurrentUserId()
                            let localModels = try await localService.fetchAlarms(userId: userId)
                            let localAlarms = localModels.map { model in
                                AlarmEntity(
                                    id: model.id,
                                    userId: model.userId,
                                    label: model.label.isEmpty ? nil : model.label,
                                    time: model.time,
                                    repeatDays: model.repeatDays,
                                    snoozeEnabled: model.snoozeEnabled,
                                    snoozeInterval: model.snoozeInterval,
                                    snoozeLimit: model.snoozeLimit,
                                    soundName: model.soundName,
                                    soundURL: model.soundURL,
                                    vibrationPattern: model.vibrationPattern,
                                    volumeOverride: model.volumeOverride,
                                    linkedMemoIds: model.linkedMemoIds,
                                    showMemosOnAlarm: model.showMemosOnAlarm,
                                    isEnabled: model.isEnabled,
                                    createdAt: model.createdAt,
                                    updatedAt: model.updatedAt
                                )
                            }
                            emitter.send(.setAlarms(localAlarms))
                        }
                        
                        // 5. 알람 추가 시트 닫기
                        emitter.send(.showingAddAlarmState(false))
                    } catch {
                        // 실패 시 복구
                        print("❌ [AlarmReducer] 알람 추가 실패: \(error)")
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorAddFailed",
                                detail: handleError(error)
                            )
                        ))
                        
                        // 실패 시 목록 다시 로드하여 복구
                        do {
                            let userId = try await getCurrentUserId()
                            let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                            emitter.send(.setAlarms(alarms))
                        } catch {
                            print("❌ [AlarmReducer] 알람 목록 재로드 실패")
                        }
                    }
                }
            ]
            
        case .updateAlarm(let alarm):
            // 낙관적 업데이트: UI에서 즉시 반영
            if let index = state.alarms.firstIndex(where: { $0.id == alarm.id }) {
                state.alarms[index] = alarm
                state.alarms.sort { $0.time < $1.time }
            }
            state.errorMessage = nil
            
            return [
                Effect { [self] emitter in
                    do {
                        // 1. 로컬 업데이트
                        if let localService = self.localService {
                            let model = AlarmModel(
                                id: alarm.id,
                                userId: alarm.userId,
                                label: alarm.label ?? "",
                                time: alarm.time,
                                repeatDays: alarm.repeatDays,
                                snoozeEnabled: alarm.snoozeEnabled,
                                snoozeInterval: alarm.snoozeInterval,
                                snoozeLimit: alarm.snoozeLimit,
                                soundName: alarm.soundName,
                                soundURL: alarm.soundURL,
                                vibrationPattern: alarm.vibrationPattern,
                                volumeOverride: alarm.volumeOverride,
                                linkedMemoIds: alarm.linkedMemoIds,
                                showMemosOnAlarm: alarm.showMemosOnAlarm,
                                isEnabled: alarm.isEnabled,
                                createdAt: alarm.createdAt,
                                updatedAt: alarm.updatedAt
                            )
                            try await localService.updateAlarm(model)
                        }
                        
                        // 2. 원격 업데이트
                        try await remoteRepository.updateAlarm(alarm)
                        
                        // 3. 알람 스케줄링 업데이트
                        try await self.alarmScheduler?.cancelAlarm(alarm.id)
                        if alarm.isEnabled {
                            print("🔔 [AlarmReducer] 알람 재스케줄링: \(alarm.id)")
                            try await self.alarmScheduler?.scheduleAlarm(alarm)
                        }
                        
                        print("✅ [AlarmReducer] 알람 수정 완료: \(alarm.id)")
                        
                        // 성공 후 로컬에서 최신 상태 다시 로드하여 UI 동기화
                        if let localService = self.localService {
                            let userId = try await getCurrentUserId()
                            let localModels = try await localService.fetchAlarms(userId: userId)
                            let localAlarms = localModels.map { model in
                                AlarmEntity(
                                    id: model.id,
                                    userId: model.userId,
                                    label: model.label.isEmpty ? nil : model.label,
                                    time: model.time,
                                    repeatDays: model.repeatDays,
                                    snoozeEnabled: model.snoozeEnabled,
                                    snoozeInterval: model.snoozeInterval,
                                    snoozeLimit: model.snoozeLimit,
                                    soundName: model.soundName,
                                    soundURL: model.soundURL,
                                    vibrationPattern: model.vibrationPattern,
                                    volumeOverride: model.volumeOverride,
                                    linkedMemoIds: model.linkedMemoIds,
                                    showMemosOnAlarm: model.showMemosOnAlarm,
                                    isEnabled: model.isEnabled,
                                    createdAt: model.createdAt,
                                    updatedAt: model.updatedAt
                                )
                            }
                            emitter.send(.setAlarms(localAlarms))
                        }
                        
                        // 편집 시트 닫기
                        emitter.send(.showingEditAlarmState(nil))
                    } catch {
                        // 실패 시 복구
                        print("❌ [AlarmReducer] 알람 수정 실패: \(error)")
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorUpdateFailed",
                                detail: handleError(error)
                            )
                        ))
                        
                        // 실패 시 목록 다시 로드하여 복구
                        do {
                            let userId = try await getCurrentUserId()
                            let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                            emitter.send(.setAlarms(alarms))
                        } catch {
                            print("❌ [AlarmReducer] 알람 목록 재로드 실패")
                        }
                    }
                }
            ]
            
        case .deleteAlarm(let id):
            state.alarms.removeAll { $0.id == id }
            state.errorMessage = nil
            
            return [
                Effect { [self] emitter in
                    do {
                        // 1. 로컬 삭제
                        if let localService = self.localService {
                            try await localService.deleteAlarm(id: id)
                        }
                        
                        // 2. 원격 삭제
                        try await remoteRepository.deleteAlarm(alarmId: id)
                        
                        // 3. 알람 스케줄링 취소
                        print("🔕 [AlarmReducer] 알람 스케줄링 취소: \(id)")
                        try await self.alarmScheduler?.cancelAlarm(id)
                        
                        print("✅ [AlarmReducer] 알람 삭제 완료: \(id)")
                    } catch {
                        // 실패 시 에러 메시지만 표시 (이미 UI에서는 제거됨)
                        print("❌ [AlarmReducer] 알람 삭제 실패: \(error)")
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorDeleteFailed",
                                detail: handleError(error)
                            )
                        ))
                        
                        // 실패 시 목록 다시 로드하여 복구
                        do {
                            let userId = try await getCurrentUserId()
                            let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                            emitter.send(.setAlarms(alarms))
                        } catch {
                            print("❌ [AlarmReducer] 알람 목록 재로드 실패")
                        }
                    }
                }
            ]
            
        case .toggleAlarm(let id):
            guard let alarmIndex = state.alarms.firstIndex(where: { $0.id == id }) else {
                return []
            }
            
            // 낙관적 업데이트: UI에서 즉시 토글
            let newIsEnabled = !state.alarms[alarmIndex].isEnabled
            state.alarms[alarmIndex].isEnabled = newIsEnabled
            state.errorMessage = nil
            
            return [
                Effect { [self] emitter in
                    do {
                        // 1. 로컬 토글
                        if let localService = self.localService {
                            try await localService.toggleAlarm(id: id, isEnabled: newIsEnabled)
                        }
                        
                        // 2. 원격 토글
                        try await remoteRepository.toggleAlarm(alarmId: id, isEnabled: newIsEnabled)
                        
                        // 3. 알람 스케줄링 토글
                        if newIsEnabled {
                            // 알람 재스케줄링 (전체 알람 정보가 필요)
                            let userId = try await getCurrentUserId()
                            let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                            if let alarm = alarms.first(where: { $0.id == id }) {
                                print("🔔 [AlarmReducer] 알람 활성화 스케줄링: \(id)")
                                try await self.alarmScheduler?.scheduleAlarm(alarm)
                            }
                        } else {
                            print("🔕 [AlarmReducer] 알람 비활성화: \(id)")
                            try await self.alarmScheduler?.cancelAlarm(id)
                        }
                        
                        print("✅ [AlarmReducer] 알람 토글 완료: \(id) -> \(newIsEnabled)")
                    } catch {
                        // 실패 시 원래 상태로 복구
                        print("❌ [AlarmReducer] 알람 토글 실패: \(error)")
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorToggleFailed",
                                detail: handleError(error)
                            )
                        ))
                        
                        // 실패 시 목록 다시 로드하여 복구
                        do {
                            let userId = try await getCurrentUserId()
                            let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                            emitter.send(.setAlarms(alarms))
                        } catch {
                            print("❌ [AlarmReducer] 알람 목록 재로드 실패")
                        }
                    }
                }
            ]
            
        case .updateAlarmWithData(let id, let time, let label, let repeatDays):
            // 비즈니스 로직: 기존 알람 정보를 가져와서 업데이트
            state.errorMessage = nil
            
            // 먼저 현재 상태에서 알람 찾기
            guard let existingAlarm = state.alarms.first(where: { $0.id == id }) else {
                // 상태에 없으면 로컬 또는 원격에서 찾기
                return [
                    Effect { [self] emitter in
                        do {
                            let userId = try await getCurrentUserId()
                            var foundAlarm: AlarmEntity?
                            
                            // 1. 로컬 서비스에서 찾기
                            if let localService = self.localService {
                                let localModels = try await localService.fetchAlarms(userId: userId)
                                if let model = localModels.first(where: { $0.id == id }) {
                                    foundAlarm = AlarmEntity(
                                        id: model.id,
                                        userId: model.userId,
                                        label: model.label.isEmpty ? nil : model.label,
                                        time: model.time,
                                        repeatDays: model.repeatDays,
                                        snoozeEnabled: model.snoozeEnabled,
                                        snoozeInterval: model.snoozeInterval,
                                        snoozeLimit: model.snoozeLimit,
                                        soundName: model.soundName,
                                        soundURL: model.soundURL,
                                        vibrationPattern: model.vibrationPattern,
                                        volumeOverride: model.volumeOverride,
                                        linkedMemoIds: model.linkedMemoIds,
                                        showMemosOnAlarm: model.showMemosOnAlarm,
                                        isEnabled: model.isEnabled,
                                        createdAt: model.createdAt,
                                        updatedAt: model.updatedAt
                                    )
                                }
                            }
                            
                            // 2. 로컬에 없으면 원격에서 찾기
                            if foundAlarm == nil {
                                let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                                foundAlarm = alarms.first(where: { $0.id == id })
                            }
                            
                            guard let existingAlarm = foundAlarm else {
                                emitter.send(.setError("AlarmErrorEntityNotFound".localized()))
                                return
                            }
                            
                            // 업데이트된 알람 엔티티 생성
                            let updatedAlarm = AlarmEntity(
                                id: existingAlarm.id,
                                userId: existingAlarm.userId,
                                label: label?.isEmpty == false ? label : nil,
                                time: time,
                                repeatDays: repeatDays,
                                snoozeEnabled: existingAlarm.snoozeEnabled,
                                snoozeInterval: existingAlarm.snoozeInterval,
                                snoozeLimit: existingAlarm.snoozeLimit,
                                soundName: existingAlarm.soundName,
                                soundURL: existingAlarm.soundURL,
                                vibrationPattern: existingAlarm.vibrationPattern,
                                volumeOverride: existingAlarm.volumeOverride,
                                linkedMemoIds: existingAlarm.linkedMemoIds,
                                showMemosOnAlarm: existingAlarm.showMemosOnAlarm,
                                isEnabled: existingAlarm.isEnabled,
                                createdAt: existingAlarm.createdAt,
                                updatedAt: Date()
                            )
                            
                            // updateAlarm 액션으로 전달하여 처리
                            emitter.send(.updateAlarm(updatedAlarm))
                        } catch {
                            print("❌ [AlarmReducer] 알람 업데이트 실패: \(error)")
                        emitter.send(.setError(
                            formatErrorMessage(
                                "AlarmErrorUpdateFailed",
                                detail: handleError(error)
                            )
                        ))
                        }
                    }
                ]
            }
            
            // 상태에서 찾은 경우
            let updatedAlarm = AlarmEntity(
                id: existingAlarm.id,
                userId: existingAlarm.userId,
                label: label?.isEmpty == false ? label : nil,
                time: time,
                repeatDays: repeatDays,
                snoozeEnabled: existingAlarm.snoozeEnabled,
                snoozeInterval: existingAlarm.snoozeInterval,
                snoozeLimit: existingAlarm.snoozeLimit,
                soundName: existingAlarm.soundName,
                soundURL: existingAlarm.soundURL,
                vibrationPattern: existingAlarm.vibrationPattern,
                volumeOverride: existingAlarm.volumeOverride,
                linkedMemoIds: existingAlarm.linkedMemoIds,
                showMemosOnAlarm: existingAlarm.showMemosOnAlarm,
                isEnabled: existingAlarm.isEnabled,
                createdAt: existingAlarm.createdAt,
                updatedAt: Date()
            )
            
            return [
                Effect { emitter in
                    emitter.send(.updateAlarm(updatedAlarm))
                }
            ]
        case .setError(let message):
            state.isLoading = false
            state.errorMessage = message
            return []
        case let .showingAddAlarmState(status):
            state.showingAddAlarm = status
            return []
        case let .showingEditAlarmState(alarm):
            state.editingAlarm = alarm
            return []
        }
    }
}

// MARK: - AlarmError
enum AlarmError: Error {
    case userNotFound
    
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "AlarmErrorUserNotFound".localized()
        }
    }
}

private extension Locale {
    static var appLocale: Locale {
        Locale(identifier: LocalizationController.shared.languageCode)
    }
}
