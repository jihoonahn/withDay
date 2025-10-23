import Foundation

public protocol SleepPatternRepository {
    func fetch(userId: UUID, date: Date) async throws -> SleepPatternEntity?
    func create(_ pattern: SleepPatternEntity) async throws
    func update(_ pattern: SleepPatternEntity) async throws
}
