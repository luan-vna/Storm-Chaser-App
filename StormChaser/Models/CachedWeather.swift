import Foundation
import SwiftData

@Model
final class CachedWeather {
    @Attribute(.unique) var id: String
    var fetchedAt: Date
    var latitude: Double
    var longitude: Double
    var payload: Data

    init(id: String = "current", fetchedAt: Date, latitude: Double, longitude: Double, payload: Data) {
        self.id = id
        self.fetchedAt = fetchedAt
        self.latitude = latitude
        self.longitude = longitude
        self.payload = payload
    }

    func decodedReport() -> WeatherReport? {
        try? JSONDecoder.weather.decode(WeatherReport.self, from: payload)
    }

    static func encode(_ report: WeatherReport) throws -> Data {
        try JSONEncoder.weather.encode(report)
    }
}

extension JSONEncoder {
    static let weather: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let weather: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
