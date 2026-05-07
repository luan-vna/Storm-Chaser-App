import SwiftUI

struct OfflineBanner: View {
    let fetchedAt: Date

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Showing cached data")
                    .font(.subheadline.weight(.semibold))
                Text("Last updated \(relativeTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: fetchedAt, relativeTo: Date())
    }
}
