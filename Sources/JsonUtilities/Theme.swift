import SwiftUI

/// The four built-in colour themes.
public enum ThemeID: String, CaseIterable, Identifiable {
    case midnight
    case graphite
    case frost
    case paper

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        case .frost:    return "Frost"
        case .paper:    return "Paper"
        }
    }
}

/// A resolved colour set for one theme.
public struct Theme {
    public let bg: Color
    public let chrome: Color
    public let bar: Color
    public let pane: Color
    public let paneHeader: Color
    public let text: Color
    public let muted: Color
    public let gutter: Color
    public let border: Color
    public let track: Color
    public let segActive: Color
    public let accent: Color
    public let accentText: Color
    public let key: Color
    public let string: Color
    public let number: Color
    public let boolean: Color
    public let null: Color
    public let punct: Color
    public let errorBg: Color
    public let errorText: Color

    public static func palette(_ id: ThemeID) -> Theme {
        switch id {
        case .midnight:
            return Theme(
                bg: .hex(0x0f1117), chrome: .hex(0x161a24), bar: .hex(0x12151d),
                pane: .hex(0x12151d), paneHeader: .hex(0x161a24), text: .hex(0xc9cdda),
                muted: .hex(0x5b6076), gutter: .hex(0x363b4d), border: .whiteAlpha(0.06),
                track: .hex(0x0b0d13), segActive: .hex(0x232838), accent: .hex(0x6ea8fe),
                accentText: .hex(0x0b0d13), key: .hex(0x79c0ff), string: .hex(0xe0b078),
                number: .hex(0x67d4b5), boolean: .hex(0xc792ea), null: .hex(0xff7a93),
                punct: .hex(0x5b6076), errorBg: .hex(0xff7a93, alpha: 0.10), errorText: .hex(0xff9db0))
        case .graphite:
            return Theme(
                bg: .hex(0x1b1b1d), chrome: .hex(0x242427), bar: .hex(0x1f1f22),
                pane: .hex(0x1f1f22), paneHeader: .hex(0x242427), text: .hex(0xe3e3e6),
                muted: .hex(0x87878e), gutter: .hex(0x4a4a52), border: .whiteAlpha(0.07),
                track: .hex(0x151517), segActive: .hex(0x323236), accent: .hex(0xa8c7fa),
                accentText: .hex(0x1a1a1a), key: .hex(0x9ecbff), string: .hex(0xd3a06b),
                number: .hex(0x8bd5b0), boolean: .hex(0xc9a0f0), null: .hex(0xf09199),
                punct: .hex(0x87878e), errorBg: .hex(0xf09199, alpha: 0.10), errorText: .hex(0xf09199))
        case .frost:
            return Theme(
                bg: .hex(0x2e3440), chrome: .hex(0x3b4252), bar: .hex(0x323846),
                pane: .hex(0x323846), paneHeader: .hex(0x3b4252), text: .hex(0xe5e9f0),
                muted: .hex(0x7b8394), gutter: .hex(0x4c566a), border: .whiteAlpha(0.07),
                track: .hex(0x2a303c), segActive: .hex(0x434c5e), accent: .hex(0x88c0d0),
                accentText: .hex(0x2e3440), key: .hex(0x8fbcbb), string: .hex(0xa3be8c),
                number: .hex(0xa3be8c), boolean: .hex(0xebcb8b), null: .hex(0xbf616a),
                punct: .hex(0x7b8394), errorBg: .hex(0xbf616a, alpha: 0.15), errorText: .hex(0xd08770))
        case .paper:
            return Theme(
                bg: .hex(0xf4f2ec), chrome: .hex(0xe9e6de), bar: .hex(0xf0ede6),
                pane: .hex(0xffffff), paneHeader: .hex(0xf0ede6), text: .hex(0x2b2a26),
                muted: .hex(0x8c887c), gutter: .hex(0xc3bfb2), border: .blackAlpha(0.09),
                track: .hex(0xe2ded4), segActive: .hex(0xffffff), accent: .hex(0x3a6ea5),
                accentText: .hex(0xffffff), key: .hex(0x2563a8), string: .hex(0xa15a24),
                number: .hex(0x2f7a4f), boolean: .hex(0x7a4bc0), null: .hex(0xc0392b),
                punct: .hex(0x9a978c), errorBg: .hex(0xc0392b, alpha: 0.10), errorText: .hex(0xb23524))
        }
    }
}

extension Color {
    static func hex(_ value: UInt32, alpha: Double = 1) -> Color {
        Color(.sRGB,
              red: Double((value >> 16) & 0xff) / 255,
              green: Double((value >> 8) & 0xff) / 255,
              blue: Double(value & 0xff) / 255,
              opacity: alpha)
    }
    static func whiteAlpha(_ a: Double) -> Color { Color(.sRGB, white: 1, opacity: a) }
    static func blackAlpha(_ a: Double) -> Color { Color(.sRGB, white: 0, opacity: a) }
}
