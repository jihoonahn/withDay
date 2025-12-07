import Foundation
import AlarmExecutionsDomainInterface

public protocol AlarmExecutionsService: Sendable {
    func startExecution(alarmId: UUID) async throws -> AlarmExecutionsEntity
    func updateExecution(_ execution: AlarmExecutionsEntity) async throws
    func completeExecution(id: UUID) async throws
}
