import Foundation
import MotionCoreInterface
import MotionDomainInterface

public final class MotionRepositoryImpl: MotionRepository {

    private let service: MotionService

    public init(service: MotionService) {
        self.service = service
    }

    public func startMonitoring(for executionId: UUID) async throws -> MotionEntity {
        try await service.startMonitoring(for: executionId)
    }

    public func stopMonitoring(for executionId: UUID) {
        service.stopMonitoring(for: executionId)
    }

    public func stopAllMonitoring() {
        service.stopAllMonitoring()
    }
}
