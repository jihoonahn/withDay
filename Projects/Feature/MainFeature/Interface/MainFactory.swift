import SwiftUI
import Rex

public protocol MainFactory {
    func makeInterface() -> MainInterface
    func makeView() -> AnyView
}
