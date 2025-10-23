import Foundation
import AlarmExecutionDomainInterface

public protocol AlarmExecutionService {
    func fetchExecutions(for userId: UUID) async throws -> [AlarmExecutionEntity]
    func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionEntity]
    func createExecution(_ execution: AlarmExecutionEntity) async throws
    func updateExecution(_ execution: AlarmExecutionEntity) async throws
    func deleteExecution(id: UUID) async throws
}
