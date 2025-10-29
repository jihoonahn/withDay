import Foundation
import SwiftDataCoreInterface
import AlarmDomainInterface

/// AlarmModel <-> AlarmEntity 변환을 담당하는 DTO
public enum AlarmDTO {
    /// AlarmEntity -> AlarmModel 변환
    public static func toModel(from entity: AlarmEntity) -> AlarmModel {
        AlarmModel(
            id: entity.id,
            userId: entity.userId,
            label: entity.label ?? "",
            time: entity.time,
            repeatDays: entity.repeatDays,
            snoozeEnabled: entity.snoozeEnabled,
            snoozeInterval: entity.snoozeInterval,
            snoozeLimit: entity.snoozeLimit,
            soundName: entity.soundName,
            soundURL: entity.soundURL,
            vibrationPattern: entity.vibrationPattern,
            volumeOverride: entity.volumeOverride,
            linkedMemoIds: entity.linkedMemoIds,
            showMemosOnAlarm: entity.showMemosOnAlarm,
            isEnabled: entity.isEnabled,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// AlarmModel -> AlarmEntity 변환
    public static func toEntity(from model: AlarmModel) -> AlarmEntity {
        AlarmEntity(
            id: model.id,
            userId: model.userId,
            label: model.label.isEmpty ? nil : model.label,
            time: model.time,
            repeatDays: model.repeatDays,
            snoozeEnabled: model.snoozeEnabled,
            snoozeInterval: model.snoozeInterval,
            snoozeLimit: model.snoozeLimit,
            soundName: model.soundName,
            soundURL: model.soundURL,
            vibrationPattern: model.vibrationPattern,
            volumeOverride: model.volumeOverride,
            linkedMemoIds: model.linkedMemoIds,
            showMemosOnAlarm: model.showMemosOnAlarm,
            isEnabled: model.isEnabled,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

