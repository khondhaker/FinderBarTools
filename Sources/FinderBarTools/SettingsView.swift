import Carbon
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var recordingAction: FinderActionService.Action?
    @State private var launchAtLogin = false

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

            Divider()

            ForEach(FinderActionService.Action.allCases) { action in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.title)
                        Text(action.systemImage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(recordingAction == action ? "Press Keys…" : appModel.shortcutLabel(for: action)) {
                        recordingAction = action
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            Divider()

            Text("Recorded shortcuts are saved automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 520)
        .background(keyRecorder)
        .onAppear {
            launchAtLogin = appModel.launchAtLoginManager.isEnabled
        }
    }

    private var keyRecorder: some View {
        KeyRecorderView(recordingAction: $recordingAction) { keyCode, modifiers in
            guard let action = recordingAction else {
                return
            }

            let filtered = modifiers.intersection([.command, .option, .control, .shift])
            guard filtered.isEmpty == false else {
                return
            }

            let shortcut = Shortcut(keyCode: UInt32(keyCode), modifiers: UInt32(filtered.rawValue))
            appModel.shortcutStore.update(shortcut: shortcut, for: action)
            recordingAction = nil
        }
        .frame(width: 0, height: 0)
    }
}

private struct KeyRecorderView: NSViewRepresentable {
    @Binding var recordingAction: FinderActionService.Action?
    let onRecord: (UInt16, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onRecord = onRecord
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.isRecording = recordingAction != nil
        if recordingAction != nil, nsView.window != nil {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyRecorderNSView: NSView {
    var onRecord: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        onRecord?(event.keyCode, event.modifierFlags)
    }
}
