import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    let actionService = FinderActionService()
    let shortcutStore = ShortcutStore()
    let launchAtLoginManager = LaunchAtLoginManager()
    private var hotkeyManager: HotKeyManager?

    /// Whether the menu bar icon should be rendered with color.
    @Published var iconColorEnabled: Bool {
        didSet { UserDefaults.standard.set(iconColorEnabled, forKey: "iconColorEnabled") }
    }

    /// The user-chosen icon tint color, stored as RGB components.
    @Published var iconColor: Color {
        didSet { persistIconColor() }
    }

    static let presetIconColors: [(String, Color)] = [
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Red", .red),
        ("Orange", .orange),
        ("Green", .green),
        ("Teal", .teal),
        ("White", .white),
    ]

    init() {
        self.iconColorEnabled = UserDefaults.standard.bool(forKey: "iconColorEnabled")
        self.iconColor = Self.loadIconColor()

        hotkeyManager = HotKeyManager(shortcutStore: shortcutStore) { [weak self] action in
            self?.run(action)
        }
    }

    private func persistIconColor() {
        guard let components = NSColor(iconColor).usingColorSpace(.sRGB) else { return }
        UserDefaults.standard.set(Double(components.redComponent), forKey: "iconColorR")
        UserDefaults.standard.set(Double(components.greenComponent), forKey: "iconColorG")
        UserDefaults.standard.set(Double(components.blueComponent), forKey: "iconColorB")
    }

    private static func loadIconColor() -> Color {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "iconColorR") != nil else { return .blue }
        let r = defaults.double(forKey: "iconColorR")
        let g = defaults.double(forKey: "iconColorG")
        let b = defaults.double(forKey: "iconColorB")
        return Color(red: r, green: g, blue: b)
    }

    func run(_ action: FinderActionService.Action) {
        actionService.run(action)
    }

    func shortcutLabel(for action: FinderActionService.Action) -> String {
        shortcutStore.shortcut(for: action).displayString
    }
}
