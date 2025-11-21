import Foundation

public struct MotionDetectionEvent {
    public let alarmId: UUID
    public let count: Int
    public let motionData: MotionEntity
    
    public init(alarmId: UUID, count: Int, motionData: MotionEntity) {
        self.alarmId = alarmId
        self.count = count
        self.motionData = motionData
    }
}

