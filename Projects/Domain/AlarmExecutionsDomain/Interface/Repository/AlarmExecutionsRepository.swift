import Foundation

public protocol AlarmExecutionsRepository: Sendable {
    func startExecution(alarmId: UUID) async throws -> AlarmExecutionsEntity
    func updateExecution(_ execution: AlarmExecutionsEntity) async throws
    func completeExecution(id: UUID) async throws
}
