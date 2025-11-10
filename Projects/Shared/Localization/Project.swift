import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = Localization().module()

struct Localization: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Shared
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .domain(target: "LocalizationDomain", type: .interface)
                ]
            )
        }
    }
}
