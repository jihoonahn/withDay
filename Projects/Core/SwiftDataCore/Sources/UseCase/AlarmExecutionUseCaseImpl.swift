import Foundation
import AlarmExecutionDomainInterface

@MainActor
public final class AlarmExecutionUseCaseImpl: AlarmExecutionUseCase {

    private let alarmExecutionRepository: AlarmExecutionRepository
    
    public init(alarmExecutionRepository: AlarmExecutionRepository) {
        self.alarmExecutionRepository = alarmExecutionRepository
    }
    
    public func getExecutions(userId: UUID, date: Date) async throws -> [AlarmExecutionEntity] {
        return try await alarmExecutionRepository.fetchAll(userId: userId, date: date)
    }
    
    public func saveExecution(_ execution: AlarmExecutionEntity) async throws {
        if execution.createdAt == Date() {
            try await alarmExecutionRepository.create(execution)
        } else {
            try await alarmExecutionRepository.update(execution)
        }
    }
    
    public func markMotionDetected(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws {
        try await alarmExecutionRepository.updateMotion(
            id: id,
            motionData: motionData,
            wakeConfidence: wakeConfidence,
            postureChanges: postureChanges,
            isMoving: isMoving
        )
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionRepository.updateExecutionStatus(id: id, status: "completed")
    }
}
