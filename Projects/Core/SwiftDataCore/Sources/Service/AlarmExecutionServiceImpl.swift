import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class AlarmExecutionServiceImpl: AlarmExecutionService {

    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchExecution(userId: UUID) async throws -> AlarmExecutionsModel {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionsModel>(
            predicate: #Predicate { execution in
                execution.userId == userId
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        return try context.fetch(descriptor).first!
    }
    
    public func fetchExecutions(userId: UUID) async throws -> [AlarmExecutionsModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionsModel>(
            predicate: #Predicate { execution in
                execution.userId == userId
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionsModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionsModel>(
            predicate: #Predicate { execution in
                execution.alarmId == alarmId
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func createExecution(_ execution: AlarmExecutionsModel) async throws {
        let context = await container.mainContext
        context.insert(execution)
        try context.save()
    }
    
    public func updateExecution(_ execution: AlarmExecutionsModel) async throws {
        let context = await container.mainContext
        try context.save()
    }
    
    public func updateExecutionStatus(id: UUID, status: String) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionsModel>(
            predicate: #Predicate { execution in
                execution.id == id
            }
        )
        
        if let execution = try context.fetch(descriptor).first {
            execution.status = status
            try context.save()
        }
    }

    public func updateMotion(
        id: UUID,
        motionData: Data,
        wakeConfidence: Double,
        postureChanges: Int,
        isMoving: Bool
    ) async throws {
        let context = await container.mainContext

        let descriptor = FetchDescriptor<AlarmExecutionsModel>(
            predicate: #Predicate { execution in
                execution.id == id
            }
        )

        guard let execution = try context.fetch(descriptor).first else {
            throw AlarmExecutionServiceError.executionNotFound
        }

        execution.motionData = motionData
        execution.wakeConfidence = wakeConfidence
        execution.isMoving = isMoving
        execution.postureChanges = postureChanges
        execution.motionCompleted = true

        execution.status = "motionDetected"
        try context.save()
    }
}
