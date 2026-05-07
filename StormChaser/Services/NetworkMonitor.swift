import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "stormchaser.networkmonitor")

    nonisolated init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
