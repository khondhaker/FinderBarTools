import Carbon
import Foundation

@MainActor
final class HotKeyManager {
    private var hotKeyRefs: [FinderActionService.Action: EventHotKeyRef] = [:]
    private let shortcutStore: ShortcutStore
    private let handler: (FinderActionService.Action) -> Void
    private var eventHandler: EventHandlerRef?

    init(shortcutStore: ShortcutStore, handler: @escaping (FinderActionService.Action) -> Void) {
        self.shortcutStore = shortcutStore
        self.handler = handler

        installHandler()
        registerAll()

        shortcutStore.objectWillChange.sink { [weak self] _ in
            self?.registerAll()
        }
        .store(in: &cancellables)
    }

    deinit {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    private var cancellables: Set<AnyCancellable> = []

    private func installHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData,
                  let event else { return noErr }

            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr,
                  let action = FinderActionService.Action.allCases.first(where: { $0.hotKeyID == hotKeyID.id }) else {
                return noErr
            }

            manager.handler(action)
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }

    private func registerAll() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()

        for action in FinderActionService.Action.allCases {
            var hotKeyRef: EventHotKeyRef?
            let shortcut = shortcutStore.shortcut(for: action)
            let hotKeyID = EventHotKeyID(signature: OSType(0x4642544C), id: action.hotKeyID)

            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.carbonModifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let hotKeyRef {
                hotKeyRefs[action] = hotKeyRef
            }
        }
    }
}

import Combine

private extension FinderActionService.Action {
    var hotKeyID: UInt32 {
        switch self {
        case .newTextFile:
            return 1
        case .openTerminalHere:
            return 2
        case .openITermHere:
            return 3
        case .copyPath:
            return 4
        case .openVSCodeHere:
            return 5
        case .openAntigravityHere:
            return 6
        }
    }
}
