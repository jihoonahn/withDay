import Foundation
import SwiftDataCoreInterface
import SchedulesDomainInterface

/// ScheduleModel <-> SchedulesEntity 변환을 담당하는 DTO
public enum ScheduleDTO {
    /// SchedulesEntity -> ScheduleModel 변환
    public static func toModel(from entity: SchedulesEntity) -> SchedulesModel {
        SchedulesModel(
            id: entity.id,
            userId: entity.userId,
            title: entity.title,
            content: entity.description,
            date: entity.date,
            startTime: entity.startTime,
            endTime: entity.endTime,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// ScheduleModel -> SchedulesEntity 변환
    public static func toEntity(from model: SchedulesModel) -> SchedulesEntity {
        SchedulesEntity(
            id: model.id,
            userId: model.userId,
            title: model.title,
            description: model.content,
            date: model.date,
            startTime: model.startTime,
            endTime: model.endTime,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}
