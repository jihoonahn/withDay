import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = Shared().module()

struct Shared: Module {
    var body: some Module {
        ProjectContainer(name: typeName, target: .Shared) {
            Sources(
                name: "Dependency",
                destinations: .iOS,
                sources: "Sources/Dependency/**",
                dependencies: [
                    .external(name: "Logging"),
                    .external(name: "Rex")
                ]
            )
            Sources(
                name: "Designsystem",
                destinations: .iOS,
                sources: "Sources/Designsystem/**",
                resources: "Resources/**",
                dependencies: [
                    .external(name: "RefineUIIcons"),
                    .external(name: "Logging")
                ]
            )
        }
    }
}
