import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = MotionCore().module()

struct MotionCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                    .core(target: "SupabaseCore", type: .interface),
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "MotionDomain", type: .interface)
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
