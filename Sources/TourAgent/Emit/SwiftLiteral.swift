//  WHAT: A value as Swift source writes it: a string as a literal a person would type (`"Everything\nSeer can do."`,
//        an em dash as itself), a number as short as it reads (`42`, `0.55`, `0.0525`).

import Foundation

enum SwiftLiteral {
    /// `text` as a Swift string literal, quotes included: a line break as `\n`, a quote as `\"`, a backslash as `\\`,
    /// so nothing in the words becomes interpolation.
    static func string(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\t": out += "\\t"
            case "\r": out += "\\r"
            default:
                if scalar.value < 0x20 || scalar.value == 0x7F {
                    out += "\\u{" + String(scalar.value, radix: 16, uppercase: true) + "}"
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out + "\""
    }

    /// `value` as short as it reads: `42`, `0.55`, `0.0525`, `-1`.
    static func number(_ value: Double) -> String {
        if value == value.rounded(), abs(value) < 1e12 { return String(Int64(value)) }
        return "\(value)"
    }

    /// A colour channel's byte as the share `Color(red:green:blue:)` takes, to three places: `0x21` → `0.129`.
    static func channel(_ byte: UInt32) -> String {
        number((Double(byte & 0xFF) / 255 * 1000).rounded() / 1000)
    }

    /// `Color(red: 0.129, green: 0.78, blue: 0.678)`: a colour's 24 bits as SwiftUI takes them.
    static func color(_ value: UInt32) -> String {
        "Color(red: \(channel(value >> 16)), green: \(channel(value >> 8)), blue: \(channel(value)))"
    }

    /// `0x21C7AD`: a colour's 24 bits as a person writes them.
    static func hex(_ value: UInt32) -> String {
        let digits = String(value, radix: 16, uppercase: true)
        return "0x" + String(repeating: "0", count: max(0, 6 - digits.count)) + digits
    }
}
