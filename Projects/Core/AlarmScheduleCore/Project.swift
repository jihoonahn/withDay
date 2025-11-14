import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = AlarmScheduleCore().module()

struct AlarmScheduleCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                    .shared(target: "Dependency"),
                    .sdk(name: "ActivityKit", type: .framework)
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "AlarmScheduleDomain", type: .interface),
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
