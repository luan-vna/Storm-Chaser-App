import SwiftUI

struct SyncBadge: View {
    let status: SyncStatus

    var body: some View {
        HStack(spacing: 4) {
            if status == .syncing {
                ProgressView().controlSize(.mini)
            } else {
                Image(systemName: status.symbolName)
            }
            Text(status.label)
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .foregroundStyle(status.color)
        .background(
            Capsule().fill(status.color.opacity(0.15))
        )
    }
}
