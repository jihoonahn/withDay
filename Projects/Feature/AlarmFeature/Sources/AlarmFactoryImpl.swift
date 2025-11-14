import SwiftUI
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface
import AlarmScheduleDomainInterface
import UserDomainInterface

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
        alarmUseCase: AlarmUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        userUseCase: UserUseCase
    ) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: AlarmState(),
            reducer: AlarmReducer(
                alarmUseCase: alarmUseCase,
                alarmScheduleUseCase: alarmScheduleUseCase,
                userUseCase: userUseCase
            )
        )
        return AlarmFactoryImpl(store: store)
    }
    
    static func create(
        initialState: AlarmState,
        alarmUseCase: AlarmUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        userUseCase: UserUseCase
    ) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: initialState,
            reducer: AlarmReducer(
                alarmUseCase: alarmUseCase,
                alarmScheduleUseCase: alarmScheduleUseCase,
                userUseCase: userUseCase
            )
        )
        return AlarmFactoryImpl(store: store)
    }
}
