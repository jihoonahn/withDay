import Foundation
import AlarmKit
import Rex
import AlarmsFeatureInterface
import AlarmsDomainInterface
import AlarmSchedulesCoreInterface
import UsersDomainInterface
import Dependency
import Localization

public struct AlarmReducer: Reducer {
    private let alarmsUseCase: AlarmsUseCase
    private let alarmSchedulesUseCase: AlarmSchedulesUseCase
    private let usersUseCase: UsersUseCase
    
    public init(
        alarmsUseCase: AlarmsUseCase,
        alarmSchedulesUseCase: AlarmSchedulesUseCase,
        usersUseCase: UsersUseCase
    ) {
        self.alarmsUseCase = alarmsUseCase
        self.alarmSchedulesUseCase = alarmSchedulesUseCase
        self.usersUseCase = usersUseCase
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await usersUseCase.getCurrentUser() else {
            throw AlarmError.userNotFound
        }
        return user.id
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
                        let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
            return []
            
        case .createAlarm(let time, let label, let repeatDays):
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        let userId = try await getCurrentUserId()
                        
                        let newAlarm = AlarmsEntity(
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
                        try await alarmsUseCase.create(alarm)
                        
                        // 2. 알람 스케줄링
                        if alarm.isEnabled {
                            print("🔔 [AlarmReducer] 알람 스케줄링 시작: \(alarm.id)")
                            try await alarmSchedulesUseCase.scheduleAlarm(alarm)
                        }
                        
                        print("✅ [AlarmReducer] 알람 추가 완료: \(alarm.id)")
                        
                        // 3. 최신 상태 다시 로드하여 UI 동기화
                        let userId = try await getCurrentUserId()
                        let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
                            let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
                        try await alarmsUseCase.update(alarm)
                        
                        // 2. 알람 스케줄링 업데이트
                        print("🔔 [AlarmReducer] 알람 스케줄링 업데이트: \(alarm.id)")
                        try await alarmSchedulesUseCase.updateAlarm(alarm)
                        
                        print("✅ [AlarmReducer] 알람 수정 완료: \(alarm.id)")
                        
                        // 3. 최신 상태 다시 로드하여 UI 동기화
                        let userId = try await getCurrentUserId()
                        let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
                            let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
                        try await alarmsUseCase.delete(id: id)
                        
                        // 2. 알람 스케줄링 취소 (실패해도 무시 - 이미 삭제되었거나 존재하지 않을 수 있음)
                        print("🔕 [AlarmReducer] 알람 스케줄링 취소: \(id)")
                        do {
                            try await alarmSchedulesUseCase.cancelAlarm(id)
                        } catch {
                            // 취소 실패는 무시 (알람이 이미 없거나 취소되었을 수 있음)
                            print("⚠️ [AlarmReducer] 알람 스케줄링 취소 실패 (무시됨): \(id) - \(error)")
                        }
                        
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
                            let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
                        try await alarmsUseCase.toggle(id: id, isEnabled: newIsEnabled)
                        
                        // 2. 알람 엔티티를 가져와서 스케줄링 토글
                        let userId = try await getCurrentUserId()
                        let alarms = try await alarmsUseCase.fetchAll(userId: userId)
                        guard let alarm = alarms.first(where: { $0.id == id }) else {
                            throw AlarmServiceError.entityNotFound
                        }
                        
                        print("🔔 [AlarmReducer] 알람 스케줄링 토글: \(id) -> \(newIsEnabled)")
                        
                        if newIsEnabled {
                            try await alarmSchedulesUseCase.scheduleAlarm(alarm)
                        } else {
                            try await alarmSchedulesUseCase.cancelAlarm(id)
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
                            let alarms = try await alarmsUseCase.fetchAll(userId: userId)
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
                            let alarms = try await alarmsUseCase.fetchAll(userId: userId)
                            guard let existingAlarm = alarms.first(where: { $0.id == id }) else {
                                emitter.send(.setError("AlarmErrorEntityNotFound".localized()))
                                return
                            }
                            
                            // 업데이트된 알람 엔티티 생성
                            let updatedAlarm = AlarmsEntity(
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
            let updatedAlarm = AlarmsEntity(
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
                        try await alarmSchedulesUseCase.stopAlarm(id)
                    } catch {
                        print("Failed To Stop Alarm: \(error.localizedDescription)")
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
