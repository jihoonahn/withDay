import SwiftUI
import Rex
import MotionFeatureInterface
import UserDomainInterface
import MotionRawDataDomainInterface
import MotionDomainInterface
import AlarmScheduleDomainInterface
import MotionCoreInterface
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
        userUseCase: UserUseCase,
        motionUseCase: MotionUseCase,
        motionRawDataUseCase: MotionRawDataUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        motionService: MotionCoreInterface.MotionService
    ) -> MotionFactoryImpl {
        let store = Store<MotionReducer>(
            initialState: MotionState(),
            reducer: MotionReducer(
                userUseCase: userUseCase,
                motionUseCase: motionUseCase,
                motionRawDataUseCase: motionRawDataUseCase,
                alarmScheduleUseCase: alarmScheduleUseCase,
                motionService: motionService
            )
        )
        return MotionFactoryImpl(store: store)
    }
    
    static func create(
        initialState: MotionState,
        userUseCase: UserUseCase,
        motionUseCase: MotionUseCase,
        motionRawDataUseCase: MotionRawDataUseCase,
        alarmScheduleUseCase: AlarmScheduleUseCase,
        motionService: MotionCoreInterface.MotionService
    ) -> MotionFactoryImpl {
        let store = Store<MotionReducer>(
            initialState: initialState,
            reducer: MotionReducer(
                userUseCase: userUseCase,
                motionUseCase: motionUseCase,
                motionRawDataUseCase: motionRawDataUseCase,
                alarmScheduleUseCase: alarmScheduleUseCase,
                motionService: motionService
            )
        )
        return MotionFactoryImpl(store: store)
    }
}
