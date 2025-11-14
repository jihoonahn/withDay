import Rex
import MainFeatureInterface
import BaseFeature

public class MainStore: MainInterface {
    private let store: Store<MainReducer>
    private var continuation: AsyncStream<MainState>.Continuation?

    public var stateStream: AsyncStream<MainState> {
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

    public init(store: Store<MainReducer>) {
        self.store = store
        setupEventBusObserver()
    }

    public func send(_ action: MainAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> MainState {
        return store.getInitialState()
    }
    
    private func setupEventBusObserver() {
        Task {
            await GlobalEventBus.shared.subscribe { event in
                guard let alarmEvent = event as? AlarmEvent else {
                    return
                }
                switch alarmEvent {
                case let .triggered(alarmId: id):
                    self.send(.showMotion(id: id))
                case let .stopped(alarmId: id):
                    self.send(.closeMotion(id: id))
                }
            }
        }
    }
}
