import Foundation
import MotionRawDataDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class MotionRawDataRepositoryImpl: MotionRawDataRepository {
    private let motionRawDataService: MotionRawDataService
    
    public init(motionRawDataService: MotionRawDataService) {
        self.motionRawDataService = motionRawDataService
    }
    
    public func fetchAll(executionId: UUID) async throws -> [MotionRawDataEntity] {
        let models = try await motionRawDataService.fetchMotionData(executionId: executionId)
        return models.map { $0.toEntity() }
    }
    
    public func create(_ data: MotionRawDataEntity) async throws {
        let model = MotionRawDataModel(from: data)
        try await motionRawDataService.saveMotionData(model)
    }
}

