import Foundation
import SwiftDataCoreInterface
import AlarmMissionsDomainInterface

/// AlarmMissionModel <-> AlarmMissionsEntity 변환을 담당하는 DTO
public enum AlarmMissionDTO {
    /// AlarmMissionsEntity -> AlarmMissionModel 변환
    public static func toModel(from entity: AlarmMissionsEntity) -> AlarmMissionModel {
        let configData: Data?
        if let config = entity.config {
            configData = try? JSONEncoder().encode(config)
        } else {
            configData = nil
        }
        
        return AlarmMissionModel(
            id: entity.id,
            alarmId: entity.alarmId,
            missionType: entity.missionType,
            difficulty: entity.difficulty,
            configData: configData,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// AlarmMissionModel -> AlarmMissionsEntity 변환
    public static func toEntity(from model: AlarmMissionModel) -> AlarmMissionsEntity {
        let config: MissionConfig?
        if let configData = model.configData {
            config = try? JSONDecoder().decode(MissionConfig.self, from: configData)
        } else {
            config = nil
        }
        
        return AlarmMissionsEntity(
            id: model.id,
            alarmId: model.alarmId,
            missionType: model.missionType,
            difficulty: model.difficulty,
            config: config,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

