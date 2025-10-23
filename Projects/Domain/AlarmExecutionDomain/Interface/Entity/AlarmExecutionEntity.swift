import Foundation
import Helpers

public struct AlarmExecutionEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let alarmId: UUID
    public var scheduledTime: Date
    public var triggeredTime: Date?
    public var motionDetectedTime: Date?
    public var completedTime: Date?
    public var motionCompleted: Bool
    public var motionAttempts: Int
    public var motionData: AnyJSON
    public var wakeConfidence: Double?
    public var postureChanges: Int?
    public var snoozeCount: Int
    public var totalWakeDuration: Int?
    public var status: String // "scheduled", "triggered", "motion_detected", "completed", "missed"
    public var viewedMemoIds: [UUID]
    public let createdAt: Date

    public init(
        id: UUID,
        userId: UUID,
        alarmId: UUID,
        scheduledTime: Date,
        triggeredTime: Date? = nil,
        motionDetectedTime: Date? = nil,
        completedTime: Date? = nil,
        motionCompleted: Bool,
        motionAttempts: Int,
        motionData: AnyJSON,
        wakeConfidence: Double? = nil,
        postureChanges: Int? = nil,
        snoozeCount: Int,
        totalWakeDuration: Int? = nil,
        status: String,
        viewedMemoIds: [UUID],
        createdAt: Date
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
    }
}
