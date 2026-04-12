import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    struct RunningAction: Equatable {
        let action: FinderActionService.Action
        let message: String
    }

    struct ActionFeedback: Equatable {
        let action: FinderActionService.Action
        let message: String
        let isError: Bool
        let usesClipboardPulse: Bool
    }

    let actionService = FinderActionService()
    let shortcutStore = ShortcutStore()
    let launchAtLoginManager = LaunchAtLoginManager()
    private var hotkeyManager: HotKeyManager?
    private var feedbackDismissTask: Task<Void, Never>?

    /// Whether the menu bar icon should be rendered with color.
    @Published var iconColorEnabled: Bool {
        didSet { UserDefaults.standard.set(iconColorEnabled, forKey: "iconColorEnabled") }
    }

    /// The user-chosen icon tint color, stored as RGB components.
    @Published var iconColor: Color {
        didSet { persistIconColor() }
    }

    @Published private(set) var runningAction: RunningAction?
    @Published private(set) var actionFeedback: ActionFeedback?

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
        feedbackDismissTask?.cancel()

        withAnimation(.easeInOut(duration: 0.16)) {
            runningAction = .init(action: action, message: action.runningMessage)
            actionFeedback = nil
        }

        Task { @MainActor [weak self] in
            await Task.yield()

            guard let self else { return }

            let result = self.actionService.run(action)

            withAnimation(.easeOut(duration: 0.16)) {
                self.runningAction = nil
            }

            switch result {
            case .success:
                self.presentFeedback(
                    .init(
                        action: action,
                        message: action.successMessage,
                        isError: false,
                        usesClipboardPulse: action.usesClipboardPulse
                    ),
                    duration: 1.8
                )
            case .failure(let error):
                self.presentFeedback(
                    .init(
                        action: action,
                        message: error.localizedDescription,
                        isError: true,
                        usesClipboardPulse: false
                    ),
                    duration: 4.0
                )
            }
        }
    }

    func shortcutLabel(for action: FinderActionService.Action) -> String {
        shortcutStore.shortcut(for: action).displayString
    }

    func isPresetIconColor(_ color: Color) -> Bool {
        colorComponentsMatch(iconColor, color)
    }

    private func colorComponentsMatch(_ lhs: Color, _ rhs: Color) -> Bool {
        guard let lhsComponents = NSColor(lhs).usingColorSpace(.sRGB),
              let rhsComponents = NSColor(rhs).usingColorSpace(.sRGB) else {
            return false
        }

        let tolerance = 0.001
        return abs(lhsComponents.redComponent - rhsComponents.redComponent) < tolerance
            && abs(lhsComponents.greenComponent - rhsComponents.greenComponent) < tolerance
            && abs(lhsComponents.blueComponent - rhsComponents.blueComponent) < tolerance
    }

    private func presentFeedback(_ feedback: ActionFeedback, duration: TimeInterval) {
        feedbackDismissTask?.cancel()

        withAnimation(.spring(response: 0.24, dampingFraction: 0.85)) {
            actionFeedback = feedback
        }

        feedbackDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    self?.actionFeedback = nil
                }
            }
        }
    }
}
