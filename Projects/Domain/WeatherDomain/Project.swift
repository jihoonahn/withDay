import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = WeatherDomain().module()

struct WeatherDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain"),
                    .core(target: "NetworkCore", type: .interface)
                ]
            )
        }
    }
}
