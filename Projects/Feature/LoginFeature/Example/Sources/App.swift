import SwiftUI
import Rex
import LoginFeature
import LoginFeatureInterface

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            LoginView(interface: LoginStore(store: Store(initialState: .init(), reducer: .init())))
        }
    }
}
