import Foundation
import MotionRawDataDomainInterface
import SupabaseCoreInterface

public final class MotionRawDataRepositoryImpl: MotionRawDataRepository {
    private let motionRawDataService: SupabaseCoreInterface.MotionRawDataService
    
    public init(motionRawDataService: SupabaseCoreInterface.MotionRawDataService) {
        self.motionRawDataService = motionRawDataService
    }
    
    public func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity] {
        return try await motionRawDataService.fetchMotionData(for: executionId)
    }
    
    public func create(_ data: MotionRawDataEntity) async throws {
        try await motionRawDataService.createMotionData(data)
    }
}
