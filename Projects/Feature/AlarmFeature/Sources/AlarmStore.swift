import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import BaseFeature

public class AlarmStore: AlarmInterface {
    private let store: Store<AlarmReducer>
    private let remoteRepository: AlarmRepository
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

    public init(store: Store<AlarmReducer>, remoteRepository: AlarmRepository) {
        self.store = store
        self.remoteRepository = remoteRepository
    }

    public func send(_ action: AlarmAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> AlarmState {
        return store.getInitialState()
    }
}
