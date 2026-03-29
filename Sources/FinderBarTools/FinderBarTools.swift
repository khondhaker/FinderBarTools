import SwiftUI

@main
struct FinderBarToolsApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(appModel)
        } label: {
            Label("FinderBarTools", systemImage: "folder.badge.gearshape")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appModel)
        }
    }
}
