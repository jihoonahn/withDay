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
                    .sdk(name: "ActivityKit", type: .framework),
                    .sdk(name: "AVFoundation", type: .framework),
                    .shared(target: "Dependency"),
                    .feature(target: "BaseFeature", type: .sources)
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "AlarmScheduleDomain", type: .interface),
                    .sdk(name: "ActivityKit", type: .framework),
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
