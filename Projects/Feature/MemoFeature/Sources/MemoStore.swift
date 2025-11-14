import Rex
import MemoFeatureInterface

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
    }

    public func send(_ action: MemoAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> MemoState {
        return store.getInitialState()
    }
}
