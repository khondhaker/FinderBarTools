import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

    private static let orderedActions: [FinderActionService.Action] = [
        .newTextFile,
        .openTerminalHere,
        .openITermHere,
        .openVSCodeHere,
        .copyPath,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("FinderBar Tools")
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 10)

            // Actions
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(Self.orderedActions.enumerated()), id: \.element.id) { index, action in
                    actionButton(for: action, isEven: index.isMultiple(of: 2))
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)

            Divider()
                .padding(.horizontal, 10)

            // Footer: Settings and Quit side by side
            HStack {
                Button("Settings") {
                    openWindow(id: FinderBarToolsApp.settingsWindowID)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 280)
    }

    @State private var hoveredAction: FinderActionService.Action?

    private func actionButton(for action: FinderActionService.Action, isEven: Bool) -> some View {
        let isHovered = hoveredAction == action

        return Button {
            appModel.run(action)
        } label: {
            HStack(spacing: 10) {
                actionIcon(for: action)
                    .frame(width: 18, height: 18)

                Text(action.title)
                    .font(.system(size: 13))

                Spacer()

                Text(appModel.shortcutLabel(for: action))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered
                        ? Color.accentColor.opacity(0.15)
                        : isEven
                            ? Color.primary.opacity(0.04)
                            : Color.clear)
                    .shadow(color: isEven ? Color.black.opacity(0.03) : .clear,
                            radius: 1, x: 0, y: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredAction = hovering ? action : nil
        }
    }

    @ViewBuilder
    private func actionIcon(for action: FinderActionService.Action) -> some View {
        if let bundleID = action.appBundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let icon = loadAppIcon(from: appURL) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
        } else {
            Image(systemName: action.systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.medium)
        }
    }

    private func loadAppIcon(from appURL: URL) -> NSImage? {
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        icon.size = NSSize(width: 18, height: 18)
        return icon
    }
}
