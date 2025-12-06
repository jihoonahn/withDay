import Foundation

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
    public var motionData: Data
    public var wakeConfidence: Double?
    public var postureChanges: Int?
    public var snoozeCount: Int
    public var totalWakeDuration: Int?
    public var status: String // "scheduled", "triggered", "motion_detected", "completed", "missed"
    public var viewedMemoIds: [UUID]
    public let createdAt: Date
    public var isMoving: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case alarmId = "alarm_id"
        case scheduledTime = "scheduled_time"
        case triggeredTime = "triggered_time"
        case motionDetectedTime = "motion_detected_time"
        case completedTime = "completed_time"
        case motionCompleted = "motion_completed"
        case motionAttempts = "motion_attempts"
        case motionData = "motion_data"
        case wakeConfidence = "wake_confidence"
        case postureChanges = "posture_changes"
        case snoozeCount = "snooze_count"
        case totalWakeDuration = "total_wake_duration"
        case status
        case viewedMemoIds = "viewed_memo_ids"
        case createdAt = "created_at"
        case isMoving = "is_moving"
    }
    
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
        motionData: Data,
        wakeConfidence: Double? = nil,
        postureChanges: Int? = nil,
        snoozeCount: Int,
        totalWakeDuration: Int? = nil,
        status: String,
        viewedMemoIds: [UUID],
        createdAt: Date,
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
