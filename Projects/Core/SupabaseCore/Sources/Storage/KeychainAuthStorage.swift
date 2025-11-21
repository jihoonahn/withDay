import Foundation
import Supabase
import Utility

public final class KeychainAuthStorage: AuthLocalStorage {
    private let keychain = Keychain.shared
    private let servicePrefix = "com.withday.supabase"
    
    public init() {}
    
    // MARK: - AuthLocalStorage Protocol
    
    public func store(key: String, value: Data) throws {
        let serviceKey = makeServiceKey(key)
        guard let stringValue = String(data: value, encoding: .utf8) else {
            throw KeychainAuthStorageError.encodingFailed
        }
        
        let success = keychain.save(stringValue, forKey: serviceKey)
        if !success {
            throw KeychainAuthStorageError.saveFailed
        }
    }
    
    public func retrieve(key: String) throws -> Data? {
        let serviceKey = makeServiceKey(key)
        guard let stringValue = keychain.load(forKey: serviceKey) else {
            return nil
        }
        
        guard let data = stringValue.data(using: .utf8) else {
            throw KeychainAuthStorageError.decodingFailed
        }
        return data
    }
    
    public func remove(key: String) throws {
        let serviceKey = makeServiceKey(key)
        let _ = keychain.delete(forKey: serviceKey)
    }
    
    // MARK: - Helper Methods
    
    private func makeServiceKey(_ key: String) -> String {
        return "\(servicePrefix).\(key)"
    }
    
    public func clearAllSessions() {
        _ = keychain.clearAll()
    }
}

// MARK: - Errors

enum KeychainAuthStorageError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "세션 데이터 인코딩에 실패했습니다."
        case .decodingFailed:
            return "세션 데이터 디코딩에 실패했습니다."
        case .saveFailed:
            return "세션 저장에 실패했습니다."
        }
    }
}
