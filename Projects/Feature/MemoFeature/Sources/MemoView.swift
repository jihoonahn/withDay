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
            switch state.flow {
            case .all:
                MemoListView(interface: interface, state: state)
            case .add:
                MemoAddView(interface: interface, state: state)
            case .edit:
                MemoEditView(interface: interface, state: state)
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
        .onAppear {
            interface.send(.loadMemos)
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
