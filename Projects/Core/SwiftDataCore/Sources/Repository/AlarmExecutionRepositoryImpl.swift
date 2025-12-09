import Foundation
import AlarmExecutionsDomainInterface
import SwiftDataCoreInterface

// MARK: - Repository Implementation
public final class AlarmExecutionRepositoryImpl: AlarmExecutionsRepository {

    private let alarmExecutionService: SwiftDataCoreInterface.AlarmExecutionsService

    public init(alarmExecutionService: SwiftDataCoreInterface.AlarmExecutionsService) {
        self.alarmExecutionService = alarmExecutionService
    }

    public func startExecution(userId: UUID, alarmId: UUID) async throws -> AlarmExecutionsEntity {
        let execution = AlarmExecutionsEntity(
            id: UUID(),
            userId: userId,
            alarmId: alarmId,
            scheduledTime: Date(),
            triggeredTime: nil,
            motionDetectedTime: nil,
            completedTime: nil,
            motionCompleted: false,
            motionAttempts: 0,
            motionData: Data(),
            wakeConfidence: nil,
            postureChanges: nil,
            snoozeCount: 0,
            totalWakeDuration: nil,
            status: "scheduled",
            viewedMemoIds: [],
            createdAt: Date(),
            isMoving: false
        )
        
        let model = AlarmExecutionsDTO.toModel(from: execution)
        try await alarmExecutionService.createExecution(model)
        
        return execution
    }
    
    public func updateExecution(_ execution: AlarmExecutionsEntity) async throws {
        let model = AlarmExecutionsDTO.toModel(from: execution)
        try await alarmExecutionService.updateExecution(model)
    }
    
    public func completeExecution(id: UUID) async throws {
        try await alarmExecutionService.updateExecutionStatus(id: id, status: "completed")
    }
}
