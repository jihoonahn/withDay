import SwiftUI
import Rex
import HomeFeatureInterface
import MemoFeatureInterface
import MemoDomainInterface
import UserDomainInterface
import AlarmExecutionDomainInterface
import Dependency

public struct HomeFactoryImpl: HomeFactory {
    private let store: Store<HomeReducer>
    private let memoFactory: MemoFactory
    
    public init(store: Store<HomeReducer>, memoFactory: MemoFactory) {
        self.store = store
        self.memoFactory = memoFactory
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
        let memoFactory = container.resolve(MemoFactory.self)
        return HomeFactoryImpl(store: store, memoFactory: memoFactory)
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
        let memoFactory = container.resolve(MemoFactory.self)
        return HomeFactoryImpl(store: store, memoFactory: memoFactory)
    }
}

