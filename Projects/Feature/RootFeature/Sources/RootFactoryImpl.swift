import SwiftUI
import Rex
import RootFeatureInterface

public struct RootFactoryImpl: RootFactory {
    private let store: Store<RootReducer>
    
    public init(store: Store<RootReducer>) {
        self.store = store
    }

    public func makeInterface() -> RootInterface {
        return RootStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(RootView(interface: interface))
    }
}

public extension RootFactoryImpl {
    static func create() -> RootFactoryImpl {
        let store = Store<RootReducer>(
            initialState: RootState(),
            reducer: RootReducer()
        )
        return RootFactoryImpl(store: store)
    }
    
    static func create(initialState: RootState) -> RootFactoryImpl {
        let store = Store<RootReducer>(
            initialState: initialState,
            reducer: RootReducer()
        )
        return RootFactoryImpl(store: store)
    }
}
