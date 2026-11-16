//  WHAT: What Swift accepts as a name, and what an SF Symbol's name looks like: a type, a module, a member, a prefix
//        for the kit's types and the modifier named after it.

import Foundation

enum SwiftName {
    /// `Tour`, `SeerMark`: UpperCamelCase letters and digits.
    static func isTypeName(_ text: String) -> Bool {
        text.range(of: #"^[A-Z][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    /// `SeerKit`, `Foundation`: what an `import` names.
    static func isModuleName(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    /// `aurora`, `sunrise`: a static member Swift accepts without backticks.
    static func isMemberName(_ text: String) -> Bool {
        text.range(of: #"^[a-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil && !keywords.contains(text)
    }

    /// `infinity`, `wallet.bifold`, `point.3.connected.trianglepath.dotted`: an SF Symbol's name.
    static func isSymbol(_ text: String) -> Bool {
        text.range(of: #"^[a-z0-9]+(\.[a-z0-9]+)*$"#, options: .regularExpression) != nil
    }

    /// `Tour` → `tour`, `UIKit` → `uiKit`, `SDK` → `sdk`: a type prefix as the name of the modifier it gives.
    static func lowerCamel(_ text: String) -> String {
        let characters = Array(text)
        var upper = 0
        while upper < characters.count, characters[upper].isUppercase { upper += 1 }
        guard upper > 0 else { return text }
        // A run of capitals before a lowercase letter keeps its last capital: `UIKit` is `uiKit`, not `uikit`.
        let lowered = upper == characters.count || upper == 1 ? upper : upper - 1
        return String(characters[..<lowered]).lowercased() + String(characters[lowered...])
    }

    /// The words Swift reserves, which a member or a modifier may not be named without backticks.
    static let keywords: Set<String> = [
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout",
        "internal", "let", "open", "operator", "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var", "break", "case", "catch", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw", "switch", "where", "while", "as", "false",
        "is", "nil", "self", "super", "throws", "true", "try", "any", "some", "await", "async",
    ]
}
