//  WHAT: What a spec writes: each file's name and text, made from its template with the spec's flags and values, or
//        from the spec's lines; the views and the support files apart, for the answer.

import Foundation

struct TourPlan: Sendable {
    struct Planned: Sendable {
        let file: TourFile
        /// `TourLayer.swift`.
        let name: String
        /// The type it is named after: `TourLayer`.
        let type: String
        let text: String
    }

    let spec: TourSpec
    let files: [Planned]

    init(_ spec: TourSpec) throws {
        self.spec = spec
        let flags = Self.flags(spec), values = Self.values(spec)
        files = try TourCatalog.files(for: spec.parts).map { file in
            let text: String
            if let template = file.template {
                text = try TemplateRender.make(template, flags: flags, prefix: spec.prefix, values: values)
            } else {
                switch file.stem {
                case "Look": text = TourEmitter.look(spec)
                case "Launch": text = TourEmitter.launch(spec)
                default: text = TourEmitter.content(spec)
                }
            }
            return Planned(file: file, name: spec.prefix + file.stem + ".swift", type: spec.prefix + file.stem, text: text)
        }
    }

    /// The views written, by type name.
    var views: [String] { files.filter { $0.file.kind == .view }.map(\.type) }

    /// The views the asked parts are built from, in the order the parts are asked.
    var expected: [String] {
        var names: [String] = []
        for part in spec.parts {
            for stem in TourCatalog.views(of: part) where !names.contains(spec.prefix + stem) { names.append(spec.prefix + stem) }
        }
        return names
    }

    /// The modifier the app applies the layer with, as a line; nil without the layer.
    var modifier: String? { spec.layer ? ".\(SwiftName.lowerCamel(spec.prefix))(tab: String)" : nil }

    /// Each root view's initializer, as a line a page body calls.
    var initializers: [String] {
        var lines: [String] = []
        if spec.layer { lines.append("\(spec.prefix)Layer(tab: String, start: \(spec.prefix)Launch.Start = \(spec.prefix)Launch.start)") }
        if spec.parts.contains(.about) { lines.append("\(spec.prefix)About(onClose: (() -> Void)? = nil)") }
        return lines
    }

    /// The UserDefaults keys the first run is kept under.
    var keys: [String] {
        var keys: [String] = []
        if spec.parts.contains(.welcome) { keys.append(spec.defaultsKey + ".welcomed") }
        if spec.parts.contains(.tips) { keys.append(spec.defaultsKey + ".finished") }
        return keys
    }

    /// The names a template's blocks are chosen by.
    static func flags(_ spec: TourSpec) -> Set<String> {
        var flags = Set(spec.parts.map { "part." + $0.rawValue })
        if spec.layer { flags.insert("layer") }
        if (spec.tuning["mark.turn"]?.number ?? 0) > 0 { flags.insert("turns") }
        if (spec.tuning["gradient.start"]?.number ?? 0) != 0 { flags.insert("gradient.starts") }
        switch spec.mark {
        case .view: flags.insert("mark.view")
        case .symbol: flags.insert("mark.symbol")
        }
        return flags
    }

    /// Every placeholder a template may name, filled from the spec.
    static func values(_ spec: TourSpec) -> [String: String] {
        var values: [String: String] = [:]
        for (key, text) in spec.strings { values["s:" + key] = SwiftLiteral.string(text) }
        for (key, value) in spec.tuning {
            switch value {
            case .number: values["n:" + key] = value.swift
            case .animation: values["a:" + key] = value.swift
            case .symbol: values["y:" + key] = value.swift
            case .palette: values["p:" + key] = value.swift
            }
        }
        values["x:modifier"] = SwiftName.lowerCamel(spec.prefix)
        values["x:welcomedKey"] = SwiftLiteral.string(spec.defaultsKey + ".welcomed")
        values["x:finishedKey"] = SwiftLiteral.string(spec.defaultsKey + ".finished")
        switch spec.mark {
        case .view(let expression):
            values["x:mark"] = expression
            values["x:markSymbol"] = SwiftLiteral.string(MarkValue.fallbackSymbol)
        case .symbol(let name):
            values["x:mark"] = "Image(systemName: \(SwiftLiteral.string(name)))"
            values["x:markSymbol"] = SwiftLiteral.string(name)
        }
        let counter = spec.strings["tip.counter"] ?? "{n} of {count}"
        values["x:counter"] = counterLiteral(counter)
        values["x:counterExample"] = SwiftLiteral.string(oneLine(counter.replacingOccurrences(of: "{n}", with: "1").replacingOccurrences(of: "{count}", with: "3")))
        values["x:doneExample"] = SwiftLiteral.string(oneLine(spec.strings["tip.done"] ?? "Got it"))
        values["x:previewTab"] = SwiftLiteral.string(spec.tabs.first ?? "main")
        values["x:imports"] = spec.imports.map { "import \($0)" }.joined(separator: "\n")
        return values
    }

    /// `{n} of {count}` as the literal the card shows it with: `"\(number) of \(count)"`.
    static func counterLiteral(_ format: String) -> String {
        var out = "\""
        var rest = Substring(format)
        while !rest.isEmpty {
            if let token = TourStrings.counterTokens.keys.first(where: { rest.hasPrefix($0) }) {
                out += "\\(" + (TourStrings.counterTokens[token] ?? "number") + ")"
                rest = rest.dropFirst(token.count)
            } else {
                let next = rest.first!
                out += String(SwiftLiteral.string(String(next)).dropFirst().dropLast())
                rest = rest.dropFirst()
            }
        }
        return out + "\""
    }

    /// Text for a comment: on one line.
    static func oneLine(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: " ")
    }
}
