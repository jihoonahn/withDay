import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = MemoDomain().module()

struct MemoDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain"),
                    .core(target: "SupabaseCore")
                ]
            )
        }
    }
}
