import SwiftUI

@main
struct GHNApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var bridge = GHNBridge()

    var body: some Scene {
        MenuBarExtra {
            MenuView(bridge: bridge)
        } label: {
            Image(systemName: bridge.unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
        }

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        GHNBridge.shared?.stopWatching()
    }
}
