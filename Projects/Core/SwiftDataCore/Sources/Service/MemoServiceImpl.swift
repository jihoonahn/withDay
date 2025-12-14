import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class MemoServiceImpl: MemosService {

    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }

    public func createMemo(_ memo: MemosModel) async throws {
        let context = await container.mainContext
        context.insert(memo)
        try context.save()
    }
    
    public func updateMemo(_ memo: MemosModel) async throws {
        let context = await container.mainContext
        memo.updatedAt = Date()
        try context.save()
    }
    
    public func deleteMemo(id: UUID) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<MemosModel>(
            predicate: #Predicate { memo in
                memo.id == id
            }
        )
        if let memo = try context.fetch(descriptor).first {
            context.delete(memo)
            try context.save()
        }
    }
    
    public func getMemo(id: UUID) async throws -> MemosModel {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<MemosModel>(
            predicate: #Predicate { memo in
                memo.id == id
            }
        )
        return try context.fetch(descriptor).first!
    }
    
    public func getMemos(userId: UUID) async throws -> [MemosModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<MemosModel>(
            predicate: #Predicate { memo in
                memo.userId == userId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func searchMemos(userId: UUID, keyword: String) async throws -> [MemosModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<MemosModel>(
            predicate: #Predicate { memo in
                (memo.content.contains(keyword) == true) && memo.userId == userId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func getMemosByAlarmId(alarmId: UUID) async throws -> [MemosModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<MemosModel>(
            predicate: #Predicate { memo in
                memo.alarmId == alarmId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func getMemosByScheduleId(scheduleId: UUID) async throws -> [MemosModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<MemosModel>(
            predicate: #Predicate { memo in
                memo.scheduleId == scheduleId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
