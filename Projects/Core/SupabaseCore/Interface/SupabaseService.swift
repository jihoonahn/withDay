import Foundation
import Supabase

public protocol SupabaseService: Sendable {
    var client: SupabaseClient { get }
    func clearSession()
}
