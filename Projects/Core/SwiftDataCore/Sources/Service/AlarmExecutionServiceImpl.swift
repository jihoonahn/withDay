import Foundation
import SwiftData
import SwiftDataCoreInterface

@MainActor
public final class AlarmExecutionServiceImpl: AlarmExecutionService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchExecutions(userId: UUID) async throws -> [AlarmExecutionModel] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionModel>(
            predicate: #Predicate { execution in
                execution.userId == userId
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func fetchExecutionsByAlarm(alarmId: UUID) async throws -> [AlarmExecutionModel] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionModel>(
            predicate: #Predicate { execution in
                execution.alarmId == alarmId
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    public func createExecution(_ execution: AlarmExecutionModel) async throws {
        let context = container.mainContext
        context.insert(execution)
        try context.save()
    }
    
    public func updateExecution(_ execution: AlarmExecutionModel) async throws {
        let context = container.mainContext
        try context.save()
    }
    
    public func updateExecutionStatus(id: UUID, status: String) async throws {
        let context = container.mainContext
        let descriptor = FetchDescriptor<AlarmExecutionModel>(
            predicate: #Predicate { execution in
                execution.id == id
            }
        )
        
        if let execution = try context.fetch(descriptor).first {
            execution.status = status
            try context.save()
        }
    }
}

