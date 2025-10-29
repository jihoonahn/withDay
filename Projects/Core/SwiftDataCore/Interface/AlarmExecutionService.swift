import Foundation

public protocol AlarmExecutionService: Sendable {
    func fetchExecution(userId: UUID) async throws -> AlarmExecutionModel
    func fetchExecutions(userId: UUID) async throws -> [AlarmExecutionModel]
    func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionModel]
    func createExecution(_ execution: AlarmExecutionModel) async throws
    func updateExecution(_ execution: AlarmExecutionModel) async throws
    func updateExecutionStatus(id: UUID, status: String) async throws
    func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws
}
