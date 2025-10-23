import Foundation
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface

public struct AlarmReducer: Reducer {
    private let alarmUseCase: AlarmUseCase
    
    public init(alarmUseCase: AlarmUseCase) {
        self.alarmUseCase = alarmUseCase
    }
    
    public func reduce(state: inout AlarmState, action: AlarmAction) -> [Effect<AlarmAction>] {
        return []
    }
}
