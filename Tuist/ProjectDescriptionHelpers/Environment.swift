import ProjectDescription
import TuistUI

public struct AppEnvironment: ModuleObject {
    public let organizationName = "me.jihoon"
    public let devTeam = ""
    public let options: ProjectDescription.Project.Options = .options(
        defaultKnownRegions: ["ko", "en"],
        developmentRegion: "ko"
    )
    public let baseSettings: SettingsDictionary = [
        "SUPABASE_URL": SettingValue.string(Environment.supabaseURL ?? ""),
        "SUPABASE_ANON_KEY": SettingValue.string(Environment.supabaseAnonKey ?? "")
    ]
    public let packageplatform: [ProjectDescription.PackagePlatform] = [.iOS]
    public let destinations = Destinations.iOS
    public let deploymentTargets = DeploymentTargets.iOS("26.1")
    public let configuration = AppConfiguration()
    public init() {}
}

public enum Environment {
    public static let supabaseURL: String? = EnvironmentVariable("SUPABASE_URL").value
    public static let supabaseAnonKey: String? = EnvironmentVariable("SUPABASE_ANON_KEY").value
}
