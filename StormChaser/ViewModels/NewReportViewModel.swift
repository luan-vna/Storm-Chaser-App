import CoreLocation
import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class NewReportViewModel {
    var stormType: StormType = .thunderstorm
    var notes: String = ""
    var capturedImage: UIImage?
    var coordinate: CLLocationCoordinate2D?
    var weather: WeatherSnapshot?

    var isFetchingMeta: Bool = false
    var metaError: String?
    var saveError: String?

    private let weatherService: WeatherServiceProtocol
    private let locationService: LocationServiceProtocol
    private let imageStore: ImageStore
    private let modelContext: ModelContext
    private let onSaved: (StormReport) -> Void

    init(
        weatherService: WeatherServiceProtocol,
        locationService: LocationServiceProtocol,
        imageStore: ImageStore = ImageStore(),
        modelContext: ModelContext,
        onSaved: @escaping (StormReport) -> Void = { _ in }
    ) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.imageStore = imageStore
        self.modelContext = modelContext
        self.onSaved = onSaved
    }

    var canSave: Bool { capturedImage != nil && coordinate != nil }

    func fetchMetadata() async {
        isFetchingMeta = true
        metaError = nil
        defer { isFetchingMeta = false }

        do {
            coordinate = try await locationService.requestLocation()
        } catch {
            metaError = error.localizedDescription
            return
        }

        guard let coordinate else { return }
        do {
            let report = try await weatherService.fetchWeather(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            weather = report.current
        } catch {
            metaError = "Couldn't fetch weather: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func save() -> StormReport? {
        guard let capturedImage, let coordinate else { return nil }

        let filename: String
        do {
            filename = try imageStore.save(capturedImage)
        } catch {
            saveError = "Could not save the image."
            return nil
        }

        let report = StormReport(
            notes: notes,
            stormType: stormType,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            temperatureC: weather?.temperatureC,
            windSpeedKph: weather?.windSpeedKph,
            precipitationMm: weather?.precipitationMm,
            weatherConditions: weather?.conditionDescription,
            imageFilename: filename
        )
        modelContext.insert(report)
        try? modelContext.save()
        onSaved(report)
        return report
    }
}
