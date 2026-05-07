import Foundation

enum WeatherServiceError: Error, LocalizedError {
    case invalidResponse
    case decoding
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The weather service returned an invalid response."
        case .decoding: return "Could not decode the weather data."
        case .network(let error): return error.localizedDescription
        }
    }
}

protocol WeatherServiceProtocol: Sendable {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherReport
}

struct WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.open-meteo.com/v1/forecast")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherReport {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m,is_day"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]

        guard let url = components.url else { throw WeatherServiceError.invalidResponse }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw WeatherServiceError.network(error)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WeatherServiceError.invalidResponse
        }

        do {
            let payload = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return payload.toWeatherReport()
        } catch {
            throw WeatherServiceError.decoding
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let time: String
        let temperature_2m: Double
        let apparent_temperature: Double
        let relative_humidity_2m: Double
        let precipitation: Double
        let weather_code: Int
        let cloud_cover: Double
        let pressure_msl: Double
        let wind_speed_10m: Double
        let wind_direction_10m: Double
        let wind_gusts_10m: Double
        let is_day: Int
    }

    struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let precipitation_sum: [Double]
        let wind_speed_10m_max: [Double]
    }

    func toWeatherReport() -> WeatherReport {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime]

        let observed = isoFormatter.date(from: current.time + ":00Z")
            ?? Self.parseLocalTime(current.time)
            ?? Date()

        let snapshot = WeatherSnapshot(
            temperatureC: current.temperature_2m,
            apparentTemperatureC: current.apparent_temperature,
            windSpeedKph: current.wind_speed_10m,
            windGustKph: current.wind_gusts_10m,
            windDirectionDegrees: current.wind_direction_10m,
            precipitationMm: current.precipitation,
            humidityPercent: current.relative_humidity_2m,
            pressureHpa: current.pressure_msl,
            cloudCoverPercent: current.cloud_cover,
            weatherCode: current.weather_code,
            isDay: current.is_day == 1,
            observedAt: observed
        )

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone(identifier: "UTC")

        let forecast: [DailyForecast] = zip(daily.time.indices, daily.time).compactMap { index, dayString in
            guard let date = dayFormatter.date(from: dayString) else { return nil }
            return DailyForecast(
                date: date,
                weatherCode: daily.weather_code[index],
                highC: daily.temperature_2m_max[index],
                lowC: daily.temperature_2m_min[index],
                precipitationMm: daily.precipitation_sum[index],
                windSpeedMaxKph: daily.wind_speed_10m_max[index]
            )
        }

        return WeatherReport(current: snapshot, daily: forecast, latitude: latitude, longitude: longitude)
    }

    private static func parseLocalTime(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = .current
        return formatter.date(from: string)
    }
}
