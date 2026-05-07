import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SyncCoordinator {
    enum State: Equatable {
        case disabled
        case idle
        case running(pending: Int)
        case error(String)
    }

    private(set) var state: State

    private let modelContainer: ModelContainer
    private let networkMonitor: NetworkMonitor
    private let client: SupabaseClient?
    private var observerTask: Task<Void, Never>?
    private var isDraining = false

    init(modelContainer: ModelContainer, networkMonitor: NetworkMonitor) {
        self.modelContainer = modelContainer
        self.networkMonitor = networkMonitor
        if let config = SupabaseConfig.current {
            self.client = SupabaseClient(config: config)
            self.state = .idle
        } else {
            self.client = nil
            self.state = .disabled
        }
    }

    func start() {
        guard client != nil else { return }
        observerTask?.cancel()
        observerTask = Task { [weak self] in
            guard let self else { return }
            var lastConnected = self.networkMonitor.isConnected
            await self.drainIfPossible()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let now = self.networkMonitor.isConnected
                if now && !lastConnected {
                    await self.drainIfPossible()
                }
                lastConnected = now
            }
        }
    }

    func stop() {
        observerTask?.cancel()
        observerTask = nil
    }

    /// Trigger a sync attempt manually (e.g. after the user creates a report).
    func nudge() {
        Task { await drainIfPossible() }
    }

    private func drainIfPossible() async {
        guard let client else { return }
        guard networkMonitor.isConnected else { return }
        guard !isDraining else { return }
        isDraining = true
        defer { isDraining = false }

        let context = ModelContext(modelContainer)
        let pendingDescriptor = FetchDescriptor<StormReport>(
            predicate: #Predicate { $0.syncStatusRaw != "synced" },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let pending = try? context.fetch(pendingDescriptor), !pending.isEmpty else {
            state = .idle
            return
        }

        state = .running(pending: pending.count)

        for report in pending {
            report.syncStatus = .syncing
            report.lastSyncAttemptAt = Date()
            try? context.save()

            do {
                var photoPath: String?
                if let filename = report.imageFilename,
                   let data = ImageStore.shared.loadData(named: filename) {
                    photoPath = try await client.uploadPhoto(data: data, clientID: report.id)
                }
                try await client.insertReport(report, photoPath: photoPath)
                report.cloudPhotoPath = photoPath
                report.syncStatus = .synced
                report.lastSyncError = nil
            } catch {
                report.syncStatus = .failed
                report.lastSyncError = error.localizedDescription
                try? context.save()
                state = .error(error.localizedDescription)
                return
            }
            try? context.save()
        }

        state = .idle
    }
}
