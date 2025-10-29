import SwiftUI
import Rex
import RootFeatureInterface
import UserDomainInterface

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
    static func create(userUseCase: UserUseCase) -> RootFactoryImpl {
        let store = Store<RootReducer>(
            initialState: RootState(),
            reducer: RootReducer(userUseCase: userUseCase)
        )
        return RootFactoryImpl(store: store)
    }
    
    static func create(initialState: RootState, userUseCase: UserUseCase) -> RootFactoryImpl {
        let store = Store<RootReducer>(
            initialState: initialState,
            reducer: RootReducer(userUseCase: userUseCase)
        )
        return RootFactoryImpl(store: store)
    }
}
