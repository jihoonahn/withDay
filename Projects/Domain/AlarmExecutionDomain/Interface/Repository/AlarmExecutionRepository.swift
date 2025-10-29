import Foundation

public protocol AlarmExecutionRepository {
    func fetchAll(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity]
    func fetch(id: UUID) async throws -> AlarmExecutionEntity?
    func create(_ execution: AlarmExecutionEntity) async throws
    func update(_ execution: AlarmExecutionEntity) async throws
    func updateMotion(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws
    func updateExecutionStatus(id: UUID, status: String) async throws
}
