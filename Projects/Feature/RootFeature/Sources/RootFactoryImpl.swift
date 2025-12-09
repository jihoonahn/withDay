import SwiftUI
import Rex
import RootFeatureInterface
import UsersDomainInterface

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
    static func create(usersUseCase: UsersUseCase) -> RootFactoryImpl {
        let store = Store<RootReducer>(
            initialState: RootState(),
            reducer: RootReducer(usersUseCase: usersUseCase)
        )
        return RootFactoryImpl(store: store)
    }
    
    static func create(initialState: RootState, usersUseCase: UsersUseCase) -> RootFactoryImpl {
        let store = Store<RootReducer>(
            initialState: initialState,
            reducer: RootReducer(usersUseCase: usersUseCase)
        )
        return RootFactoryImpl(store: store)
    }
}
