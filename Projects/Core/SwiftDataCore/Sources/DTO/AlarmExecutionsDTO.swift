import Foundation
import SwiftDataCoreInterface
import AlarmExecutionsDomainInterface

/// AlarmExecutionModel <-> AlarmExecutionEntity 변환을 담당하는 DTO
public enum AlarmExecutionsDTO {
    /// AlarmExecutionEntity -> AlarmExecutionModel 변환
    public static func toModel(from entity: AlarmExecutionsEntity) -> AlarmExecutionsModel {
        AlarmExecutionsModel(
            id: entity.id,
            userId: entity.userId,
            alarmId: entity.alarmId,
            scheduledTime: entity.scheduledTime,
            triggeredTime: entity.triggeredTime,
            motionDetectedTime: entity.motionDetectedTime,
            completedTime: entity.completedTime,
            motionCompleted: entity.motionCompleted,
            motionAttempts: entity.motionAttempts,
            motionData: entity.motionData,
            wakeConfidence: entity.wakeConfidence,
            postureChanges: entity.postureChanges,
            snoozeCount: entity.snoozeCount,
            totalWakeDuration: entity.totalWakeDuration,
            status: entity.status,
            viewedMemoIds: entity.viewedMemoIds,
            createdAt: entity.createdAt,
            isMoving: entity.isMoving
        )
    }
    
    /// AlarmExecutionModel -> AlarmExecutionEntity 변환
    public static func toEntity(from model: AlarmExecutionsModel) -> AlarmExecutionsEntity {
        AlarmExecutionsEntity(
            id: model.id,
            userId: model.userId,
            alarmId: model.alarmId,
            scheduledTime: model.scheduledTime,
            triggeredTime: model.triggeredTime,
            motionDetectedTime: model.motionDetectedTime,
            completedTime: model.completedTime,
            motionCompleted: model.motionCompleted,
            motionAttempts: model.motionAttempts,
            motionData: model.motionData,
            wakeConfidence: model.wakeConfidence,
            postureChanges: model.postureChanges,
            snoozeCount: model.snoozeCount,
            totalWakeDuration: model.totalWakeDuration,
            status: model.status,
            viewedMemoIds: model.viewedMemoIds,
            createdAt: model.createdAt,
            isMoving: model.isMoving
        )
    }
}
