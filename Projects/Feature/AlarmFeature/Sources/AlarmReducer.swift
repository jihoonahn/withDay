import Foundation
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import AlarmScheduleDomainInterface
import UserDomainInterface
import Dependency
import Localization

public struct AlarmReducer: Reducer {
    private let alarmUseCase: AlarmUseCase
    private let alarmScheduleUseCase: AlarmScheduleUseCase
    private let userUseCase: UserUseCase
    
    public init(
        alarmUseCase: AlarmUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        userUseCase: UserUseCase
    ) {
        self.alarmUseCase = alarmUseCase
        self.alarmScheduleUseCase = alarmScheduleUseCase
        self.userUseCase = userUseCase
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await userUseCase.getCurrentUser() else {
            throw AlarmError.userNotFound
        }
        return user.id
    }
    
    // MARK: - Entity Conversion
    private func toScheduleEntity(_ alarm: AlarmEntity) -> AlarmScheduleEntity {
        AlarmScheduleEntity(
            id: alarm.id,
            userId: alarm.userId,
            label: alarm.label,
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
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) -> String {
        if let alarmError = error as? AlarmError {
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
                        let alarms = try await alarmUseCase.fetchAll(userId: userId)
                        emitter.send(.setAlarms(alarms))
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
            // 스케줄링은 명시적으로 알람이 변경될 때만 수행
            // (createAlarm, updateAlarm, toggleAlarm 등에서 처리)
            return []
            
        case .createAlarm(let time, let label, let repeatDays):
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
            // 중복 체크
            if state.alarms.contains(where: { $0.id == alarm.id }) {
                print("⚠️ [AlarmReducer] 이미 존재하는 알람입니다: \(alarm.id)")
                return []
            }
            
            // 낙관적 업데이트: UI에서 즉시 추가
            state.alarms.append(alarm)
            state.alarms.sort { $0.time < $1.time }
            state.errorMessage = nil
            
            return [
                Effect { [self, alarm] emitter in
                    do {
                        // 1. 알람 저장 (UseCase가 로컬/원격 모두 처리)
                        try await alarmUseCase.create(alarm)
                        
                        // 2. 알람 스케줄링
                        if alarm.isEnabled {
                            print("🔔 [AlarmReducer] 알람 스케줄링 시작: \(alarm.id)")
                            let scheduleEntity = toScheduleEntity(alarm)
                            try await alarmScheduleUseCase.scheduleAlarm(scheduleEntity)
                        }
                        
                        print("✅ [AlarmReducer] 알람 추가 완료: \(alarm.id)")
                        
                        // 3. 최신 상태 다시 로드하여 UI 동기화
                        let userId = try await getCurrentUserId()
                        let alarms = try await alarmUseCase.fetchAll(userId: userId)
                        emitter.send(.setAlarms(alarms))
                        
                        // 4. 알람 추가 시트 닫기
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
                            let alarms = try await alarmUseCase.fetchAll(userId: userId)
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
                Effect { [self, alarm] emitter in
                    do {
                        // 1. 알람 업데이트 (UseCase가 로컬/원격 모두 처리)
                        try await alarmUseCase.update(alarm)
                        
                        // 2. 알람 스케줄링 업데이트
                        let scheduleEntity = toScheduleEntity(alarm)
                        print("🔔 [AlarmReducer] 알람 스케줄링 업데이트: \(alarm.id)")
                        try await alarmScheduleUseCase.updateAlarm(scheduleEntity)
                        
                        print("✅ [AlarmReducer] 알람 수정 완료: \(alarm.id)")
                        
                        // 3. 최신 상태 다시 로드하여 UI 동기화
                        let userId = try await getCurrentUserId()
                        let alarms = try await alarmUseCase.fetchAll(userId: userId)
                        emitter.send(.setAlarms(alarms))
                        
                        // 4. 편집 시트 닫기
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
                            let alarms = try await alarmUseCase.fetchAll(userId: userId)
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
                Effect { [self, id] emitter in
                    do {
                        // 1. 알람 삭제 (UseCase가 로컬/원격 모두 처리)
                        try await alarmUseCase.delete(id: id)
                        
                        // 2. 알람 스케줄링 취소
                        print("🔕 [AlarmReducer] 알람 스케줄링 취소: \(id)")
                        try await alarmScheduleUseCase.cancelAlarm(id)
                        
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
                            let alarms = try await alarmUseCase.fetchAll(userId: userId)
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
                Effect { [self, id, newIsEnabled] emitter in
                    do {
                        // 1. 알람 토글 (UseCase가 로컬/원격 모두 처리)
                        try await alarmUseCase.toggle(id: id, isEnabled: newIsEnabled)
                        
                        // 2. 알람 스케줄링 토글
                        print("🔔 [AlarmReducer] 알람 스케줄링 토글: \(id) -> \(newIsEnabled)")
                        try await alarmScheduleUseCase.toggleAlarm(id, isEnabled: newIsEnabled)
                        
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
                            let alarms = try await alarmUseCase.fetchAll(userId: userId)
                            emitter.send(.setAlarms(alarms))
                        } catch {
                            print("❌ [AlarmReducer] 알람 목록 재로드 실패")
                        }
                    }
                }
            ]
            
        case .updateAlarmWithData(let id, let time, let label, let repeatDays):
            state.errorMessage = nil
            
            // 먼저 현재 상태에서 알람 찾기
            guard let existingAlarm = state.alarms.first(where: { $0.id == id }) else {
                // 상태에 없으면 UseCase를 통해 찾기
                return [
                    Effect { [self, id, time, label, repeatDays] emitter in
                        do {
                            let userId = try await getCurrentUserId()
                            let alarms = try await alarmUseCase.fetchAll(userId: userId)
                            guard let existingAlarm = alarms.first(where: { $0.id == id }) else {
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
                Effect { [updatedAlarm] emitter in
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
            
        case .stopAlarm(let id):
            return [
                Effect { [self, id] emitter in
                    do {
                        print("🛑 [AlarmReducer] 알람 중지 요청: \(id)")
                        await alarmScheduleUseCase.stopAlarm(id)
                        print("✅ [AlarmReducer] 알람 중지 완료: \(id)")
                    } catch {
                        print("❌ [AlarmReducer] 알람 중지 실패: \(error)")
                    }
                }
            ]
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
