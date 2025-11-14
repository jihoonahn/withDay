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
                    .shared(target: "Utility"),
                ]
            )
            Interface(
                name: typeName,
                dependencies: [
                    .domain(target: "AlarmDomain", type: .interface),
                    .domain(target: "AlarmExecutionDomain", type: .interface),
                    .domain(target: "AchievementDomain", type: .interface),
                    .domain(target: "SleepPatternDomain", type: .interface),
                    .domain(target: "UserDomain", type: .interface),
                    .domain(target: "MemoDomain", type: .interface),
                    .domain(target: "MotionDomain", type: .interface),
                    .domain(target: "MotionRawDataDomain", type: .interface),
                    .external(name: "Supabase")
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
