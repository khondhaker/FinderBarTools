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

    @Published private var disabledActionIDs: Set<String> {
        didSet { persistDisabledActions() }
    }

    @Published private(set) var actionOrder: [FinderActionService.Action] {
        didSet { persistActionOrder() }
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
        self.disabledActionIDs = Self.loadDisabledActionIDs()
        self.actionOrder = Self.loadActionOrder()

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

    private func persistDisabledActions() {
        let validIDs = Set(FinderActionService.Action.allCases.map(\.id))
        let payload = disabledActionIDs.intersection(validIDs).sorted()
        UserDefaults.standard.set(payload, forKey: "disabledActionIDs")
    }

    private static func loadDisabledActionIDs() -> Set<String> {
        let validIDs = Set(FinderActionService.Action.allCases.map(\.id))
        let storedIDs = UserDefaults.standard.stringArray(forKey: "disabledActionIDs") ?? []
        return Set(storedIDs).intersection(validIDs)
    }

    private func persistActionOrder() {
        UserDefaults.standard.set(actionOrder.map(\.id), forKey: "actionOrder")
    }

    private static func loadActionOrder() -> [FinderActionService.Action] {
        let storedIDs = UserDefaults.standard.stringArray(forKey: "actionOrder") ?? []
        var seenIDs = Set<String>()
        let storedActions = storedIDs.compactMap { id -> FinderActionService.Action? in
            guard seenIDs.insert(id).inserted else { return nil }
            return FinderActionService.Action(rawValue: id)
        }
        let missingActions = FinderActionService.Action.displayOrder.filter { storedActions.contains($0) == false }
        let orderedActions = storedActions + missingActions

        return orderedActions.isEmpty ? FinderActionService.Action.displayOrder : orderedActions
    }

    func isActionEnabled(_ action: FinderActionService.Action) -> Bool {
        disabledActionIDs.contains(action.id) == false
    }

    func enabledActionsInPreferredOrder() -> [FinderActionService.Action] {
        actionOrder.filter { isActionEnabled($0) }
    }

    func setAction(_ action: FinderActionService.Action, enabled: Bool) {
        if enabled {
            disabledActionIDs.remove(action.id)
        } else {
            disabledActionIDs.insert(action.id)

            if runningAction?.action == action {
                runningAction = nil
            }

            if actionFeedback?.action == action {
                actionFeedback = nil
            }
        }
    }

    func moveAction(_ action: FinderActionService.Action, direction: ActionMoveDirection) {
        guard let currentIndex = actionOrder.firstIndex(of: action) else { return }

        let destinationIndex: Int
        switch direction {
        case .up:
            destinationIndex = actionOrder.index(before: currentIndex)
        case .down:
            destinationIndex = actionOrder.index(after: currentIndex)
        }

        guard actionOrder.indices.contains(destinationIndex) else { return }
        actionOrder.swapAt(currentIndex, destinationIndex)
    }

    func canMoveAction(_ action: FinderActionService.Action, direction: ActionMoveDirection) -> Bool {
        guard let index = actionOrder.firstIndex(of: action) else { return false }

        switch direction {
        case .up:
            return index > actionOrder.startIndex
        case .down:
            return index < actionOrder.index(before: actionOrder.endIndex)
        }
    }

    func run(_ action: FinderActionService.Action) {
        guard isActionEnabled(action) else { return }

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

enum ActionMoveDirection {
    case up
    case down
}
