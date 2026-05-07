import SwiftUI

struct OfflineRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Offline")
                    .font(.subheadline.weight(.semibold))
                Text("Reports will upload when you're back online.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
