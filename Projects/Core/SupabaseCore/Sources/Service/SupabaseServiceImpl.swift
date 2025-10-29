import Foundation
import Supabase
import SupabaseCoreInterface

public final class SupabaseServiceImpl: SupabaseService {
    public let client: SupabaseClient
    private let authStorage: KeychainAuthStorage
    
    public init() {
        self.authStorage = KeychainAuthStorage()
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://uikavecpbbswtwcgmnpp.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVpa2F2ZWNwYmJzd3R3Y2dtbnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzODIwNDksImV4cCI6MjA3Mzk1ODA0OX0.qEMYd8VCfvPRk1EuBKuOZlwCzDEG9TX_tjgDtTEwcRE",
            options: SupabaseClientOptions(
                auth: .init(
                    storage: authStorage,
                    flowType: .pkce
                )
            )
        )
        
        print("✅ [SupabaseServiceImpl] Keychain 기반 세션 저장소 초기화 완료")
    }
    
    /// 로그아웃 시 세션 정리
    public func clearSession() {
        authStorage.clearAllSessions()
    }
}
