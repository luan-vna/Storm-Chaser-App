import SwiftUI

struct LoadedWeatherView: View {
    let report: WeatherReport

    var body: some View {
        VStack(spacing: 20) {
            currentCard
            metricsGrid
            forecastSection
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }

    private var currentCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: report.current.conditionSymbol)
                    .font(.system(size: 56, weight: .light))
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 70)
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.current.conditionDescription)
                        .font(.title3.weight(.semibold))
                    Text(coordinateLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(observedAtLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(formattedTemperature(report.current.temperatureC))
                    .font(.system(size: 52, weight: .thin, design: .rounded))
                    .monospacedDigit()
            }
            HStack {
                Label("Feels like \(formattedTemperature(report.current.apparentTemperatureC))", systemImage: "thermometer.medium")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var metricsGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            MetricTile(symbol: "wind", title: "Wind", value: "\(Int(report.current.windSpeedKph.rounded())) km/h", subtitle: nil)
            MetricTile(symbol: "tornado", title: "Gusts", value: "\(Int(report.current.windGustKph.rounded())) km/h", subtitle: nil)
            MetricTile(symbol: "cloud.rain", title: "Precip", value: String(format: "%.1f mm", report.current.precipitationMm), subtitle: nil)
            MetricTile(symbol: "humidity", title: "Humidity", value: "\(Int(report.current.humidityPercent.rounded()))%", subtitle: nil)
            MetricTile(symbol: "gauge.with.dots.needle.bottom.50percent", title: "Pressure", value: "\(Int(report.current.pressureHpa.rounded())) hPa", subtitle: nil)
            MetricTile(symbol: "cloud", title: "Cloud", value: "\(Int(report.current.cloudCoverPercent.rounded()))%", subtitle: nil)
        }
    }

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Forecast")
                .font(.headline)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(Array(report.daily.enumerated()), id: \.element.id) { index, day in
                    ForecastRow(day: day, isFirst: index == 0)
                    if index < report.daily.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var coordinateLabel: String {
        String(format: "%.3f°, %.3f°", report.latitude, report.longitude)
    }

    private var observedAtLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "Updated \(formatter.string(from: report.current.observedAt))"
    }

    private func formattedTemperature(_ celsius: Double) -> String {
        Measurement(value: celsius, unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .narrow, usage: .weather))
    }
}
