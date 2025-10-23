import Foundation
import MotionRawDataDomainInterface

public final class MotionRawDataUseCaseImpl: MotionRawDataUseCase {
    private let motionRawDataRepository: MotionRawDataRepository
    
    public init(motionRawDataRepository: MotionRawDataRepository) {
        self.motionRawDataRepository = motionRawDataRepository
    }
    
    public func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity] {
        return try await motionRawDataRepository.fetchAll(executionId: executionId)
    }
    
    public func create(_ data: MotionRawDataEntity) async throws {
        try await motionRawDataRepository.create(data)
    }
}
