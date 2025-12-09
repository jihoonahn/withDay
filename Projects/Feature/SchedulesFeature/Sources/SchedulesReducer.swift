import Rex
import SchedulesFeatureInterface

public struct SchedulesReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout SchedulesState, action: SchedulesAction) -> [Effect<SchedulesAction>] {
        switch action {
        default:
            return []
        }
    }
}
