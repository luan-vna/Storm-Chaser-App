import SwiftUI

struct SyncIndicator: View {
    @Environment(\.syncCoordinator) private var syncCoordinator
    @Environment(\.networkMonitor) private var networkMonitor

    var body: some View {
        if let syncCoordinator {
            content(for: syncCoordinator.state)
        }
    }

    @ViewBuilder
    private func content(for state: SyncCoordinator.State) -> some View {
        switch state {
        case .disabled:
            Image(systemName: "icloud.slash")
                .foregroundStyle(.tertiary)
        case .idle:
            Image(systemName: networkMonitor.isConnected ? "icloud" : "icloud.slash")
                .foregroundStyle(networkMonitor.isConnected ? Color.secondary : Color.orange)
        case .running(let pending):
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("\(pending)")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
            }
        case .error:
            Image(systemName: "exclamationmark.icloud")
                .foregroundStyle(.red)
        }
    }
}
