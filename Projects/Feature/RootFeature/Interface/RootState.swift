import Rex

public struct RootState: StateType {
    public enum Flow: Sendable, Codable, CaseIterable {
        case login
        case main
        
        public var displayName: String {
            switch self {
            case .login: return "Login"
            case .main: return "Main"
            }
        }
    }

    public var flow: Flow = .login

    public init() {}
}
