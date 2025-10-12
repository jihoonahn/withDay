import SwiftUI
import Rex

public protocol HomeFactory {
    func makeInterface() -> HomeInterface
    func makeView() -> AnyView
}
