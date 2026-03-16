import SwiftUI

struct MenuView: View {
    @ObservedObject var bridge: GHNBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if bridge.reviewPRs.isEmpty {
                Text("No review requests")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                Text("Review Requests (\(bridge.reviewPRs.count))")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                Divider()

                ForEach(bridge.reviewPRs) { pr in
                    Button {
                        if let url = URL(string: pr.url) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pr.title)
                                .lineLimit(1)
                            HStack {
                                Text(pr.repo)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(pr.author)
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
            }

            Divider()

            SettingsLink {
                Text("Settings...")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(minWidth: 300)
    }
}
