import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = NotificationCore().module()

struct NotificationCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "AlarmDomain", type: .interface),
                    .domain(target: "NotificationDomain", type: .interface),
                ]
            )
            Testing(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                ]
            )
            Tests(
                name: typeName,
                dependencies: [
                    .core(target: typeName),
                    .core(target: typeName, type: .testing)
                ]
            )
        }
    }
}
