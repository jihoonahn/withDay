import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = Dependency().module()

struct Dependency: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Shared
        ) {
            Sources(
                name: typeName,
                destinations: .iOS,
                dependencies: [
                    .external(name: "Rex")
                ]
            )
        }
    }
}
