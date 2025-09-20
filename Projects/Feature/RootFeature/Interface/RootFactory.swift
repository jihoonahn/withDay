import SwiftUI
import BaseFeature

public protocol RootFactory {
    func makeInterface() -> RootInterface
    func makeView() -> AnyView
}
