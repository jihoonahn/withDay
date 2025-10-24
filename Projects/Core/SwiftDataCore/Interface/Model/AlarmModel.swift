import Foundation
import SwiftData

@Model
public final class AlarmModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var label: String
    public var time: String // "HH:mm" 형식
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
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        label: String,
        time: String,
        repeatDays: [Int] = [],
        snoozeEnabled: Bool = false,
        snoozeInterval: Int = 5,
        snoozeLimit: Int = 3,
        soundName: String,
        soundURL: String? = nil,
        vibrationPattern: String? = nil,
        volumeOverride: Int? = nil,
        linkedMemoIds: [UUID] = [],
        showMemosOnAlarm: Bool = false,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
