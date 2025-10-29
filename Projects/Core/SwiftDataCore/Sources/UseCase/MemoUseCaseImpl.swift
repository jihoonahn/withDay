import Foundation
import MemoDomainInterface

@MainActor
public final class MemoUseCaseImpl: MemoUseCase {
    private let memoRepository: MemoRepository
    
    public init(memoRepository: MemoRepository) {
        self.memoRepository = memoRepository
    }
    
    public func fetchAll(userId: UUID) async throws -> [MemoEntity] {
        return try await memoRepository.fetchAll(userId: userId)
    }
    
    public func create(_ memo: MemoEntity) async throws {
        try await memoRepository.create(memo)
    }
    
    public func update(_ memo: MemoEntity) async throws {
        try await memoRepository.update(memo)
    }
    
    public func delete(id: UUID) async throws {
        try await memoRepository.delete(id: id)
    }
}
