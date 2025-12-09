import SwiftUI
import Rex
import MemosFeatureInterface
import MemosDomainInterface
import Designsystem
import Utility

struct MemoListView: View {
    let interface: MemoInterface
    @State var state: MemoState

    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
            }
        }
        .navigationTitle("Memos")
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}
