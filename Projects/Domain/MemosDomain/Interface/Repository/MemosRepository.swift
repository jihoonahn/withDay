import Foundation

public protocol MemosRepository: Sendable {
    func createMemo(_ memo: MemosEntity) async throws
    func updateMemo(_ memo: MemosEntity) async throws
    func deleteMemo(id: UUID) async throws
    func fetchMemo(id: UUID) async throws -> MemosEntity
    func fetchMemos() async throws -> [MemosEntity]
    func searchMemos(keyword: String) async throws -> [MemosEntity]
}
