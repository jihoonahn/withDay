import SwiftUI
import Rex
import SettingFeatureInterface

public struct SettingFactoryImpl: SettingFactory {
    private let store: Store<SettingReducer>
    
    public init(store: Store<SettingReducer>) {
        self.store = store
    }

    public func makeInterface() -> SettingInterface {
        return SettingStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(SettingView(interface: interface))
    }
}

public extension SettingFactoryImpl {
    static func create() -> SettingFactoryImpl {
        let store = Store<SettingReducer>(
            initialState: SettingState(),
            reducer: SettingReducer()
        )
        return SettingFactoryImpl(store: store)
    }
    
    static func create(initialState: SettingState) -> SettingFactoryImpl {
        let store = Store<SettingReducer>(
            initialState: initialState,
            reducer: SettingReducer()
        )
        return SettingFactoryImpl(store: store)
    }
}
