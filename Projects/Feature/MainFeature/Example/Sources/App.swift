import SwiftUI
import Rex
import MainFeature
import MainFeatureInterface

@main
struct ExampleApp: App {

    var body: some Scene {
        WindowGroup {
            MainView(interface: MainStore(store: Store(initialState: .init(), reducer: .init())))
        }
    }
}
