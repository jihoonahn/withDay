import ProjectDescription

extension Scheme {
    public static func makeScheme(
        name: String,
        hasExampleTarget: Bool = false,
        hasSourceTarget: Bool = true,
        hasInterfaceTarget: Bool = true,
        hasTestTarget: Bool = true,
        target: ConfigurationName
    ) -> Scheme {

        let buildTargets: [TargetReference] = {
            if hasExampleTarget {
                return ["\(name)Example"]
            } else if hasSourceTarget {
                return ["\(name)"]
            } else {
                return []
            }
        }()

        let buildAction = BuildAction.buildAction(targets: buildTargets)

        let testTargets: [TestableTarget] = {
            if hasTestTarget {
                return ["\(name)Tests"]
            } else {
                return []
            }
        }()

        let coverageTargets: [TargetReference] = {
            if hasExampleTarget {
                return ["\(name)Example"]
            } else if hasSourceTarget {
                return ["\(name)"]
            } else {
                return []
            }
        }()

        let testAction: TestAction? = testTargets.isEmpty
        ? nil
        : TestAction.targets(
            testTargets,
            configuration: target,
            options: .options(
                coverage: true,
                codeCoverageTargets: coverageTargets
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
