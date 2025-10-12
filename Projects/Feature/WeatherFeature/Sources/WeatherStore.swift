import Rex
import WeatherFeatureInterface
import BaseFeature

public class WeatherStore: WeatherInterface {
    private let store: Store<WeatherReducer>
    private var continuation: AsyncStream<WeatherState>.Continuation?

    public var stateStream: AsyncStream<WeatherState> {
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

    public init(store: Store<WeatherReducer>) {
        self.store = store
    }

    public func send(_ action: WeatherAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> WeatherState {
        return store.getInitialState()
    }
}
