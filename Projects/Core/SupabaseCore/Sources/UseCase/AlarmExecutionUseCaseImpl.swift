import Foundation
import AlarmExecutionDomainInterface

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
    
    public func completeExecution(id: UUID) async throws {
        guard var execution = try await alarmExecutionRepository.fetch(id: id) else {
            throw AlarmExecutionError.executionNotFound
        }
        
        execution.completedTime = Date.now
        execution.status = "completed"
        execution.motionCompleted = true

        if let motionDetectedTime = execution.motionDetectedTime {
            let duration = Date.now.timeIntervalSince(motionDetectedTime)
            execution.totalWakeDuration = Int(duration)
        } else {
            let duration = Date.now.timeIntervalSince(execution.createdAt)
            execution.totalWakeDuration = Int(duration)
        }

        try await alarmExecutionRepository.update(execution)
    }

    public func markMotionDetected(id: UUID, motionData: Data, wakeConfidence: Double, postureChanges: Int, isMoving: Bool) async throws {
        guard var execution = try await alarmExecutionRepository.fetch(id: id) else {
            throw AlarmExecutionError.executionNotFound
        }

        execution.motionData = motionData
        execution.wakeConfidence = wakeConfidence
        execution.postureChanges = postureChanges
        execution.isMoving = isMoving
        execution.motionCompleted = true
        execution.status = "motionDetected"
        execution.motionDetectedTime = Date.now

        let startTime = execution.createdAt
        let motionTime = execution.motionDetectedTime ?? startTime
        execution.totalWakeDuration = Int(Date.now.timeIntervalSince(motionTime))

        try await alarmExecutionRepository.update(execution)
    }
}
