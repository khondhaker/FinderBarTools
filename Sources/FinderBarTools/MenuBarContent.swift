import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

    @State private var hoveredAction: FinderActionService.Action?
    @State private var clipboardPulseActive = false

    private var enabledActions: [FinderActionService.Action] {
        appModel.enabledActionsInPreferredOrder()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FinderBar Tools")
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 10)

            VStack(alignment: .leading, spacing: 0) {
                if enabledActions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text("All features are disabled")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                } else {
                    ForEach(Array(enabledActions.enumerated()), id: \.element.id) { index, action in
                        actionButton(for: action, isEven: index.isMultiple(of: 2))
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)

            if let runningAction = appModel.runningAction {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)

                    Text(runningAction.message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if let feedback = appModel.actionFeedback {
                HStack(spacing: 8) {
                    Image(systemName: statusSymbol(for: feedback))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor(for: feedback))

                    Text(feedback.message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(statusColor(for: feedback))
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
                .padding(.horizontal, 10)

            HStack {
                Button("Settings") {
                    openWindow(id: FinderBarToolsApp.settingsWindowID)
                    appModel.bringSettingsWindowToFront()
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

    private func actionButton(for action: FinderActionService.Action, isEven: Bool) -> some View {
        let isHovered = hoveredAction == action
        let runningAction = appModel.runningAction
        let feedback = appModel.actionFeedback
        let isRunningAction = runningAction?.action == action
        let isHighlightedAction = feedback?.action == action
        let isError = feedback?.isError == true && isHighlightedAction
        let usesClipboardPulse = feedback?.usesClipboardPulse == true && isHighlightedAction

        return Button {
            appModel.run(action)
        } label: {
            HStack(spacing: 10) {
                actionIcon(for: action)
                    .frame(width: 18, height: 18)

                Text(action.title)
                    .font(.system(size: 13))

                Spacer()

                if isRunningAction {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                        .transition(.opacity)
                } else if isHighlightedAction {
                    trailingFeedbackIcon(isError: isError, usesClipboardPulse: usesClipboardPulse)
                } else {
                    Text(appModel.shortcutLabel(for: action))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundFill(
                        isHovered: isHovered,
                        isEven: isEven,
                        isRunningAction: isRunningAction,
                        isHighlightedAction: isHighlightedAction,
                        isError: isError,
                        usesClipboardPulse: usesClipboardPulse
                    ))
                    .shadow(color: isEven ? Color.black.opacity(0.03) : .clear, radius: 1, x: 0, y: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: appModel.runningAction)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: appModel.actionFeedback)
        .onHover { hovering in
            hoveredAction = hovering ? action : nil
        }
        .onChange(of: appModel.actionFeedback) { newValue in
            guard action == .copyPath else { return }

            if newValue?.action == .copyPath, newValue?.usesClipboardPulse == true {
                clipboardPulseActive = false
                withAnimation(.easeOut(duration: 0.12)) {
                    clipboardPulseActive = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(220))
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        clipboardPulseActive = false
                    }
                }
            } else {
                clipboardPulseActive = false
            }
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

    @ViewBuilder
    private func trailingFeedbackIcon(isError: Bool, usesClipboardPulse: Bool) -> some View {
        if usesClipboardPulse {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: clipboardPulseActive ? 14 : 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .scaleEffect(clipboardPulseActive ? 1.12 : 0.92)
                .opacity(clipboardPulseActive ? 1 : 0.72)
                .transition(.scale.combined(with: .opacity))
        } else {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isError ? Color.orange : Color.green)
                .transition(.scale.combined(with: .opacity))
        }
    }

    private func loadAppIcon(from appURL: URL) -> NSImage? {
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        icon.size = NSSize(width: 18, height: 18)
        return icon
    }

    private func statusSymbol(for feedback: AppModel.ActionFeedback) -> String {
        if feedback.isError {
            return "exclamationmark.triangle.fill"
        }
        return feedback.usesClipboardPulse ? "doc.on.clipboard.fill" : "checkmark.circle.fill"
    }

    private func statusColor(for feedback: AppModel.ActionFeedback) -> Color {
        if feedback.isError {
            return .orange
        }
        return feedback.usesClipboardPulse ? .accentColor : .secondary
    }

    private func backgroundFill(
        isHovered: Bool,
        isEven: Bool,
        isRunningAction: Bool,
        isHighlightedAction: Bool,
        isError: Bool,
        usesClipboardPulse: Bool
    ) -> Color {
        if isHovered {
            return Color.accentColor.opacity(0.15)
        }

        if isRunningAction {
            return Color.accentColor.opacity(0.11)
        }

        if isHighlightedAction {
            if isError {
                return Color.orange.opacity(0.15)
            }
            return usesClipboardPulse ? Color.accentColor.opacity(0.15) : Color.green.opacity(0.14)
        }

        return isEven ? Color.primary.opacity(0.04) : Color.clear
    }
}
