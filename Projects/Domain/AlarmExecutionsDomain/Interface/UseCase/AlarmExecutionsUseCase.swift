import Foundation

public protocol AlarmExecutionsUseCase: Sendable {
    func startExecution(userId: UUID, alarmId: UUID) async throws -> AlarmExecutionsEntity
    func updateExecution(_ execution: AlarmExecutionsEntity) async throws
    func completeExecution(id: UUID) async throws
}
