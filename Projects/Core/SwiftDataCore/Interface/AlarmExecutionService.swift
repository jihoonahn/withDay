import Foundation

public enum AlarmExecutionServiceError: Error, LocalizedError {
    case executionNotFound
    
    public var errorDescription: String? {
        switch self {
        case .executionNotFound:
            return "Execution not found"
        }
    }
}

public protocol AlarmExecutionsService: Sendable {
    func fetchExecution(userId: UUID) async throws -> AlarmExecutionsModel
    func fetchExecutions(userId: UUID) async throws -> [AlarmExecutionsModel]
    func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionsModel]
    func createExecution(_ execution: AlarmExecutionsModel) async throws
    func updateExecution(_ execution: AlarmExecutionsModel) async throws
    func updateExecutionStatus(id: UUID, status: String) async throws
    func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws
}
