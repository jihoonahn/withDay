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
                infoPlist: .file(path: "iOS/Support/Info.plist"),
                sources: "iOS/Sources/**",
                resources: ["iOS/Resources/**"],
                configuration: .App,
                dependencies: [
                    .feature(target: "BaseFeature"),
                    .feature(target: "RootFeature"),
                    .feature(target: "SplashFeature"),
                    .feature(target: "LoginFeature"),
                    .feature(target: "MainFeature"),
                    .feature(target: "HomeFeature"),
                    .feature(target: "AlarmFeature"),
                    .feature(target: "WeatherFeature"),
                    .feature(target: "SettingFeature"),
                    .core(target: "SettingCore"),
                    .core(target: "NetworkCore"),
                    .core(target: "SupabaseCore"),
                    .core(target: "SwiftDataCore"),
                    .core(target: "AlarmCore"),
                    .shared(target: "Dependency"),
                    .shared(target: "Utility"),
                    .target(name: "\(typeName)Widget")
                ]
            )
            Sources(
                name: "\(typeName)Widget",
                destinations: [.iPhone, .iPad],
                product: .appExtension,
                infoPlist: .file(path: "Widget/Support/Info.plist"),
                sources: "Widget/Sources/**",
                configuration: .App,
                dependencies: [
                    .core(target: "AlarmCore"),
                    .shared(target: "Utility")
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
