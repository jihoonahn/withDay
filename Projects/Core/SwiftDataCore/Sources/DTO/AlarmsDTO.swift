import Foundation
import SwiftDataCoreInterface
import AlarmsDomainInterface

/// AlarmModel <-> AlarmEntity 변환을 담당하는 DTO
public enum AlarmsDTO {
    /// AlarmEntity -> AlarmModel 변환
    public static func toModel(from entity: AlarmsEntity) -> AlarmsModel {
        AlarmsModel(
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
            isEnabled: entity.isEnabled,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// AlarmModel -> AlarmEntity 변환
    public static func toEntity(from model: AlarmsModel) -> AlarmsEntity {
        AlarmsEntity(
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
            isEnabled: model.isEnabled,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

