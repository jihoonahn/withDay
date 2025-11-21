import Foundation

public protocol MotionUseCase {
    func startMonitoring(for alarmId: UUID, executionId: UUID, requiredCount: Int) async throws
    func stopMonitoring(for alarmId: UUID)
    func stopAllMonitoring()
}
