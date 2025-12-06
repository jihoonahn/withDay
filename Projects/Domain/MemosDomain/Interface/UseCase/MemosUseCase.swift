import Foundation

public protocol MemosUseCase {
    func createMemo(_ memo: MemosEntity) async throws -> MemosEntity
    func updateMemo(_ memo: MemosEntity) async throws -> MemosEntity
    func deleteMemo(id: UUID) async throws
    func getMemo(id: UUID) async throws -> MemosEntity
    func getMemos(userID: UUID) async throws -> [MemosEntity]
    func searchMemos(userID: UUID, keyword: String) async throws -> [MemosEntity]
}
