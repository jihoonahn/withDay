import SwiftUI
import Rex
import HomeFeature
import HomeFeatureInterface

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(interface: HomeStore(store: Store(initialState: .init(), reducer: .init())))
        }
    }
}
