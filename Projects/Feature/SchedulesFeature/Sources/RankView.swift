import SwiftUI
import Rex
import RankFeatureInterface
import Designsystem

public struct RankView: View {
    let interface: RankInterface
    @State private var state = RankState()

    public init(
        interface: RankInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
        .onAppear {
            interface.send(.loadRank)
        }
    }
}
