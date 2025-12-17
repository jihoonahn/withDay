import SwiftUI
import Rex
import SchedulesFeatureInterface
import SchedulesDomainInterface
import UsersDomainInterface
import MemosDomainInterface
import Dependency

public struct SchedulesFactoryImpl: SchedulesFactory {
    private let store: Store<SchedulesReducer>
    
    public init(store: Store<SchedulesReducer>) {
        self.store = store
    }

    public func makeInterface() -> SchedulesInterface {
        return SchedulesStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(SchedulesView(interface: interface))
    }
}

public extension SchedulesFactoryImpl {
    static func create(
        schedulesUseCase: SchedulesUseCase,
        usersUseCase: UsersUseCase,
        memosUseCase: MemosUseCase
    ) -> SchedulesFactoryImpl {
        let reducer = SchedulesReducer(
            schedulesUseCase: schedulesUseCase,
            usersUseCase: usersUseCase,
            memosUseCase: memosUseCase
        )
        let store = Store<SchedulesReducer>(
            initialState: SchedulesState(),
            reducer: reducer
        )
        return SchedulesFactoryImpl(store: store)
    }
    
    static func create(
        initialState: SchedulesState,
        schedulesUseCase: SchedulesUseCase,
        usersUseCase: UsersUseCase,
        memosUseCase: MemosUseCase
    ) -> SchedulesFactoryImpl {
        let reducer = SchedulesReducer(
            schedulesUseCase: schedulesUseCase,
            usersUseCase: usersUseCase,
            memosUseCase: memosUseCase
        )
        let store = Store<SchedulesReducer>(
            initialState: initialState,
            reducer: reducer
        )
        return SchedulesFactoryImpl(store: store)
    }
}
