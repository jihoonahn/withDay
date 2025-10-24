import Foundation
import AlarmExecutionDomainInterface
import Helpers

struct AlarmExecutionDTO: Codable {
    let id: UUID
    let userId: UUID
    let alarmId: UUID
    let scheduledTime: Date
    let triggeredTime: Date?
    let motionDetectedTime: Date?
    let completedTime: Date?
    let motionCompleted: Bool
    let motionAttempts: Int
    let motionData: Data
    let wakeConfidence: Double?
    let postureChanges: Int?
    let snoozeCount: Int
    let totalWakeDuration: Int?
    let status: String
    let viewedMemoIds: [UUID]
    let createdAt: Date
    
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
    }
    
    init(from entity: AlarmExecutionEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.alarmId = entity.alarmId
        self.scheduledTime = entity.scheduledTime
        self.triggeredTime = entity.triggeredTime
        self.motionDetectedTime = entity.motionDetectedTime
        self.completedTime = entity.completedTime
        self.motionCompleted = entity.motionCompleted
        self.motionAttempts = entity.motionAttempts
        self.motionData = entity.motionData
        self.wakeConfidence = entity.wakeConfidence
        self.postureChanges = entity.postureChanges
        self.snoozeCount = entity.snoozeCount
        self.totalWakeDuration = entity.totalWakeDuration
        self.status = entity.status
        self.viewedMemoIds = entity.viewedMemoIds
        self.createdAt = entity.createdAt
    }
    
    func toEntity() -> AlarmExecutionEntity {
        AlarmExecutionEntity(
            id: id,
            userId: userId,
            alarmId: alarmId,
            scheduledTime: scheduledTime,
            triggeredTime: triggeredTime,
            motionDetectedTime: motionDetectedTime,
            completedTime: completedTime,
            motionCompleted: motionCompleted,
            motionAttempts: motionAttempts,
            motionData: motionData,
            wakeConfidence: wakeConfidence,
            postureChanges: postureChanges,
            snoozeCount: snoozeCount,
            totalWakeDuration: totalWakeDuration,
            status: status,
            viewedMemoIds: viewedMemoIds,
            createdAt: createdAt
        )
    }
}
