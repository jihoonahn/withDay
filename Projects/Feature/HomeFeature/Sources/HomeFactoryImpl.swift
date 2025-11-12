import SwiftUI
import Rex
import HomeFeatureInterface
import MemoDomainInterface
import UserDomainInterface
import AlarmExecutionDomainInterface
import Dependency

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
        let container = DIContainer.shared
        let reducer = HomeReducer(
            memoUseCase: container.resolve(MemoUseCase.self),
            userUseCase: container.resolve(UserUseCase.self),
            alarmExecutionUseCase: container.resolve(AlarmExecutionUseCase.self)
        )
        let store = Store<HomeReducer>(
            initialState: HomeState(),
            reducer: reducer
        )
        return HomeFactoryImpl(store: store)
    }
    
    static func create(initialState: HomeState) -> HomeFactoryImpl {
        let container = DIContainer.shared
        let reducer = HomeReducer(
            memoUseCase: container.resolve(MemoUseCase.self),
            userUseCase: container.resolve(UserUseCase.self),
            alarmExecutionUseCase: container.resolve(AlarmExecutionUseCase.self)
        )
        let store = Store<HomeReducer>(
            initialState: initialState,
            reducer: reducer
        )
        return HomeFactoryImpl(store: store)
    }
}

