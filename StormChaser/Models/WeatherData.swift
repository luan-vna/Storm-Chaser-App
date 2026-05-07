import Foundation

nonisolated struct WeatherSnapshot: Codable, Equatable, Hashable, Sendable {
    let temperatureC: Double
    let apparentTemperatureC: Double
    let windSpeedKph: Double
    let windGustKph: Double
    let windDirectionDegrees: Double
    let precipitationMm: Double
    let humidityPercent: Double
    let pressureHpa: Double
    let cloudCoverPercent: Double
    let weatherCode: Int
    let isDay: Bool
    let observedAt: Date

    var conditionDescription: String { Self.description(for: weatherCode) }
    var conditionSymbol: String { Self.symbol(for: weatherCode, isDay: isDay) }

    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }

    static func symbol(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95: return "cloud.bolt.rain.fill"
        case 96, 99: return "cloud.bolt.fill"
        default: return "questionmark.circle"
        }
    }
}

nonisolated struct DailyForecast: Identifiable, Codable, Equatable, Hashable, Sendable {
    let date: Date
    let weatherCode: Int
    let highC: Double
    let lowC: Double
    let precipitationMm: Double
    let windSpeedMaxKph: Double

    var id: Date { date }
    var conditionSymbol: String { WeatherSnapshot.symbol(for: weatherCode, isDay: true) }
    var conditionDescription: String { WeatherSnapshot.description(for: weatherCode) }
}

nonisolated struct WeatherReport: Codable, Equatable, Sendable {
    let current: WeatherSnapshot
    let daily: [DailyForecast]
    let latitude: Double
    let longitude: Double
}
