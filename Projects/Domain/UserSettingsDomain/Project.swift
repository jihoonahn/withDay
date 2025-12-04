import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = UserSettingsDomain().module()

struct UserSettingsDomain: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Domain
        ) {
            Interface(name: typeName)
        }
    }
}
