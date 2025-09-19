import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = CoreNetwork().module()

struct CoreNetwork: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(name: typeName)
            Tests(
                name: typeName,
                dependencies: [
                    .core(target: typeName)
                ]
            )
        }
    }
}
