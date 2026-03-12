import SwiftUI

struct SettingsView: View {
    @State private var org: String = ""
    @State private var polling: String = "5m"
    @State private var saved: Bool = false

    var body: some View {
        Form {
            TextField("Organization:", text: $org)
                .textFieldStyle(.roundedBorder)

            Picker("Polling Interval:", selection: $polling) {
                Text("1 min").tag("1m")
                Text("3 min").tag("3m")
                Text("5 min").tag("5m")
                Text("10 min").tag("10m")
                Text("30 min").tag("30m")
            }

            HStack {
                Spacer()
                if saved {
                    Text("Saved!")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                Button("Save") {
                    let config = GHNConfig(org: org, polling: polling)
                    try? config.save()
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        saved = false
                    }
                }
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 350)
        .onAppear {
            let config = GHNConfig.load()
            org = config.org
            polling = config.polling.isEmpty ? "5m" : config.polling
        }
    }
}
