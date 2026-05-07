import SwiftUI
import CoreLocation

struct NewReportConditionsSection: View {
    let isFetchingMeta: Bool
    let coordinate: CLLocationCoordinate2D?
    let weather: WeatherSnapshot?
    let metaError: String?
    let onFetch: () -> Void

    var body: some View {
        if isFetchingMeta {
            HStack {
                ProgressView()
                Text("Fetching location and weather…")
                    .foregroundStyle(.secondary)
            }
        } else if let coordinate {
            LabeledContent("Location") {
                Text(String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude))
                    .monospacedDigit()
            }
            if let weather {
                LabeledContent("Conditions", value: weather.conditionDescription)
                LabeledContent("Temperature", value: String(format: "%.1f°C", weather.temperatureC))
                LabeledContent("Wind", value: String(format: "%.0f km/h", weather.windSpeedKph))
                LabeledContent("Precipitation", value: String(format: "%.1f mm", weather.precipitationMm))
            } else if let metaError {
                Text(metaError)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button(action: onFetch) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        } else {
            Button(action: onFetch) {
                Label("Capture location & weather", systemImage: "location.viewfinder")
            }
            if let metaError {
                Text(metaError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}
