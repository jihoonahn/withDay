import Rex

public struct MainState: StateType {
    public enum Flow: Sendable, Codable, CaseIterable {
        case home
        case alarm
        case weather
        case setting

        public var displayName: String {
            switch self {
            case .home:
                return "Home"
            case .alarm:
                return "Alarm"
            case .weather:
                return "Weather"
            case .setting:
                return "Setting"
            }
        }
    }

    public var flow: Flow = .home

    public init() {}
}
