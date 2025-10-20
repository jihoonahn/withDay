import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = AlarmDomain().module()

struct AlarmDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain"),
                    .core(target: "AlarmCore", type: .interface)
                ]
            )
        }
    }
}
