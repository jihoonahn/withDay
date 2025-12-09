import Foundation

public protocol MemosService: Sendable {
    func createMemo(_ memo: MemosModel) async throws
    func updateMemo(_ memo: MemosModel) async throws
    func deleteMemo(id: UUID) async throws
    func getMemo(id: UUID) async throws -> MemosModel
    func getMemos(userId: UUID) async throws -> [MemosModel]
    func searchMemos(userId: UUID, keyword: String) async throws -> [MemosModel]
}
