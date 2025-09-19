import ProjectDescription

extension Scheme {
    public static func makeScheme(
        name: String,
        hasExampleTarget: Bool = false,
        target: ConfigurationName
    ) -> Scheme {
        
        let buildAction = hasExampleTarget
        ? BuildAction.buildAction(targets: ["\(name)Example"])
        : BuildAction.buildAction(targets: ["\(name)"])
        
        let testAction = hasExampleTarget
        ? TestAction.targets(
            ["\(name)Tests"],
            configuration: target,
            options: .options(
                coverage: true,
                codeCoverageTargets: ["\(name)Example"]
            )
        )
        : TestAction.targets(
            ["\(name)Tests"],
            configuration: target,
            options: .options(
                coverage: true,
                codeCoverageTargets: ["\(name)"]
            )
        )
        
        let archiveAction = ArchiveAction.archiveAction(configuration: target)
        let profileAction = ProfileAction.profileAction(configuration: target)
        let analyzeAction = AnalyzeAction.analyzeAction(configuration: target)
        
        let base = Scheme.scheme(
            name: "\(name)-\(target.rawValue)",
            shared: true,
            buildAction: buildAction,
            testAction: testAction,
            archiveAction: archiveAction,
            profileAction: profileAction,
            analyzeAction: analyzeAction
        )
        
        return base
    }
}
