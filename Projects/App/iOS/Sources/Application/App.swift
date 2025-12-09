import SwiftUI
import SwiftData
import RootFeatureInterface
import Dependency
import SwiftDataCoreInterface
import ActivityKit

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
                    AlarmsModel.self,
                    MemosModel.self,
                    AlarmExecutionsModel.self,
                    SchedulesModel.self,
                    AlarmMissionsModel.self,
                    UserSettingsModel.self
                ])
        }
    }
}
