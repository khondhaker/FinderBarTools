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
        if let specialKey = Self.specialKeyDisplay[keyCode] {
            return specialKey
        }

        if let translatedKey = Self.translatedKeyDisplay(for: UInt16(keyCode)) {
            return translatedKey
        }

        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_V): return "V"
        default: return "Key \(keyCode)"
        }
    }

    private static let specialKeyDisplay: [UInt32: String] = [
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_Escape): "Esc",
        UInt32(kVK_LeftArrow): "\u{2190}",
        UInt32(kVK_RightArrow): "\u{2192}",
        UInt32(kVK_DownArrow): "\u{2193}",
        UInt32(kVK_UpArrow): "\u{2191}",
    ]

    private static func translatedKeyDisplay(for keyCode: UInt16) -> String? {
        guard let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }

        let data = unsafeBitCast(layoutData, to: CFData.self) as Data
        return data.withUnsafeBytes { rawBuffer in
            guard let keyboardLayout = rawBuffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return nil
            }

            var deadKeyState: UInt32 = 0
            var actualLength = 0
            var unicodeChars = [UniChar](repeating: 0, count: 4)

            let status = UCKeyTranslate(
                keyboardLayout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                unicodeChars.count,
                &actualLength,
                &unicodeChars
            )

            guard status == noErr, actualLength > 0 else {
                return nil
            }

            let string = String(utf16CodeUnits: unicodeChars, count: actualLength)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard string.isEmpty == false else {
                return nil
            }

            return string.count == 1 ? string.uppercased() : string
        }
    }
}
