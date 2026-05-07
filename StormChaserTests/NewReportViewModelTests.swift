import CoreLocation
import Foundation
import SwiftData
import Testing
import UIKit
@testable import StormChaser

@MainActor
struct NewReportViewModelTests {

    // MARK: helpers

    private func makeViewModel(
        weather: MockWeatherService,
        location: MockLocationService
    ) throws -> (NewReportViewModel, ModelContext, ImageStore, URL) {
        let container = try TestModelContainer.make()
        let context = ModelContext(container)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StormChaserTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let imageStore = ImageStore(baseURL: tempDir)
        let viewModel = NewReportViewModel(
            weatherService: weather,
            locationService: location,
            imageStore: imageStore,
            modelContext: context
        )
        return (viewModel, context, imageStore, tempDir)
    }

    private func tinyImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 4, height: 4), true, 1)
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    // MARK: tests

    @Test
    func canSave_isFalse_whenMissingImageOrCoordinate() throws {
        let (vm, _, _, tempDir) = try makeViewModel(weather: MockWeatherService(), location: MockLocationService())
        defer { try? FileManager.default.removeItem(at: tempDir) }
        #expect(vm.canSave == false)

        vm.capturedImage = tinyImage()
        #expect(vm.canSave == false, "Image alone is not enough")

        vm.coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        #expect(vm.canSave == true)
    }

    @Test
    func save_returnsNil_whenPreconditionsMissing() throws {
        let (vm, context, _, tempDir) = try makeViewModel(weather: MockWeatherService(), location: MockLocationService())
        defer { try? FileManager.default.removeItem(at: tempDir) }
        #expect(vm.save() == nil)
        let reports = try context.fetch(FetchDescriptor<StormReport>())
        #expect(reports.isEmpty)
    }

    @Test
    func save_persistsReportWithMetadataAndImage() throws {
        let (vm, context, imageStore, tempDir) = try makeViewModel(weather: MockWeatherService(), location: MockLocationService())
        defer { try? FileManager.default.removeItem(at: tempDir) }

        vm.capturedImage = tinyImage()
        vm.coordinate = CLLocationCoordinate2D(latitude: 41.9, longitude: -87.6)
        vm.notes = "Big cell over the lake"
        vm.stormType = .tornado
        vm.weather = WeatherSnapshot(
            temperatureC: 22, apparentTemperatureC: 20, windSpeedKph: 50, windGustKph: 80,
            windDirectionDegrees: 90, precipitationMm: 5, humidityPercent: 70, pressureHpa: 1005,
            cloudCoverPercent: 90, weatherCode: 95, isDay: true, observedAt: Date()
        )

        let saved = vm.save()
        #expect(saved != nil)

        let reports = try context.fetch(FetchDescriptor<StormReport>())
        #expect(reports.count == 1)

        let report = try #require(reports.first)
        #expect(report.stormType == .tornado)
        #expect(report.notes == "Big cell over the lake")
        #expect(report.latitude == 41.9)
        #expect(report.longitude == -87.6)
        #expect(report.temperatureC == 22)
        #expect(report.windSpeedKph == 50)
        #expect(report.precipitationMm == 5)
        #expect(report.weatherConditions == "Thunderstorm")
        #expect(report.syncStatus == .pending, "New reports must start as pending")

        let filename = try #require(report.imageFilename)
        let storedData = imageStore.loadData(named: filename)
        #expect(storedData != nil, "Image bytes were written to disk")
    }

    @Test
    func save_doesNotAttachWeather_whenNoneFetched() throws {
        let (vm, context, _, tempDir) = try makeViewModel(weather: MockWeatherService(), location: MockLocationService())
        defer { try? FileManager.default.removeItem(at: tempDir) }

        vm.capturedImage = tinyImage()
        vm.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        _ = vm.save()
        let report = try #require(try context.fetch(FetchDescriptor<StormReport>()).first)
        #expect(report.temperatureC == nil)
        #expect(report.weatherConditions == nil)
    }

    @Test
    func save_invokesOnSavedCallback() throws {
        let container = try TestModelContainer.make()
        let context = ModelContext(container)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StormChaserTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var receivedReport: StormReport?
        let viewModel = NewReportViewModel(
            weatherService: MockWeatherService(),
            locationService: MockLocationService(),
            imageStore: ImageStore(baseURL: tempDir),
            modelContext: context,
            onSaved: { receivedReport = $0 }
        )
        viewModel.capturedImage = tinyImage()
        viewModel.coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)

        _ = viewModel.save()
        #expect(receivedReport != nil)
        #expect(receivedReport?.latitude == 1)
    }

    @Test
    func fetchMetadata_populatesCoordinateAndWeather_onSuccess() async throws {
        let weather = MockWeatherService()
        weather.outcome = .success(.sample(latitude: 5, longitude: 6))
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 5, longitude: 6))
        let (vm, _, _, tempDir) = try makeViewModel(weather: weather, location: location)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        await vm.fetchMetadata()

        #expect(vm.isFetchingMeta == false)
        #expect(vm.metaError == nil)
        #expect(vm.coordinate?.latitude == 5)
        #expect(vm.weather?.temperatureC == 12.5)
    }

    @Test
    func fetchMetadata_setsError_whenLocationFails() async throws {
        let location = MockLocationService()
        location.outcome = .failure(LocationError.permissionDenied)
        let weather = MockWeatherService()
        let (vm, _, _, tempDir) = try makeViewModel(weather: weather, location: location)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        await vm.fetchMetadata()

        #expect(vm.coordinate == nil)
        #expect(vm.weather == nil)
        #expect(vm.metaError != nil)
        #expect(weather.callCount == 0)
    }

    @Test
    func fetchMetadata_setsWeatherError_whenWeatherFails() async throws {
        let location = MockLocationService()
        location.outcome = .success(CLLocationCoordinate2D(latitude: 1, longitude: 2))
        let weather = MockWeatherService()
        weather.outcome = .failure(WeatherServiceError.invalidResponse)
        let (vm, _, _, tempDir) = try makeViewModel(weather: weather, location: location)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        await vm.fetchMetadata()

        #expect(vm.coordinate?.latitude == 1)
        #expect(vm.weather == nil)
        let error = try #require(vm.metaError)
        #expect(error.contains("weather"))
    }
}

// CLLocationCoordinate2D doesn't conform to Equatable by default — give the tests a small helper.
private extension CLLocationCoordinate2D {
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
