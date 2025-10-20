import Foundation
import MemoDomainInterface

public protocol SupabaseMemoStorage {
    func fetchMemos(for userId: UUID) async throws -> [MemoEntity]
    func saveMemo(_ memo: MemoEntity) async throws
    func deleteMemo(id: UUID) async throws
}
