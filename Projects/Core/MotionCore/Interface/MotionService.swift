import Foundation
import MotionDomainInterface

public enum MotionServiceError: Error {
    case accelerometerNotAvailable
    case monitoringNotStarted
    case monitoringStopped
}

public protocol MotionService {
    func startMonitoring(for executionId: UUID) async throws -> MotionEntity
    func stopMonitoring(for executionId: UUID)
    func stopAllMonitoring()
}
