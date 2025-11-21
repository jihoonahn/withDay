import Foundation
import MotionDomainInterface

public final class MotionUseCaseImpl: MotionUseCase {

    private let repository: MotionRepository
    
    public init(repository: MotionRepository) {
        self.repository = repository
    }

    public func startMonitoring(for alarmId: UUID, executionId: UUID, requiredCount: Int) async throws {
        try await repository.startMonitoring(for: alarmId, executionId: executionId, requiredCount: requiredCount)
    }

    public func stopMonitoring(for alarmId: UUID) {
        repository.stopMonitoring(for: alarmId)
    }

    public func stopAllMonitoring() {
        repository.stopAllMonitoring()
    }
}
