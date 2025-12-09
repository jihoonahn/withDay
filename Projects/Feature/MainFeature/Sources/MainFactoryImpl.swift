import SwiftUI
import Rex
import MainFeatureInterface

public struct MainFactoryImpl: MainFactory {
    private let store: Store<MainReducer>
    
    public init(store: Store<MainReducer>) {
        self.store = store
    }

    public func makeInterface() -> MainInterface {
        return MainStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(MainView(interface: interface))
    }
}

public extension MainFactoryImpl {
    static func create() -> MainFactoryImpl {
        let store = Store<MainReducer>(
            initialState: MainState(),
            reducer: MainReducer()
        )
        return MainFactoryImpl(store: store)
    }
    
    static func create(initialState: MainState) -> MainFactoryImpl {
        let store = Store<MainReducer>(
            initialState: initialState,
            reducer: MainReducer()
        )
        return MainFactoryImpl(store: store)
    }
}
