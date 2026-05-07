import SwiftUI

struct ForecastRow: View {
    let day: DailyForecast
    let isFirst: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(dayLabel)
                .font(.subheadline.weight(.medium))
                .frame(width: 56, alignment: .leading)
            Image(systemName: day.conditionSymbol)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(day.conditionDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if day.precipitationMm > 0 {
                    Text(String(format: "%.1f mm", day.precipitationMm))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text("\(Int(day.lowC.rounded()))° / \(Int(day.highC.rounded()))°")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    private var dayLabel: String {
        if isFirst { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }
}
