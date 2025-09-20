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
                    .external(name: "Rex"),
                    .external(name: "Logging")
                ]
            )
            Tests(name: typeName, dependencies: [
                .feature(target: typeName)
            ])
        }
    }
}
