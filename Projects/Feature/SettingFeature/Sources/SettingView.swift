import SwiftUI
import Rex
import SettingFeatureInterface

public struct SettingView: View {
    let interface: SettingInterface
    @State private var state = SettingState()

    public init(
        interface: SettingInterface
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
