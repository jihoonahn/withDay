import Foundation
import MotionDomainInterface

public enum MotionServiceError: Error {
    case accelerometerNotAvailable
    case monitoringNotStarted
    case monitoringStopped
}

public protocol MotionService {
    func startMonitoring(for executionId: UUID) async throws -> MotionEntity
    func startMonitoring(for alarmId: UUID, requiredCount: Int) async throws
    func stopMonitoring(for alarmId: UUID)
    func stopAllMonitoring()
    func getMotionCount(for alarmId: UUID) -> Int
}
