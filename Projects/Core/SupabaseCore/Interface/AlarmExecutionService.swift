import Foundation
import AlarmExecutionDomainInterface

public protocol AlarmExecutionService {
    func fetchExecutions(for userId: UUID) async throws -> [AlarmExecutionEntity]
    func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionEntity]
    func createExecution(_ execution: AlarmExecutionEntity) async throws
    func updateExecution(_ execution: AlarmExecutionEntity) async throws
    func updateExecutionStatus(id: UUID, status: String) async throws
    func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws
    func deleteExecution(id: UUID) async throws
}
