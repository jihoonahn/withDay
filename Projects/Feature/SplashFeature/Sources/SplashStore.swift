import Rex
import SplashFeatureInterface
import BaseFeature

public class SplashStore: SplashInterface {
    private let store: Store<SplashReducer>
    private var continuation: AsyncStream<SplashState>.Continuation?

    public var stateStream: AsyncStream<SplashState> {
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

    public init(store: Store<SplashReducer>) {
        self.store = store
    }

    public func send(_ action: SplashAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> SplashState {
        return store.getInitialState()
    }
}
