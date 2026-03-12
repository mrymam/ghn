import Foundation

struct GHNEvent: Decodable {
    let type: String
    let pr: GHNPR?
    let url: String?
    let count: Int
    let timestamp: Date
}

struct GHNPR: Decodable, Identifiable {
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

@MainActor
class GHNBridge: ObservableObject {
    @Published var reviewPRs: [GHNPR] = []
    @Published var unreadCount: Int = 0

    private var process: Process?
    private var pipe: Pipe?

    init() {
        startWatching()
    }

    func startWatching() {
        stopWatching()

        let process = Process()
        let pipe = Pipe()

        // Look for ghn binary bundled in the app, or fallback to PATH
        if let bundledURL = Bundle.main.url(forAuxiliaryExecutable: "ghn") {
            process.executableURL = bundledURL
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ghn")
        }

        process.arguments = ["watch"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        self.process = process
        self.pipe = pipe

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }

            guard let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !line.isEmpty else { return }

            // NDJSON: each line is a separate JSON object
            for jsonLine in line.components(separatedBy: "\n") {
                guard let jsonData = jsonLine.data(using: .utf8) else { continue }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                guard let event = try? decoder.decode(GHNEvent.self, from: jsonData) else { continue }

                Task { @MainActor [weak self] in
                    self?.handleEvent(event)
                }
            }
        }

        do {
            try process.run()
        } catch {
            print("Failed to start ghn process: \(error)")
        }
    }

    func stopWatching() {
        pipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        process = nil
        pipe = nil
    }

    private func handleEvent(_ event: GHNEvent) {
        switch event.type {
        case "init":
            unreadCount = event.count

        case "new":
            if let pr = event.pr {
                reviewPRs.insert(pr, at: 0)
                unreadCount = event.count
                sendNotification(pr: pr)
            }

        case "removed":
            if let url = event.url {
                reviewPRs.removeAll { $0.url == url }
            }
            unreadCount = event.count

        case "poll":
            unreadCount = event.count

        default:
            break
        }
    }

    private func sendNotification(pr: GHNPR) {
        let notification = NSUserNotification()
        notification.title = "New Review Request"
        notification.subtitle = "\(pr.repo) by \(pr.author)"
        notification.informativeText = pr.title
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }

    deinit {
        process?.terminate()
    }
}
