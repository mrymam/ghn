import Foundation

struct GHNConfig: Codable {
    var org: String
    var polling: String

    static let defaultConfig = GHNConfig(org: "", polling: "5m")

    static var configURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/ghn/config.json")
    }

    static func load() -> GHNConfig {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(GHNConfig.self, from: data) else {
            return defaultConfig
        }
        return config
    }

    func save() throws {
        let dir = GHNConfig.configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: GHNConfig.configURL)
    }
}
