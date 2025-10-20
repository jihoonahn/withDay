import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = UserDomain().module()

struct UserDomain: Module {
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
