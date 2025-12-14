import SwiftUI
import Rex
import AlarmsFeatureInterface
import AlarmsDomainInterface
import AlarmSchedulesDomainInterface
import UsersDomainInterface
import MemosDomainInterface

public struct AlarmFactoryImpl: AlarmFactory {
    private let store: Store<AlarmReducer>
    
    public init(store: Store<AlarmReducer>) {
        self.store = store
    }

    public func makeInterface() -> AlarmInterface {
        let store = AlarmStore(store: store)
        return store
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(AlarmView(interface: interface))
    }
}

public extension AlarmFactoryImpl {
    static func create(
        alarmsUseCase: AlarmsUseCase,
        alarmSchedulesUseCase: AlarmSchedulesUseCase,
        usersUseCase: UsersUseCase,
        memosUseCase: MemosUseCase
    ) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: AlarmState(),
            reducer: AlarmReducer(
                alarmsUseCase: alarmsUseCase,
                alarmSchedulesUseCase: alarmSchedulesUseCase,
                usersUseCase: usersUseCase,
                memosUseCase: memosUseCase
            )
        )
        return AlarmFactoryImpl(store: store)
    }
    
    static func create(
        initialState: AlarmState,
        alarmsUseCase: AlarmsUseCase,
        alarmSchedulesUseCase: AlarmSchedulesUseCase,
        usersUseCase: UsersUseCase,
        memosUseCase: MemosUseCase
    ) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: initialState,
            reducer: AlarmReducer(
                alarmsUseCase: alarmsUseCase,
                alarmSchedulesUseCase: alarmSchedulesUseCase,
                usersUseCase: usersUseCase,
                memosUseCase: memosUseCase
            )
        )
        return AlarmFactoryImpl(store: store)
    }
}
