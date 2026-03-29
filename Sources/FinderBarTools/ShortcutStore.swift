import AppKit
import Carbon
import Foundation

@MainActor
final class ShortcutStore: ObservableObject {
    @Published private(set) var shortcuts: [FinderActionService.Action: Shortcut]

    private let defaultsKey = "finderBarTools.shortcuts"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([String: Shortcut].self, from: data) {
            shortcuts = Dictionary(
                uniqueKeysWithValues: decoded.compactMap { key, value in
                    FinderActionService.Action(rawValue: key).map { ($0, value) }
                }
            )
        } else {
            shortcuts = Self.defaultShortcuts
        }
    }

    func shortcut(for action: FinderActionService.Action) -> Shortcut {
        shortcuts[action] ?? Self.defaultShortcuts[action]!
    }

    func update(shortcut: Shortcut, for action: FinderActionService.Action) {
        shortcuts[action] = shortcut
        persist()
    }

    private func persist() {
        let payload = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(payload) else {
            return
        }

        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static let defaultModifiers = UInt32(
        NSEvent.ModifierFlags.command.rawValue
        | NSEvent.ModifierFlags.option.rawValue
        | NSEvent.ModifierFlags.control.rawValue
    )

    private static let defaultShortcuts: [FinderActionService.Action: Shortcut] = [
        .newTextFile: Shortcut(keyCode: UInt32(kVK_ANSI_N), modifiers: defaultModifiers),
        .openTerminalHere: Shortcut(keyCode: UInt32(kVK_ANSI_T), modifiers: defaultModifiers),
        .openITermHere: Shortcut(keyCode: UInt32(kVK_ANSI_I), modifiers: defaultModifiers),
        .copyPath: Shortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: defaultModifiers),
    ]
}
