import SwiftUI
import Rex
import WeatherFeature
import WeatherFeatureInterface

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            WeatherView(interface: WeatherStore(store: Store(initialState: .init(), reducer: .init())))
        }
    }
}
