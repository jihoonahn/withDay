import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = AchievementDomain().module()

struct AchievementDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "BaseDomain")
                ]
            )
        }
    }
}
