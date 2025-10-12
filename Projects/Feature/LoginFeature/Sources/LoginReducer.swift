import Rex
import LoginFeatureInterface

public struct LoginReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout LoginState, action: LoginAction) -> [Effect<LoginAction>] {
        switch action {
        case .selectToGoogleOauth:
            state.loginStatus = true
            return []
        }
    }
}
