import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class AlarmServiceImpl: AlarmService {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchAlarms(userId: UUID) async throws -> [AlarmModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmModel>(
            predicate: #Predicate { alarm in
                alarm.userId == userId
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    public func saveAlarm(_ alarm: AlarmModel) async throws {
        let context = await container.mainContext
        context.insert(alarm)
        try context.save()
    }

    public func updateAlarm(_ alarm: AlarmModel) async throws {
        let context = await container.mainContext
        let alarmId = alarm.id
        let descriptor = FetchDescriptor<AlarmModel>(
            predicate: #Predicate { model in
                model.id == alarmId
            }
        )
        
        if let existingModel = try context.fetch(descriptor).first {
            existingModel.userId = alarm.userId
            existingModel.label = alarm.label
            existingModel.time = alarm.time
            existingModel.repeatDays = alarm.repeatDays
            existingModel.snoozeEnabled = alarm.snoozeEnabled
            existingModel.snoozeInterval = alarm.snoozeInterval
            existingModel.snoozeLimit = alarm.snoozeLimit
            existingModel.soundName = alarm.soundName
            existingModel.soundURL = alarm.soundURL
            existingModel.vibrationPattern = alarm.vibrationPattern
            existingModel.volumeOverride = alarm.volumeOverride
            existingModel.linkedMemoIds = alarm.linkedMemoIds
            existingModel.showMemosOnAlarm = alarm.showMemosOnAlarm
            existingModel.isEnabled = alarm.isEnabled
            existingModel.updatedAt = Date()
            try context.save()
        }
    }

    public func deleteAlarm(id: UUID) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmModel>(
            predicate: #Predicate { alarm in
                alarm.id == id
            }
        )
        
        if let alarm = try context.fetch(descriptor).first {
            context.delete(alarm)
            try context.save()
        }
    }

    public func toggleAlarm(id: UUID, isEnabled: Bool) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmModel>(
            predicate: #Predicate { alarm in
                alarm.id == id
            }
        )
        
        if let alarm = try context.fetch(descriptor).first {
            alarm.isEnabled = isEnabled
            alarm.updatedAt = Date()
            try context.save()
        }
    }
}
