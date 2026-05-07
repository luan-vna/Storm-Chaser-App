import Foundation

enum StormType: String, Codable, CaseIterable, Identifiable {
    case thunderstorm
    case tornado
    case hurricane
    case blizzard
    case hailstorm
    case derecho
    case waterspout
    case duststorm
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thunderstorm: return "Thunderstorm"
        case .tornado: return "Tornado"
        case .hurricane: return "Hurricane"
        case .blizzard: return "Blizzard"
        case .hailstorm: return "Hailstorm"
        case .derecho: return "Derecho"
        case .waterspout: return "Waterspout"
        case .duststorm: return "Dust Storm"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .tornado: return "tornado"
        case .hurricane: return "hurricane"
        case .blizzard: return "snowflake"
        case .hailstorm: return "cloud.hail.fill"
        case .derecho: return "wind"
        case .waterspout: return "water.waves"
        case .duststorm: return "sun.dust.fill"
        case .other: return "cloud.fill"
        }
    }
}
