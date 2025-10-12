import SwiftUI
import RootFeatureInterface
import Dependency

@main
struct WithDayApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

    private let rootFactory: RootFactory

    init() {
        AppDependencies.setup()
        self.rootFactory = DIContainer.shared.resolve(RootFactory.self)
    }

    var body: some Scene {
        WindowGroup {
            rootFactory.makeView()
        }
    }
}
