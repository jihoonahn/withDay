import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = BaseFeature().module()

struct BaseFeature: Module {

    var body: some Module {
        ProjectContainer(name: typeName, target: .Feature) {
            Sources(
                name: typeName,
                dependencies: [
                    .shared(target: "Dependency"),
                    .shared(target: "Designsystem")
                ]
            )
            Tests(name: typeName, dependencies: [
                .feature(target: typeName)
            ])
        }
    }
}
