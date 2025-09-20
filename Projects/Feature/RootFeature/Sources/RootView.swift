import SwiftUI
import Rex
import RootFeatureInterface
import Shared

public struct RootView: View {
    let interface: RootInterface
    @State private var state = RootState()

    public init(
        interface: RootInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        Group {

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

