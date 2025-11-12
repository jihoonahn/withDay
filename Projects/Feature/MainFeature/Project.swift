import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = MainFeature().module()

struct MainFeature: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Feature
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .feature(target: "BaseFeature", type: .sources),
                    .feature(target: typeName, type: .interface),
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .external(name: "RefineUIIcons"),
                    .feature(target: "HomeFeature", type: .interface),
                    .feature(target: "AlarmFeature", type: .interface),
                    .feature(target: "WeatherFeature", type: .interface),
                    .feature(target: "SettingFeature", type: .interface)
                ]
            )
            Example(
                name: typeName,
                dependencies: [
                    .feature(target: typeName),
                    .feature(target: typeName, type: .testing),
                ]
            )
            Testing(
                name: typeName,
                dependencies: [
                    .feature(target: typeName, type: .interface)
                ]
            )
            Tests(
                name: typeName,
                dependencies: [
                    .feature(target: typeName),
                    .feature(target: typeName, type: .testing)
                ]
            )
            UITests(
                name: typeName,
                dependencies: [
                    .feature(target: typeName),
                    .feature(target: typeName, type: .testing)
                ]
            )
        }
    }
}
