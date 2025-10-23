import Foundation
import Supabase

public protocol SupabaseService {
    var client: SupabaseClient { get }
}
