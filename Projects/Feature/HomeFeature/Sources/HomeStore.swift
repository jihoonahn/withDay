import Rex
import HomeFeatureInterface

public class HomeStore: HomeInterface {
    private let store: Store<HomeReducer>
    private var continuation: AsyncStream<HomeState>.Continuation?

    public var stateStream: AsyncStream<HomeState> {
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

    public init(store: Store<HomeReducer>) {
        self.store = store
    }

    public func send(_ action: HomeAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> HomeState {
        return store.getInitialState()
    }
}
