import Foundation
import SwiftUI

enum SyncStatus: String, Codable, CaseIterable {
    case pending
    case syncing
    case synced
    case failed

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .syncing: return "Uploading"
        case .synced: return "Synced"
        case .failed: return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .syncing: return .blue
        case .synced: return .green
        case .failed: return .red
        }
    }

    var symbolName: String {
        switch self {
        case .pending: return "clock.arrow.circlepath"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.icloud.fill"
        case .failed: return "exclamationmark.icloud.fill"
        }
    }
}
