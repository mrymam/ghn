import SwiftUI

@main
struct GHNApp: App {
    @StateObject private var bridge = GHNBridge()

    var body: some Scene {
        MenuBarExtra {
            MenuView(bridge: bridge)
        } label: {
            Label {
                Text("GHN")
            } icon: {
                Image(systemName: "bell.fill")
            }
            if bridge.unreadCount > 0 {
                Text("\(bridge.unreadCount)")
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
