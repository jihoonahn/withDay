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
            title: "",
            content: entity.content,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    /// MemoModel -> MemoEntity 변환
    public static func toEntity(from model: MemoModel) -> MemoEntity {
        MemoEntity(
            id: model.id,
            userId: model.userId,
            content: model.content,
            date: model.createdAt,
            alarmId: nil,
            reminderTime: nil,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
}

