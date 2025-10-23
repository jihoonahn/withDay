import Foundation
import AlarmExecutionDomainInterface
import SupabaseCoreInterface

public final class AlarmExecutionRepositoryImpl: AlarmExecutionRepository {
    private let alarmExecutionService: AlarmExecutionService
    
    public init(alarmExecutionService: AlarmExecutionService) {
        self.alarmExecutionService = alarmExecutionService
    }
    
    public func fetchAll(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity] {
        let allExecutions = try await alarmExecutionService.fetchExecutions(for: userId)
        
        let calendar = Calendar.current
        return allExecutions.filter { execution in
            calendar.isDate(execution.scheduledTime, inSameDayAs: date)
        }
    }
    
    public func create(_ execution: AlarmExecutionEntity) async throws {
        try await alarmExecutionService.createExecution(execution)
    }
    
    public func update(_ execution: AlarmExecutionEntity) async throws {
        try await alarmExecutionService.updateExecution(execution)
    }
    
    public func updateStatus(id: UUID, status: String) async throws {
        try await alarmExecutionService.updateExecutionStatus(id: id, status: status)
    }
}
