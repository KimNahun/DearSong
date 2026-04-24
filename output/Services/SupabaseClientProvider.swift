import Foundation
import Supabase

// MARK: - SupabaseClientProvider

final class SupabaseClientProvider: Sendable {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        let urlString = Bundle.main.infoDictionary?["SupabaseURL"] as? String ?? ""
        let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String ?? ""

        guard let url = URL(string: urlString) else {
            fatalError("SupabaseURL is invalid or missing in Info.plist")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
}
