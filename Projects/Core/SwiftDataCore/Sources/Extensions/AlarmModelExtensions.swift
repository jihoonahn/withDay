import Foundation
import SwiftDataCoreInterface
import AlarmDomainInterface

extension AlarmModel {
    public convenience init(from entity: AlarmEntity) {
        self.init(
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
    
    public func toEntity() -> AlarmEntity {
        AlarmEntity(
            id: id,
            userId: userId,
            label: label.isEmpty ? nil : label,
            time: time,
            repeatDays: repeatDays,
            snoozeEnabled: snoozeEnabled,
            snoozeInterval: snoozeInterval,
            snoozeLimit: snoozeLimit,
            soundName: soundName,
            soundURL: soundURL,
            vibrationPattern: vibrationPattern,
            volumeOverride: volumeOverride,
            linkedMemoIds: linkedMemoIds,
            showMemosOnAlarm: showMemosOnAlarm,
            isEnabled: isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

