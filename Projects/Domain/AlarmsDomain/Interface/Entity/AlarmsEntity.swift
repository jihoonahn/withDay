import Foundation

public struct AlarmsEntity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var label: String?
    public var time: String
    public var repeatDays: [Int]
    public var snoozeEnabled: Bool
    public var snoozeInterval: Int
    public var snoozeLimit: Int
    public var soundName: String
    public var soundURL: String?
    public var vibrationPattern: String?
    public var volumeOverride: Int?
    public var linkedMemoIds: [UUID]
    public var showMemosOnAlarm: Bool
    public var isEnabled: Bool
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case label
        case time
        case repeatDays
        case snoozeEnabled = "snooze_enabled"
        case snoozeInterval = "snooze_interval"
        case snoozeLimit = "snooze_limit"
        case soundName = "sound_name"
        case soundURL = "sound_url"
        case vibrationPattern = "vibration_pattern"
        case volumeOverride = "volume_override"
        case linkedMemoIds = "linked_memo_ids"
        case showMemosOnAlarm = "show_memos_on_alarm"
        case isEnabled
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID,
        userId: UUID,
        label: String?,
        time: String,
        repeatDays: [Int],
        snoozeEnabled: Bool,
        snoozeInterval: Int,
        snoozeLimit: Int,
        soundName: String,
        soundURL: String?,
        vibrationPattern: String?,
        volumeOverride: Int?,
        linkedMemoIds: [UUID],
        showMemosOnAlarm: Bool,
        isEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.label = label
        self.time = time
        self.repeatDays = repeatDays
        self.snoozeEnabled = snoozeEnabled
        self.snoozeInterval = snoozeInterval
        self.snoozeLimit = snoozeLimit
        self.soundName = soundName
        self.soundURL = soundURL
        self.vibrationPattern = vibrationPattern
        self.volumeOverride = volumeOverride
        self.linkedMemoIds = linkedMemoIds
        self.showMemosOnAlarm = showMemosOnAlarm
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
