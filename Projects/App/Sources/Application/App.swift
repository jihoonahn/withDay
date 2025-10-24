import SwiftUI
import SwiftData
import RootFeatureInterface
import Dependency
import SwiftDataCoreInterface

@main
struct WithDayApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    @State private var modelContainer: ModelContainer?
    private let rootFactory: RootFactory

    init() {
        Task { @MainActor in
            await AppDependencies.setup()
        }
        self.rootFactory = DIContainer.shared.resolve(RootFactory.self)
    }

    var body: some Scene {
        WindowGroup {
            rootFactory.makeView()
                .preferredColorScheme(.dark)
                .onAppear {
                    Task { @MainActor in
                        // SwiftData ModelContainer 가져오기
                        if let swiftDataService = try? DIContainer.shared.resolve(SwiftDataService.self) {
                            modelContainer = swiftDataService.container
                        }
                    }
                }
        }
        .modelContainer(for: [
            AlarmModel.self,
            MemoModel.self,
            AlarmExecutionModel.self,
            MotionRawDataModel.self,
            AchievementModel.self
        ])
    }
}
