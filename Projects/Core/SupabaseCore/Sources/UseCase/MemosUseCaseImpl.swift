import Foundation
import MemosDomainInterface

public final class MemosUseCaseImpl: MemosUseCase {
    private let memosRepository: MemosRepository
    
    public init(memosRepository: MemosRepository) {
        self.memosRepository = memosRepository
    }
    
    public func createMemo(_ memo: MemosEntity) async throws {
        return try await memosRepository.createMemo(memo)
    }
    
    public func updateMemo(_ memo: MemosEntity) async throws {
        return try await memosRepository.updateMemo(memo)
    }
    
    public func deleteMemo(id: UUID) async throws {
        try await memosRepository.deleteMemo(id: id)
    }
    
    public func getMemo(id: UUID) async throws -> MemosEntity {
        return try await memosRepository.fetchMemo(id: id)
    }
    
    public func getMemos(userId: UUID) async throws -> [MemosEntity] {
        return try await memosRepository.fetchMemos(userId: userId)
    }
    
    public func searchMemos(userId: UUID, keyword: String) async throws -> [MemosEntity] {
        return try await memosRepository.searchMemos(userId: userId, keyword: keyword)
    }
}
