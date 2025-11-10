import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = NotificationDomain().module()

struct NotificationDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain"),
                    .domain(target: "AlarmDomain", type: .interface)
                ]
            )
        }
    }
}
