import Foundation
import ActivityKit

public struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let isAlerting: Bool
        public let motionCount: Int
        public let requiredMotionCount: Int
        public let lastUpdateTime: Date
        
        public init(
            isAlerting: Bool = false,
            motionCount: Int = 0,
            requiredMotionCount: Int = 3,
            lastUpdateTime: Date = Date()
        ) {
            self.isAlerting = isAlerting
            self.motionCount = motionCount
            self.requiredMotionCount = requiredMotionCount
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
