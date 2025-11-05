import SwiftUI
import SwiftData
import RootFeatureInterface
import Dependency
import SwiftDataCoreInterface
import ActivityKit
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
                        await checkLiveActivities()
                    }
                }
        }
    }
    
    @MainActor
    private func checkLiveActivities() async {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("⚠️ [App] ActivityKit is not enabled. Please enable Live Activities in Settings.")
            return
        }
        
        // 활성 Live Activity 확인
        let activities = Activity<AlarmAttributes>.activities
        print("📱 [App] Found \(activities.count) active Live Activities")
        
        for activity in activities {
            print("   - Alarm ID: \(activity.attributes.alarmId)")
            print("   - Scheduled Time: \(activity.attributes.scheduledTime)")
            print("   - Is Alerting: \(activity.content.state.isAlerting)")
            print("   - Motion Count: \(activity.content.state.motionCount)/\(activity.content.state.requiredMotionCount)")
        }
    }
}
