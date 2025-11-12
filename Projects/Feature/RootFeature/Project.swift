import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = RootFeature().module()

struct RootFeature: Module {
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
                    .shared(target: "Designsystem")
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .feature(target: "SplashFeature", type: .interface),
                    .feature(target: "LoginFeature", type: .interface),
                    .feature(target: "MainFeature", type: .interface)
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
        }
    }
}
