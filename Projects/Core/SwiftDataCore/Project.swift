import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = SwiftDataCore().module()

struct SwiftDataCore: Module {
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
                    .domain(target: "AlarmsDomain", type: .interface),
                    .domain(target: "AlarmMissionsDomain", type: .interface),
                    .domain(target: "AlarmExecutionsDomain", type: .interface),
                    .domain(target: "UsersDomain", type: .interface),
                    .domain(target: "UserSettingsDomain", type: .interface),
                    .domain(target: "SchedulesDomain", type: .interface),
                    .domain(target: "MemosDomain", type: .interface),
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
