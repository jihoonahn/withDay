import SwiftUI
import Rex

public protocol LoginFactory {
    func makeInterface() -> LoginInterface
    func makeView() -> AnyView
}
