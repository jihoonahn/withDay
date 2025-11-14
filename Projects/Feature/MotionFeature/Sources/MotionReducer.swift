import Foundation
import Rex
import MotionFeatureInterface
import UserDomainInterface
import MotionDomainInterface
import SupabaseCoreInterface
import MotionRawDataDomainInterface
import AlarmScheduleDomainInterface
import MotionCoreInterface
import Localization
import BaseFeature
import Dependency

public struct MotionReducer: Reducer {
    private let userUseCase: UserUseCase
    private let motionUseCase: MotionUseCase
    private let motionRawDataUseCase: MotionRawDataUseCase
    private let alarmScheduleUseCase: AlarmScheduleUseCase
    private let motionService: MotionCoreInterface.MotionService
    
    public init(
        userUseCase: UserUseCase,
        motionUseCase: MotionUseCase,
        motionRawDataUseCase: MotionRawDataUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        motionService: MotionCoreInterface.MotionService
    ) {
        self.userUseCase = userUseCase
        self.motionUseCase = motionUseCase
        self.motionRawDataUseCase = motionRawDataUseCase
        self.alarmScheduleUseCase = alarmScheduleUseCase
        self.motionService = motionService
    }
    
    public func reduce(state: inout MotionState, action: MotionAction) -> [Effect<MotionAction>] {
        switch action {
        case .viewAppear:
            return []
            
        case .startMonitoring(let alarmId, let requiredCount):
            state.alarmId = alarmId
            state.requiredCount = requiredCount
            state.motionCount = 0
            state.isMonitoring = true
            return [
                Effect { [self, alarmId, requiredCount] continuation in
                    do {
                        print("📱 [MotionReducer] 모션 모니터링 시작: \(alarmId), 필요 카운트: \(requiredCount)")
                        try await motionService.startMonitoring(for: alarmId, requiredCount: requiredCount)
                        print("✅ [MotionReducer] 모션 모니터링 시작 완료")
                    } catch {
                        print("❌ [MotionReducer] 모션 모니터링 시작 실패: \(error)")
                        continuation.send(.stopMonitoring)
                    }
                }
            ]
            
        case .motionDetected(let count, let motionData):
            state.motionCount = count
            
            // 모션 데이터를 Supabase에 저장
            if let motionData = motionData {
                return [
                    Effect { [self, motionData] continuation in
                        do {
                            try await motionRawDataUseCase.create(motionData)
                            print("✅ [MotionReducer] 모션 데이터 저장 완료")
                        } catch {
                            print("❌ [MotionReducer] 모션 데이터 저장 실패: \(error)")
                        }
                        continuation.send(.motionDataSaved(count: count))
                    }
                ]
            }
            
            if count >= state.requiredCount {
                state.isMonitoring = false
                let alarmId = state.alarmId
                return [
                    Effect { [self, alarmId] continuation in
                        // MotionFeature에서 직접 알람 중지 처리
                        if let alarmId = alarmId {
                            print("🛑 [MotionReducer] 모션 감지 완료 - 알람 중지: \(alarmId)")
                            await alarmScheduleUseCase.stopAlarm(alarmId)
                            print("✅ [MotionReducer] 알람 중지 완료: \(alarmId)")
                        }
                        continuation.send(.alarmStopped)
                    }
                ]
            }
            return []
            
        case .motionDataSaved(let count):
            if count >= state.requiredCount {
                state.isMonitoring = false
                let alarmId = state.alarmId
                return [
                    Effect { [self, alarmId] continuation in
                        // MotionFeature에서 직접 알람 중지 처리
                        if let alarmId = alarmId {
                            print("🛑 [MotionReducer] 모션 감지 완료 - 알람 중지: \(alarmId)")
                            await alarmScheduleUseCase.stopAlarm(alarmId)
                            print("✅ [MotionReducer] 알람 중지 완료: \(alarmId)")
                        }
                        continuation.send(.alarmStopped)
                    }
                ]
            }
            return []
            
        case .stopMonitoring:
            state.isMonitoring = false
            let alarmId = state.alarmId
            state.motionCount = 0
            state.alarmId = nil
            if let alarmId = alarmId {
                motionService.stopMonitoring(for: alarmId)
            }
            return []
            
        case .alarmStopped:
            state.isMonitoring = false
            let alarmId = state.alarmId
            state.motionCount = 0
            state.alarmId = nil
            if let alarmId = alarmId {
                motionService.stopMonitoring(for: alarmId)
            }
            return []
        }
    }
}
