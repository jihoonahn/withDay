import ProjectDescription
import TuistUI

public struct AppEnvironment: ModuleObject {
    public let organizationName = "me.jihoon"
    public let baseSettings: SettingsDictionary = [:]
    public let packageplatform: [ProjectDescription.PackagePlatform] = [.iOS]
    public let destinations = Destinations.iOS
    public let deploymentTargets = DeploymentTargets.iOS("17.0")
    public let configuration = AppConfiguration()
    public init() {}
}
