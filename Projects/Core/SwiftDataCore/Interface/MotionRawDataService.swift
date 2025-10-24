import Foundation

public protocol MotionRawDataService {
    func fetchMotionData(executionId: UUID) async throws -> [MotionRawDataModel]
    func saveMotionData(_ data: MotionRawDataModel) async throws
}
