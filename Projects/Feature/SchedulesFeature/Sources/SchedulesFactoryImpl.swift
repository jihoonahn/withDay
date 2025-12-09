import SwiftUI
import Rex
import SchedulesFeatureInterface

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
    static func create() -> SchedulesFactoryImpl {
        let store = Store<SchedulesReducer>(
            initialState: SchedulesState(),
            reducer: SchedulesReducer()
        )
        return SchedulesFactoryImpl(store: store)
    }
    
    static func create(initialState: SchedulesState) -> SchedulesFactoryImpl {
        let store = Store<SchedulesReducer>(
            initialState: initialState,
            reducer: SchedulesReducer()
        )
        return SchedulesFactoryImpl(store: store)
    }
}
