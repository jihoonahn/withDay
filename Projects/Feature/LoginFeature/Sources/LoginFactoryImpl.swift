import SwiftUI
import Rex
import LoginFeatureInterface
import UserDomainInterface

public struct LoginFactoryImpl: LoginFactory {
    private let store: Store<LoginReducer>
    
    public init(store: Store<LoginReducer>) {
        self.store = store
    }

    public func makeInterface() -> LoginInterface {
        return LoginStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(LoginView(interface: interface))
    }
}

public extension LoginFactoryImpl {
    static func create(userUseCase: UserUseCase) -> LoginFactoryImpl {
        let store = Store<LoginReducer>(
            initialState: LoginState(),
            reducer: LoginReducer(userUseCase: userUseCase)
        )
        return LoginFactoryImpl(store: store)
    }
    
    static func create(initialState: LoginState, userUseCase: UserUseCase) -> LoginFactoryImpl {
        let store = Store<LoginReducer>(
            initialState: initialState,
            reducer: LoginReducer(userUseCase: userUseCase)
        )
        return LoginFactoryImpl(store: store)
    }
}

