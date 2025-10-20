import Foundation

public protocol MemoUseCase {
    func getMemos(for userId: UUID) async throws -> [MemoEntity]
    func addMemo(_ memo: MemoEntity) async throws
}
