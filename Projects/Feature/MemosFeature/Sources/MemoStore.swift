import Rex
import MemosFeatureInterface
import BaseFeature

public class MemoStore: MemoInterface {
    private let store: Store<MemoReducer>
    private var continuation: AsyncStream<MemoState>.Continuation?

    public var stateStream: AsyncStream<MemoState> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(store.getInitialState())

            store.subscribe { newState in
                Task { @MainActor in
                    continuation.yield(newState)
                }
            }
        }
    }

    public init(store: Store<MemoReducer>) {
        self.store = store
        setupEventBusObserver()
    }

    public func send(_ action: MemoAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> MemoState {
        return store.getInitialState()
    }

    private func setupEventBusObserver() {
        Task {
            await GlobalEventBus.shared.subscribe(MemoEvent.self) { event in
                switch event {
                case .allMemo:
                    self.send(.setMemoFlow(.all))
                case .addMemo:
                    self.send(.setMemoFlow(.add))
                case .editMemo:
                    self.send(.setMemoFlow(.edit))
                }
            }
        }
    }
}
