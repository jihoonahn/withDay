import SwiftUI
import Rex
import AlarmFeatureInterface

public struct AlarmFactoryImpl: AlarmFactory {
    private let store: Store<AlarmReducer>
    
    public init(store: Store<AlarmReducer>) {
        self.store = store
    }

    public func makeInterface() -> AlarmInterface {
        return AlarmStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(AlarmView(interface: interface))
    }
}

public extension AlarmFactoryImpl {
    static func create() -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: AlarmState(),
            reducer: AlarmReducer()
        )
        return AlarmFactoryImpl(store: store)
    }
    
    static func create(initialState: AlarmState) -> AlarmFactoryImpl {
        let store = Store<AlarmReducer>(
            initialState: initialState,
            reducer: AlarmReducer()
        )
        return AlarmFactoryImpl(store: store)
    }
}
