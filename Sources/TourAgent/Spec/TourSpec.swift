//  WHAT: A call read whole: every field and line understood and checked against the others (a page's palette among
//        the palettes, a launch's tab among the tips' tabs), every default filled in. What the files are written
//        from, and nothing else.
//  PIN:  EVERY PROBLEM AT ONCE. Reading goes on past a bad line, so one refusal names all of them; a spec exists only
//        when there are none.

import Foundation

struct TourSpec: Sendable {
    /// The parts asked for, in the kit's order.
    var parts: [TourPart]
    var into: String
    var prefix: String
    var defaultsKey: String
    var mark: MarkValue
    /// Each tab with tips, in the order the call first names it, with its tips in line order.
    var tips: [(tab: String, tips: [TipLine])]
    var palettes: [PaletteLine]
    var pages: [PageLine]
    /// Every string key with its text.
    var strings: [String: String]
    /// Every tuning key with its value; `about.cover` always named.
    var tuning: [String: TuningValue]
    /// Every look role with its Swift.
    var look: [String: String]
    /// Each launch line, its tab and page made concrete.
    var launch: [Launch]
    var imports: [String]
    /// What was read generously or left out, one sentence each.
    var notes: [String]

    struct Launch: Equatable, Sendable {
        enum State: Equatable, Sendable {
            case welcome
            case tips(String)
            case done
            case about(Int)
        }

        let destination: String
        let state: State
    }

    /// Whether the first-run layer is written: the welcome or the tips.
    var layer: Bool { parts.contains(.welcome) || parts.contains(.tips) }

    /// The tabs with tips, in order.
    var tabs: [String] { tips.map(\.tab) }

    /// The palettes a written view names: the cover's and each page's.
    var usedPalettes: [PaletteLine] {
        guard parts.contains(.about) else { return [] }
        var names: Set<String> = [cover]
        for page in pages { names.insert(page.palette ?? cover) }
        return palettes.filter { names.contains($0.name) }
    }

    /// The cover's palette, by name.
    var cover: String {
        if case .palette(let name)? = tuning["about.cover"] { return name }
        return palettes.first?.name ?? Self.fallbackPalette.name
    }

    /// The palette a call that gives none is drawn in: soft blue, violet, rose and mint.
    static let fallbackPalette = PaletteLine(name: "dawn", colors: [0x7FB3FF, 0xB39DFF, 0xFFB3C7, 0x9EE6CF])

    static let defaultInto = "Components/Tour"
    static let defaultPrefix = "Tour"
    static let defaultKey = "tour"

    /// The call read, or every problem with it.
    static func read(_ input: TourAgent.Input) -> Result<TourSpec, TourError> {
        var problems: [String] = []
        var notes: [String] = []
        func line(_ field: String, _ index: Int, _ text: String) -> String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let shown = trimmed.count > 64 ? String(trimmed.prefix(61)) + "…" : trimmed
            return "\(field) line \(index + 1) `\(shown)`"
        }
        func named(_ palettes: [PaletteLine]) -> String {
            palettes.isEmpty ? "none" : palettes.map { "`\($0.name)`" }.joined(separator: ", ")
        }
        func lines(_ list: [String]?) -> [(Int, String)] {
            (list ?? []).enumerated().filter { !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.map { ($0.offset, $0.element) }
        }

        // Parts, in the kit's order.
        var parts = TourPart.allCases
        if let asked = input.parts {
            if asked.isEmpty { problems.append("`parts` names no part: name welcome, tips or about, or leave it out for all three") }
            parts = TourPart.allCases.filter(asked.contains)
        }

        // Where, under which names, remembered under which key.
        let into = (input.into ?? "").trimmingCharacters(in: .whitespaces)
        let prefix = (input.prefix ?? defaultPrefix).trimmingCharacters(in: .whitespaces)
        if !SwiftName.isTypeName(prefix) {
            problems.append("`prefix` `\(prefix)` is not a prefix for type names: UpperCamelCase letters and digits, like `Tour` or `Kit`")
        } else if SwiftName.keywords.contains(SwiftName.lowerCamel(prefix)) {
            problems.append("`prefix` `\(prefix)` names the modifier `.\(SwiftName.lowerCamel(prefix))(tab:)`, which Swift reserves: choose another prefix")
        }
        let defaultsKey = (input.defaultsKey ?? defaultKey).trimmingCharacters(in: .whitespaces)
        if !TourName.isDefaultsKey(defaultsKey) {
            problems.append("`defaultsKey` `\(defaultsKey)` is not a UserDefaults key: letters, digits, `.`, `_` or `-`, like `myapp.tour`")
        }
        var imports: [String] = []
        for module in (input.imports ?? []).map({ $0.trimmingCharacters(in: .whitespaces) }) where !module.isEmpty {
            if !SwiftName.isModuleName(module) { problems.append("`imports` `\(module)` is not a module name") }
            else if !imports.contains(module) { imports.append(module) }
        }

        // The mark.
        var mark = MarkValue.fallback
        if let raw = input.mark, !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            switch MarkValue.parse(raw) {
            case .success(let (value, note)):
                mark = value
                if let note { notes.append(note) }
            case .failure(let error): problems.append("`mark`: \(error.reason)")
            }
        } else if parts.contains(.welcome) || parts.contains(.about) {
            notes.append("No `mark`: the welcome card and the cover draw the `sparkles` symbol; give `mark` the app's mark view, like `AppMark()`.")
        }

        // Tips, grouped by tab in the order the call first names each.
        var tips: [(tab: String, tips: [TipLine])] = []
        for (index, text) in lines(input.tips) {
            switch TipLine.parse(text) {
            case .success(let tip):
                if let at = tips.firstIndex(where: { $0.tab == tip.tab }) { tips[at].tips.append(tip) } else { tips.append((tip.tab, [tip])) }
            case .failure(let error): problems.append("\(line("tips", index, text)): \(error.reason)")
            }
        }

        // Palettes: the call's, else one to draw in.
        var palettes: [PaletteLine] = []
        for (index, text) in lines(input.palettes) {
            switch PaletteLine.parse(text) {
            case .success(let palette):
                if palettes.contains(where: { $0.name == palette.name }) {
                    problems.append("\(line("palettes", index, text)): `\(palette.name)` is named twice")
                } else {
                    palettes.append(palette)
                }
            case .failure(let error): problems.append("\(line("palettes", index, text)): \(error.reason)")
            }
        }
        let paletteLinesGiven = !lines(input.palettes).isEmpty
        if palettes.isEmpty, !paletteLinesGiven { palettes = [fallbackPalette] }

        // Feature pages.
        var pages: [PageLine] = []
        for (index, text) in lines(input.pages) {
            switch PageLine.parse(text) {
            case .success(let page):
                if let name = page.palette, !palettes.contains(where: { $0.name == name }), paletteLinesGiven || name != fallbackPalette.name {
                    problems.append("\(line("pages", index, text)): no palette is named `\(name)`: the palettes are \(named(palettes)); add a `palettes` line for it, or leave it empty for the cover's")
                }
                if page.rows.contains(where: { $0.symbol == nil }) {
                    notes.append("A row of the page `\(page.name)` names no symbol, so it shows `symbol.row`.")
                }
                pages.append(page)
            case .failure(let error): problems.append("\(line("pages", index, text)): \(error.reason)")
            }
        }

        // Strings.
        var strings = Dictionary(uniqueKeysWithValues: TourStrings.all.map { ($0.key, $0.fallback) })
        var setStrings: Set<String> = []
        for (index, text) in lines(input.strings) {
            guard let (key, raw) = Assignment.split(text) else {
                problems.append("\(line("strings", index, text)): a strings line is `key = \"text\"`, like `welcome.title = \"Welcome\"`")
                continue
            }
            guard TourStrings.named(key) != nil else {
                problems.append("\(line("strings", index, text)): `\(key)` is not a string key: \(TourStrings.keys.joined(separator: ", "))")
                continue
            }
            guard setStrings.insert(key).inserted else {
                problems.append("\(line("strings", index, text)): `\(key)` is set twice")
                continue
            }
            let value = Unquote.text(raw)
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                problems.append("\(line("strings", index, text)): `\(key)` is empty; leave the line out for its default, \"\(strings[key] ?? "")\"")
                continue
            }
            if key == "tip.counter" {
                let tokens = value.matchesOf(#"(\{[^}]*\})"#)
                if let wrong = tokens.first(where: { TourStrings.counterTokens[$0] == nil }) {
                    problems.append("\(line("strings", index, text)): `tip.counter` holds `{n}` and `{count}`, not `\(wrong)`")
                    continue
                }
                if !value.contains("{n}") {
                    problems.append("\(line("strings", index, text)): `tip.counter` needs `{n}`, the tip's number, like `{n} of {count}`")
                    continue
                }
            }
            strings[key] = value
        }

        // Tuning.
        var tuning: [String: TuningValue] = [:]
        for key in TourTuning.all {
            if let fallback = key.fallback, case .success(let value) = TuningValue.parse(fallback, as: key) { tuning[key.key] = value }
        }
        var setTuning: Set<String> = []
        for (index, text) in lines(input.tuning) {
            guard let (key, raw) = Assignment.split(text) else {
                problems.append("\(line("tuning", index, text)): a tuning line is `key = value`, like `tip.scale = 0.88`")
                continue
            }
            guard let tuned = TourTuning.named(key) else {
                problems.append("\(line("tuning", index, text)): `\(key)` is not a tuning key: \(TourTuning.keys.joined(separator: ", "))")
                continue
            }
            guard setTuning.insert(key).inserted else {
                problems.append("\(line("tuning", index, text)): `\(key)` is set twice")
                continue
            }
            switch TuningValue.parse(raw, as: tuned) {
            case .success(let value): tuning[key] = value
            case .failure(let error): problems.append("\(line("tuning", index, text)): \(error.reason)")
            }
        }
        if case .palette(let name)? = tuning["about.cover"], !palettes.contains(where: { $0.name == name }) {
            problems.append("`about.cover` names `\(name)`, and the palettes are \(named(palettes))")
        }
        if tuning["about.cover"] == nil { tuning["about.cover"] = .palette(palettes.first?.name ?? fallbackPalette.name) }

        // Look.
        var look = Dictionary(uniqueKeysWithValues: TourLookRoles.all.map { ($0.role, $0.fallback) })
        var setLook: Set<String> = []
        for (index, text) in lines(input.look) {
            guard let (role, raw) = Assignment.split(text) else {
                problems.append("\(line("look", index, text)): a look line is `role = Swift`, like `accent = Color.accent`")
                continue
            }
            guard let named = TourLookRoles.named(role) else {
                problems.append("\(line("look", index, text)): `\(role)` is not a look role: \(TourLookRoles.roles.joined(separator: ", "))")
                continue
            }
            guard setLook.insert(role).inserted else {
                problems.append("\(line("look", index, text)): `\(role)` is set twice")
                continue
            }
            switch LookValue.parse(raw, as: named) {
            case .success(let swift): look[role] = swift
            case .failure(let error): problems.append("\(line("look", index, text)): \(error.reason)")
            }
        }

        // Launch: each destination's state, made concrete against the tips and pages.
        var launch: [Launch] = []
        var destinations: Set<String> = []
        for (index, text) in lines(input.launch) {
            let said = line("launch", index, text)
            switch LaunchLine.parse(text) {
            case .success(let read):
                guard destinations.insert(read.destination).inserted else {
                    problems.append("\(said): `\(read.destination)` is given twice")
                    continue
                }
                switch read.state {
                case .welcome:
                    guard parts.contains(.welcome) else { problems.append("\(said): the welcome is not among the parts written"); continue }
                    launch.append(Launch(destination: read.destination, state: .welcome))
                case .tips(let tab):
                    guard parts.contains(.tips) else { problems.append("\(said): the tips are not among the parts written"); continue }
                    let tabs = tips.map(\.tab)
                    guard let chosen = tab ?? tabs.first else { problems.append("\(said): no `tips` line gives a tab its tips"); continue }
                    guard tabs.contains(chosen) else {
                        problems.append("\(said): no tip is for `\(chosen)`: the tabs with tips are \(tabs.isEmpty ? "none" : tabs.map { "`\($0)`" }.joined(separator: ", "))")
                        continue
                    }
                    launch.append(Launch(destination: read.destination, state: .tips(chosen)))
                case .done:
                    guard parts.contains(.welcome) || parts.contains(.tips) else { problems.append("\(said): `done` is the first-run layer's, and neither the welcome nor the tips is written"); continue }
                    launch.append(Launch(destination: read.destination, state: .done))
                case .about(let page):
                    guard parts.contains(.about) else { problems.append("\(said): the about pager is not among the parts written"); continue }
                    switch page {
                    case .number(let number):
                        guard number <= pages.count else {
                            problems.append("\(said): the pager has \(pages.count + 1) page\(pages.count == 0 ? "" : "s"), 0 (the cover) to \(pages.count)")
                            continue
                        }
                        launch.append(Launch(destination: read.destination, state: .about(number)))
                    case .named(let name):
                        guard let at = pages.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) else {
                            problems.append("\(said): no page is named `\(name)`: the pages are \(pages.isEmpty ? "none" : pages.map { "`\($0.name)`" }.joined(separator: ", "))")
                            continue
                        }
                        launch.append(Launch(destination: read.destination, state: .about(at + 1)))
                    }
                }
            case .failure(let error): problems.append("\(said): \(error.reason)")
            }
        }

        // What the call gave for a part it leaves out, or asked of a part with nothing to show.
        if !tips.isEmpty, !parts.contains(.tips) { notes.append("The `tips` lines are not written: `parts` leaves out the tips.") }
        if !pages.isEmpty, !parts.contains(.about) { notes.append("The `pages` lines are not written: `parts` leaves out the about pager.") }
        if parts.contains(.tips), tips.isEmpty { notes.append("No `tips` lines: the tips part shows nothing until a call gives each tab its tips (`tab: title | body | symbol | place`).") }
        if parts.contains(.about), pages.isEmpty { notes.append("No `pages` lines: the about pager shows only its cover.") }
        if parts.contains(.about), palettes.count == 1, palettes[0] == fallbackPalette { notes.append("No `palettes` lines: the about pager drifts through `dawn`, soft blue, violet, rose and mint.") }

        guard problems.isEmpty else { return .failure(.problems(problems)) }
        return .success(TourSpec(parts: parts, into: into.isEmpty ? defaultInto : into, prefix: prefix, defaultsKey: defaultsKey,
                                 mark: mark, tips: tips, palettes: palettes, pages: pages, strings: strings, tuning: tuning,
                                 look: look, launch: launch, imports: imports, notes: notes))
    }
}

extension String {
    /// The first capture of every match of `pattern`.
    func matchesOf(_ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: self, range: NSRange(startIndex..., in: self)).compactMap { Range($0.range(at: 1), in: self).map { String(self[$0]) } }
    }
}
