import Foundation

public protocol MotionUseCase {
    func startMonitoring(for executionId: UUID) async throws -> MotionEntity
    func stopMonitoring(for executionId: UUID)
    func stopAllMonitoring()
}
