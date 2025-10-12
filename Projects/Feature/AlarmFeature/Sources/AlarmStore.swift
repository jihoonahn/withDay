import Rex
import AlarmFeatureInterface
import BaseFeature

public class AlarmStore: AlarmInterface {
    private let store: Store<AlarmReducer>
    private var continuation: AsyncStream<AlarmState>.Continuation?

    public var stateStream: AsyncStream<AlarmState> {
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

    public init(store: Store<AlarmReducer>) {
        self.store = store
    }

    public func send(_ action: AlarmAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> AlarmState {
        return store.getInitialState()
    }
}
