import AlarmKit
import Foundation

public struct AlarmData: AlarmMetadata, Codable {
    public let createdAt: Date
    public let alarmId: UUID
    public let nextAlarmTime: Date?
    public let alarmLabel: String?
    public let isAlerting: Bool
    public let motionCount: Int
    public let requiredMotionCount: Int

    public init(
        alarmId: UUID = UUID(),
        nextAlarmTime: Date? = nil,
        alarmLabel: String? = nil,
        isAlerting: Bool = false,
        motionCount: Int = 0,
        requiredMotionCount: Int = 3
    ) {
        self.createdAt = .now
        self.alarmId = alarmId
        self.nextAlarmTime = nextAlarmTime
        self.alarmLabel = alarmLabel
        self.isAlerting = isAlerting
        self.motionCount = motionCount
        self.requiredMotionCount = requiredMotionCount
    }
}
