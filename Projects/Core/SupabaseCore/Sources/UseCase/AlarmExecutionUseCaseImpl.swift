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
    
    public func markMotionDetected(id: UUID, motionData: Data, wakeConfidence: Double) async throws {
        guard var execution = try await alarmExecutionRepository.fetch(id: id) else {
            throw NSError(domain: "AlarmExecutionUseCaseImpl", code: 404, userInfo: [NSLocalizedDescriptionKey: "Execution not found"])
        }

        execution.motionDetectedTime = Date()
        execution.motionData = motionData
        execution.wakeConfidence = wakeConfidence

        execution.status = "motion_detected"
        try await alarmExecutionRepository.update(execution)
    }
    
    public func completeExecution(id: UUID) async throws {
        guard var execution = try await alarmExecutionRepository.fetch(id: id) else {
            throw NSError(domain: "AlarmExecutionUseCaseImpl", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "Execution not found"
            ])
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
}
