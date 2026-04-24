import Foundation
import Supabase

// MARK: - SupabaseClientProvider

final class SupabaseClientProvider: Sendable {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        let urlString = Bundle.main.infoDictionary?["SupabaseURL"] as? String ?? ""
        let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String ?? ""

        let url = URL(string: urlString) ?? URL(string: "https://placeholder.supabase.co")!

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key.isEmpty ? "placeholder" : key
        )
    }
}
