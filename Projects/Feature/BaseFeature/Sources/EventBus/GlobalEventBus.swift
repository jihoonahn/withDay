import Foundation
import Rex

public final class GlobalEventBus {
    public static let shared = GlobalEventBus()

    private let eventBus = EventBus()

    public init() {}

    public func publish<T: EventType>(_ event: T) async {
        await eventBus.publish(event)
    }

    public func subscribe<T: EventType>(_ eventType: T.Type, handler: @Sendable @escaping (T) -> Void) async {
        await eventBus.subscribe(to: eventType, handler: handler)
    }

    public func subscribe(handler: @Sendable @escaping (Any) -> Void) async {
        await eventBus.subscribe(handler: handler)
    }
}
