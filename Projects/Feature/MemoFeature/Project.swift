import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = MemoFeature().module()

struct MemoFeature: Module {
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
                    .shared(target: "Designsystem"),
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "UserDomain", type: .interface),
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
