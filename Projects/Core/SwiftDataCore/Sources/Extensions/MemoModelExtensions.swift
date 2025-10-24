import Foundation
import SwiftDataCoreInterface
import MemoDomainInterface

extension MemoModel {
    public convenience init(from entity: MemoEntity) {
        self.init(
            id: entity.id,
            userId: entity.userId,
            title: "",
            content: entity.content,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
    
    public func toEntity() -> MemoEntity {
        MemoEntity(
            id: id,
            userId: userId,
            content: content,
            date: createdAt,
            alarmId: nil,
            reminderTime: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

