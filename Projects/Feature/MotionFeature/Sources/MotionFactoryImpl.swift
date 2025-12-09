import SwiftUI
import Rex
import MotionFeatureInterface
import MotionDomainInterface
import MotionCoreInterface
import UsersDomainInterface
import AlarmsDomainInterface
import AlarmExecutionsDomainInterface
import Dependency

public struct MotionFactoryImpl: MotionFactory {
    private let store: Store<MotionReducer>
    
    public init(store: Store<MotionReducer>) {
        self.store = store
    }

    public func makeInterface() -> MotionInterface {
        return MotionStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(MotionView(interface: interface))
    }
}

public extension MotionFactoryImpl {
    static func create(
        usersUseCase: UsersUseCase,
        motionUseCase: MotionUseCase,
        alarmSchedulesUseCase: AlarmSchedulesUseCase,
        alarmExecutionsUseCase: AlarmExecutionsUseCase
    ) -> MotionFactoryImpl {
        let store = Store<MotionReducer>(
            initialState: MotionState(),
            reducer: MotionReducer(
                usersUseCase: usersUseCase,
                alarmSchedulesUseCase: alarmSchedulesUseCase,
                alarmExecutionsUseCase: alarmExecutionsUseCase,
                motionUseCase: motionUseCase
            )
        )
        return MotionFactoryImpl(store: store)
    }
    
    static func create(
        initialState: MotionState,
        usersUseCase: UsersUseCase,
        motionUseCase: MotionUseCase,
        alarmSchedulesUseCase: AlarmSchedulesUseCase,
        alarmExecutionsUseCase: AlarmExecutionsUseCase
    ) -> MotionFactoryImpl {
        let store = Store<MotionReducer>(
            initialState: initialState,
            reducer: MotionReducer(
                usersUseCase: usersUseCase,
                alarmSchedulesUseCase: alarmSchedulesUseCase,
                alarmExecutionsUseCase: alarmExecutionsUseCase,
                motionUseCase: motionUseCase
            )
        )
        return MotionFactoryImpl(store: store)
    }
}
