import ProjectDescription
import TuistUI

public struct AppConfiguration: XCConfig {
    public enum XCConfigTarget: String, XCConfigTargetType {
        case App
        case Domain
        case Feature
        case Core
        case Shared

        public func path(for config: ConfigurationName) -> ProjectDescription.Path {
            switch self {
            case .App:
                return .relativeToConfiguration("App/\(config.rawValue).xcconfig")
            case .Domain:
                return .relativeToConfiguration("Domain/\(config.rawValue).xcconfig")
            case .Feature:
                return .relativeToConfiguration("Feature/\(config.rawValue).xcconfig")
            case .Core:
                return .relativeToConfiguration("Core/\(config.rawValue).xcconfig")
            case .Shared:
                return .relativeToConfiguration("Shared/\(config.rawValue).xcconfig")
            }
        }
    }
    
    public var body: some XCConfigOf<Self> {
        Configure({
            switch $0 {
            case .App:
                return [
                    .debug(name: .dev, xcconfig: $0.path(for: .dev)),
                    .debug(name: .stage, xcconfig: $0.path(for: .stage)),
                    .release(name: .prod, xcconfig: $0.path(for: .prod))
                ]
            case .Domain:
                return [
                    .debug(name: .dev, xcconfig: $0.path(for: .dev)),
                    .debug(name: .stage, xcconfig: $0.path(for: .stage)),
                    .release(name: .prod, xcconfig: $0.path(for: .prod))
                ]
            case .Feature:
                return [
                    .debug(name: .dev, xcconfig: $0.path(for: .dev)),
                    .debug(name: .stage, xcconfig: $0.path(for: .stage)),
                    .release(name: .prod, xcconfig: $0.path(for: .prod))
                ]
            case .Core:
                return [
                    .debug(name: .dev, xcconfig: $0.path(for: .dev)),
                    .debug(name: .stage, xcconfig: $0.path(for: .stage)),
                    .release(name: .prod, xcconfig: $0.path(for: .prod))
                ]
            case .Shared:
                return [
                    .debug(name: .dev, xcconfig: $0.path(for: .dev)),
                    .debug(name: .stage, xcconfig: $0.path(for: .stage)),
                    .release(name: .prod, xcconfig: $0.path(for: .prod))
                ]
            }
        })
    }
}
