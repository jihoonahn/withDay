import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = LocalizationCore().module()

struct LocalizationCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                resources: ["Resources/**"],
                dependencies: [
                    .core(target: typeName, type: .interface),
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "LocalizationDomain", type: .interface)
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
