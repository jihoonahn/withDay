import Rex
import SettingFeatureInterface

public struct SettingReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout SettingState, action: SettingAction) -> [Effect<SettingAction>] {
        switch action {
        case let .nameTextDidChanged(text):
            state.name = text
            return []
        case let .emailTextDidChanged(text):
            state.email = text
            return []
        case .logout:
            print("Logoout")
            return []
        }
    }
}
