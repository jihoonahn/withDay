import Rex
import SettingFeatureInterface

public struct SettingReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout SettingState, action: SettingAction) -> [Effect<SettingAction>] {
        switch action {
        default:
            return []
        }
    }
}
