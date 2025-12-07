import Foundation
import Supabase
import MemosDomainInterface
import SupabaseCoreInterface

// MARK: - Repository Implementation
public final class MemosRepositoryImpl: MemosRepository {

    private let memosService: MemosService

    public init(memosService: MemosService) {
        self.memosService = memosService
    }

    public func createMemo(_ memo: MemosEntity) async throws {
        try await memosService.createMemo(memo)
    }
    
    public func updateMemo(_ memo: MemosEntity) async throws {
        try await memosService.updateMemo(memo)
    }
    
    public func deleteMemo(id: UUID) async throws {
        try await memosService.deleteMemo(id: id)
    }
    
    public func fetchMemo(id: UUID) async throws -> MemosEntity {
        try await memosService.getMemo(id: id)
    }
    
    public func fetchMemos() async throws -> [MemosEntity] {
        try await memosService.getMemos()
    }
    
    public func searchMemos(keyword: String) async throws -> [MemosEntity] {
        try await memosService.searchMemos(keyword: keyword)
    }
}
