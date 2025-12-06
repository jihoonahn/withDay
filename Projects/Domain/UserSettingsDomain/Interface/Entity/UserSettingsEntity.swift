import Foundation

public struct UserSettingsEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let language: String
    public let notificationEnabled: Bool
    public let allowPush: Bool
    public let allowVibration: Bool
    public let allowSound: Bool
    public let widgetEnabled: Bool
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case language
        case notificationEnabled = "notification_enabled"
        case allowPush = "allow_push"
        case allowVibration = "allow_vibration"
        case allowSound = "allow_sound"
        case widgetEnabled = "widget_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID,
        userId: UUID,
        language: String,
        notificationEnabled: Bool,
        allowPush: Bool,
        allowVibration: Bool,
        allowSound: Bool,
        widgetEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.language = language
        self.notificationEnabled = notificationEnabled
        self.allowPush = allowPush
        self.allowVibration = allowVibration
        self.allowSound = allowSound
        self.widgetEnabled = widgetEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
