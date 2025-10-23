import Foundation
import MemoDomainInterface

public protocol MemoService {
    func fetchMemos(for userId: UUID) async throws -> [MemoEntity]
    func fetchMemosByAlarm(alarmId: UUID) async throws -> [MemoEntity]
    func createMemo(_ memo: MemoEntity) async throws
    func updateMemo(_ memo: MemoEntity) async throws
    func deleteMemo(id: UUID) async throws
}
