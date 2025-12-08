import Foundation
import SwiftDataCoreInterface
import MemosDomainInterface

/// MemoModel <-> MemoEntity 변환을 담당하는 DTO
public enum MemosDTO {
    /// MemoEntity -> MemoModel 변환
    public static func toModel(from entity: MemosEntity) -> MemosModel {
        MemosModel(
            id: entity.id,
            userId: entity.userId,
            title: entity.title,
            content: entity.description,
            blocks: entity.blocks.map { toBlockModel(from: $0) },
            alarmId: entity.alarmId ?? UUID(),
            reminderTime: entity.reminderTime,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
    
    /// MemoModel -> MemoEntity 변환
    public static func toEntity(from model: MemosModel) -> MemosEntity {
        MemosEntity(
            id: model.id,
            userId: model.userId,
            title: model.title,
            description: model.content,
            blocks: model.blocks.map { toBlockEntity(from: $0) },
            alarmId: model.alarmId,
            reminderTime: model.reminderTime,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }
    
    // MARK: - Block 변환 헬퍼
    
    /// MemoBlockEntity -> MemoBlockModel 변환
    private static func toBlockModel(from entity: MemoBlockEntity) -> MemoBlockModel {
        MemoBlockModel(
            id: entity.id,
            type: toBlockModelType(from: entity.type),
            content: entity.content,
            children: entity.children.map { toBlockModel(from: $0) }
        )
    }
    
    /// MemoBlockModel -> MemoBlockEntity 변환
    private static func toBlockEntity(from model: MemoBlockModel) -> MemoBlockEntity {
        MemoBlockEntity(
            id: model.id,
            type: toBlockEntityType(from: model.type),
            content: model.content,
            children: model.children.map { toBlockEntity(from: $0) }
        )
    }
    
    /// MemoBlockEntity.BlockType -> MemoBlockModel.BlockType 변환
    private static func toBlockModelType(from entityType: MemoBlockEntity.BlockType) -> MemoBlockModel.BlockType {
        switch entityType {
        case .text:
            return .text
        case .heading:
            return .heading
        case .checklist:
            return .checklist
        case .image:
            return .image
        case .divider:
            return .divider
        }
    }
    
    /// MemoBlockModel.BlockType -> MemoBlockEntity.BlockType 변환
    private static func toBlockEntityType(from modelType: MemoBlockModel.BlockType) -> MemoBlockEntity.BlockType {
        switch modelType {
        case .text:
            return .text
        case .heading:
            return .heading
        case .checklist:
            return .checklist
        case .image:
            return .image
        case .divider:
            return .divider
        }
    }
}
