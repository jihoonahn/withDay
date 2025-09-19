import ProjectDescription

public extension TargetDependency {
    static func feature(
        target: String,
        type: MicroTargetType = .sources
    ) -> TargetDependency {
        .project(
            target: "\(target)\(type.rawValue)",
            path: .relativeToFeature(target),
        )
    }
    static func domain(
        target: String,
        type: MicroTargetType = .sources
    ) -> TargetDependency {
        .project(
            target: "\(target)\(type.rawValue)",
            path: .relativeToDomain(target),
        )
    }
    static func core(
        target: String,
        type: MicroTargetType = .sources
    ) -> TargetDependency {
        .project(
            target: "\(target)\(type.rawValue)",
            path: .relativeToCore(target),
        )
    }
    static func shared(type: MicroTargetType = .sources) -> TargetDependency {
        .project(
            target: "\(type.rawValue)",
            path: .relativeToShared(),
        )
    }
}
