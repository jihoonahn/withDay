import SwiftUI
import Rex
import SettingFeature
import SettingFeatureInterface

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            SettingView(interface: SettingStore(store: Store(initialState: .init(), reducer: .init())))
        }
    }
}
