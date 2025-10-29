import Rex

public struct RootState: StateType {
    public enum Flow: Sendable, Codable, CaseIterable {
        case splash
        case login
        case main
        
        public var displayName: String {
            switch self {
            case .splash: return "Splash"
            case .login: return "Login"
            case .main: return "Main"
            }
        }
    }

    public var flow: Flow = .splash  // 초기 상태를 loading으로 변경

    public init() {}
}
