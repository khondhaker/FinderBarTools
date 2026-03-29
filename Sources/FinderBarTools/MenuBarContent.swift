import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FinderBarTools")
                .font(.system(size: 15, weight: .semibold, design: .rounded))

            Text("Front Finder window utilities")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            actionButton(for: .newTextFile)
            actionButton(for: .openTerminalHere)
            actionButton(for: .openITermHere)
            actionButton(for: .copyPath)

            Divider()

            if #available(macOS 14.0, *) {
                SettingsLink {
                    Label("Settings…", systemImage: "gearshape")
                }
            } else {
                Button {
                    appModel.openSettingsFallback()
                } label: {
                    Label("Settings…", systemImage: "gearshape")
                }
            }

            Button("Quit FinderBarTools") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(minWidth: 270, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func actionButton(for action: FinderActionService.Action) -> some View {
        Button {
            appModel.run(action)
        } label: {
            HStack {
                Label(action.title, systemImage: action.systemImage)
                Spacer()
                Text(appModel.shortcutLabel(for: action))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
