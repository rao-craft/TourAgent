//  WHAT: An app's first-run tour as a Granite agent package. A call gives the tour's words, tips, feature pages,
//        palettes, timings and look as lines; the run writes plain SwiftUI into the folder the call names: a
//        first-run layer the app applies over its tabs (a welcome card over a scrim, then each tab's tips one card at
//        a time, remembered as done), an about pager of feature pages over a drifting gradient the app presents as a
//        sheet, and what they read (the look, the launch state, the content), and answers how to use them.
//  IN:   Input: the folder, the parts, the mark, the tips, palettes and pages lines, the strings, tuning, look and
//        launch lines, the UserDefaults key, a prefix for the types, the modules they import.
//  OUT:  TourResult: the files written or taken away, the views, the modifier and initializers, the keys, the notes.
//  PIN:  NO MODEL. Every file is made from the call, the same way every time; a line that is not understood is
//        refused with its reason, and nothing is written until every problem is fixed and every file parses.
//  PIN:  THE APP KEEPS ITS NAVIGATION. The layer is told which tab is up and draws over it; the pager is a view the
//        app presents. Neither routes, and neither presents anything of the app's.

import Foundation
import GraniteAgents

public struct TourAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The folder the views go in, relative to the project; `Components/Tour` when left out.
        public var into: String?
        /// The parts to write; all three when left out.
        public var parts: [TourPart]?
        /// The app's mark: a view expression (`AppMark()`) or an SF Symbol's name; `sparkles` when left out.
        public var mark: String?
        /// One line a tip: `library: Your Memories | Toggle to view only notes marked as memories. | brain | trailing`.
        public var tips: [String]?
        /// One line a palette: `aurora: #21C7AD #612ECC #0D94E6 #73E6A6`.
        public var palettes: [String]?
        /// One line a feature page: `eye.fill | aurora | Insight | See how you think. | A description. | cloud.fill: A row`.
        public var pages: [String]?
        /// `key = "text"` lines: `welcome.title = "Welcome to Notes"`.
        public var strings: [String]?
        /// `key = value` lines: `tip.scale = 0.88`, `welcome.show = spring(0.4, 0.8)`.
        public var tuning: [String]?
        /// `role = Swift` lines: `accent = Color.accent`.
        public var look: [String]?
        /// `destination = state` lines: `onboarding = welcome`.
        public var launch: [String]?
        /// The UserDefaults key the first run is kept under; `tour` when left out.
        public var defaultsKey: String?
        /// A prefix for the types, `Tour` when left out.
        public var prefix: String?
        /// Modules the views import.
        public var imports: [String]?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, parts: [TourPart]? = nil, mark: String? = nil, tips: [String]? = nil,
                    palettes: [String]? = nil, pages: [String]? = nil, strings: [String]? = nil, tuning: [String]? = nil,
                    look: [String]? = nil, launch: [String]? = nil, defaultsKey: String? = nil, prefix: String? = nil,
                    imports: [String]? = nil, directory: String? = nil) {
            self.into = into; self.parts = parts; self.mark = mark; self.tips = tips; self.palettes = palettes
            self.pages = pages; self.strings = strings; self.tuning = tuning; self.look = look; self.launch = launch
            self.defaultsKey = defaultsKey; self.prefix = prefix; self.imports = imports; self.directory = directory
        }
    }

    public typealias Event = TourFrame
    public typealias Output = TourResult
    public typealias Compute = Void

    public static let word = "tour"
    /// What it makes: the views the app shows (the layer over its tabs, the pager it presents) and what they read.
    public static let makes = [
        AgentMake(kind: "view", what: "the first-run tour as reusable SwiftUI views: the layer the app applies over its tabs with .tour(tab:) (a welcome card over a scrim, then each tab's tips one card at a time) and the about pager TourAbout() it presents as a sheet, with the views they are built from",
                  into: ["Components/Tour/*"], never: "routes or presents the app's own screens; never a page, a service or a model type"),
        AgentMake(kind: "support", what: "what the tour's views read: TourLook (its colours and fonts), TourLaunch (the state a -destination launch opens), TourContent (the tips, pages and palettes), TourHaptics",
                  into: ["Components/Tour/*"], never: "a change to the app's own types"),
    ]
    public static let summary = "writes an app's first-run tour as plain SwiftUI: a welcome card over a scrim, each tab's tips one card at a time, and an about pager of feature pages over a drifting gradient, in the app's words, timings, symbols and look."
    public static let fields = [
        "into": "the folder for the views, relative to the project; \(TourSpec.defaultInto) when left out",
        "parts": "the parts to write, all three when left out: welcome (a card over a scrim the first time the tabs are up), tips (each tab's tips, one card at a time, the first time that tab is up), about (the about pager over a drifting gradient)",
        "mark": "the app's mark on the welcome card and the pager's cover: a view expression like `AppMark()` (`{size}` in it is the size it is drawn at), or an SF Symbol's name; sparkles when left out",
        "tips": "one line a tip, in tour order: `tab: title | body | symbol | place`; tab is the name the app passes for the tab that is up, symbol an SF Symbol, place leading (under the bar's leading control, the default; or topLeading), trailing (or topTrailing), bottomLeading, bottomTrailing or center",
        "palettes": "one line a palette the pager's gradient drifts through: `name: #RRGGBB #RRGGBB …`, two to eight colours, the first its base",
        "pages": "one line a feature page, after the cover: `symbol | palette | name | tagline | description | row | row …`, each row `symbol: text`; an empty palette takes the cover's",
        "strings": "`key = \"text\"` for any word the tour shows (a `\\n` breaks the line): " + TourStrings.keys.joined(separator: ", ") + "; tip.counter holds {n} and {count}",
        "tuning": "`key = value` for a timing (`spring(0.4, 0.8)`, `easeOut(0.2)`), a number or a symbol: " + TourTuning.keys.joined(separator: ", "),
        "look": "`role = Swift` for a colour or a font, like `accent = Color.accent`; a bare name is Color.name or Font.name, and aboutDesign is serif, rounded, monospaced or default: " + TourLookRoles.roles.joined(separator: ", "),
        "launch": "`destination = state` for a `-destination` launch argument: welcome, tips(<tab>), done, about, or about(<page number or name>); any other destination opens with the first run done",
        "defaultsKey": "the UserDefaults key the first run is kept under (key.welcomed, key.finished); \(TourSpec.defaultKey) when left out",
        "prefix": "the types' prefix, \(TourSpec.defaultPrefix) when left out: `Kit` writes KitLayer, KitAbout and the modifier .kit(tab:)",
        "imports": "modules the views import, such as the one the mark's view or a look name is declared in",
    ]
    public static let guide = """
        Tag tour for an app's first run: a welcome card over a scrim the first time the tabs are up (the mark, a title, \
        a line, a button that starts the tips and a Skip), then each tab's tips the first time that tab is up, one card \
        at a time ("1 of 3", back, dots, Next, Got it), remembered as done; and an about pager, a cover then a page a \
        feature over a drifting gradient. It writes plain SwiftUI (iOS 17 and macOS 14) into `into` \
        (Components/Tour). The app applies the layer over its tab view with `.tour(tab: selectedTab)`, passing the \
        tab that is up as the tips name it (a String, or an enum whose raw value is one); it takes touches only where \
        it draws. The app presents the pager as a sheet with `TourAbout()`, which closes itself (or calls \
        `onClose`). Lines: `tips` is `tab: title | body | symbol | place` (place leading or topLeading, trailing or \
        topTrailing, bottomLeading, bottomTrailing, center); `palettes` is `name: #RRGGBB #RRGGBB …`; `pages` is `symbol | palette | \
        name | tagline | description | symbol: row | symbol: row …`; `strings`, `tuning`, `look` and `launch` are \
        `key = value`. Strings: welcome.title, welcome.body, welcome.start, welcome.skip, tip.counter ({n} of \
        {count}), tip.next, tip.done, tip.back, about.name, about.title, about.subtitle, about.begin, about.close, \
        about.back, about.next, about.done; quote a string and write `\\n` for a line break. Tuning: mark.turn \
        (seconds a turn, 0 still), welcome.show, welcome.skip, welcome.settle, tip.step, tip.settle, tip.swap, \
        about.begin, about.step and about.blend (animations: `spring(0.4, 0.8)`, `easeOut(0.2)`, `easeIn`, \
        `easeInOut`, `linear`), scrim.opacity, tip.scale, tip.width, tip.top, tip.side, tip.bottom, welcome.mark, \
        welcome.inset, welcome.radius, about.cover (a palette), about.mark, about.markRadius, gradient.speed, gradient.strength, \
        gradient.reach, gradient.drift, gradient.opacity, symbol.back, symbol.forward, symbol.finish, \
        symbol.close, symbol.begin, symbol.row. Look roles: accent, onAccent, scrim, welcomeTitle, welcomeBody, \
        welcomeButton, welcomeSkip, tipTitle, tipCounter, tipBody, tipButton, aboutDesign, aboutTitle, \
        aboutSubtitle, aboutButton, pageTitle, pageTagline, pageBody, pageRow; one left out keeps the system's \
        value. Launch: `onboarding = welcome`, `onboarding.tips = tips(home)`, `about = about` or `about(2)`: the \
        layer and the pager read `UserDefaults.standard.string(forKey: "destination")`, and any other destination \
        opens with the first run done. The app's navigation opens the tab or the sheet a destination belongs to. \
        Every view has a #Preview. Examples. A recipe app's whole tour: \
        {"mark": "RecipeMark()", "defaultsKey": "recipes.tour", "tips": ["recipes: Your Recipes | Everything you \
        have saved, newest first. | book | leading", "recipes: Add a Recipe | Paste a link or write one by hand. | \
        plus | trailing", "plan: This Week | Drag recipes onto days to plan your meals. | calendar | center"], \
        "palettes": ["citrus: #FFB347 #FF6F61 #FFD56B #F7A072", "garden: #7BC67E #3E9E6F #B8E986 #4FB0A5"], \
        "pages": ["book.fill | citrus | Recipes | Everything you cook. | Save recipes from anywhere and keep them \
        in one place. | link: Save from any website | pencil: Write your own"], "strings": ["welcome.title = \
        \\"Welcome to Recipes\\"", "about.title = \\"Everything\\\\nRecipes can do.\\""], "tuning": ["tip.scale = \
        0.9", "about.cover = garden"], "look": ["accent = Color.orange"], "launch": ["onboarding = welcome", \
        "about = about"]}. \
        Only the about pager, in a rounded face: {"parts": ["about"], "palettes": ["sea: #4FC3F7 #0288D1 #80DEEA \
        #26A69A"], "pages": ["map | sea | Maps | Find your way. | Offline maps of every trail. | location: Where \
        you are"], "look": ["aboutDesign = rounded"]}. \
        The welcome and the tips beside the app's own Tour types, kept under the app's key: {"parts": ["welcome", \
        "tips"], "prefix": "Intro", "defaultsKey": "notes.intro", "tips": ["notes: Search | Find any note by a word \
        in it. | magnifyingglass | trailing"], "strings": ["welcome.title = \\"Hello\\""]}. \
        A line it cannot read is refused with the reason and nothing is written: fix the line and call again. Not \
        for the app's tabs, navigation, services or settings.
        """

    public static func output(from events: [TourFrame]) -> TourResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<TourFrame, Error> {
        // The folder is the call's, else the host's (a host over the wire may give it only there), else the
        // process's: never the runner's working folder while the host named one.
        var resolved = input
        if resolved.directory == nil { resolved.directory = context.host.directory }
        let call = resolved
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The whole call: the lines read, the files made, staged, parsed and written, and an earlier call's files this
    /// one does not write taken away.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (TourFrame) -> Void) throws -> TourResult {
        let spec: TourSpec
        switch TourSpec.read(input) {
        case .success(let read): spec = read
        case .failure(let error): throw error
        }
        let plan = try TourPlan(spec)
        let files = AgentFiles(directory: input.directory)
        let folder = files.resolve(spec.into)
        let tipCount = spec.tips.reduce(0) { $0 + $1.tips.count }
        yield(.read(tips: tipCount, pages: spec.pages.count, files: plan.files.count))
        note("writing \(plan.files.count) files into \(files.relative(folder))")

        let planned = plan.files.map { (url: folder.appendingPathComponent($0.name), text: $0.text) }
        // What each file held before: the same text is unchanged, other text rewritten.
        var before: [String: String] = [:]
        for file in planned {
            if let text = try? String(contentsOf: file.url, encoding: .utf8) { before[file.url.path] = text }
        }
        // The kit's files an earlier call wrote here that this one does not: they read what this call no longer
        // writes, so they go once this call's files have landed.
        let stale = Self.stale(in: folder, prefix: spec.prefix, keeping: Set(plan.files.map(\.name)))
        let written = try files.write(planned)
        var removed: [String] = []
        for url in stale where (try? FileManager.default.removeItem(at: url)) != nil { removed.append(url.path) }
        note("wrote \(written.count) files\(removed.isEmpty ? "" : ", took away \(removed.count)")")

        func state(_ path: String, _ text: String) -> AgentMade.State {
            guard let old = before[path] else { return .written }
            return old == text ? .unchanged : .rewritten
        }
        var made: [AgentMade] = []
        for (file, path) in zip(plan.files, written) {
            made.append(AgentMade(kind: file.file.kind.rawValue, name: file.type, path: path, state: state(path, file.text)))
        }
        for path in removed {
            let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
            let kind = TourCatalog.files.first { spec.prefix + $0.stem == name }?.kind ?? .view
            made.append(AgentMade(kind: kind.rawValue, name: name, path: path, state: .removed))
        }
        let expected = plan.expected.map { AgentExpected(kind: "view", name: $0) }

        var notes = spec.notes
        let modifier = SwiftName.lowerCamel(spec.prefix)
        if spec.layer {
            let tabs = spec.tabs.isEmpty ? "" : " (\(spec.tabs.map { "`\($0)`" }.joined(separator: ", ")))"
            notes.append("Apply `.\(modifier)(tab:)` to the app's tab view, passing the tab that is up as the tips name it\(tabs): "
                + (spec.parts.contains(.welcome) ? "the welcome card shows over it on the first run, then each tab's tips." : "each tab's tips show the first time it is up."))
        }
        if spec.parts.contains(.about) {
            notes.append("Present `\(spec.prefix)About()` as a sheet with no detents: it fills the sheet, shows a drag indicator and closes itself with `dismiss`, or calls `onClose` when given one. `\(spec.prefix)About.name` is its name for the menu item that opens it.")
        }
        if !spec.launch.isEmpty {
            let named = spec.launch.map { "`\($0.destination)`" }.joined(separator: ", ")
            notes.append("The app's navigation opens the tab or the sheet each launch destination belongs to (\(named)); the tour opens its own state there from `\(spec.prefix)Launch`, and any other destination opens with the first run done.")
        }
        if !removed.isEmpty {
            notes.append("Took away \(removed.count) of the kit's files an earlier call wrote here, which this call's parts no longer use: \(removed.map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")).")
        }
        let launch = spec.launch.map { launch -> String in
            switch launch.state {
            case .welcome: return "\(launch.destination) = welcome"
            case .tips(let tab): return "\(launch.destination) = tips(\(tab))"
            case .done: return "\(launch.destination) = done"
            case .about(let page): return page == 0 ? "\(launch.destination) = about" : "\(launch.destination) = about(\(page))"
            }
        }
        let paths = written + removed
        return TourResult(path: written.first, paths: paths, views: plan.views, modifier: plan.modifier,
                          initializers: plan.initializers, launch: launch, keys: plan.keys, notes: notes,
                          made: made, expected: expected)
    }

    /// The kit's files in `folder` under `prefix` that are not among `keeping`: each one named for a file of the kit
    /// and declaring its type, so an app's own file of a like name is never taken.
    static func stale(in folder: URL, prefix: String, keeping: Set<String>) -> [URL] {
        TourCatalog.files.compactMap { file -> URL? in
            let name = prefix + file.stem + ".swift"
            guard !keeping.contains(name) else { return nil }
            let url = folder.appendingPathComponent(name)
            guard let text = try? String(contentsOf: url, encoding: .utf8),
                  text.range(of: #"(?m)^(struct|enum) \#(prefix + file.stem)\b"#, options: .regularExpression) != nil else { return nil }
            return url
        }
    }
}
