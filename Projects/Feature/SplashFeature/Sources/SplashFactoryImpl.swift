import SwiftUI
import Rex
import SplashFeatureInterface

public struct SplashFactoryImpl: SplashFactory {
    private let store: Store<SplashReducer>
    
    public init(store: Store<SplashReducer>) {
        self.store = store
    }

    public func makeInterface() -> SplashInterface {
        return SplashStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(SplashView(interface: interface))
    }
}

public extension SplashFactoryImpl {
    static func create() -> SplashFactoryImpl {
        let store = Store<SplashReducer>(
            initialState: SplashState(),
            reducer: SplashReducer()
        )
        return SplashFactoryImpl(store: store)
    }
    
    static func create(initialState: SplashState) -> SplashFactoryImpl {
        let store = Store<SplashReducer>(
            initialState: initialState,
            reducer: SplashReducer()
        )
        return SplashFactoryImpl(store: store)
    }
}
