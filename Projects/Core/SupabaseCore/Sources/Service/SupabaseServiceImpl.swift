import Foundation
import Supabase
import SupabaseCoreInterface

public final class SupabaseServiceImpl: SupabaseService {
    public let client: SupabaseClient
    
    public init() {
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
              let url = URL(string: supabaseURL) else {
            fatalError("Supabase URL or Key is not set")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    }
}
