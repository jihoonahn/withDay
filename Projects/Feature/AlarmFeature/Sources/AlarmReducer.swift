import Foundation
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import UserDomainInterface
import SwiftDataCoreInterface
import AlarmCoreInterface
import Dependency

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
    
    public func reduce(state: inout AlarmState, action: AlarmAction) -> [Effect<AlarmAction>] {
        switch action {
        case .loadAlarms:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        
                        // 전략: 로컬 먼저 조회 (빠른 응답)
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
                        emitter.send(.setError("알람을 불러오는데 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
            
        case .setAlarms(let alarms):
            state.isLoading = false
            state.alarms = alarms.sorted { $0.time < $1.time }
            return []
            
        case .addAlarm(let alarm):
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        // 1. 로컬에 즉시 저장 (오프라인 우선)
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
                        
                        // 3. 알람 스케줄링 (중요!)
                        if alarm.isEnabled {
                            print("🔔 [AlarmReducer] 알람 스케줄링 시작: \(alarm.id)")
                            self.alarmScheduler?.scheduleAlarm(alarm)
                        }
                        
                        // 4. 최신 목록 다시 로드
                        let userId = try await getCurrentUserId()
                        let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                        emitter.send(.setAlarms(alarms))
                    } catch {
                        emitter.send(.setError("알람 추가에 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
            
        case .updateAlarm(let alarm):
            state.isLoading = true
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
                        self.alarmScheduler?.cancelAlarm(alarm.id)
                        if alarm.isEnabled {
                            print("🔔 [AlarmReducer] 알람 재스케줄링: \(alarm.id)")
                            self.alarmScheduler?.scheduleAlarm(alarm)
                        }
                        
                        let userId = try await getCurrentUserId()
                        let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                        emitter.send(.setAlarms(alarms))
                    } catch {
                        emitter.send(.setError("알람 수정에 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
            
        case .deleteAlarm(let id):
            state.isLoading = true
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
                        self.alarmScheduler?.cancelAlarm(id)
                        
                        let userId = try await getCurrentUserId()
                        let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                        emitter.send(.setAlarms(alarms))
                    } catch {
                        emitter.send(.setError("알람 삭제에 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
            
        case .toggleAlarm(let id):
            guard let alarm = state.alarms.first(where: { $0.id == id }) else {
                return []
            }
            
            let newIsEnabled = !alarm.isEnabled
            state.isLoading = true
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
                                self.alarmScheduler?.scheduleAlarm(alarm)
                            }
                        } else {
                            print("🔕 [AlarmReducer] 알람 비활성화: \(id)")
                            self.alarmScheduler?.cancelAlarm(id)
                        }
                        
                        let userId = try await getCurrentUserId()
                        let alarms = try await remoteRepository.fetchAlarms(userId: userId)
                        emitter.send(.setAlarms(alarms))
                    } catch {
                        emitter.send(.setError("알람 토글에 실패했습니다: \(error.localizedDescription)"))
                    }
                }
            ]
            
        case .setError(let message):
            state.isLoading = false
            state.errorMessage = message
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
            return "로그인된 사용자를 찾을 수 없습니다"
        }
    }
}
