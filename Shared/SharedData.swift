import Foundation

struct SharedPR: Codable, Identifiable {
    let repo: String
    let fullRepo: String?
    let number: Int
    let title: String
    let author: String
    let url: String
    let updatedAt: Date?
    let draft: Bool?

    var id: String { url }

    enum CodingKeys: String, CodingKey {
        case repo, number, title, author, url, draft
        case fullRepo = "full_repo"
        case updatedAt = "updated_at"
    }
}

struct SharedSnapshot: Codable {
    let prs: [SharedPR]
    let updatedAt: Date
}

enum SharedDataStore {
    static var fileURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ghn")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("widget-data.json")
    }

    static func write(prs: [SharedPR]) {
        let snapshot = SharedSnapshot(prs: prs, updatedAt: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func read() -> SharedSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? decoder.decode(SharedSnapshot.self, from: data) else {
            return SharedSnapshot(prs: [], updatedAt: Date.distantPast)
        }
        return snapshot
    }
}
