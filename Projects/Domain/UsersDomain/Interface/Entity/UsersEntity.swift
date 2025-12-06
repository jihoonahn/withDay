import Foundation

public struct UserEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public var provider: String
    public var email: String?
    public var displayName: String?
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case provider
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID,
        provider: String,
        email: String? = nil,
        displayName: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.provider = provider
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
