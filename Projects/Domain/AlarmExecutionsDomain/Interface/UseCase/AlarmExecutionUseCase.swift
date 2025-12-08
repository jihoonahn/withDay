import Foundation
import AlarmExecutionDomainInterface

public protocol AlarmExecutionUseCase {
    func startExecution(alarmId: UUID, userId: UUID) async throws -> AlarmExecutionsEntity
    func updateExecution(_ execution: AlarmExecutionsEntity) async throws
    func completeExecution(id: UUID) async throws
}
