//  WHAT: A value as a line writes it, made the text it says: quotes taken off, `\n` a line break, `\"` a quote.
//  PIN:  A LINE BREAK IS SAID EITHER WAY. A host that wrote `\n` in its JSON hands the line a real line break, one that
//        wrote `\\n` hands it a backslash and an n; both are the break the words ask for.

import Foundation

enum Unquote {
    /// `"Everything\nSeer can do."` → `Everything⏎Seer can do.`; a value without quotes is read the same way, trimmed.
    static func text(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespaces)
        if value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\""), !value.hasSuffix("\\\"") || value.hasSuffix("\\\\\"") {
            value = String(value.dropFirst().dropLast())
        }
        return unescaped(value)
    }

    /// `\n`, `\t`, `\"` and `\\` as the characters they stand for; any other backslash is kept as it is.
    static func unescaped(_ text: String) -> String {
        var out = ""
        var escaped = false
        for character in text {
            if escaped {
                switch character {
                case "n": out.append("\n")
                case "t": out.append("\t")
                case "\"": out.append("\"")
                case "\\": out.append("\\")
                default: out.append("\\"); out.append(character)
                }
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else {
                out.append(character)
            }
        }
        if escaped { out.append("\\") }
        return out
    }

    /// Whether `text` closes every bracket and quote it opens, as Swift written on one line must.
    static func isBalanced(_ text: String) -> Bool {
        var stack: [Character] = []
        var quoted = false, escaped = false
        let pairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
        for character in text {
            if quoted {
                if escaped { escaped = false } else if character == "\\" { escaped = true } else if character == "\"" { quoted = false }
                continue
            }
            switch character {
            case "\"": quoted = true
            case "(", "[", "{": stack.append(character)
            case ")", "]", "}":
                guard stack.popLast() == pairs[character] else { return false }
            default: break
            }
        }
        return stack.isEmpty && !quoted
    }
}
