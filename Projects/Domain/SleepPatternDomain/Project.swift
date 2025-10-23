import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = SleepPatternDomain().module()

struct SleepPatternDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain")
                ]
            )
        }
    }
}
