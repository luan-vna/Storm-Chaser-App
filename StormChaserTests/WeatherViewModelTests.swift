import CoreLocation
import Foundation
import SwiftData
import Testing
@testable import StormChaser

@MainActor
struct WeatherViewModelTests {

    // MARK: helpers

    private func makeViewModel(
        weather: MockWeatherService,
        location: MockLocationService
    ) throws -> (WeatherViewModel, ModelContext) {
        let container = try TestModelContainer.make()
        let context = ModelContext(container)
        let viewModel = WeatherViewModel(
            weatherService: weather,
            locationService: location,
            modelContext: context
        )
        return (viewModel, context)
    }

    private func seedCache(in context: ModelContext, fetchedAt: Date = Date(timeIntervalSinceNow: -3600)) throws {
        let report = WeatherReport.sample(latitude: 1.23, longitude: 4.56)
        let payload = try CachedWeather.encode(report)
        let cache = CachedWeather(
            id: "current",
            fetchedAt: fetchedAt,
            latitude: report.latitude,
            longitude: report.longitude,
            payload: payload
        )
        context.insert(cache)
        try context.save()
    }

    // MARK: tests

    @Test
    func refreshSuccess_setsLoadedStateAndPersistsCache() async throws {
        let weather = MockWeatherService()
        weather.outcome = .success(.sample(latitude: 10, longitude: 20))
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 10, longitude: 20))

        let (vm, context) = try makeViewModel(weather: weather, location: location)

        await vm.refresh()

        guard case .loaded(let report, _, let isStale) = vm.state else {
            Issue.record("Expected .loaded state, got \(vm.state)")
            return
        }
        #expect(isStale == false)
        #expect(report.latitude == 10)
        #expect(report.current.temperatureC == 12.5)

        // Persisted cache row exists.
        let cached = try context.fetch(FetchDescriptor<CachedWeather>())
        #expect(cached.count == 1)
        #expect(cached.first?.latitude == 10)
    }

    @Test
    func refreshFailure_withCache_fallsBackToStaleData() async throws {
        let weather = MockWeatherService()
        weather.outcome = .failure(WeatherServiceError.invalidResponse)
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 0, longitude: 0))

        let (vm, context) = try makeViewModel(weather: weather, location: location)
        try seedCache(in: context)

        await vm.refresh()

        guard case .loaded(let report, _, let isStale) = vm.state else {
            Issue.record("Expected .loaded state with stale data, got \(vm.state)")
            return
        }
        #expect(isStale == true)
        #expect(report.latitude == 1.23)
    }

    @Test
    func refreshFailure_withoutCache_setsNotFound() async throws {
        let weather = MockWeatherService()
        weather.outcome = .failure(WeatherServiceError.invalidResponse)
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 0, longitude: 0))

        let (vm, _) = try makeViewModel(weather: weather, location: location)

        await vm.refresh()

        guard case .notFound = vm.state else {
            Issue.record("Expected .notFound, got \(vm.state)")
            return
        }
    }

    @Test
    func locationFailure_withCache_fallsBackToStaleData() async throws {
        let weather = MockWeatherService()
        let location = MockLocationService()
        location.outcome = .failure(LocationError.permissionDenied)

        let (vm, context) = try makeViewModel(weather: weather, location: location)
        try seedCache(in: context)

        await vm.refresh()

        guard case .loaded(_, _, let isStale) = vm.state else {
            Issue.record("Expected .loaded fallback, got \(vm.state)")
            return
        }
        #expect(isStale == true)
        #expect(weather.callCount == 0, "Should not call weather service when location fails")
    }

    @Test
    func loadIfNeeded_skipsRefresh_whenAlreadyLoaded() async throws {
        let weather = MockWeatherService()
        weather.outcome = .success(.sample())
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 0, longitude: 0))

        let (vm, _) = try makeViewModel(weather: weather, location: location)

        await vm.loadIfNeeded()
        let firstCallCount = weather.callCount

        await vm.loadIfNeeded()

        #expect(weather.callCount == firstCallCount, "Second loadIfNeeded must not refetch")
    }

    @Test
    func successfulRefresh_replacesExistingCacheRow() async throws {
        let weather = MockWeatherService()
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 0, longitude: 0))

        let (vm, context) = try makeViewModel(weather: weather, location: location)
        try seedCache(in: context)

        weather.outcome = .success(.sample(latitude: 99, longitude: 88))
        await vm.refresh()

        let cached = try context.fetch(FetchDescriptor<CachedWeather>())
        #expect(cached.count == 1, "Should not duplicate cache rows")
        #expect(cached.first?.latitude == 99)
    }
}
