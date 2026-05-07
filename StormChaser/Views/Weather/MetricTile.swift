import SwiftUI

struct MetricTile: View {
    let symbol: String
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(value)
                .font(.body.weight(.semibold))
                .monospacedDigit()
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
