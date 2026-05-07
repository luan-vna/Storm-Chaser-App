import Foundation
import SwiftData
@testable import StormChaser

@MainActor
enum TestModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema([StormReport.self, CachedWeather.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
