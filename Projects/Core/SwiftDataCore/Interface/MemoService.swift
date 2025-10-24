import Foundation

public protocol MemoService {
    func fetchMemos(userId: UUID) async throws -> [MemoModel]
    func saveMemo(_ memo: MemoModel) async throws
    func updateMemo(_ memo: MemoModel) async throws
    func deleteMemo(id: UUID) async throws
}
