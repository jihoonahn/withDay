import Foundation
import UserSettingsDomainInterface

// MARK: - DTO
struct UserSettingsDTO: Codable {
    let id: UUID
    let userId: UUID
    let language: String
    let notificationEnabled: Bool
    let allowPush: Bool
    let allowVibration: Bool
    let allowSound: Bool
    let widgetEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    
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
    
    init(from entity: UserSettingsEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.language = entity.language
        self.notificationEnabled = entity.notificationEnabled
        self.allowPush = entity.allowPush
        self.allowVibration = entity.allowVibration
        self.allowSound = entity.allowSound
        self.widgetEnabled = entity.widgetEnabled
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> UserSettingsEntity {
        UserSettingsEntity(
            id: id,
            userId: userId,
            language: language,
            notificationEnabled: notificationEnabled,
            allowPush: allowPush,
            allowVibration: allowVibration,
            allowSound: allowSound,
            widgetEnabled: widgetEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

