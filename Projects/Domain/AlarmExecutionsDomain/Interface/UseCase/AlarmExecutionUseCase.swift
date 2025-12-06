import Foundation

public protocol AlarmExecutionUseCase {
    func startExecution(alarmId: UUID, userId: UUID) async throws -> AlarmExecutionEntity
    func updateExecution(_ execution: AlarmExecutionEntity) async throws
    func completeExecution(id: UUID) async throws
}
