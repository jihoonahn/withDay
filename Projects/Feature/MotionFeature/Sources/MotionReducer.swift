import Foundation
import Rex
import MotionFeatureInterface
import UserDomainInterface
import MotionDomainInterface
import SupabaseCoreInterface
import MotionRawDataDomainInterface
import Localization
import BaseFeature

public struct MotionReducer: Reducer {
    private let userUseCase: UserUseCase
    private let motionUseCase: MotionUseCase
    private let motionRawDataUseCase: MotionRawDataUseCase
    
    public init(
        userUseCase: UserUseCase,
        motionUseCase: MotionUseCase,
        motionRawDataUseCase: MotionRawDataUseCase,
    ) {
        self.userUseCase = userUseCase
        self.motionUseCase = motionUseCase
        self.motionRawDataUseCase = motionRawDataUseCase
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
            return []
            
        case .motionDetected(let count):
            state.motionCount = count

            if count >= state.requiredCount {
                state.isMonitoring = false
                let alarmId = state.alarmId
                return [
                    Effect { [alarmId] continuation in
                        NotificationCenter.default.post(
                            name: NSNotification.Name("MotionCountReached"),
                            object: nil,
                            userInfo: ["alarmId": alarmId as Any]
                        )
                        continuation.send(.alarmStopped)
                    }
                ]
            }
            return []
            
        case .stopMonitoring:
            state.isMonitoring = false
            state.motionCount = 0
            state.alarmId = nil
            return []
            
        case .alarmStopped:
            state.isMonitoring = false
            state.motionCount = 0
            state.alarmId = nil
            return []
        }
    }
}
