import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published var lastErrorMessage: String?

    init() {
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            isEnabled = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else {
            lastErrorMessage = "Launch at Login requires macOS 13 or newer."
            return
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            isEnabled = (SMAppService.mainApp.status == .enabled)
            lastErrorMessage = nil
        } catch {
            isEnabled = (SMAppService.mainApp.status == .enabled)
            lastErrorMessage = error.localizedDescription
        }
    }
}
