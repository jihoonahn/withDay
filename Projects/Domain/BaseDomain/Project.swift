import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = BaseDomain().module()

struct BaseDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Sources(
                name: typeName,
                product: .framework,
                dependencies: [
                    .external(name: "Supabase")
                ]
            )
            Tests(
                name: typeName,
                dependencies: [
                    .domain(target: typeName)
                ]
            )
        }
    }
}
