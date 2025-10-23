import Foundation
import UserDomainInterface

struct UserDTO: Codable {
    let id: UUID
    let provider: String
    let email: String?
    let displayName: String?
    let wakeUpGoal: Date?
    let sleepGoal: Date?
    let notificationEnabled: Bool
    let soundVolume: Int
    let hapticEnabled: Bool
    let level: Int
    let experience: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case provider
        case email
        case displayName = "display_name"
        case wakeUpGoal = "wake_up_goal"
        case sleepGoal = "sleep_goal"
        case notificationEnabled = "notification_enabled"
        case soundVolume = "sound_volume"
        case hapticEnabled = "haptic_enabled"
        case level
        case experience
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID,
        provider: String,
        email: String?,
        displayName: String?,
        wakeUpGoal: Date?,
        sleepGoal: Date?,
        notificationEnabled: Bool,
        soundVolume: Int,
        hapticEnabled: Bool,
        level: Int,
        experience: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.provider = provider
        self.email = email
        self.displayName = displayName
        self.wakeUpGoal = wakeUpGoal
        self.sleepGoal = sleepGoal
        self.notificationEnabled = notificationEnabled
        self.soundVolume = soundVolume
        self.hapticEnabled = hapticEnabled
        self.level = level
        self.experience = experience
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from entity: UserEntity) {
        self.id = entity.id
        self.provider = entity.provider
        self.email = entity.email
        self.displayName = entity.displayName
        self.wakeUpGoal = entity.wakeUpGoal
        self.sleepGoal = entity.sleepGoal
        self.notificationEnabled = entity.notificationEnabled
        self.soundVolume = entity.soundVolume
        self.hapticEnabled = entity.hapticEnabled
        self.level = entity.level
        self.experience = entity.experience
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func toEntity() -> UserEntity {
        UserEntity(
            id: id,
            provider: provider,
            email: email,
            displayName: displayName,
            wakeUpGoal: wakeUpGoal,
            sleepGoal: sleepGoal,
            notificationEnabled: notificationEnabled,
            soundVolume: soundVolume,
            hapticEnabled: hapticEnabled,
            level: level,
            experience: experience
        )
    }
}

