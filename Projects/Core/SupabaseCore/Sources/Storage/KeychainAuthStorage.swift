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
        
        print("✅ [KeychainAuthStorage] 세션 저장 성공: \(serviceKey)")
    }
    
    public func retrieve(key: String) throws -> Data? {
        let serviceKey = makeServiceKey(key)
        guard let stringValue = keychain.load(forKey: serviceKey) else {
            print("ℹ️ [KeychainAuthStorage] 저장된 세션 없음: \(serviceKey)")
            return nil
        }
        
        guard let data = stringValue.data(using: .utf8) else {
            throw KeychainAuthStorageError.decodingFailed
        }
        
        print("✅ [KeychainAuthStorage] 세션 로드 성공: \(serviceKey)")
        return data
    }
    
    public func remove(key: String) throws {
        let serviceKey = makeServiceKey(key)
        let success = keychain.delete(forKey: serviceKey)
        if !success {
            print("⚠️ [KeychainAuthStorage] 세션 삭제 실패 또는 존재하지 않음: \(serviceKey)")
        } else {
            print("✅ [KeychainAuthStorage] 세션 삭제 성공: \(serviceKey)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeServiceKey(_ key: String) -> String {
        return "\(servicePrefix).\(key)"
    }
    
    public func clearAllSessions() {
        _ = keychain.clearAll()
        print("✅ [KeychainAuthStorage] 모든 세션 삭제 완료")
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

