import Rex
import LoginFeatureInterface
import BaseFeature

public class LoginStore: LoginInterface {
    private let store: Store<LoginReducer>
    private var continuation: AsyncStream<LoginState>.Continuation?

    public var stateStream: AsyncStream<LoginState> {
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

    public init(store: Store<LoginReducer>) {
        self.store = store
        setupEventBusPublisher()
    }

    public func send(_ action: LoginAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> LoginState {
        return store.getInitialState()
    }
}

// MARK: - Login Store Extensions Feature
extension LoginStore {
    func setupEventBusPublisher() {
        store.subscribe { state in
            Task {
                if state.loginStatus {
                    await GlobalEventBus.shared.publish(RootEvent.loginSuccess)
                }
            }
        }
    }
}
