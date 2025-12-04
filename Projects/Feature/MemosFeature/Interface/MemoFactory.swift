import SwiftUI
import Rex

public protocol MemoFactory {
    func makeInterface() -> MemoInterface
    func makeView() -> AnyView
}
