import SwiftUI
import Rex
import AlarmFeature
import AlarmFeatureInterface

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            AlarmView(interface: AlarmStore(store: Store(initialState: .init(), reducer: .init())))
        }
    }
}
