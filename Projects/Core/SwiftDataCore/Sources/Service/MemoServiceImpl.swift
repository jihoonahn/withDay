import Foundation
import SwiftData
import SwiftDataCoreInterface

@MainActor
public final class MemoServiceImpl: MemoService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchMemos(userId: UUID) async throws -> [MemoModel] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<MemoModel>(
            predicate: #Predicate { memo in
                memo.userId == userId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func saveMemo(_ memo: MemoModel) async throws {
        let context = container.mainContext
        context.insert(memo)
        try context.save()
    }
    
    public func updateMemo(_ memo: MemoModel) async throws {
        let context = container.mainContext
        memo.updatedAt = Date()
        try context.save()
    }
    
    public func deleteMemo(id: UUID) async throws {
        let context = container.mainContext
        let descriptor = FetchDescriptor<MemoModel>(
            predicate: #Predicate { memo in
                memo.id == id
            }
        )
        
        if let memo = try context.fetch(descriptor).first {
            context.delete(memo)
            try context.save()
        }
    }
}

