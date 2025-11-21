import SwiftUI
import Rex
import MemoFeatureInterface
import Designsystem

struct MemoAddView: View {
    let interface: MemoInterface
    @State var state: MemoState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
        }
    }
}
