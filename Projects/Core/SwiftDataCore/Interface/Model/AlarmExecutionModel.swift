import SwiftData
import Foundation

@Model
public final class AlarmExecutionModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var alarmId: UUID
    public var scheduledTime: Date
    public var triggeredTime: Date?
    public var motionDetectedTime: Date?
    public var completedTime: Date?
    public var motionCompleted: Bool
    public var motionAttempts: Int
    public var motionData: Data
    public var wakeConfidence: Double?
    public var postureChanges: Int?
    public var snoozeCount: Int
    public var totalWakeDuration: Int?
    public var status: String
    public var viewedMemoIds: [UUID]
    public var createdAt: Date
    public var isMoving: Bool
    
    public init(
        id: UUID,
        userId: UUID,
        alarmId: UUID,
        scheduledTime: Date,
        triggeredTime: Date? = nil,
        motionDetectedTime: Date? = nil,
        completedTime: Date? = nil,
        motionCompleted: Bool = false,
        motionAttempts: Int = 0,
        motionData: Data,
        wakeConfidence: Double? = nil,
        postureChanges: Int? = nil,
        snoozeCount: Int = 0,
        totalWakeDuration: Int? = nil,
        status: String = "scheduled",
        viewedMemoIds: [UUID] = [],
        createdAt: Date = Date(),
        isMoving: Bool
    ) {
        self.id = id
        self.userId = userId
        self.alarmId = alarmId
        self.scheduledTime = scheduledTime
        self.triggeredTime = triggeredTime
        self.motionDetectedTime = motionDetectedTime
        self.completedTime = completedTime
        self.motionCompleted = motionCompleted
        self.motionAttempts = motionAttempts
        self.motionData = motionData
        self.wakeConfidence = wakeConfidence
        self.postureChanges = postureChanges
        self.snoozeCount = snoozeCount
        self.totalWakeDuration = totalWakeDuration
        self.status = status
        self.viewedMemoIds = viewedMemoIds
        self.createdAt = createdAt
        self.isMoving = isMoving
    }
}
