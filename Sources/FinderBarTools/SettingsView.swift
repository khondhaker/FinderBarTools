import Carbon
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var recordingAction: FinderActionService.Action?
    @State private var launchAtLogin = false
    @State private var shortcutErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FinderBarTools Settings")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("Assign global shortcuts and startup behavior for the menu bar actions.")
                .foregroundStyle(.secondary)

            Toggle("Launch At Login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    launchAtLogin = newValue
                    appModel.launchAtLoginManager.setEnabled(newValue)
                    launchAtLogin = appModel.launchAtLoginManager.isEnabled
                }
            ))

            if let message = appModel.launchAtLoginManager.lastErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let shortcutErrorMessage {
                Text(shortcutErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            // Icon color
            VStack(alignment: .leading, spacing: 10) {
                Text("Menu Bar Icon")
                    .font(.headline)

                Toggle("Colorful Icon", isOn: $appModel.iconColorEnabled)

                if appModel.iconColorEnabled {
                    HStack(spacing: 8) {
                        ForEach(AppModel.presetIconColors, id: \.0) { name, color in
                            Button {
                                appModel.iconColor = color
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        appModel.isPresetIconColor(color)
                                            ? Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white.shadow(.drop(radius: 1)))
                                            : nil
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(name)
                        }

                        Divider()
                            .frame(height: 22)

                        ColorPicker("", selection: $appModel.iconColor, supportsOpacity: false)
                            .labelsHidden()
                            .help("Custom color")
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Features")
                    .font(.headline)

                ForEach(appModel.actionOrder) { action in
                    HStack(spacing: 10) {
                        Toggle(isOn: Binding(
                            get: { appModel.isActionEnabled(action) },
                            set: { appModel.setAction(action, enabled: $0) }
                        )) {
                            HStack(spacing: 8) {
                                Image(systemName: action.systemImage)
                                    .frame(width: 18)

                                Text(action.title)
                            }
                        }

                        Spacer()

                        Button {
                            appModel.moveAction(action, direction: .up)
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.borderless)
                        .disabled(appModel.canMoveAction(action, direction: .up) == false)
                        .help("Move up")

                        Button {
                            appModel.moveAction(action, direction: .down)
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.borderless)
                        .disabled(appModel.canMoveAction(action, direction: .down) == false)
                        .help("Move down")
                    }
                }
            }

            Divider()

            ForEach(appModel.actionOrder) { action in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.title)
                        Text(action.systemImage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(recordingAction == action ? "Press Keys…" : appModel.shortcutLabel(for: action)) {
                        shortcutErrorMessage = nil
                        recordingAction = recordingAction == action ? nil : action
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            Divider()

            Text("Recorded shortcuts are saved automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Copyright 2026 Khondhaker Al Momin")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 520)
        .background(keyRecorder)
        .onAppear {
            launchAtLogin = appModel.launchAtLoginManager.isEnabled
        }
    }

    private var keyRecorder: some View {
        KeyRecorderView(recordingAction: $recordingAction, onCancel: {
            recordingAction = nil
            shortcutErrorMessage = nil
        }) { keyCode, modifiers in
            guard let action = recordingAction else {
                return
            }

            let filtered = modifiers.intersection([.command, .option, .control, .shift])
            guard filtered.isEmpty == false else {
                shortcutErrorMessage = "Shortcuts must include Command, Option, Control, or Shift."
                recordingAction = nil
                return
            }

            let shortcut = Shortcut(keyCode: UInt32(keyCode), modifiers: UInt32(filtered.rawValue))
            if let existingAction = appModel.shortcutStore.action(using: shortcut, excluding: action) {
                shortcutErrorMessage = "\"\(shortcut.displayString)\" is already assigned to \(existingAction.title)."
                recordingAction = nil
                return
            }

            appModel.shortcutStore.update(shortcut: shortcut, for: action)
            shortcutErrorMessage = nil
            recordingAction = nil
        }
        .frame(width: 0, height: 0)
    }
}

private struct KeyRecorderView: NSViewRepresentable {
    @Binding var recordingAction: FinderActionService.Action?
    let onCancel: () -> Void
    let onRecord: (UInt16, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onCancel = onCancel
        view.onRecord = onRecord
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.isRecording = recordingAction != nil
        nsView.onCancel = onCancel
        nsView.onRecord = onRecord
        if recordingAction != nil, nsView.window != nil {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyRecorderNSView: NSView {
    var onCancel: (() -> Void)?
    var onRecord: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == UInt16(kVK_Escape) {
            onCancel?()
            return
        }

        onRecord?(event.keyCode, event.modifierFlags)
    }
}
