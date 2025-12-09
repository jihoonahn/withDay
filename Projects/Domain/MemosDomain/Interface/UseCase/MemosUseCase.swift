import Foundation

public protocol MemosUseCase: Sendable {
    func createMemo(_ memo: MemosEntity) async throws
    func updateMemo(_ memo: MemosEntity) async throws
    func deleteMemo(id: UUID) async throws
    func getMemo(id: UUID) async throws -> MemosEntity
    func getMemos(userId: UUID) async throws -> [MemosEntity]
    func searchMemos(userId: UUID, keyword: String) async throws -> [MemosEntity]
}
