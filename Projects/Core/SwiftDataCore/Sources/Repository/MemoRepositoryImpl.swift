import Foundation
import MemoDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class MemoRepositoryImpl: MemoRepository {
    private let memoService: SwiftDataCoreInterface.MemoService
    
    public init(memoService: SwiftDataCoreInterface.MemoService) {
        self.memoService = memoService
    }
    
    public func fetchAll(userId: UUID) async throws -> [MemoEntity] {
        let models = try await memoService.fetchMemos(userId: userId)
        return models.map { MemoDTO.toEntity(from: $0) }
    }
    
    public func create(_ memo: MemoEntity) async throws {
        let model = MemoDTO.toModel(from: memo)
        try await memoService.saveMemo(model)
    }
    
    public func update(_ memo: MemoEntity) async throws {
        let model = MemoDTO.toModel(from: memo)
        try await memoService.updateMemo(model)
    }
    
    public func delete(id: UUID) async throws {
        try await memoService.deleteMemo(id: id)
    }
}

