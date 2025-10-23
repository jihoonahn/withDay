import Foundation

public protocol SleepPatternUseCase {
    func getSleepPattern(userId: UUID, date: Date) async throws -> SleepPatternEntity?
    func saveSleepPattern(_ pattern: SleepPatternEntity) async throws
}
