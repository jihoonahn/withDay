import Foundation

public struct UserEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let email: String
    public let profileName: String?
    public let createdAt: Date

    public init(id: UUID, email: String, profileName: String?, createdAt: Date) {
        self.id = id
        self.email = email
        self.profileName = profileName
        self.createdAt = createdAt
    }
}
