import SwiftUI
import Rex
import WeatherFeatureInterface

public struct WeatherView: View {
    let interface: WeatherInterface
    @State private var state = WeatherState()

    public init(
        interface: WeatherInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        Group {
            Text("Setting")
        }
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
