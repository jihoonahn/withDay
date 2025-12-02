import Foundation

public protocol MotionRawDataService: Sendable {
    func fetchMotionData(executionId: UUID) async throws -> [MotionRawDataModel]
    func saveMotionData(_ data: MotionRawDataModel) async throws
}
