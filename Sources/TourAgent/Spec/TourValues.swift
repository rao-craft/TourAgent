//  WHAT: The values a call's single fields and `key = value` lines say, read: the mark, a look role's Swift, a tuning
//        value, a string. Each reader answers the value or why it is not one, with what it accepts.

import Foundation

/// The app's mark as the welcome card and the cover draw it.
enum MarkValue: Equatable, Sendable {
    /// A view expression the app declares, like `SeerMark()`; `{size}` in it is the size the kit draws it at.
    case view(String)
    /// An SF Symbol, drawn in the accent.
    case symbol(String)

    static let fallbackSymbol = "sparkles"
    static let fallback = MarkValue.symbol(fallbackSymbol)

    /// The mark a call names, a note when it was read generously, or why it is not one.
    static func parse(_ raw: String) -> Result<(MarkValue, String?), LineError> {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if SwiftName.isSymbol(text) { return .success((.symbol(text), nil)) }
        // A bare type, `SeerMark` or `SeerKit.SeerMark`, is the view made with no arguments.
        if text.range(of: #"^[A-Z][A-Za-z0-9_]*(\.[A-Z][A-Za-z0-9_]*)*$"#, options: .regularExpression) != nil {
            return .success((.view(text + "()"), "`mark` named the type `\(text)`, so it is drawn as `\(text)()`."))
        }
        guard !text.contains("\n"), Unquote.isBalanced(text), text.first.map({ $0.isLetter || $0 == "_" }) == true else {
            return .failure(LineError("`\(raw)` is not a view expression or an SF Symbol's name: write the app's mark as Swift, like `AppMark()` or `Image(\"logo\").resizable()`, or a symbol like `sparkles`"))
        }
        return .success((.view(text.replacingOccurrences(of: "{size}", with: "size")), nil))
    }
}

/// A tuning value, read by its key's kind.
enum TuningValue: Equatable, Sendable {
    case number(Double)
    case animation(TourAnimation)
    case symbol(String)
    case palette(String)
    case flag(Bool)

    /// The Swift the views write for it.
    var swift: String {
        switch self {
        case .number(let value): return SwiftLiteral.number(value)
        case .animation(let animation): return animation.swift
        case .symbol(let name): return SwiftLiteral.string(name)
        case .palette(let name): return "." + name
        case .flag(let on): return on ? "true" : "false"
        }
    }

    var number: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var flag: Bool? {
        if case .flag(let on) = self { return on }
        return nil
    }

    static func parse(_ raw: String, as key: TourTuningKey) -> Result<TuningValue, LineError> {
        let text = Unquote.text(raw)
        switch key.kind {
        case .number(let low, let high):
            guard let value = Double(text), value.isFinite else {
                return .failure(LineError("`\(key.key)` is a number from \(SwiftLiteral.number(low)) to \(SwiftLiteral.number(high)), not `\(raw)`"))
            }
            guard value >= low, value <= high else {
                return .failure(LineError("`\(key.key)` is \(SwiftLiteral.number(low)) to \(SwiftLiteral.number(high)), not \(text)"))
            }
            return .success(.number(value))
        case .animation:
            return TourAnimation.parse(text).map { .animation($0) }
        case .symbol:
            guard SwiftName.isSymbol(text) else {
                return .failure(LineError("`\(key.key)` is an SF Symbol's name, like `\(key.fallback ?? "xmark")`, not `\(raw)`"))
            }
            return .success(.symbol(text))
        case .palette:
            var name = text
            if name.hasPrefix(".") { name.removeFirst() }
            guard SwiftName.isMemberName(name) else {
                return .failure(LineError("`\(key.key)` names one of the call's palettes, like `aurora`, not `\(raw)`"))
            }
            return .success(.palette(name))
        case .flag:
            switch text.lowercased() {
            case "true": return .success(.flag(true))
            case "false": return .success(.flag(false))
            default: return .failure(LineError("`\(key.key)` is true or false, not `\(raw)`"))
            }
        }
    }
}

enum LookValue {
    /// The Swift a role reads for `raw`: `accent` and `.accent` are `Color.accent` for a colour, `brandTitle` is
    /// `Font.brandTitle` for a font, and anything else is Swift as written.
    static func parse(_ raw: String, as role: TourLookRole) -> Result<String, LineError> {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return .failure(LineError("`\(role.role) =` gives no value")) }
        if role.kind == .design {
            var word = text
            for head in ["Font.Design.", "Design.", "."] where word.hasPrefix(head) { word.removeFirst(head.count) }
            guard let design = TourLookRoles.designs.first(where: { $0 == word.lowercased() }) else {
                return .failure(LineError("`aboutDesign` is serif, rounded, monospaced or default, not `\(raw)`"))
            }
            return .success("." + design)
        }
        if text.range(of: #"^[a-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil {
            return .success("\(role.kind.rawValue).\(text)")
        }
        if text.hasPrefix("."), text.dropFirst().first?.isLetter == true {
            return .success(role.kind.rawValue + text)
        }
        guard !text.contains("\n"), Unquote.isBalanced(text) else {
            return .failure(LineError("`\(raw)` is not Swift a \(role.kind == .color ? "colour" : "font") can be: one line with its brackets and quotes closed, like `\(role.kind == .color ? "Color.accent" : "Font.brandTitle")`"))
        }
        return .success(text)
    }
}
