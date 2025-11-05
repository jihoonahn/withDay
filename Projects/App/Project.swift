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
                sources: ["iOS/Sources/**"],
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
                    .target(name: "\(typeName)Widget"),
                ]
            )
            Sources(
                name: "\(typeName)Widget",
                product: .appExtension,
                bundleId: "me.jihoon.\(typeName).Widget",
                infoPlist: .file(path: "Widget/Support/Info.plist"),
                sources: ["Widget/Sources/**"],
                resources: ["Widget/Support/WithDayWidget.intentdefinition"],
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
            Scheme.scheme(
                name: "\(typeName)-dev",
                shared: true,
                buildAction: .buildAction(targets: ["\(typeName)", "\(typeName)Widget"]),
                runAction: .runAction(configuration: .dev),
                archiveAction: .archiveAction(configuration: .dev),
                profileAction: .profileAction(configuration: .dev),
                analyzeAction: .analyzeAction(configuration: .dev)
            )
            Scheme.scheme(
                name: "\(typeName)-stage",
                shared: true,
                buildAction: .buildAction(targets: ["\(typeName)", "\(typeName)Widget"]),
                runAction: .runAction(configuration: .stage),
                archiveAction: .archiveAction(configuration: .stage),
                profileAction: .profileAction(configuration: .stage),
                analyzeAction: .analyzeAction(configuration: .stage)
            )
            Scheme.scheme(
                name: "\(typeName)-prod",
                shared: true,
                buildAction: .buildAction(targets: ["\(typeName)", "\(typeName)Widget"]),
                runAction: .runAction(configuration: .prod),
                archiveAction: .archiveAction(configuration: .prod),
                profileAction: .profileAction(configuration: .prod),
                analyzeAction: .analyzeAction(configuration: .prod)
            )
        }
    }
}
