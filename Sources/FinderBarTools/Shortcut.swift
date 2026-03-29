import AppKit
import Carbon
import Foundation

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    private var commandFlag: UInt32 { UInt32(NSEvent.ModifierFlags.command.rawValue) }
    private var optionFlag: UInt32 { UInt32(NSEvent.ModifierFlags.option.rawValue) }
    private var controlFlag: UInt32 { UInt32(NSEvent.ModifierFlags.control.rawValue) }
    private var shiftFlag: UInt32 { UInt32(NSEvent.ModifierFlags.shift.rawValue) }

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0

        if modifiers & commandFlag != 0 {
            result |= UInt32(cmdKey)
        }
        if modifiers & optionFlag != 0 {
            result |= UInt32(optionKey)
        }
        if modifiers & controlFlag != 0 {
            result |= UInt32(controlKey)
        }
        if modifiers & shiftFlag != 0 {
            result |= UInt32(shiftKey)
        }

        return result
    }

    var displayString: String {
        var parts: [String] = []

        if modifiers & controlFlag != 0 {
            parts.append("⌃")
        }
        if modifiers & optionFlag != 0 {
            parts.append("⌥")
        }
        if modifiers & shiftFlag != 0 {
            parts.append("⇧")
        }
        if modifiers & commandFlag != 0 {
            parts.append("⌘")
        }

        parts.append(keyDisplay)
        return parts.joined()
    }

    private var keyDisplay: String {
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_T): return "T"
        default: return "Key \(keyCode)"
        }
    }
}
