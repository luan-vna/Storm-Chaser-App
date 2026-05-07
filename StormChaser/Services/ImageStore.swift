import Foundation
import UIKit

nonisolated enum ImageStoreError: Error {
    case failedToEncode
    case failedToWrite
}

nonisolated struct ImageStore {
    static let shared = ImageStore()

    let baseURL: URL

    init(baseURL: URL = ImageStore.defaultDirectory()) {
        self.baseURL = baseURL
    }

    private static func defaultDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("StormPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func ensureDirectoryExists() {
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    @discardableResult
    func save(_ image: UIImage, suggestedName: String? = nil) throws -> String {
        ensureDirectoryExists()
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw ImageStoreError.failedToEncode
        }
        let filename = (suggestedName ?? UUID().uuidString) + ".jpg"
        let url = baseURL.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ImageStoreError.failedToWrite
        }
        return filename
    }

    func loadImage(named filename: String) -> UIImage? {
        guard let data = loadData(named: filename) else { return nil }
        return UIImage(data: data)
    }

    func loadData(named filename: String) -> Data? {
        let url = baseURL.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    func delete(filename: String) {
        let url = baseURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
