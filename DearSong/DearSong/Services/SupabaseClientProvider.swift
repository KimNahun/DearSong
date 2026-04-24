import Foundation
import Supabase

// MARK: - SupabaseClientProvider

final class SupabaseClientProvider: Sendable {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        let urlString = Bundle.main.infoDictionary?["SupabaseURL"] as? String ?? ""
        let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String ?? ""

        guard let url = URL(string: urlString), !urlString.isEmpty else {
            fatalError("SupabaseURL is invalid or missing. Check Secrets.xcconfig and Info.plist.")
        }
        guard !key.isEmpty else {
            fatalError("SupabaseAnonKey is missing. Check Secrets.xcconfig and Info.plist.")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
}
