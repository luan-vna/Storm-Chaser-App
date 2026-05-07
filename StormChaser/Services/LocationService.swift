import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class LocationService: NSObject, LocationServiceProtocol {
    enum Status {
        case idle
        case requestingPermission
        case denied
        case fetching
        case located(CLLocationCoordinate2D)
        case failed(String)
    }

    private(set) var status: Status = .idle
    private(set) var lastLocation: CLLocationCoordinate2D?

    private let manager: CLLocationManager
    private var pendingContinuations: [CheckedContinuation<CLLocationCoordinate2D, Error>] = []

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async throws -> CLLocationCoordinate2D {
        let authorization = manager.authorizationStatus
        switch authorization {
        case .notDetermined:
            status = .requestingPermission
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            status = .denied
            throw LocationError.permissionDenied
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }

        status = .fetching
        return try await withCheckedThrowingContinuation { continuation in
            pendingContinuations.append(continuation)
            manager.requestLocation()
        }
    }
}

extension LocationService: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            self.status = .denied
            failAllPending(with: LocationError.permissionDenied)
        case .authorizedAlways, .authorizedWhenInUse:
            if !pendingContinuations.isEmpty {
                manager.requestLocation()
            }
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationManager(manager, didChangeAuthorization: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        lastLocation = coordinate
        status = .located(coordinate)
        let pending = pendingContinuations
        pendingContinuations.removeAll()
        for continuation in pending {
            continuation.resume(returning: coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = .failed(error.localizedDescription)
        failAllPending(with: error)
    }

    private func failAllPending(with error: Error) {
        let pending = pendingContinuations
        pendingContinuations.removeAll()
        for continuation in pending {
            continuation.resume(throwing: error)
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Location permission was denied. Enable it in Settings to use your current location."
        }
    }
}
