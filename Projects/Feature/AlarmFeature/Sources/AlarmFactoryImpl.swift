import SwiftUI
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface

public struct AlarmFactoryImpl: AlarmFactory {
    private let store: Store<AlarmReducer>
    private let alarmUseCase: AlarmUseCase
    
    public init(store: Store<AlarmReducer>, useCase: AlarmUseCase) {
        self.store = store
        self.alarmUseCase = useCase
    }

    public func makeInterface() -> AlarmInterface {
        return AlarmStore(store: store, useCase: alarmUseCase)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(AlarmView(interface: interface))
    }
}

public extension AlarmFactoryImpl {
    static func create(useCase: AlarmUseCase) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: AlarmState(),
            reducer: AlarmReducer(alarmUseCase: useCase)
        )
        return AlarmFactoryImpl(store: store, useCase: useCase)
    }
    
    static func create(initialState: AlarmState, useCase: AlarmUseCase) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: initialState,
            reducer: AlarmReducer(alarmUseCase: useCase)
        )
        return AlarmFactoryImpl(store: store, useCase: useCase)
    }
}
