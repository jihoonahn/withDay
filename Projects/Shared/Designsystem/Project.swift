import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = Designsystem().module()

struct Designsystem: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Shared
        ) {
            Sources(
                name: typeName,
                destinations: .iOS,
                dependencies: [
                    .external(name: "RefineUIIcons"),
                    .external(name: "Logging")
                ]
            )
        }
    }
}
