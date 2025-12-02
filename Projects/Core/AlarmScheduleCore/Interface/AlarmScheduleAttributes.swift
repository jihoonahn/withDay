import Foundation
import ActivityKit
import AlarmKit

public struct AlarmScheduleAttributes: AlarmMetadata, Codable, Hashable {
    public let alarmId: UUID
    public let alarmLabel: String?
    public let nextAlarmTime: Date
    public let isAlerting: Bool
    public let lastUpdateTime: Date

    public init(
        alarmId: UUID,
        alarmLabel: String?,
        nextAlarmTime: Date,
        isAlerting: Bool = false,
        lastUpdateTime: Date = Date()
    ) {
        self.alarmId = alarmId
        self.alarmLabel = alarmLabel
        self.nextAlarmTime = nextAlarmTime
        self.isAlerting = isAlerting
        self.lastUpdateTime = lastUpdateTime
    }
}
