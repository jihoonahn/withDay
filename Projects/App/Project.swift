import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI
import Playgrounds

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
                    .feature(target: "MotionFeature"),
                    .feature(target: "MemosFeature"),
                    .feature(target: "AlarmsFeature"),
                    .feature(target: "SchedulesFeature"),
                    .feature(target: "SettingsFeature"),
                    .core(target: "AlarmSchedulesCore"),
                    .core(target: "MotionCore"),
                    .core(target: "NotificationCore"),
                    .core(target: "SupabaseCore"),
                    .core(target: "SwiftDataCore"),
                    .core(target: "LocalizationCore"),
                    .shared(target: "Dependency"),
                    .shared(target: "Localization"),
                    .shared(target: "Utility"),
                    .sdk(name: "AlarmKit", type: .framework),
                    .target(name: "\(typeName)Widget"),
                ]
            )
            Sources(
                name: "\(typeName)Widget",
                product: .appExtension,
                bundleId: "me.jihoon.\(typeName).Widget",
                infoPlist: .file(path: "Widget/Support/Info.plist"),
                sources: ["Widget/Sources/**"],
                resources: [
                    "Widget/Resources/**"
                ],
                configuration: .App,
                dependencies: [
                    .core(target: "AlarmSchedulesCore"),
                    .shared(target: "Utility"),
                    .sdk(name: "AlarmKit", type: .framework)
                ]
            )
        }
        .organizationName(env.organizationName)
        .settings(.settings(
            base: env.baseSettings,
            configurations: env.configuration.configure(into: .App),
            defaultSettings: .recommended
        ))
        .option(options: env.options)
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
