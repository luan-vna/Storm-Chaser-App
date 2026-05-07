import Foundation

enum SupabaseError: LocalizedError {
    case notConfigured
    case http(Int, String)
    case invalidResponse
    case authMissing

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase is not configured. Sync stays local."
        case .http(let code, let body): return "Supabase HTTP \(code): \(body)"
        case .invalidResponse: return "Supabase returned an unexpected response."
        case .authMissing: return "Missing Supabase auth session."
        }
    }
}

actor SupabaseClient {
    let config: SupabaseConfig
    private let session: URLSession
    private var cachedSession: AuthSession?

    init(config: SupabaseConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        self.cachedSession = AuthSession.load()
    }

    struct AuthSession: Codable, Sendable {
        let accessToken: String
        let refreshToken: String
        let userID: UUID
        let expiresAt: Date

        var isExpiringSoon: Bool {
            expiresAt.timeIntervalSinceNow < 60
        }

        fileprivate static let storageKey = "supabase.authSession"

        fileprivate static func load() -> AuthSession? {
            guard let data = UserDefaults.standard.data(forKey: AuthSession.storageKey) else { return nil }
            return try? JSONDecoder().decode(AuthSession.self, from: data)
        }

        fileprivate func save() {
            guard let data = try? JSONEncoder().encode(self) else { return }
            UserDefaults.standard.set(data, forKey: AuthSession.storageKey)
        }
    }

    private struct GoTrueResponse: Decodable {
        let access_token: String
        let refresh_token: String
        let expires_in: Int
        let user: User

        struct User: Decodable { let id: UUID }
    }

    private func ensureSession() async throws -> AuthSession {
        if let session = cachedSession, !session.isExpiringSoon {
            return session
        }
        if let session = cachedSession, session.isExpiringSoon {
            if let refreshed = try? await refresh(token: session.refreshToken) {
                cachedSession = refreshed
                refreshed.save()
                return refreshed
            }
        }
        let new = try await signInAnonymously()
        cachedSession = new
        new.save()
        return new
    }

    private func signInAnonymously() async throws -> AuthSession {
        var request = URLRequest(url: config.url.appendingPathComponent("auth/v1/signup"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": [:]])
        let response = try await perform(request)
        let payload = try JSONDecoder().decode(GoTrueResponse.self, from: response)
        return AuthSession(
            accessToken: payload.access_token,
            refreshToken: payload.refresh_token,
            userID: payload.user.id,
            expiresAt: Date().addingTimeInterval(TimeInterval(payload.expires_in))
        )
    }

    private func refresh(token: String) async throws -> AuthSession {
        var components = URLComponents(url: config.url.appendingPathComponent("auth/v1/token"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": token])
        let response = try await perform(request)
        let payload = try JSONDecoder().decode(GoTrueResponse.self, from: response)
        return AuthSession(
            accessToken: payload.access_token,
            refreshToken: payload.refresh_token,
            userID: payload.user.id,
            expiresAt: Date().addingTimeInterval(TimeInterval(payload.expires_in))
        )
    }

    ///`storm-photos/{userId}/{clientId}.jpg`.
    func uploadPhoto(data: Data, clientID: UUID) async throws -> String {
        let session = try await ensureSession()
        let path = "\(session.userID.uuidString.lowercased())/\(clientID.uuidString.lowercased()).jpg"
        let url = config.url
            .appendingPathComponent("storage/v1/object/storm-photos")
            .appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = data
        _ = try await perform(request)
        return path
    }

    struct ReportPayload: Encodable {
        let client_id: UUID
        let user_id: UUID
        let captured_at: Date
        let storm_type: String
        let latitude: Double
        let longitude: Double
        let notes: String
        let temperature_c: Double?
        let wind_speed_kph: Double?
        let precipitation_mm: Double?
        let weather_conditions: String?
        let photo_path: String?
    }

    func insertReport(_ report: StormReport, photoPath: String?) async throws {
        let session = try await ensureSession()
        let payload = ReportPayload(
            client_id: report.id,
            user_id: session.userID,
            captured_at: report.createdAt,
            storm_type: report.stormType.rawValue,
            latitude: report.latitude,
            longitude: report.longitude,
            notes: report.notes,
            temperature_c: report.temperatureC,
            wind_speed_kph: report.windSpeedKph,
            precipitation_mm: report.precipitationMm,
            weather_conditions: report.weatherConditions,
            photo_path: photoPath
        )

        let url = config.url.appendingPathComponent("rest/v1/storm_reports")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(payload)
        _ = try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseError.http(http.statusCode, body)
        }
        return data
    }
}
