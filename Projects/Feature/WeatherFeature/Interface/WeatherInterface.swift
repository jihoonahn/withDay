import Foundation
import Rex

public protocol WeatherInterface {
    var stateStream: AsyncStream<WeatherState> { get }
    func send(_ action: WeatherAction)
    func getCurrentState() -> WeatherState
}
