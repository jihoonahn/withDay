import Foundation
import Rex
import MotionFeatureInterface
import UserDomainInterface
import MotionRawDataDomainInterface
import AlarmScheduleDomainInterface
import MotionDomainInterface
import AlarmExecutionDomainInterface
import Localization
import BaseFeature
import Dependency

public struct MotionReducer: Reducer {
    private let userUseCase: UserUseCase
    private let motionRawDataUseCase: MotionRawDataUseCase
    private let alarmScheduleUseCase: AlarmScheduleUseCase
    private let motionUseCase: MotionUseCase
    private let alarmExecutionUseCase: AlarmExecutionUseCase
    
    public init(
        userUseCase: UserUseCase,
        motionRawDataUseCase: MotionRawDataUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        motionUseCase: MotionUseCase,
        alarmExecutionUseCase: AlarmExecutionUseCase
    ) {
        self.userUseCase = userUseCase
        self.motionRawDataUseCase = motionRawDataUseCase
        self.alarmScheduleUseCase = alarmScheduleUseCase
        self.motionUseCase = motionUseCase
        self.alarmExecutionUseCase = alarmExecutionUseCase
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await userUseCase.getCurrentUser() else {
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
        motionData: MotionRawDataEntity?,
        state: inout MotionState
    ) -> [Effect<MotionAction>] {
        print("📲 [MotionReducer] motionDetected 액션 수신: count=\(count), motionData=\(motionData != nil ? "있음" : "없음")")
        
        // 상태 업데이트
        let previousCount = state.motionCount
        state.motionCount = count
        print("📊 [MotionReducer] 모션 카운트 업데이트: \(previousCount) -> \(count)/\(state.requiredCount)")
        
        var effects: [Effect<MotionAction>] = []
        
        // 1. 모션 데이터 저장 (있는 경우)
        if let motionData = motionData {
            effects.append(createSaveMotionDataEffect(motionData: motionData))
        } else {
            print("⚠️ [MotionReducer] motionData가 nil입니다")
        }
        
        // 2. 필요한 카운트 도달 여부 확인
        if count >= state.requiredCount {
            effects.append(contentsOf: handleMotionCountReached(state: &state))
        } else {
            print("⏳ [MotionReducer] 아직 카운트 부족: \(count)/\(state.requiredCount)")
        }
        
        return effects
    }
    
    /// 모션 데이터 저장 Effect 생성
    private func createSaveMotionDataEffect(motionData: MotionRawDataEntity) -> Effect<MotionAction> {
        Effect { [self] continuation in
            do {
                print("💾 [MotionReducer] 모션 데이터 저장 시작... executionId=\(motionData.executionId)")
                try await self.motionRawDataUseCase.create(motionData)
                print("✅ [MotionReducer] 모션 데이터 저장 완료")
            } catch {
                let errorString = String(describing: error)
                // FK 제약 위반 (23503)인 경우에도 재시도하지 않고 로그만 출력
                if errorString.contains("23503") || errorString.contains("motion_raw_data_execution_id_fkey") {
                    print("❌ [MotionReducer] execution FK 제약 위반: \(errorString)")
                } else {
                    print("❌ [MotionReducer] 모션 데이터 저장 실패: \(error)")
                }
            }
        }
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
                await self.alarmScheduleUseCase.stopAlarm(alarmId)
                print("✅ [MotionReducer] 알람 중지 완료: \(alarmId)")
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
                motionData: motionData,
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
