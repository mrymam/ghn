import SwiftUI

@main
struct GHNApp: App {
    @StateObject private var bridge = GHNBridge()

    var body: some Scene {
        MenuBarExtra {
            MenuView(bridge: bridge)
        } label: {
            Image(systemName: bridge.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
