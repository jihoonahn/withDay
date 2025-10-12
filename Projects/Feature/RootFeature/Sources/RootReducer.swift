import Rex
import RootFeatureInterface

public struct RootReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout RootState, action: RootAction) -> [Effect<RootAction>] {
        switch action {
        case .switchToLogin:
            state.flow = .login 
            return []
        case .switchToMain:
            state.flow = .main
            return []
        }
    }
}
