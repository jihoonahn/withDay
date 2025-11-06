import ProjectDescription
import Foundation
import TuistUI

public struct ProjectContainer<Content>: Module where Content: TargetConvertable {
    @Constant var env = AppEnvironment()
    public let projectModifier = ProjectModifier()

    public init(
        name: String,
        target xcconfig: AppConfiguration.XCConfigTarget,
        options: ProjectDescription.Project.Options = .options(),
        package: [Package] = [],
        fileHeaderTemplate: FileHeaderTemplate? = nil,
        additionalFiles: [FileElement] = [],
        resourceSynthesizers: [ResourceSynthesizer] = .default,
        hasExampleTarget: Bool? = nil,
        hasSourceTarget: Bool? = nil,
        hasTestTarget: Bool? = nil,
        @TargetBuilder content: () -> [Content]
    ) {
        projectModifier.targets = content().map { $0.build() }
        projectModifier.organizationName = env.organizationName
        projectModifier.options = options
        projectModifier.packages = package
        projectModifier.fileHeaderTemplate = fileHeaderTemplate
        projectModifier.additionalFiles = additionalFiles
        projectModifier.resourceSynthesizers = resourceSynthesizers
        projectModifier.settings = .settings(
            base: env.baseSettings
                .merging(
                    SettingsDictionary()
                        .codeSignIdentityAppleDevelopment()
                        .automaticCodeSigning(devTeam: env.devTeam)
                ),
            configurations: env.configuration.configure(into: xcconfig),
            defaultSettings: .recommended
        )

        let targetNames = projectModifier.targets.map { $0.name }

        let hasExample = hasExampleTarget ?? targetNames.contains { $0.contains("Example") }
        let hasSource = hasSourceTarget ?? targetNames.contains(name)
        let hasTest = hasTestTarget ?? targetNames.contains { $0.contains("Tests") }

        projectModifier.schemes = projectModifier.targets.flatMap {
            $0.build().product == .app ? [
                Scheme.makeScheme(
                    name: name,
                    hasExampleTarget: hasExample,
                    hasSourceTarget: hasSource,
                    hasTestTarget: hasTest,
                    target: .dev
                ),
                Scheme.makeScheme(
                    name: name,
                    hasExampleTarget: hasExample,
                    hasSourceTarget: hasSource,
                    hasTestTarget: hasTest,
                    target: .prod
                )
            ] : [
                Scheme.makeScheme(
                    name: name,
                    hasExampleTarget: hasExample,
                    hasSourceTarget: hasSource,
                    hasTestTarget: hasTest,
                    target: .dev
                )
            ]
        }
    }

    public func module(_ name: String) -> AnyModule {
        projectModifier.name = name
        let project = projectModifier.build()
        return AnyModule(module: .project(project))
    }

    public var body: Never {
        neverModule("ProjectContainer")
    }
}
