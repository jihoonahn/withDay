import Foundation
import SwiftDataCoreInterface
import MemoDomainInterface

/// MemoModel <-> MemoEntity 변환을 담당하는 DTO
public enum MemoDTO {
    /// MemoEntity -> MemoModel 변환
    public static func toModel(from entity: MemoEntity) -> MemoModel {
        MemoModel(
            id: entity.id,
            userId: entity.userId,
            title: entity.title,
            content: entity.content,
            reminderTime: entity.reminderTime,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
    
    /// MemoModel -> MemoEntity 변환
    public static func toEntity(from model: MemoModel) -> MemoEntity {
        MemoEntity(
            id: model.id,
            userId: model.userId,
            title: model.title,
            content: model.content,
            alarmId: nil,
            reminderTime: model.reminderTime,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

