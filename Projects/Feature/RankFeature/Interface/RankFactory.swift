import SwiftUI
import Rex

public protocol RankFactory {
    func makeInterface() -> RankInterface
    func makeView() -> AnyView
}
