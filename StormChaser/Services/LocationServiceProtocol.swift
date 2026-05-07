import CoreLocation

@MainActor
protocol LocationServiceProtocol: AnyObject {
    func requestLocation() async throws -> CLLocationCoordinate2D
}
