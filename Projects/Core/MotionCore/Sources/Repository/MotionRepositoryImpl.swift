import Foundation
import MotionCoreInterface
import MotionDomainInterface

public final class MotionRepositoryImpl: MotionRepository {

    private let service: MotionService

    public init(service: MotionService) {
        self.service = service
    }

    public func startMonitoring(for alarmId: UUID, executionId: UUID, requiredCount: Int) async throws {
        try await service.startMonitoring(for: alarmId, executionId: executionId, requiredCount: requiredCount)
    }

    public func stopMonitoring(for alarmId: UUID) {
        service.stopMonitoring(for: alarmId)
    }

    public func stopAllMonitoring() {
        service.stopAllMonitoring()
    }
}
