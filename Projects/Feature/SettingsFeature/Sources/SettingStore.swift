import Rex
import SettingsFeatureInterface
import BaseFeature

public class SettingStore: SettingInterface {
    private let store: Store<SettingReducer>
    private var continuation: AsyncStream<SettingState>.Continuation?

    public var stateStream: AsyncStream<SettingState> {
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

    public init(store: Store<SettingReducer>) {
        self.store = store
    }

    public func send(_ action: SettingAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> SettingState {
        return store.getInitialState()
    }
}
