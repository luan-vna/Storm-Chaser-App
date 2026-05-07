import CoreLocation
import Foundation
@testable import StormChaser

@MainActor
final class MockLocationService: LocationServiceProtocol {
    enum Outcome {
        case success(CLLocationCoordinate2D)
        case failure(Error)
    }

    var outcome: Outcome = .failure(LocationError.permissionDenied)
    private(set) var callCount = 0

    func requestLocation() async throws -> CLLocationCoordinate2D {
        callCount += 1
        switch outcome {
        case .success(let coordinate): return coordinate
        case .failure(let error): throw error
        }
    }
}
