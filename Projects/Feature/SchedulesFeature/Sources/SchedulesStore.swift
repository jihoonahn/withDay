import Rex
import SchedulesFeatureInterface
import BaseFeature

public class SchedulesStore: SchedulesInterface {
    private let store: Store<SchedulesReducer>
    private var continuation: AsyncStream<SchedulesState>.Continuation?

    public var stateStream: AsyncStream<SchedulesState> {
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

    public init(store: Store<SchedulesReducer>) {
        self.store = store
    }

    public func send(_ action: SchedulesAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> SchedulesState {
        return store.getInitialState()
    }
}
