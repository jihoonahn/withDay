import SwiftUI
import Rex
import HomeFeatureInterface

public struct HomeFactoryImpl: HomeFactory {
    private let store: Store<HomeReducer>
    
    public init(store: Store<HomeReducer>) {
        self.store = store
    }

    public func makeInterface() -> HomeInterface {
        return HomeStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(HomeView(interface: interface))
    }
}

public extension HomeFactoryImpl {
    static func create() -> HomeFactoryImpl {
        let store = Store<HomeReducer>(
            initialState: HomeState(),
            reducer: HomeReducer()
        )
        return HomeFactoryImpl(store: store)
    }
    
    static func create(initialState: HomeState) -> HomeFactoryImpl {
        let store = Store<HomeReducer>(
            initialState: initialState,
            reducer: HomeReducer()
        )
        return HomeFactoryImpl(store: store)
    }
}

