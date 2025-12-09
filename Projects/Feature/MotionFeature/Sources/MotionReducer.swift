import Foundation
import Rex
import MotionFeatureInterface
import UsersDomainInterface
import AlarmsDomainInterface
import AlarmExecutionsDomainInterface
import MotionDomainInterface
import Localization
import BaseFeature
import Dependency

public struct MotionReducer: Reducer {
    private let usersUseCase: UsersUseCase
    private let alarmSchedulesUseCase: AlarmSchedulesUseCase
    private let alarmExecutionsUseCase: AlarmExecutionsUseCase
    private let motionUseCase: MotionUseCase
    
    public init(
        usersUseCase: UsersUseCase,
        alarmSchedulesUseCase: AlarmSchedulesUseCase,
        alarmExecutionsUseCase: AlarmExecutionsUseCase,
        motionUseCase: MotionUseCase
    ) {
        self.usersUseCase = usersUseCase
        self.alarmSchedulesUseCase = alarmSchedulesUseCase
        self.alarmExecutionsUseCase = alarmExecutionsUseCase
        self.motionUseCase = motionUseCase
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await usersUseCase.getCurrentUser() else {
            throw NSError(domain: "MotionReducer", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user.id
    }
    
    // MARK: - Motion Detection Handling
    
    /// 모션 감지 이벤트 처리
    /// - Parameters:
    ///   - count: 현재 감지된 모션 카운트
    ///   - motionData: 감지된 모션 원시 데이터 (선택적)
    ///   - state: 현재 상태 (inout)
    /// - Returns: 실행할 Effect 배열
    private func handleMotionDetected(
        count: Int,
        state: inout MotionState
    ) -> [Effect<MotionAction>] {
        // 상태 업데이트
        let previousCount = state.motionCount
        state.motionCount = count
        print("📊 [MotionReducer] 모션 카운트 업데이트: \(previousCount) -> \(count)/\(state.requiredCount)")
        
        var effects: [Effect<MotionAction>] = []

        // 2. 필요한 카운트 도달 여부 확인
        if count >= state.requiredCount {
            effects.append(contentsOf: handleMotionCountReached(state: &state))
        } else {
            print("⏳ [MotionReducer] 아직 카운트 부족: \(count)/\(state.requiredCount)")
        }
        
        return effects
    }
    /// 필요한 모션 카운트 도달 시 처리
    /// - Parameter state: 현재 상태 (inout)
    /// - Returns: 실행할 Effect 배열
    private func handleMotionCountReached(state: inout MotionState) -> [Effect<MotionAction>] {
        print("🎯 [MotionReducer] 필요한 카운트 도달: \(state.motionCount) >= \(state.requiredCount)")
        
        state.isMonitoring = false
        let alarmId = state.alarmId
        print("📊 [MotionReducer] 상태 업데이트: isMonitoring=false")
        
        guard let alarmId = alarmId else {
            print("⚠️ [MotionReducer] alarmId가 nil입니다")
            return []
        }
        
        return [
            Effect { [self] continuation in
                print("🛑 [MotionReducer] 모션 감지 완료 - 알람 중지 시작: \(alarmId)")
                do {
                    try await self.alarmSchedulesUseCase.stopAlarm(alarmId)
                } catch {
                    print("Failed to Motion Reducer: stopAlarm(\(alarmId))")
                }
                continuation.send(.alarmStopped(alarmId: alarmId))
            }
        ]
    }
    
    public func reduce(state: inout MotionState, action: MotionAction) -> [Effect<MotionAction>] {
        switch action {
        case .viewAppear:
            return []
            
        case .startMonitoring(let alarmId, let executionId, let requiredCount):
            if state.isMonitoring && state.alarmId == alarmId && state.executionId == executionId {
                print("⏭️ [MotionReducer] 이미 모니터링 중 - 중복 호출 무시: alarmId=\(alarmId), executionId=\(executionId), 현재 카운트=\(state.motionCount)")
                return []
            }
            
            // executionId와 alarmId를 동시에 설정
            state.alarmId = alarmId
            state.executionId = executionId
            state.requiredCount = requiredCount
            state.motionCount = 0
            state.isMonitoring = true
            print("📊 [MotionReducer] 상태 업데이트: alarmId = \(alarmId), isMonitoring=\(state.isMonitoring), motionCount=\(state.motionCount), executionId=\(executionId)")
            
            return [
                Effect { [self, alarmId, executionId, requiredCount] continuation in
                    do {
                        try await self.motionUseCase.startMonitoring(for: alarmId, executionId: executionId, requiredCount: requiredCount)
                    } catch {
                        continuation.send(.stopMonitoring)
                    }
                }
            ]
            
        case .motionDetected(let count, let motionData):
            return handleMotionDetected(
                count: count,
                state: &state
            )
        case .stopMonitoring:
            print("🛑 [MotionReducer] stopMonitoring 액션 수신")
            state.isMonitoring = false
            let alarmId = state.alarmId
            state.motionCount = 0
            state.alarmId = nil
            state.executionId = nil
            if let alarmId = alarmId {
                print("🛑 [MotionReducer] 모션 모니터링 중지: \(alarmId)")
                motionUseCase.stopMonitoring(for: alarmId)
            } else {
                print("⚠️ [MotionReducer] stopMonitoring: alarmId가 nil입니다")
            }
            return []
            
        case .alarmStopped(let alarmId):
            print("🛑 [MotionReducer] alarmStopped 액션 수신: \(alarmId)")
            state.isMonitoring = false
            state.motionCount = 0
            state.alarmId = nil
            state.executionId = nil
            print("🛑 [MotionReducer] 모션 모니터링 중지: \(alarmId)")
            motionUseCase.stopMonitoring(for: alarmId)
            return []
        }
    }
}
