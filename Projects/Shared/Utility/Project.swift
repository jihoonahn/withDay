import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = Utility().module()

struct Utility: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Shared
        ) {
            Sources(
                name: typeName,
                destinations: .iOS,
                dependencies: [
                    .external(name: "Logging")
                ]
            )
        }
    }
}
