import SwiftUI
import SwiftData
import RootFeatureInterface
import Dependency
import AlarmDomainInterface

@main
struct WithDayApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
//    let modelContainer: ModelContainer
    private let rootFactory: RootFactory

    init() {
        AppDependencies.setup()
        self.rootFactory = DIContainer.shared.resolve(RootFactory.self)
    }

    var body: some Scene {
        WindowGroup {
            rootFactory.makeView()
                .preferredColorScheme(.dark)
        }
    }
}
