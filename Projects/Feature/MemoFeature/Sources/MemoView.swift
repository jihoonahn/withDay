import Foundation
import SwiftUI
import Rex
import MemoFeatureInterface
import Designsystem
import Localization
import MemoDomainInterface

public struct MemoView: View {
    let interface: MemoInterface
    @State private var state = MemoState()

    public init(
        interface: MemoInterface
    ) {
        self.interface = interface
    }

    public var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if state.sheetAction {
                    MemoFormView(interface: interface, state: state)
                } else if state.memoDetailPresented {
                    MemoCalendarView(interface: interface, state: state)
                }
            }
        }
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
        .toast(
            isPresented: Binding(
                get: { state.memoToastIsPresented },
                set: { interface.send(.memoToastStatus($0)) }
            )
        ) {
            Toast(title: state.memoToastMessage)
        }
    }
}
