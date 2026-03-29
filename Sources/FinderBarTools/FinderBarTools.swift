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
            Image(systemName: "filemenu.and.cursorarrow")
                .symbolRenderingMode(appModel.iconColorEnabled ? .palette : .monochrome)
                .foregroundStyle(appModel.iconColorEnabled ? appModel.iconColor : .primary)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: Self.settingsWindowID) {
            SettingsView()
                .environmentObject(appModel)
        }
        .windowResizability(.contentSize)
    }
}
