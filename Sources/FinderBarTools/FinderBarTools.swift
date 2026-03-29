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
            if appModel.iconColorEnabled {
                Image(systemName: "filemenu.and.cursorarrow")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(appModel.iconColor)
            } else {
                Image(systemName: "filemenu.and.cursorarrow")
                    .fontWeight(.medium)
            }
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: Self.settingsWindowID) {
            SettingsView()
                .environmentObject(appModel)
        }
        .windowResizability(.contentSize)
    }
}
