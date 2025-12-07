import Foundation
import SwiftDataCoreInterface
import UserSettingsDomainInterface

/// UserSettingsModel <-> UserSettingsEntity 변환을 담당하는 DTO
public enum UserSettingsDTO {
    /// UserSettingsEntity -> UserSettingsModel 변환
    public static func toModel(from entity: UserSettingsEntity) -> UserSettingsModel {
        UserSettingsModel(
            id: entity.id,
            userId: entity.userId,
            language: entity.language,
            notificationEnabled: entity.notificationEnabled,
            allowPush: entity.allowPush,
            allowVibration: entity.allowVibration,
            allowSound: entity.allowSound,
            widgetEnabled: entity.widgetEnabled,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// UserSettingsModel -> UserSettingsEntity 변환
    public static func toEntity(from model: UserSettingsModel) -> UserSettingsEntity {
        UserSettingsEntity(
            id: model.id,
            userId: model.userId,
            language: model.language,
            notificationEnabled: model.notificationEnabled,
            allowPush: model.allowPush,
            allowVibration: model.allowVibration,
            allowSound: model.allowSound,
            widgetEnabled: model.widgetEnabled,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

