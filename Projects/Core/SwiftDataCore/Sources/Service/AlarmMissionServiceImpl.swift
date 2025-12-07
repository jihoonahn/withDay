import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class AlarmMissionServiceImpl: AlarmMissionService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchMissions(alarmId: UUID) async throws -> [AlarmMissionModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmMissionModel>(
            predicate: #Predicate { mission in
                mission.alarmId == alarmId
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }
    
    public func saveMission(_ mission: AlarmMissionModel) async throws {
        let context = await container.mainContext
        context.insert(mission)
        try context.save()
    }
    
    public func updateMission(_ mission: AlarmMissionModel) async throws {
        let context = await container.mainContext
        let missionId = mission.id
        let descriptor = FetchDescriptor<AlarmMissionModel>(
            predicate: #Predicate { model in
                model.id == missionId
            }
        )
        
        if let existingModel = try context.fetch(descriptor).first {
            existingModel.alarmId = mission.alarmId
            existingModel.missionType = mission.missionType
            existingModel.difficulty = mission.difficulty
            existingModel.configData = mission.configData
            existingModel.updatedAt = Date()
            try context.save()
        }
    }
    
    public func deleteMission(id: UUID) async throws {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<AlarmMissionModel>(
            predicate: #Predicate { mission in
                mission.id == id
            }
        )
        
        if let mission = try context.fetch(descriptor).first {
            context.delete(mission)
            try context.save()
        }
    }
}

