import SwiftUI
import Rex

public protocol AlarmFactory {
    func makeInterface() -> AlarmInterface
    func makeView() -> AnyView
}
