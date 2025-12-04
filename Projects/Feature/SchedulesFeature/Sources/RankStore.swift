import Rex
import RankFeatureInterface
import BaseFeature

public class RankStore: RankInterface {
    private let store: Store<RankReducer>
    private var continuation: AsyncStream<RankState>.Continuation?

    public var stateStream: AsyncStream<RankState> {
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

    public init(store: Store<RankReducer>) {
        self.store = store
    }

    public func send(_ action: RankAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> RankState {
        return store.getInitialState()
    }
}
