import CoreLocation
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class WeatherViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(WeatherReport, fetchedAt: Date, isStale: Bool)
        case notFound(String)
    }

    var state: State = .idle

    private let weatherService: WeatherServiceProtocol
    private let locationService: LocationServiceProtocol
    private let modelContext: ModelContext

    init(weatherService: WeatherServiceProtocol, locationService: LocationServiceProtocol, modelContext: ModelContext) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.modelContext = modelContext
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        loadFromCache()
        await refresh()
    }

    func refresh() async {
        if case .loaded = state {} else {
            state = .loading
            loadFromCache()
        }
        do {
            let coordinate = try await locationService.requestLocation()
            let report = try await weatherService.fetchWeather(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            persistCache(report)
            state = .loaded(report, fetchedAt: Date(), isStale: false)
        } catch {
            if loadFromCache() == false {
                state = .notFound(error.localizedDescription)
            }
        }
    }

    @discardableResult
    private func loadFromCache() -> Bool {
        let descriptor = FetchDescriptor<CachedWeather>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        guard let cached = (try? modelContext.fetch(descriptor))?.first,
              let report = cached.decodedReport() else {
            return false
        }
        state = .loaded(report, fetchedAt: cached.fetchedAt, isStale: true)
        return true
    }

    private func persistCache(_ report: WeatherReport) {
        guard let data = try? CachedWeather.encode(report) else { return }
        let descriptor = FetchDescriptor<CachedWeather>(predicate: #Predicate { $0.id == "current" })
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            existing.fetchedAt = Date()
            existing.latitude = report.latitude
            existing.longitude = report.longitude
            existing.payload = data
        } else {
            let cache = CachedWeather(
                fetchedAt: Date(),
                latitude: report.latitude,
                longitude: report.longitude,
                payload: data
            )
            modelContext.insert(cache)
        }
        try? modelContext.save()
    }
}
