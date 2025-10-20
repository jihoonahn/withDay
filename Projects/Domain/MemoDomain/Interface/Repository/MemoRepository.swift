import Foundation

public protocol MemoRepository {
    func fetchMemos(for userId: UUID) async throws -> [MemoEntity]
    func saveMemo(_ memo: MemoEntity) async throws
}
