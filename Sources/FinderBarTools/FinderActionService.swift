import AppKit

struct FinderActionService {
    enum Action: String, CaseIterable, Identifiable {
        case newTextFile
        case openTerminalHere
        case openITermHere
        case copyPath
        case openVSCodeHere

        var id: String { rawValue }

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
            }
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
            }
        }

        /// Bundle identifier used to load the real app icon for actions that launch external apps.
        var appBundleIdentifier: String? {
            switch self {
            case .openITermHere:
                return "com.googlecode.iterm2"
            case .openVSCodeHere:
                return "com.microsoft.VSCode"
            default:
                return nil
            }
        }
    }

    func run(_ action: Action) {
        let script: String

        switch action {
        case .newTextFile:
            script = """
            tell application "Finder"
                if (count of windows) is 0 then
                    display notification "No Finder window is open." with title "New Text File"
                    return
                end if

                set currentFolder to (target of front window as alias)
                set basePath to POSIX path of currentFolder
                set fileName to "new document.txt"
                set newFilePath to basePath & fileName
            end tell

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
            tell application "Finder"
                if (count of windows) is 0 then
                    display notification "No Finder window is open." with title "Open Terminal Here"
                    return
                end if

                set currentFolder to (target of front window as alias)
            end tell

            tell application "Terminal"
                activate
                do script "cd " & quoted form of POSIX path of currentFolder & "; clear"
            end tell
            """

        case .openITermHere:
            script = """
            tell application "Finder"
                if (count of windows) is 0 then
                    display notification "No Finder window is open." with title "Open iTerm Here"
                    return
                end if

                set currentFolder to (target of front window as alias)
            end tell

            tell application "iTerm"
                activate
                create window with default profile
                tell current session of current window
                    write text "cd " & quoted form of POSIX path of currentFolder & " && clear"
                end tell
            end tell
            """

        case .copyPath:
            script = """
            tell application "Finder"
                if (count of windows) is 0 then
                    display notification "No Finder window is open." with title "Copy Path"
                    return
                end if

                set currentFolder to (target of front window as alias)
                set folderPath to POSIX path of currentFolder
            end tell

            set the clipboard to folderPath
            display notification folderPath with title "Path Copied"
            """

        case .openVSCodeHere:
            script = """
            tell application "Finder"
                if (count of windows) is 0 then
                    display notification "No Finder window is open." with title "Open in VS Code"
                    return
                end if

                set currentFolder to (target of front window as alias)
            end tell

            do shell script "open -a 'Visual Studio Code' " & quoted form of POSIX path of currentFolder
            """
        }

        do {
            try AppleScriptRunner.run(script)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "FinderBarTools Error"
        alert.informativeText = message
        alert.runModal()
    }
}
