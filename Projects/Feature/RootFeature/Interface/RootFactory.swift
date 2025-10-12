import SwiftUI
import Rex

public protocol RootFactory {
    func makeInterface() -> RootInterface
    func makeView() -> AnyView
}
