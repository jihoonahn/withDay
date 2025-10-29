import Foundation
import MotionRawDataDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class MotionRawDataRepositoryImpl: MotionRawDataRepository {
    private let motionRawDataService: SwiftDataCoreInterface.MotionRawDataService
    
    public init(motionRawDataService: SwiftDataCoreInterface.MotionRawDataService) {
        self.motionRawDataService = motionRawDataService
    }
    
    public func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity] {
        let models = try await motionRawDataService.fetchMotionData(executionId: executionId)
        return models.map { MotionRawDataDTO.toEntity(from: $0) }
    }
    
    public func create(_ data: MotionRawDataEntity) async throws {
        let model = MotionRawDataDTO.toModel(from: data)
        try await motionRawDataService.saveMotionData(model)
    }
}
