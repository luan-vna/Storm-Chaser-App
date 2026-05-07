import Foundation
import SwiftData

@Model
final class StormReport {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var notes: String = ""
    var stormTypeRaw: String = StormType.thunderstorm.rawValue

    var latitude: Double = 0
    var longitude: Double = 0

    var temperatureC: Double?
    var windSpeedKph: Double?
    var precipitationMm: Double?
    var weatherConditions: String?

    var imageFilename: String?

    var syncStatusRaw: String = SyncStatus.pending.rawValue
    var cloudPhotoPath: String?
    var lastSyncAttemptAt: Date?
    var lastSyncError: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        notes: String = "",
        stormType: StormType = .thunderstorm,
        latitude: Double,
        longitude: Double,
        temperatureC: Double? = nil,
        windSpeedKph: Double? = nil,
        precipitationMm: Double? = nil,
        weatherConditions: String? = nil,
        imageFilename: String? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.createdAt = createdAt
        self.notes = notes
        self.stormTypeRaw = stormType.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.temperatureC = temperatureC
        self.windSpeedKph = windSpeedKph
        self.precipitationMm = precipitationMm
        self.weatherConditions = weatherConditions
        self.imageFilename = imageFilename
        self.syncStatusRaw = syncStatus.rawValue
    }

    var stormType: StormType {
        get { StormType(rawValue: stormTypeRaw) ?? .other }
        set { stormTypeRaw = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
