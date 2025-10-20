import Foundation

public protocol NetworkCoreInterface {
    func request<T: Codable>(_ endpoint: String, responseType: T.Type) async throws -> T
    func request(_ endpoint: String) async throws -> Data
}
