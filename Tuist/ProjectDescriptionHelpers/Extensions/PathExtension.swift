import ProjectDescription

public extension ProjectDescription.Path {
    static var app: Self {
        return .relativeToRoot("Projects/App")
    }
    static func relativeToProjects(_ path: String) -> Self {
        return .relativeToRoot("Projects/\(path)")
    }
    static func relativeToConfiguration(_ path: String) -> Self {
        return .relativeToRoot("Configuration/\(path)")
    }
    static func relativeToFeature(_ path: String) -> Self {
        return .relativeToRoot("Projects/Feature/\(path)")
    }
    static func relativeToDomain(_ path: String) -> Self {
        return .relativeToRoot("Projects/Domain/\(path)")
    }
    static func relativeToCore(_ path: String) -> Self {
        return .relativeToRoot("Projects/Core/\(path)")
    }
    static func relativeToShared() -> Self {
        return .relativeToRoot("Projects/Shard")
    }
}
