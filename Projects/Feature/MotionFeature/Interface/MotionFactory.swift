import SwiftUI
import Rex

public protocol MotionFactory {
    func makeInterface() -> MotionInterface
    func makeView() -> AnyView
}
