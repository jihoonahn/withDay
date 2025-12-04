import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = UsersDomain().module()

struct UsersDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain"),
                ]
            )
        }
    }
}
