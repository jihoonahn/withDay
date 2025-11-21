import Foundation
import ActivityKit

public struct AlarmAttributes: ActivityAttributes, Codable {
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
    
    public init(
        alarmId: UUID,
        alarmLabel: String?,
        scheduledTime: Date
    ) {
        self.alarmId = alarmId
        self.alarmLabel = alarmLabel
        self.scheduledTime = scheduledTime
    }
}

