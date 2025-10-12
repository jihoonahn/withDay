import Rex
import RootFeatureInterface
import BaseFeature

public class RootStore: RootInterface {
    private let store: Store<RootReducer>
    private var continuation: AsyncStream<RootState>.Continuation?

    public var stateStream: AsyncStream<RootState> {
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

    public init(store: Store<RootReducer>) {
        self.store = store
        setupEventBusObserver()
    }

    public func send(_ action: RootAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> RootState {
        return store.getInitialState()
    }
    
    private func setupEventBusObserver() {
        Task {
            await GlobalEventBus.shared.subscribe { event in
                guard let rootEvent = event as? RootEvent else { return }
                switch rootEvent {
                case .loginSuccess:
                    self.send(.switchToMain)
                case .logout:
                    self.send(.switchToLogin)
                }
            }
        }
    }
}
