import Foundation

public class DIContainer {
    public static let shared = DIContainer()
    
    private var factories: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    
    private init() {}
    
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    public func registerSingleton<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }

    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        guard let factory = factories[key] as? () -> T else {
            fatalError("Factory for \(type) not registered")
        }
        
        let instance = factory()
        
        return instance
    }
    
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return factories[key] != nil || singletons[key] != nil
    }
    
    public func clear() {
        factories.removeAll()
        singletons.removeAll()
    }
}
