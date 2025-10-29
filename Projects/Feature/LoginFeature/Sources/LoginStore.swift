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
        setupLogoutObserver()
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
                if state.isLoggedIn {
                    await GlobalEventBus.shared.publish(RootEvent.loginSuccess)
                }
            }
        }
    }
    
    func setupLogoutObserver() {
        Task {
            await GlobalEventBus.shared.subscribe { event in
                guard let rootEvent = event as? RootEvent else { return }
                if case .logout = rootEvent {
                    self.send(.loginFailure)
                }
            }
        }
    }
}
