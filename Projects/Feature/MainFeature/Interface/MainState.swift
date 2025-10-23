import Rex
import RefineUIIcons

public struct MainState: StateType {
    public enum Flow: Sendable, Codable, CaseIterable {
        case alarm
        case setting

        public var displayName: String {
            switch self {
            case .alarm:
                return "Alarm"
            case .setting:
                return "Setting"
            }
        }
        
        public var icon: RefineUIIcons {
            switch self {
            case .alarm:
                return .clockAlarm32Regular
            case .setting:
                return .settings32Regular
            }
        }
    }

    public var flow: Flow = .alarm

    public init() {}
}
