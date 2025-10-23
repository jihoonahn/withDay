import Foundation

public protocol AlarmExecutionUseCase {
    func getExecutions(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity]
    func saveExecution(_ execution: AlarmExecutionEntity) async throws
    func markMotionDetected(id: UUID, motionData: [String: Any], wakeConfidence: Double) async throws
    func completeExecution(id: UUID) async throws
}
