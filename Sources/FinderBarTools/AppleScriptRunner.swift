import Foundation

enum AppleScriptRunner {
    enum ScriptError: LocalizedError {
        case compileFailed
        case executionFailed(details: String)

        var errorDescription: String? {
            switch self {
            case .compileFailed:
                return "AppleScript compilation failed."
            case .executionFailed(let details):
                return details
            }
        }
    }

    static func run(_ source: String) throws {
        guard let script = NSAppleScript(source: source) else {
            throw ScriptError.compileFailed
        }

        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            throw ScriptError.executionFailed(details: errorInfo.description)
        }
    }
}
