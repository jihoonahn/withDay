import Foundation
import ActivityKit

public struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let isAlerting: Bool
        public let lastUpdateTime: Date
        
        public init(
            isAlerting: Bool = false,
            lastUpdateTime: Date = Date()
        ) {
            self.isAlerting = isAlerting
            self.lastUpdateTime = lastUpdateTime
        }
    }
    
    public let alarmId: UUID
    public let alarmLabel: String?
    public let scheduledTime: Date
    public let nextAlarmId: UUID?  // 다음 알람 ID
    public let nextAlarmTime: Date?  // 다음 알람 시간
    
    public init(
        alarmId: UUID,
        alarmLabel: String?,
        scheduledTime: Date,
        nextAlarmId: UUID? = nil,
        nextAlarmTime: Date? = nil
    ) {
        self.alarmId = alarmId
        self.alarmLabel = alarmLabel
        self.scheduledTime = scheduledTime
        self.nextAlarmId = nextAlarmId
        self.nextAlarmTime = nextAlarmTime
    }
}
