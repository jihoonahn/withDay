import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class SwiftDataServiceImpl: SwiftDataService {
    public let container: ModelContainer
    
    public init() {
        let schema = Schema([
            AlarmModel.self,
            MemoModel.self,
            AlarmExecutionModel.self,
            ScheduleModel.self,
            AlarmMissionModel.self,
            UserSettingsModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    public init(isStoredInMemoryOnly: Bool) {
        let schema = Schema([
            AlarmModel.self,
            MemoModel.self,
            AlarmExecutionModel.self,
            ScheduleModel.self,
            AlarmMissionModel.self,
            UserSettingsModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

