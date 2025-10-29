import SwiftUI
import Rex

public protocol SplashFactory {
    func makeInterface() -> SplashInterface
    func makeView() -> AnyView
}
