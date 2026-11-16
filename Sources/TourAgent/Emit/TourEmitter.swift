//  WHAT: The files written from the call's lines rather than a template: the look (each role's Swift), the launch
//        (each destination's state) and the content (each tab's tips, each feature page, each palette). Written with
//        the call's prefix in place, so no word of the call is ever renamed.

import Foundation

enum TourEmitter {
    /// `TourLook.swift`: one static member a role the parts read.
    static func look(_ spec: TourSpec) -> String {
        let p = spec.prefix
        var lines = ["import SwiftUI"] + spec.imports.map { "import \($0)" }
        lines += [
            "",
            "/// The tour's look: every colour and font its views read, named once. A role the call did not map keeps the",
            "/// system's value, so the views build in any app.",
            "enum \(p)Look {",
        ]
        var first = true
        for role in TourLookRoles.all where role.part.map(spec.parts.contains) ?? true {
            var swift = spec.look[role.role] ?? role.fallback
            if role.role == "scrim" { swift += ".opacity(\(spec.tuning["scrim.opacity"]?.swift ?? "0.55"))" }
            if !first { lines.append("") }
            first = false
            lines.append("    /// \(sentence(role.what))")
            lines.append("    static var \(role.role): \(role.kind.rawValue) { \(swift) }")
        }
        lines.append("}")
        return TemplateRender.tidy(lines)
    }

    /// `TourLaunch.swift`: the `-destination` launch argument, read, and the state each destination opens in.
    static func launch(_ spec: TourSpec) -> String {
        let p = spec.prefix
        var lines = [
            "import Foundation",
            "",
            "/// Where a launch opens the tour. The `-destination <name>` launch argument, which UserDefaults reads, is how UI",
            "/// tests and screenshots open a screen with no tap.",
            "enum \(p)Launch {",
        ]
        if spec.layer {
            lines += [
                "    /// The state the first-run layer opens in.",
                "    enum Start: Equatable, Sendable {",
                "        /// What this device remembers: \(spec.parts.contains(.welcome) ? "the welcome until it is passed, then " : "")each tab's tips until they are done.",
                "        case remembered",
            ]
            if spec.parts.contains(.welcome) {
                lines += ["        /// The welcome card, as on a first run.", "        case welcome"]
            }
            if spec.parts.contains(.tips) {
                lines += ["        /// \(spec.parts.contains(.welcome) ? "The welcome passed, and" : "Only") this tab's tips up.", "        case tips(String)"]
            }
            lines += ["        /// The first run over: the layer draws nothing.", "        case done", "    }", ""]
        }
        lines += [
            "    /// The `-destination` launch argument, when the app was launched with one.",
            "    static var destination: String? {",
            "        UserDefaults.standard.string(forKey: \"destination\")",
            "    }",
        ]
        if spec.layer {
            let states = spec.launch.compactMap { launch -> String? in
                switch launch.state {
                case .welcome: return "        case \(SwiftLiteral.string(launch.destination)): return .welcome"
                case .tips(let tab): return "        case \(SwiftLiteral.string(launch.destination)): return .tips(\(SwiftLiteral.string(tab)))"
                case .done: return "        case \(SwiftLiteral.string(launch.destination)): return .done"
                case .about: return nil
                }
            }
            lines += [
                "",
                "    /// The state the first-run layer opens in. With no destination it is what this device remembers; a",
                "    /// destination named here opens its state; any other opens with the first run over, so nothing covers it.",
                "    static var start: Start {",
                "        guard let destination, !destination.isEmpty else { return .remembered }",
            ]
            if states.isEmpty {
                lines += ["        return .done"]
            } else {
                lines += ["        switch destination {"] + states + ["        default: return .done", "        }"]
            }
            lines += ["    }"]
        }
        if spec.parts.contains(.about) {
            let pages = spec.launch.compactMap { launch -> String? in
                guard case .about(let page) = launch.state else { return nil }
                return "        case \(SwiftLiteral.string(launch.destination)): return \(page)"
            }
            lines += ["", "    /// The page the about pager opens on: 0 is its cover."]
            if pages.isEmpty {
                lines += ["    static var aboutPage: Int { 0 }"]
            } else {
                lines += [
                    "    static var aboutPage: Int {",
                    "        guard let destination else { return 0 }",
                    "        switch destination {",
                ] + pages + ["        default: return 0", "        }", "    }"]
            }
        }
        lines.append("}")
        return TemplateRender.tidy(lines)
    }

    /// `TourContent.swift`: each tab's tips and the feature pages, as the call gave them, and the palettes they name.
    static func content(_ spec: TourSpec) -> String {
        let p = spec.prefix
        let tips = spec.parts.contains(.tips), about = spec.parts.contains(.about)
        var lines = [about ? "import SwiftUI" : "import Foundation", ""]
        if tips {
            lines += [
                "/// A tip of a tab's tour: one control, said in a title and a line, in a card under it.",
                "struct \(p)Tip: Hashable, Sendable {",
                "    /// Where the card stands: under the bar's control it explains, over the tab bar, or centred.",
                "    enum Place: Hashable, Sendable {",
                "        case topLeading, topTrailing, bottomLeading, bottomTrailing, center",
                "    }",
                "",
                "    var title: String",
                "    var body: String",
                "    var symbol: String?",
                "    var place: Place",
                "}",
                "",
            ]
        }
        if about {
            lines += [
                "/// A feature page of the about pager: the feature's symbol and palette, its name, tagline and description, and",
                "/// the rows that say what it does.",
                "struct \(p)Page: Hashable, Sendable {",
                "    /// A row of a page: one thing the feature does.",
                "    struct Row: Hashable, Sendable {",
                "        var symbol: String",
                "        var text: String",
                "    }",
                "",
                "    var name: String",
                "    var tagline: String",
                "    var description: String",
                "    var symbol: String",
                "    /// The colours of the gradient behind the page.",
                "    var palette: [Color]",
                "    var rows: [Row]",
                "}",
                "",
            ]
        }
        lines += ["/// What the tour shows, as the call gave it.", "enum \(p)Content {"]
        if tips {
            lines += ["    /// Each tab's tips, by the tab's name."]
            if spec.tips.isEmpty {
                lines += ["    static let tips: [String: [\(p)Tip]] = [:]"]
            } else {
                lines += ["    static let tips: [String: [\(p)Tip]] = ["]
                for (tab, list) in spec.tips {
                    lines += ["        \(SwiftLiteral.string(tab)): ["]
                    for tip in list {
                        lines += [
                            "            \(p)Tip(",
                            "                title: \(SwiftLiteral.string(tip.title)),",
                            "                body: \(SwiftLiteral.string(tip.body)),",
                            "                symbol: \(tip.symbol.map(SwiftLiteral.string) ?? "nil"),",
                            "                place: .\(tip.place.rawValue)",
                            "            ),",
                        ]
                    }
                    lines += ["        ],"]
                }
                lines += ["    ]"]
            }
            lines += [
                "",
                "    /// The tabs with tips, in the order the call named them.",
                "    static let tabs: [String] = [\(spec.tabs.map(SwiftLiteral.string).joined(separator: ", "))]",
            ]
        }
        if about {
            if tips { lines.append("") }
            lines += [
                "    /// The palette behind the cover.",
                "    static let cover: [Color] = \(p)Palette.\(spec.cover)",
                "",
                "    /// The feature pages, after the cover.",
            ]
            if spec.pages.isEmpty {
                lines += ["    static let pages: [\(p)Page] = []"]
            } else {
                let fallbackRow = spec.tuning["symbol.row"].flatMap { value -> String? in
                    if case .symbol(let name) = value { return name }
                    return nil
                } ?? "checkmark.circle"
                lines += ["    static let pages: [\(p)Page] = ["]
                for page in spec.pages {
                    lines += [
                        "        \(p)Page(",
                        "            name: \(SwiftLiteral.string(page.name)),",
                        "            tagline: \(SwiftLiteral.string(page.tagline)),",
                        "            description: \(SwiftLiteral.string(page.description)),",
                        "            symbol: \(SwiftLiteral.string(page.symbol)),",
                        "            palette: \(p)Palette.\(page.palette ?? spec.cover),",
                    ]
                    if page.rows.isEmpty {
                        lines += ["            rows: []"]
                    } else {
                        lines += ["            rows: ["]
                        for row in page.rows {
                            lines += ["                \(p)Page.Row(symbol: \(SwiftLiteral.string(row.symbol ?? fallbackRow)), text: \(SwiftLiteral.string(row.text))),"]
                        }
                        lines += ["            ]"]
                    }
                    lines += ["        ),"]
                }
                lines += ["    ]"]
            }
        }
        lines.append("}")
        if about {
            lines += [
                "",
                "/// The palettes the about pager's gradient is drawn from: the first colour of each is its base.",
                "enum \(p)Palette {",
            ]
            for (index, palette) in spec.usedPalettes.enumerated() {
                if index > 0 { lines.append("") }
                lines += [
                    "    /// " + palette.colors.map { "#" + SwiftLiteral.hex($0).dropFirst(2) }.joined(separator: " "),
                    "    static let \(palette.name): [Color] = [",
                ]
                lines += palette.colors.map { "        " + SwiftLiteral.color($0) + "," }
                lines.append("    ]")
            }
            lines.append("}")
        }
        return TemplateRender.tidy(lines)
    }

    /// `the welcome card's title` as a doc comment's sentence: `The welcome card's title.`
    static func sentence(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst() + (text.hasSuffix(".") ? "" : ".")
    }
}
