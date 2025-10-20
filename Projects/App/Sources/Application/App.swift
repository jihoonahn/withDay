import SwiftUI
import SwiftData
import RootFeatureInterface
import Dependency
import AlarmDomainInterface

@main
struct WithDayApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    let modelContainer: ModelContainer
    private let rootFactory: RootFactory

    init() {
        // SwiftData ModelContainer 설정
        do {
            modelContainer = try ModelContainer(for: LocalAlarmEntity.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // DI 설정 (ModelContext 전달)
        AppDependencies.setup(modelContext: modelContainer.mainContext)
        self.rootFactory = DIContainer.shared.resolve(RootFactory.self)
    }

    var body: some Scene {
        WindowGroup {
            rootFactory.makeView()
                .preferredColorScheme(.dark)
                .modelContainer(modelContainer)
        }
    }
}
