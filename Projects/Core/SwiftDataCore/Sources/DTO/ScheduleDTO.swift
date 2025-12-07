import Foundation
import SwiftDataCoreInterface
import SchedulesDomainInterface

/// ScheduleModel <-> SchedulesEntity 변환을 담당하는 DTO
public enum ScheduleDTO {
    /// SchedulesEntity -> ScheduleModel 변환
    public static func toModel(from entity: SchedulesEntity) -> ScheduleModel {
        ScheduleModel(
            id: entity.id,
            userId: entity.userId,
            title: entity.title,
            description: entity.description,
            date: entity.date,
            startTime: entity.startTime,
            endTime: entity.endTime,
            memoIds: entity.memoIds,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// ScheduleModel -> SchedulesEntity 변환
    public static func toEntity(from model: ScheduleModel) -> SchedulesEntity {
        SchedulesEntity(
            id: model.id,
            userId: model.userId,
            title: model.title,
            description: model.description,
            date: model.date,
            startTime: model.startTime,
            endTime: model.endTime,
            memoIds: model.memoIds,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

