import SwiftUI
import MapKit

struct ReportDetailView: View {
    let report: StormReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let filename = report.imageFilename, let image = ImageStore.shared.loadImage(named: filename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 10) {
                    Image(systemName: report.stormType.symbolName)
                        .font(.title2)
                        .foregroundStyle(.tint)
                    Text(report.stormType.displayName)
                        .font(.title2.weight(.semibold))
                }

                if !report.notes.isEmpty {
                    Text(report.notes)
                        .font(.body)
                }

                metadataSection

                miniMap
            }
            .padding()
        }
        .navigationTitle("Storm Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var metadataSection: some View {
        VStack(spacing: 0) {
            MetadataRow(symbol: "calendar", title: "Captured", value: report.createdAt.formatted(date: .abbreviated, time: .shortened))
            Divider().padding(.leading, 44)
            MetadataRow(symbol: "location", title: "Coordinates", value: String(format: "%.5f°, %.5f°", report.latitude, report.longitude))
            if let condition = report.weatherConditions {
                Divider().padding(.leading, 44)
                MetadataRow(symbol: "cloud", title: "Conditions", value: condition)
            }
            if let temperature = report.temperatureC {
                Divider().padding(.leading, 44)
                MetadataRow(symbol: "thermometer.medium", title: "Temperature", value: String(format: "%.1f°C", temperature))
            }
            if let wind = report.windSpeedKph {
                Divider().padding(.leading, 44)
                MetadataRow(symbol: "wind", title: "Wind", value: String(format: "%.0f km/h", wind))
            }
            if let precip = report.precipitationMm {
                Divider().padding(.leading, 44)
                MetadataRow(symbol: "cloud.rain", title: "Precipitation", value: String(format: "%.1f mm", precip))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var miniMap: some View {
        let coordinate = CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude)
        let position = MapCameraPosition.region(
            MKCoordinateRegion(center: coordinate, latitudinalMeters: 4_000, longitudinalMeters: 4_000)
        )
        return Map(initialPosition: position, interactionModes: []) {
            Marker(report.stormType.displayName, systemImage: report.stormType.symbolName, coordinate: coordinate)
                .tint(.red)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

