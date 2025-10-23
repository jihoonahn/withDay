import Foundation
import AlarmDomainInterface

struct AlarmDTO: Codable {
    let id: UUID
    let userId: UUID
    let label: String?
    let time: String
    let repeatDays: [Int]
    let snoozeEnabled: Bool
    let snoozeInterval: Int
    let snoozeLimit: Int
    let soundName: String
    let soundUrl: String?
    let vibrationPattern: String?
    let volumeOverride: Int?
    let linkedMemoIds: [UUID]
    let showMemosOnAlarm: Bool
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case label
        case time
        case repeatDays = "repeat_days"
        case snoozeEnabled = "snooze_enabled"
        case snoozeInterval = "snooze_interval"
        case snoozeLimit = "snooze_limit"
        case soundName = "sound_name"
        case soundUrl = "sound_url"
        case vibrationPattern = "vibration_pattern"
        case volumeOverride = "volume_override"
        case linkedMemoIds = "linked_memo_ids"
        case showMemosOnAlarm = "show_memos_on_alarm"
        case isEnabled = "is_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from entity: AlarmEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.label = entity.label
        self.time = entity.time
        self.repeatDays = entity.repeatDays
        self.snoozeEnabled = entity.snoozeEnabled
        self.snoozeInterval = entity.snoozeInterval
        self.snoozeLimit = entity.snoozeLimit
        self.soundName = entity.soundName
        self.soundUrl = entity.soundURL
        self.vibrationPattern = entity.vibrationPattern
        self.volumeOverride = entity.volumeOverride
        self.linkedMemoIds = entity.linkedMemoIds
        self.showMemosOnAlarm = entity.showMemosOnAlarm
        self.isEnabled = entity.isEnabled
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> AlarmEntity {
        AlarmEntity(
            id: id,
            userId: userId,
            label: label,
            time: time,
            repeatDays: repeatDays,
            snoozeEnabled: snoozeEnabled,
            snoozeInterval: snoozeInterval,
            snoozeLimit: snoozeLimit,
            soundName: soundName,
            soundURL: soundUrl,
            vibrationPattern: vibrationPattern,
            volumeOverride: volumeOverride,
            linkedMemoIds: linkedMemoIds,
            showMemosOnAlarm: showMemosOnAlarm,
            isEnabled: isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

