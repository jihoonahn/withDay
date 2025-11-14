import Foundation

public protocol MotionRepository {
    func startMonitoring(for executionId: UUID) async throws -> MotionEntity
    func stopMonitoring(for executionId: UUID)
    func stopAllMonitoring()
}
