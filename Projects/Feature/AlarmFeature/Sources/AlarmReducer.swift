import Rex
import AlarmFeatureInterface

public struct AlarmReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout AlarmState, action: AlarmAction) -> [Effect<AlarmAction>] {
        switch action {
        default:
            return []
        }
    }
}
