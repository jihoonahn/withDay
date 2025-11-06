import Foundation

public struct SettingEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public var language: String
    public var notificationEnabled: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        language: String,
        notificationEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.language = language
        self.notificationEnabled = notificationEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
