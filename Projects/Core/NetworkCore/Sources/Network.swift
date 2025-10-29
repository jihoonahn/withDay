import Foundation
import NetworkCoreInterface

public class NetworkCore: NetworkCoreInterface {
    public static let shared = NetworkCore()
    
    private init() {}
    
    public func request<T: Codable>(_ endpoint: String, responseType: T.Type) async throws -> T {
        fatalError("Not implemented")
    }
    
    public func request(_ endpoint: String) async throws -> Data {
        fatalError("Not implemented")
    }
}
