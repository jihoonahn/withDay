import SwiftUI
import Rex
import WeatherFeatureInterface

public struct WeatherFactoryImpl: WeatherFactory {
    private let store: Store<WeatherReducer>
    
    public init(store: Store<WeatherReducer>) {
        self.store = store
    }

    public func makeInterface() -> WeatherInterface {
        return WeatherStore(store: store)
    }
    
    public func makeView() -> AnyView {
        let interface = makeInterface()
        return AnyView(WeatherView(interface: interface))
    }
}

public extension WeatherFactoryImpl {
    static func create() -> WeatherFactoryImpl {
        let store = Store<WeatherReducer>(
            initialState: WeatherState(),
            reducer: WeatherReducer()
        )
        return WeatherFactoryImpl(store: store)
    }
    
    static func create(initialState: WeatherState) -> WeatherFactoryImpl {
        let store = Store<WeatherReducer>(
            initialState: initialState,
            reducer: WeatherReducer()
        )
        return WeatherFactoryImpl(store: store)
    }
}
