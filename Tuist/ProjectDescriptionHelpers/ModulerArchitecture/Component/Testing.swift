import ProjectDescription
import TuistUI

public struct Testing: TargetConvertable {
    let env = AppEnvironment()
    let name: String
    let target: AppConfiguration.XCConfigTarget
    let dependencies: [TargetDependency]

    public init(
        name: String,
        configuration target: AppConfiguration.XCConfigTarget = .Shared,
        dependencies: [TargetDependency]
    ) {
        self.name = name + "Testing"
        self.target = target
        self.dependencies = dependencies
    }

    public func build() -> ProjectDescription.Target {
        return Target(
            name: name,
            destinations: env.destinations,
            product: .framework,
            bundleId: "\(env.organizationName).\(name)",
            deploymentTargets: env.deploymentTargets,
            infoPlist: .default,
            sources: .testing,
            dependencies: dependencies,
            settings: .settings(
                base: env.baseSettings,
                configurations: env.configuration.configure(into: target),
                defaultSettings: .recommended
            )
        ).build()
    }
}
