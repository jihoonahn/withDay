import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = WithDay().module()

struct WithDay: Module {
    @Constant var env = AppEnvironment()

    var body: some Module {
        Project {
            Sources(
                name: typeName,
                product: .app,
                infoPlist: .file(path: "Support/Info.plist"),
                resources: ["Resources/**"],
                configuration: .App,
                dependencies: [
                    .feature(target: "BaseFeature"),
                    .feature(target: "RootFeature"),
                    .feature(target: "LoginFeature"),
                    .feature(target: "MainFeature"),
                    .feature(target: "HomeFeature"),
                    .feature(target: "AlarmFeature"),
                    .feature(target: "WeatherFeature"),
                    .feature(target: "SettingFeature"),
                    .domain(target: "BaseDomain"),
                    .core(target: "NetworkCore"),
                    .core(target: "SupabaseCore"),
                    .shared(target: "Dependency")
                ]
            )
        }
        .organizationName(env.organizationName)
        .settings(.settings(
            base: env.baseSettings,
            configurations: env.configuration.configure(into: .App),
            defaultSettings: .recommended
        ))
        .scheme {
            Scheme.makeScheme(
                name: typeName,
                target: .dev
            )
            Scheme.makeScheme(
                name: typeName,
                target: .stage
            )
            Scheme.makeScheme(
                name: typeName,
                target: .prod
            )
        }
    }
}
