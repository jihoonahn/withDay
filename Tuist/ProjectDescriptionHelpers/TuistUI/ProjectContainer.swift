import ProjectDescription
import Foundation
import TuistUI

/// Custom Project for DesignTuist (using ModularArchitecture)
public struct ProjectContainer<Content>: Module where Content: TargetConvertable {
    /// Allows project modifier to be made to a given Project Type.
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
        @TargetBuilder content: () -> [Content]
    ) {
        
        projectModifier.targets = content().map { $0.build() }
        projectModifier.organizationName = env.organizationName
        projectModifier.options = options
        projectModifier.packages = package
        projectModifier.fileHeaderTemplate = fileHeaderTemplate
        projectModifier.additionalFiles = additionalFiles
        projectModifier.resourceSynthesizers = resourceSynthesizers
        projectModifier.settings = .settings(configurations: env.configuration.configure(into: xcconfig))
        projectModifier.schemes = projectModifier.targets.flatMap {
            $0.build().product == .app ? [
                Scheme.makeScheme(name: name, hasExampleTarget: false, target: .dev),
                Scheme.makeScheme(name: name, hasExampleTarget: true, target: .dev),
            ] : [
                Scheme.makeScheme(name: name, hasExampleTarget: false, target: .dev)
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
