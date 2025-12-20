import Rex
import HomeFeatureInterface
import BaseFeature

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
        setupEventBusObserver()
    }

    public func send(_ action: HomeAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> HomeState {
        return store.getInitialState()
    }
    
    // MARK: - Event Bus Observer
    private func setupEventBusObserver() {
        Task {
            await GlobalEventBus.shared.subscribe(AlarmDataEvent.self) { [weak self] event in
                self?.send(.loadHomeData)
            }
            await GlobalEventBus.shared.subscribe(ScheduleDataEvent.self) { [weak self] event in
                self?.send(.loadHomeData)
            }
        }
    }
}
