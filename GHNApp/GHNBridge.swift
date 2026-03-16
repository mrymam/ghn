import Foundation
import UserNotifications

struct GHNEvent: Decodable {
    let type: String
    let pr: GHNPR?
    let prs: [GHNPR]?
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
        requestNotificationPermission()
        startWatching()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func startWatching() {
        stopWatching()

        let process = Process()
        let pipe = Pipe()

        if let bundledURL = Bundle.main.url(forAuxiliaryExecutable: "ghn-cli") {
            process.executableURL = bundledURL
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ghn-cli")
        }

        // Pass through PATH so ghn-cli can find `gh`
        var env = ProcessInfo.processInfo.environment
        if env["PATH"] == nil {
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        }
        process.environment = env

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

            for jsonLine in line.components(separatedBy: "\n") {
                let trimmed = jsonLine.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, let jsonData = trimmed.data(using: .utf8) else { continue }

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
            print("Failed to start ghn-cli process: \(error)")
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
            if let prs = event.prs {
                reviewPRs = prs
            }
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

        syncToWidget()
    }

    private func syncToWidget() {
        let shared = reviewPRs.map { pr in
            SharedPR(
                repo: pr.repo,
                fullRepo: pr.fullRepo,
                number: pr.number,
                title: pr.title,
                author: pr.author,
                url: pr.url,
                updatedAt: pr.updatedAt,
                draft: pr.draft
            )
        }
        SharedDataStore.write(prs: shared)
    }

    private func sendNotification(pr: GHNPR) {
        let content = UNMutableNotificationContent()
        content.title = "New Review Request"
        content.subtitle = "\(pr.repo) by \(pr.author)"
        content.body = pr.title
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: pr.url,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    deinit {
        process?.terminate()
    }
}
