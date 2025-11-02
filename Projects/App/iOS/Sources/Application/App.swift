import SwiftUI
import SwiftData
import RootFeatureInterface
import Dependency
import SwiftDataCoreInterface
import ActivityKit
import AlarmKit
import AlarmCore

@main
struct WithDayApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    @State private var modelContainer: ModelContainer?
    private let rootFactory: RootFactory

    init() {
        AppDependencies.setup()
        self.rootFactory = DIContainer.shared.resolve(RootFactory.self)
    }

    var body: some Scene {
        WindowGroup {
            rootFactory.makeView()
                .preferredColorScheme(.dark)
                .modelContainer(for: [
                    AlarmModel.self,
                    MemoModel.self,
                    AlarmExecutionModel.self,
                    MotionRawDataModel.self,
                    AchievementModel.self
                ])
                .onAppear {
                    Task { @MainActor in
                        await checkAndStartLiveActivities()
                    }
                }
        }
    }
    
    @MainActor
    private func checkAndStartLiveActivities() async {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("⚠️ [App] ActivityKit is not enabled. Please enable Live Activities in Settings.")
            return
        }
        
        do {
            let alarmManager = AlarmManager.shared
            let alarms = try alarmManager.alarms
            
            print("📱 [App] Found \(alarms.count) scheduled alarms")
            
            for alarm in alarms {
                let activities = Activity<AlarmAttributes<AlarmData>>.activities
                let hasActivity = activities.contains { activity in
                    guard let metadata = activity.attributes.metadata else { return false }
                    return metadata.alarmId == alarm.id
                }
                
                if !hasActivity {
                    print("⚠️ [App] Live Activity not found for alarm: \(alarm.id)")
                    print("   - Alarm state: \(alarm.state)")
                    print("   - This is expected - AlarmKit starts Live Activity when alarm becomes active")
                } else {
                    print("✅ [App] Live Activity exists for alarm: \(alarm.id)")
                }
            }
        } catch {
            print("❌ [App] Failed to check alarms: \(error)")
        }
    }
}
