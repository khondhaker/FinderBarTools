import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    let actionService = FinderActionService()
    let shortcutStore = ShortcutStore()
    let launchAtLoginManager = LaunchAtLoginManager()
    private var hotkeyManager: HotKeyManager?

    init() {
        hotkeyManager = HotKeyManager(shortcutStore: shortcutStore) { [weak self] action in
            self?.run(action)
        }
    }

    func run(_ action: FinderActionService.Action) {
        actionService.run(action)
    }

    func shortcutLabel(for action: FinderActionService.Action) -> String {
        shortcutStore.shortcut(for: action).displayString
    }
}
