import SwiftUI
import Rex

public protocol WeatherFactory {
    func makeInterface() -> WeatherInterface
    func makeView() -> AnyView
}
