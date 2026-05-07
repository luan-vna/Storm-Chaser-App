import SwiftUI

private struct WeatherServiceKey: EnvironmentKey {
    static let defaultValue: WeatherServiceProtocol = WeatherService()
}

private struct LocationServiceKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: LocationServiceProtocol = LocationService()
}

private struct NetworkMonitorKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: NetworkMonitor = NetworkMonitor()
}

private struct SyncCoordinatorKey: EnvironmentKey {
    static let defaultValue: SyncCoordinator? = nil
}

extension EnvironmentValues {
    var weatherService: WeatherServiceProtocol {
        get { self[WeatherServiceKey.self] }
        set { self[WeatherServiceKey.self] = newValue }
    }

    var locationService: LocationServiceProtocol {
        get { self[LocationServiceKey.self] }
        set { self[LocationServiceKey.self] = newValue }
    }

    var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }

    var syncCoordinator: SyncCoordinator? {
        get { self[SyncCoordinatorKey.self] }
        set { self[SyncCoordinatorKey.self] = newValue }
    }
}
