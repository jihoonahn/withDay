import Foundation
import SwiftDataCoreInterface
import AlarmExecutionDomainInterface

extension AlarmExecutionModel {
    public convenience init(from entity: AlarmExecutionEntity) {
        let motionDataDict = entity.motionData
        let motionDataJSON = try? JSONSerialization.data(withJSONObject: motionDataDict, options: [])
        
        self.init(
            id: entity.id,
            userId: entity.userId,
            alarmId: entity.alarmId,
            scheduledTime: entity.scheduledTime,
            triggeredTime: entity.triggeredTime,
            motionDetectedTime: entity.motionDetectedTime,
            completedTime: entity.completedTime,
            motionCompleted: entity.motionCompleted,
            motionAttempts: entity.motionAttempts,
            motionData: motionDataJSON ?? Data(),
            wakeConfidence: entity.wakeConfidence,
            postureChanges: entity.postureChanges,
            snoozeCount: entity.snoozeCount,
            totalWakeDuration: entity.totalWakeDuration,
            status: entity.status,
            viewedMemoIds: entity.viewedMemoIds,
            createdAt: entity.createdAt
        )
    }
    
    public func toEntity() -> AlarmExecutionEntity {
        var motionDataDict: [String: String] = [:]
        if let json = try? JSONSerialization.jsonObject(with: motionData, options: []) as? [String: String] {
            motionDataDict = json
        }
        
        return AlarmExecutionEntity(
            id: id,
            userId: userId,
            alarmId: alarmId,
            scheduledTime: scheduledTime,
            triggeredTime: triggeredTime,
            motionDetectedTime: motionDetectedTime,
            completedTime: completedTime,
            motionCompleted: motionCompleted,
            motionAttempts: motionAttempts,
            motionData: motionDataDict,
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

