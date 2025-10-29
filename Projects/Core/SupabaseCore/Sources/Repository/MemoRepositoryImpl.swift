import Foundation
import MemoDomainInterface
import SupabaseCoreInterface

public final class MemoRepositoryImpl: MemoRepository {
    private let memoService: SupabaseCoreInterface.MemoService
    
    public init(memoService: SupabaseCoreInterface.MemoService) {
        self.memoService = memoService
    }
    
    public func fetchAll(userId: UUID) async throws -> [MemoEntity] {
        return try await memoService.fetchMemos(for: userId)
    }
    
    public func create(_ memo: MemoEntity) async throws {
        try await memoService.createMemo(memo)
    }
    
    public func update(_ memo: MemoEntity) async throws {
        try await memoService.updateMemo(memo)
    }
    
    public func delete(id: UUID) async throws {
        try await memoService.deleteMemo(id: id)
    }
}
