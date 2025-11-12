import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = HomeFeature().module()

struct HomeFeature: Module {
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
                    .shared(target: "Localization"),
                    .shared(target: "Dependency")
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "MemoDomain", type: .interface),
                    .domain(target: "UserDomain", type: .interface),
                    .domain(target: "AlarmExecutionDomain", type: .interface),
                    .domain(target: "MemoDomain", type: .interface)
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
