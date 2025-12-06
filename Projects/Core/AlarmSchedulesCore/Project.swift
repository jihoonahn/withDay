import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = AlarmSchedulesCore().module()

struct AlarmSchedulesCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                    .sdk(name: "AlarmKit", type: .framework),
                    .sdk(name: "ActivityKit", type: .framework),
                    .sdk(name: "AVFoundation", type: .framework),
                    .shared(target: "Dependency"),
                    .feature(target: "BaseFeature", type: .sources)
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "AlarmsDomain", type: .interface),
                    .sdk(name: "AlarmKit", type: .framework),
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
