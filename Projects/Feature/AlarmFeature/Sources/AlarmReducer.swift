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
                        emitter.send(.setError("알람 생성에 실패했습니다: \(error.localizedDescription)"))
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
                        emitter.send(.setError("알람 추가에 실패했습니다: \(error.localizedDescription)"))
                        
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
                        emitter.send(.setError("알람 수정에 실패했습니다: \(error.localizedDescription)"))
                        
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
                        emitter.send(.setError("알람 삭제에 실패했습니다: \(error.localizedDescription)"))
                        
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
                        emitter.send(.setError("알람 토글에 실패했습니다: \(error.localizedDescription)"))
                        
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
                                emitter.send(.setError("알람을 찾을 수 없습니다"))
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
                            emitter.send(.setError("알람 업데이트에 실패했습니다: \(error.localizedDescription)"))
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
            
        case .testLiveActivity:
            // 테스트용 Live Activity 시작
            return [
                Effect { [self] emitter in
                    do {
                        print("🧪 [AlarmReducer] 테스트용 Live Activity 시작")
                        
                        // 1분 후에 울릴 테스트 알람 생성
                        let testTime = Date().addingTimeInterval(60) // 1분 후
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: testTime)
                        let minute = calendar.component(.minute, from: testTime)
                        let timeString = String(format: "%02d:%02d", hour, minute)
                        
                        let userId = try await getCurrentUserId()
                        
                        let testAlarm = AlarmEntity(
                            id: UUID(),
                            userId: userId,
                            label: "테스트 알람",
                            time: timeString,
                            repeatDays: [],
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
                        
                        // Live Activity 시작
                        if let scheduler = self.alarmScheduler {
                            print("🧪 [AlarmReducer] 테스트 알람 스케줄링: \(testAlarm.id)")
                            print("   - 시간: \(timeString)")
                            print("   - 1분 후 울림")
                            try await scheduler.scheduleAlarm(testAlarm)
                            print("✅ [AlarmReducer] 테스트 Live Activity 시작 완료")
                            emitter.send(.setError("✅ 테스트 Live Activity가 시작되었습니다! (1분 후 울림)"))
                        } else {
                            print("⚠️ [AlarmReducer] AlarmSchedulerService를 찾을 수 없습니다")
                            emitter.send(.setError("알람 스케줄러를 사용할 수 없습니다"))
                        }
                    } catch {
                        print("❌ [AlarmReducer] 테스트 Live Activity 시작 실패: \(error)")
                        emitter.send(.setError("테스트 Live Activity 시작 실패: \(error.localizedDescription)"))
                    }
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
            return "로그인된 사용자를 찾을 수 없습니다"
        }
    }
}
