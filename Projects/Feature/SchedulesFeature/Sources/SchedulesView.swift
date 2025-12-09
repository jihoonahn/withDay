import SwiftUI
import Rex
import SchedulesFeatureInterface
import Designsystem

public struct SchedulesView: View {
    let interface: SchedulesInterface
    @State private var state = SchedulesState()

    public init(
        interface: SchedulesInterface
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
