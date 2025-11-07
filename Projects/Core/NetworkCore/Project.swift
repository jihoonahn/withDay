import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = NetworkCore().module()

struct NetworkCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                    .external(name: "Network")
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "WeatherDomain", type: .interface)
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
