//  WHAT: A `key = value` line, the shape of the strings, tuning, look and launch lines: cut at the first `=` that
//        stands outside quotes and brackets, so `accent = Color(white: 0.5)` and `title = "a = b"` stay whole.

import Foundation

enum Assignment {
    /// The key and the value as written, both trimmed; nil when the line has no `=` at the top level.
    static func split(_ line: String) -> (key: String, value: String)? {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let equals = LineSplit.firstTop(text, "=") else { return nil }
        let key = text[..<equals].trimmingCharacters(in: .whitespaces)
        var value = text[text.index(after: equals)...]
        // `key == value` is a mistake for `key = value`, never a comparison here.
        while value.first == "=" { value = value.dropFirst() }
        return (key, value.trimmingCharacters(in: .whitespaces))
    }
}
