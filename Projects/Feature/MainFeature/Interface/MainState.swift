import Rex
import RefineUIIcons
import Foundation

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
        
        public var icon: RefineUIIcons {
            switch self {
            case .home:
                return .home32Regular
            case .alarm:
                return .clockAlarm32Regular
            case .weather:
                return .weatherCloudy32Regular
            case .setting:
                return .settings32Regular
            }
        }
    }

    public var flow: Flow = .home
    public var isShowingMotion: Bool = false
    public var motionAlarmId: UUID?

    public init() {}
}
