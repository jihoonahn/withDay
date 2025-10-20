import Foundation
import NetworkCoreInterface

public class NetworkCore: NetworkCoreInterface {
    public static let shared = NetworkCore()
    
    private init() {}
    
    public func request<T: Codable>(_ endpoint: String, responseType: T.Type) async throws -> T {
        // 실제 네트워크 요청 구현
        fatalError("Not implemented")
    }
    
    public func request(_ endpoint: String) async throws -> Data {
        // 실제 네트워크 요청 구현
        fatalError("Not implemented")
    }
}
