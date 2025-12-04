import Foundation

public protocol MemoRepository {
    func fetchAll(userId: UUID) async throws -> [MemoEntity]
    func create(_ memo: MemoEntity) async throws
    func update(_ memo: MemoEntity) async throws
    func delete(id: UUID) async throws
}
