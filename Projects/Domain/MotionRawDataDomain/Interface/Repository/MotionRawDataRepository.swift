import Foundation

public protocol MotionRawDataRepository {
    func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity]
    func create(_ data: MotionRawDataEntity) async throws
}
