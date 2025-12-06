import Foundation

public protocol MemosRepository {
    func createMemo(_ memo: MemosEntity) async throws -> MemosEntity
    func updateMemo(_ memo: MemosEntity) async throws -> MemosEntity
    func deleteMemo(id: UUID) async throws

    func fetchMemo(id: UUID) async throws -> MemosEntity
    func fetchMemos(userID: UUID) async throws -> [MemosEntity]

    func searchMemos(userID: UUID, keyword: String) async throws -> [MemosEntity]
}
