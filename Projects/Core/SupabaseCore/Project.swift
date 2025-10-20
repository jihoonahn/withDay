import ProjectDescription
import ProjectDescriptionHelpers
import TuistUI

let project = SupabaseCore().module()

struct SupabaseCore: Module {
    var body: some Module {
        ProjectContainer(
            name: typeName,
            target: .Core
        ) {
            Sources(
                name: typeName,
                dependencies: [
                    .core(target: typeName, type: .interface),
                    .external(name: "Supabase")
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "UserDomain", type: .interface),
                    .domain(target: "MemoDomain", type: .interface)
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
