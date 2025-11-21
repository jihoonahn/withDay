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
            await GlobalEventBus.shared.subscribe(AlarmEvent.self) { [weak self] event in
                guard let self = self else { return }
                switch event {
                case let .triggered(id, executionId):
                    self.send(.showMotion(id: id, executionId: executionId))
                case let .stopped(alarmId: id):
                    self.send(.closeMotion(id: id))
                }
            }
        }
    }
}
