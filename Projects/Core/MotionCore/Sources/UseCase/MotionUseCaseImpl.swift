import Foundation
import MotionDomainInterface

public final class MotionUseCaseImpl: MotionUseCase {

    private let repository: MotionRepository
    
    public init(repository: MotionRepository) {
        self.repository = repository
    }

    public func startMonitoring(for executionId: UUID) async throws -> MotionEntity {
        try await repository.startMonitoring(for: executionId)
    }

    public func stopMonitoring(for executionId: UUID) {
        repository.stopMonitoring(for: executionId)
    }

    public func stopAllMonitoring() {
        repository.stopAllMonitoring()
    }
}
