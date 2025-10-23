import Foundation

public protocol MotionRawDataUseCase {
    func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity]
    func create(_ data: MotionRawDataEntity) async throws
}
