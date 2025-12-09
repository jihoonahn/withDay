import Foundation
import SwiftData
import SwiftDataCoreInterface
import SchedulesDomainInterface

public final class ScheduleServiceImpl: SchedulesService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }

    public func getSchedules(userId: UUID) async throws -> [SchedulesEntity] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<SchedulesModel>(
            sortBy: [
                SortDescriptor(\.userId),
                SortDescriptor(\.date),
                SortDescriptor(\.startTime)
            ]
        )
        let models = try context.fetch(descriptor)
        return models.map { ScheduleDTO.toEntity(from: $0) }
    }

    public func getSchedule(id: UUID) async throws -> SchedulesEntity {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<SchedulesModel>(
            predicate: #Predicate { schedule in
                schedule.id == id
            }
        )
        guard let model = try context.fetch(descriptor).first else {
            throw NSError(domain: "ScheduleService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Schedule not found"])
        }
        return ScheduleDTO.toEntity(from: model)
    }

    public func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        let context = await container.mainContext
        let model = ScheduleDTO.toModel(from: schedule)
        context.insert(model)
        try context.save()
        return schedule
    }

    public func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        let context = await container.mainContext
        let scheduleId = schedule.id
        let descriptor = FetchDescriptor<SchedulesModel>(
            predicate: #Predicate { model in
                model.id == scheduleId
            }
        )
        
        if let existingModel = try context.fetch(descriptor).first {
            let updatedModel = ScheduleDTO.toModel(from: schedule)
            existingModel.userId = updatedModel.userId
            existingModel.title = updatedModel.title
            existingModel.content = updatedModel.content
            existingModel.date = updatedModel.date
            existingModel.startTime = updatedModel.startTime
            existingModel.endTime = updatedModel.endTime
            existingModel.memoIds = updatedModel.memoIds
            existingModel.updatedAt = Date()
            try context.save()
        }
        return schedule
    }
    
    public func deleteSchedule(id: UUID) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<SchedulesModel>(
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
