import SwiftUI

@main
struct FinderBarToolsApp: App {
    static let settingsWindowID = "settings-window"
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(appModel)
        } label: {
            Label("FinderBarTools", systemImage: "folder.badge.gearshape")
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: Self.settingsWindowID) {
            SettingsView()
                .environmentObject(appModel)
        }
        .windowResizability(.contentSize)
    }
}
