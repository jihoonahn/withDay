import Foundation
import AlarmExecutionDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class AlarmExecutionRepositoryImpl: AlarmExecutionRepository {
    
    private let alarmExecutionService: SwiftDataCoreInterface.AlarmExecutionService
    
    public init(alarmExecutionService: SwiftDataCoreInterface.AlarmExecutionService) {
        self.alarmExecutionService = alarmExecutionService
    }
    
    public func fetchAll(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity] {
        let models = try await alarmExecutionService.fetchExecutions(userId: userId)
        
        let calendar = Calendar.current
        return models
            .filter { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
            .map { AlarmExecutionDTO.toEntity(from: $0) }
    }

    public func fetch(id: UUID) async throws -> AlarmExecutionEntity? {
        let model = try await alarmExecutionService.fetchExecution(userId: id)
        return AlarmExecutionDTO.toEntity(from: model)
    }

    public func create(_ execution: AlarmExecutionEntity) async throws {
        let model = AlarmExecutionDTO.toModel(from: execution)
        try await alarmExecutionService.createExecution(model)
    }
    
    public func update(_ execution: AlarmExecutionEntity) async throws {
        let model = AlarmExecutionDTO.toModel(from: execution)
        try await alarmExecutionService.updateExecution(model)
    }
    
    public func updateStatus(id: UUID, status: String) async throws {
        try await alarmExecutionService.updateExecutionStatus(id: id, status: status)
    }

    public func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws {
        try await alarmExecutionService.updateMotion(id: id, motionData: motionData, wakeConfidence: wakeConfidence, postureChanges: postureChanges, isMoving: isMoving)
    }

    public func updateExecutionStatus(id: UUID, status: String) async throws {
        try await alarmExecutionService.updateExecutionStatus(id: id, status: status)
    }
}
