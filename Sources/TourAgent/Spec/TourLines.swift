//  WHAT: The lines of a call, each read into what it says: a tab's tip, a palette, a feature page, a launch
//        destination's state. Each parser answers the value or why the line is not one, said with what it accepts.
//  PIN:  FREE TEXT STAYS AS WRITTEN. A tip's or a page's words are cut only at `|`, never at brackets or quotes, so
//        "Tap any to explore (or long-press)" and "a — b" reach the screen as the call wrote them.

import Foundation

/// A tip of a tab's tour: `library: Your Memories | Toggle to view only notes marked as memories. | brain | trailing`.
struct TipLine: Equatable, Sendable {
    /// Where the card stands: under a control of the bar (`topLeading`, `topTrailing`), over the tab bar
    /// (`bottomLeading`, `bottomTrailing`), or in the middle (`center`).
    enum Place: String, Sendable, CaseIterable {
        case topLeading, topTrailing, bottomLeading, bottomTrailing, center
    }

    let tab: String
    let title: String
    let body: String
    let symbol: String?
    let place: Place

    static let shape = "`tab: title | body | symbol | place`, where symbol and place may be left out"

    static func parse(_ line: String) -> Result<TipLine, LineError> {
        guard let colon = line.firstIndex(of: ":") else {
            return .failure(LineError("no `:` after the tab: a tip line is \(shape)"))
        }
        let tab = line[..<colon].trimmingCharacters(in: .whitespaces)
        guard TourName.isTab(tab) else {
            return .failure(LineError("`\(tab)` is not a tab's name: letters, digits, `.`, `_` or `-`, as the app passes it to the layer"))
        }
        let parts = line[line.index(after: colon)...].split(separator: "|", omittingEmptySubsequences: false)
            .map { Unquote.text(String($0)) }
        guard parts.count >= 2 else {
            return .failure(LineError("a tip needs a title and a body: a tip line is \(shape)"))
        }
        guard parts.count <= 4 else {
            return .failure(LineError("a tip line has at most four parts after the tab, and this one has \(parts.count): \(shape); a `|` cannot stand in its words"))
        }
        guard !parts[0].isEmpty else { return .failure(LineError("the tip has no title: a tip line is \(shape)")) }
        guard !parts[1].isEmpty else { return .failure(LineError("the tip has no body: a tip line is \(shape)")) }
        var symbol: String?
        if parts.count > 2, !parts[2].isEmpty {
            guard SwiftName.isSymbol(parts[2]) else {
                return .failure(LineError("`\(parts[2])` is not an SF Symbol's name, like `brain` or `wallet.bifold`"))
            }
            symbol = parts[2]
        }
        var place = Place.topLeading
        if parts.count > 3, !parts[3].isEmpty {
            guard let read = placeNamed(parts[3]) else {
                return .failure(LineError("`\(parts[3])` is not a place: leading (topLeading), trailing (topTrailing), bottomLeading, bottomTrailing or center"))
            }
            place = read
        }
        return .success(TipLine(tab: tab, title: parts[0], body: parts[1], symbol: symbol, place: place))
    }

    /// `top leading`, `topLeading`, `left`: the place a card stands, however it is spelled.
    static func placeNamed(_ text: String) -> Place? {
        let word = text.lowercased().filter { $0.isLetter }
        switch word {
        case "leading", "topleading", "left", "topleft": return .topLeading
        case "trailing", "toptrailing", "right", "topright": return .topTrailing
        case "bottomleading", "bottomleft": return .bottomLeading
        case "bottomtrailing", "bottomright": return .bottomTrailing
        case "center", "centre", "middle", "centered", "centred": return .center
        default: return nil
        }
    }
}

/// A palette the drifting gradient blends: `aurora: #21C7AD #612ECC #0D94E6 #73E6A6`.
struct PaletteLine: Equatable, Sendable {
    let name: String
    let colors: [UInt32]

    static let shape = "`name: #RRGGBB #RRGGBB …`, two to eight colours"

    static func parse(_ line: String) -> Result<PaletteLine, LineError> {
        guard let colon = line.firstIndex(of: ":") else {
            return .failure(LineError("no `:` after the palette's name: a palette line is \(shape)"))
        }
        let name = line[..<colon].trimmingCharacters(in: .whitespaces)
        guard SwiftName.isMemberName(name) else {
            return .failure(LineError("`\(name)` is not a palette's name: lowerCamelCase letters and digits, like `aurora`"))
        }
        let words = line[line.index(after: colon)...].split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\t" })
        var colors: [UInt32] = []
        for word in words {
            guard let color = hex(String(word)) else {
                return .failure(LineError("`\(word)` is not a colour: six hex digits, like `#21C7AD`"))
            }
            colors.append(color)
        }
        guard (2...8).contains(colors.count) else {
            return .failure(LineError("`\(name)` has \(colors.count) colour\(colors.count == 1 ? "" : "s"): a palette line is \(shape)"))
        }
        return .success(PaletteLine(name: name, colors: colors))
    }

    /// `#21C7AD`, `21c7ad`, `0x21C7AD` or `#2CA` as the colour's 24 bits.
    static func hex(_ text: String) -> UInt32? {
        var digits = text
        if digits.hasPrefix("#") { digits.removeFirst() } else if digits.lowercased().hasPrefix("0x") { digits.removeFirst(2) }
        if digits.count == 3 { digits = digits.map { "\($0)\($0)" }.joined() }
        guard digits.count == 6, digits.allSatisfy(\.isHexDigit) else { return nil }
        return UInt32(digits, radix: 16)
    }
}

/// A feature page of the about pager: `symbol | palette | name | tagline | description | row | row …`.
struct PageLine: Equatable, Sendable {
    struct Row: Equatable, Sendable {
        /// The row's symbol; nil takes `symbol.row`.
        let symbol: String?
        let text: String
    }

    let symbol: String
    /// The palette behind the page; nil takes the cover's.
    let palette: String?
    let name: String
    let tagline: String
    let description: String
    let rows: [Row]

    static let shape = "`symbol | palette | name | tagline | description | row | row …`, each row `symbol: text` or `text`"

    static func parse(_ line: String) -> Result<PageLine, LineError> {
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map { Unquote.text(String($0)) }
        guard parts.count >= 5 else {
            return .failure(LineError("a page line is \(shape); this one has \(parts.count) part\(parts.count == 1 ? "" : "s")"))
        }
        guard SwiftName.isSymbol(parts[0]) else {
            return .failure(LineError("`\(parts[0])` is not an SF Symbol's name, like `eye.fill`: a page line is \(shape)"))
        }
        let palette = parts[1].isEmpty ? nil : parts[1]
        if let palette, !SwiftName.isMemberName(palette) {
            return .failure(LineError("`\(palette)` is not a palette's name, like `aurora`; leave it empty for the cover's"))
        }
        guard !parts[2].isEmpty else { return .failure(LineError("the page has no name: a page line is \(shape)")) }
        var rows: [Row] = []
        for raw in parts.dropFirst(5) where !raw.isEmpty {
            if let colon = raw.firstIndex(of: ":") {
                let head = raw[..<colon].trimmingCharacters(in: .whitespaces)
                let text = raw[raw.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                if SwiftName.isSymbol(head), !text.isEmpty {
                    rows.append(Row(symbol: head, text: text))
                    continue
                }
            }
            rows.append(Row(symbol: nil, text: raw))
        }
        guard rows.count <= 8 else {
            return .failure(LineError("the page has \(rows.count) rows, and a page shows at most eight"))
        }
        return .success(PageLine(symbol: parts[0], palette: palette, name: parts[2], tagline: parts[3], description: parts[4], rows: rows))
    }
}

/// A launch destination and the state the tour opens in for it: `onboarding = welcome`, `about = about(2)`.
struct LaunchLine: Equatable, Sendable {
    enum State: Equatable, Sendable {
        /// The welcome card.
        case welcome
        /// The welcome passed and this tab's tips up; nil names the first tab with tips.
        case tips(String?)
        /// The first run over: the layer draws nothing.
        case done
        /// The about pager on this page (0 is the cover), or on the page of this name.
        case about(AboutPage)
    }

    enum AboutPage: Equatable, Sendable {
        case number(Int)
        case named(String)
    }

    let destination: String
    let state: State

    static let states = "welcome, tips(<tab>), done, about, or about(<page>) with a page's number (0 is the cover) or name"

    static func parse(_ line: String) -> Result<LaunchLine, LineError> {
        guard let (destination, value) = Assignment.split(line) else {
            return .failure(LineError("a launch line is `destination = state`, like `onboarding = welcome`"))
        }
        guard TourName.isDestination(destination) else {
            return .failure(LineError("`\(destination)` is not a destination's name: letters, digits, `.`, `_` or `-`, as `-destination` passes it"))
        }
        var word = value, argument: String?
        if let open = value.firstIndex(of: "("), value.hasSuffix(")") {
            word = value[..<open].trimmingCharacters(in: .whitespaces)
            argument = Unquote.text(String(value[value.index(after: open)..<value.index(before: value.endIndex)]))
        }
        if word.hasPrefix(".") { word.removeFirst() }
        switch (word, argument) {
        case ("welcome", nil): return .success(LaunchLine(destination: destination, state: .welcome))
        case ("done", nil): return .success(LaunchLine(destination: destination, state: .done))
        case ("tips", nil): return .success(LaunchLine(destination: destination, state: .tips(nil)))
        case ("tips", let tab?):
            guard TourName.isTab(tab) else { return .failure(LineError("`\(tab)` is not a tab's name, as the tips lines name it")) }
            return .success(LaunchLine(destination: destination, state: .tips(tab)))
        case ("about", nil): return .success(LaunchLine(destination: destination, state: .about(.number(0))))
        case ("about", let page?):
            if let number = Int(page) {
                guard number >= 0 else { return .failure(LineError("`about(\(page))`: pages count from 0, the cover")) }
                return .success(LaunchLine(destination: destination, state: .about(.number(number))))
            }
            guard !page.isEmpty else { return .failure(LineError("`about()` names no page: write `about` for the cover")) }
            return .success(LaunchLine(destination: destination, state: .about(.named(page))))
        default:
            return .failure(LineError("`\(value)` is not a state the tour opens in: \(states)"))
        }
    }
}

/// The names a call gives tabs and destinations.
enum TourName {
    /// `library`, `seer`, `models`, `tab-2`: a tab's name, as the app passes the tab that is up.
    static func isTab(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z0-9][A-Za-z0-9_.\-]*$"#, options: .regularExpression) != nil
    }

    /// `onboarding`, `onboarding.tips`, `about`: a `-destination` launch argument.
    static func isDestination(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z0-9][A-Za-z0-9_.\-]*$"#, options: .regularExpression) != nil
    }

    /// `seer.tour`, `tour`: a UserDefaults key.
    static func isDefaultsKey(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z0-9][A-Za-z0-9_.\-]*$"#, options: .regularExpression) != nil
    }
}
