import Foundation

struct SupabaseConfig: Sendable {
    let url: URL
    let anonKey: String

    static var current: SupabaseConfig? {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !urlString.isEmpty,
            !anonKey.isEmpty,
            let url = URL(string: urlString)
        else {
            return nil
        }
        return SupabaseConfig(url: url, anonKey: anonKey)
    }
}
