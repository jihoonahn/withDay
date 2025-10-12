import Rex
import WeatherFeatureInterface

public struct WeatherReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout WeatherState, action: WeatherAction) -> [Effect<WeatherAction>] {
        switch action {
        default:
            return []
        }
    }
}
