import Foundation
import MotionRawDataDomainInterface

public protocol MotionRawDataService {
    func fetchMotionData(for executionId: UUID) async throws -> [MotionRawDataEntity]
    func createMotionData(_ data: MotionRawDataEntity) async throws
    func deleteMotionData(for executionId: UUID) async throws
}
