import SwiftUI
import SwiftData

@main
struct StormChaserApp: App {
    let sharedModelContainer: ModelContainer
    @State private var networkMonitor: NetworkMonitor
    @State private var syncCoordinator: SyncCoordinator

    init() {
        let schema = Schema([StormReport.self, CachedWeather.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.sharedModelContainer = container

        let monitor = NetworkMonitor()
        _networkMonitor = State(initialValue: monitor)
        _syncCoordinator = State(
            initialValue: SyncCoordinator(modelContainer: container, networkMonitor: monitor)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.networkMonitor, networkMonitor)
                .environment(\.syncCoordinator, syncCoordinator)
                .task { syncCoordinator.start() }
        }
        .modelContainer(sharedModelContainer)
    }
}
