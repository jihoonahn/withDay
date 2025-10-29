import Foundation
import AlarmExecutionDomainInterface
import SupabaseCoreInterface

public final class AlarmExecutionRepositoryImpl: AlarmExecutionRepository {

    private let alarmExecutionService: SupabaseCoreInterface.AlarmExecutionService
    
    public init(alarmExecutionService: SupabaseCoreInterface.AlarmExecutionService) {
        self.alarmExecutionService = alarmExecutionService
    }
    
    public func fetchAll(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity] {
        let allExecutions = try await alarmExecutionService.fetchExecutions(for: userId)
        
        let calendar = Calendar.current
        return allExecutions.filter { execution in
            calendar.isDate(execution.scheduledTime, inSameDayAs: date)
        }
    }

    public func fetch(id: UUID) async throws -> AlarmExecutionEntity? {
        try await alarmExecutionService.fetchExecutions(for: id)[0]
    }

    public func create(_ execution: AlarmExecutionEntity) async throws {
        try await alarmExecutionService.createExecution(execution)
    }
    
    public func update(_ execution: AlarmExecutionEntity) async throws {
        try await alarmExecutionService.updateExecution(execution)
    }

    public func updateExecutionStatus(id: UUID, status: String) async throws {
        try await alarmExecutionService.updateExecutionStatus(id: id, status: status)
    }

    public func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws {
        try await alarmExecutionService.updateMotion(id: id, motionData: motionData, wakeConfidence: wakeConfidence, postureChanges: postureChanges, isMoving: isMoving)
    }
}
