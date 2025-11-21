import SwiftUI
import Rex
import MemoFeatureInterface
import Designsystem

struct MemoListView: View {
    let interface: MemoInterface
    @State var state: MemoState

    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
            }
        }
    }
}
