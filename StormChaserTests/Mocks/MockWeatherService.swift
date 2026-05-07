import Foundation
@testable import StormChaser

nonisolated final class MockWeatherService: WeatherServiceProtocol, @unchecked Sendable {
    enum Outcome {
        case success(WeatherReport)
        case failure(Error)
    }

    var outcome: Outcome = .failure(WeatherServiceError.invalidResponse)
    private(set) var callCount = 0
    private(set) var lastLatitude: Double?
    private(set) var lastLongitude: Double?

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherReport {
        callCount += 1
        lastLatitude = latitude
        lastLongitude = longitude
        switch outcome {
        case .success(let report): return report
        case .failure(let error): throw error
        }
    }
}

extension WeatherReport {
    static func sample(latitude: Double = 43.65, longitude: Double = -79.38) -> WeatherReport {
        WeatherReport(
            current: WeatherSnapshot(
                temperatureC: 12.5,
                apparentTemperatureC: 10.0,
                windSpeedKph: 18,
                windGustKph: 32,
                windDirectionDegrees: 270,
                precipitationMm: 1.2,
                humidityPercent: 73,
                pressureHpa: 1012,
                cloudCoverPercent: 80,
                weatherCode: 3,
                isDay: true,
                observedAt: Date(timeIntervalSince1970: 1_750_000_000)
            ),
            daily: [
                DailyForecast(date: Date(timeIntervalSince1970: 1_750_000_000), weatherCode: 3, highC: 14, lowC: 8, precipitationMm: 1.2, windSpeedMaxKph: 22)
            ],
            latitude: latitude,
            longitude: longitude
        )
    }
}
