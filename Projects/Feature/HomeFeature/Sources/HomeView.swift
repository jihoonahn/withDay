import SwiftUI
import Rex
import RootFeatureInterface
import HomeFeatureInterface

public struct HomeView: View {
    let interface: HomeInterface
    @State private var state = HomeState()

    public init(
        interface: HomeInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        Text("Home")
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
