import AppKit

struct FinderActionService {
    enum Action: String, CaseIterable, Identifiable {
        case newTextFile
        case openTerminalHere
        case openITermHere
        case copyPath
        case openVSCodeHere
        case openAntigravityHere

        var id: String { rawValue }

        static let displayOrder: [Action] = [
            .newTextFile,
            .openTerminalHere,
            .openITermHere,
            .openVSCodeHere,
            .openAntigravityHere,
            .copyPath,
        ]

        var title: String {
            switch self {
            case .newTextFile:
                return "New Text File"
            case .openTerminalHere:
                return "Open Terminal Here"
            case .openITermHere:
                return "Open iTerm Here"
            case .copyPath:
                return "Copy Path"
            case .openVSCodeHere:
                return "Open in VS Code"
            case .openAntigravityHere:
                return "Open in Antigravity"
            }
        }

        var successMessage: String {
            switch self {
            case .newTextFile:
                return "Created new text file"
            case .openTerminalHere:
                return "Opened Terminal in Finder folder"
            case .openITermHere:
                return "Opened iTerm in Finder folder"
            case .copyPath:
                return "Copied folder path"
            case .openVSCodeHere:
                return "Opened folder in VS Code"
            case .openAntigravityHere:
                return "Opened folder in Antigravity"
            }
        }

        var runningMessage: String {
            switch self {
            case .newTextFile:
                return "Creating text file..."
            case .openTerminalHere:
                return "Opening Terminal..."
            case .openITermHere:
                return "Opening iTerm..."
            case .copyPath:
                return "Copying path..."
            case .openVSCodeHere:
                return "Opening VS Code..."
            case .openAntigravityHere:
                return "Opening Antigravity..."
            }
        }

        var usesClipboardPulse: Bool {
            self == .copyPath
        }

        var systemImage: String {
            switch self {
            case .newTextFile:
                return "doc.badge.plus"
            case .openTerminalHere:
                return "terminal"
            case .openITermHere:
                return "terminal"
            case .copyPath:
                return "doc.on.clipboard"
            case .openVSCodeHere:
                return "curlybraces"
            case .openAntigravityHere:
                return "sparkles"
            }
        }

        /// Bundle identifier used to load the real app icon for actions that launch external apps.
        var appBundleIdentifier: String? {
            switch self {
            case .openITermHere:
                return "com.googlecode.iterm2"
            case .openVSCodeHere:
                return "com.microsoft.VSCode"
            case .openAntigravityHere:
                return "com.google.antigravity"
            default:
                return nil
            }
        }
    }

    @discardableResult
    func run(_ action: Action) -> Result<Void, Error> {
        let script: String
        let finderContextScript = """
        tell application "Finder"
            if not (exists Finder window 1) and (count of selection) > 0 then
                set selectedItem to item 1 of (get selection)
                if class of selectedItem is folder then
                    set targetAlias to (selectedItem as alias)
                else
                    set targetAlias to (container of selectedItem as alias)
                end if
            else if (count of windows) > 0 then
                set targetAlias to (target of front window as alias)
            else
                set targetAlias to (desktop as alias)
            end if
        end tell

        set targetPOSIXPath to POSIX path of targetAlias
        """

        switch action {
        case .newTextFile:
            script = """
            \(finderContextScript)

            set basePath to targetPOSIXPath
            set fileName to "new document.txt"
            set newFilePath to basePath & fileName

            set counter to 1
            tell application "System Events"
                repeat while exists disk item newFilePath
                    set newFilePath to basePath & "new document " & counter & ".txt"
                    set counter to counter + 1
                end repeat
            end tell

            do shell script "touch " & quoted form of newFilePath

            tell application "Finder"
                activate
                set newItem to POSIX file newFilePath as alias
                reveal newItem
                select newItem
            end tell
            """

        case .openTerminalHere:
            script = """
            \(finderContextScript)

            tell application "Terminal"
                activate
                do script "cd " & quoted form of targetPOSIXPath & "; clear"
            end tell
            """

        case .openITermHere:
            script = """
            \(finderContextScript)

            tell application "iTerm"
                activate
                create window with default profile
                tell current session of current window
                    write text "cd " & quoted form of targetPOSIXPath & " && clear"
                end tell
            end tell
            """

        case .copyPath:
            script = """
            \(finderContextScript)

            set the clipboard to targetPOSIXPath
            display notification targetPOSIXPath with title "Path Copied"
            """

        case .openVSCodeHere:
            script = """
            \(finderContextScript)

            do shell script "open -a 'Visual Studio Code' " & quoted form of targetPOSIXPath
            """

        case .openAntigravityHere:
            script = """
            \(finderContextScript)

            do shell script "open -a 'Antigravity' " & quoted form of targetPOSIXPath
            """
        }

        do {
            try AppleScriptRunner.run(script)
            return .success(())
        } catch {
            showError(error.localizedDescription)
            return .failure(error)
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "FinderBarTools Error"
        alert.informativeText = message
        alert.runModal()
    }
}
