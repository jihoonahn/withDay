import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class ScheduleServiceImpl: ScheduleService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchSchedules(userId: UUID) async throws -> [ScheduleModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<ScheduleModel>(
            predicate: #Predicate { schedule in
                schedule.userId == userId
            },
            sortBy: [
                SortDescriptor(\.date),
                SortDescriptor(\.startTime)
            ]
        )
        return try context.fetch(descriptor)
    }
    
    public func fetchAllSchedules() async throws -> [ScheduleModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<ScheduleModel>(
            sortBy: [
                SortDescriptor(\.date),
                SortDescriptor(\.startTime)
            ]
        )
        return try context.fetch(descriptor)
    }
    
    public func fetchSchedule(id: UUID) async throws -> ScheduleModel? {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<ScheduleModel>(
            predicate: #Predicate { schedule in
                schedule.id == id
            }
        )
        return try context.fetch(descriptor).first
    }
    
    public func saveSchedule(_ schedule: ScheduleModel) async throws {
        let context = await container.mainContext
        context.insert(schedule)
        try context.save()
    }
    
    public func updateSchedule(_ schedule: ScheduleModel) async throws {
        let context = await container.mainContext
        let scheduleId = schedule.id
        let descriptor = FetchDescriptor<ScheduleModel>(
            predicate: #Predicate { model in
                model.id == scheduleId
            }
        )
        
        if let existingModel = try context.fetch(descriptor).first {
            existingModel.userId = schedule.userId
            existingModel.title = schedule.title
            existingModel.description = schedule.description
            existingModel.date = schedule.date
            existingModel.startTime = schedule.startTime
            existingModel.endTime = schedule.endTime
            existingModel.memoIds = schedule.memoIds
            existingModel.updatedAt = Date()
            try context.save()
        }
    }
    
    public func deleteSchedule(id: UUID) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<ScheduleModel>(
            predicate: #Predicate { schedule in
                schedule.id == id
            }
        )
        
        if let schedule = try context.fetch(descriptor).first {
            context.delete(schedule)
            try context.save()
        }
    }
}

