import Foundation
import XCTest
@testable import TourAgent

/// Every kind of line, read as written and refused with its reason: tips, palettes, pages, launch, animations, the
/// mark, look values and tuning values, then the call as a whole.
final class LineTests: XCTestCase {
    private func reason<T>(_ result: Result<T, LineError>) -> String? {
        if case .failure(let error) = result { return error.reason }
        return nil
    }

    // MARK: Tips

    func testATipLineIsReadWithItsSymbolAndPlace() throws {
        let tip = try TipLine.parse("library: Your Memories | Toggle to view only notes marked as memories — moments worth revisiting. | brain | trailing").get()
        XCTAssertEqual(tip, TipLine(tab: "library", title: "Your Memories",
                                    body: "Toggle to view only notes marked as memories — moments worth revisiting.", symbol: "brain", place: .topTrailing))
        let bare = try TipLine.parse("home: Search | Find anything (or nearly).").get()
        XCTAssertNil(bare.symbol)
        XCTAssertEqual(bare.place, .topLeading, "a tip stands under the bar's leading control when its line names no place")
        XCTAssertEqual(bare.body, "Find anything (or nearly).", "brackets in the words stay as written")
        XCTAssertEqual(try TipLine.parse("home: \"Search\" | \"Find it.\" | | center").get().title, "Search", "quotes are taken off")
        XCTAssertEqual(try TipLine.parse("home: A | B | | center").get().symbol, nil, "an empty symbol is none")
    }

    func testEverySpellingOfAPlaceIsRead() {
        let table: [(String, TipLine.Place)] = [
            ("leading", .topLeading), ("top leading", .topLeading), ("topLeading", .topLeading), ("left", .topLeading),
            ("trailing", .topTrailing), ("top-trailing", .topTrailing), ("right", .topTrailing),
            ("center", .center), ("centre", .center), ("middle", .center),
            ("bottomLeading", .bottomLeading), ("bottom left", .bottomLeading),
            ("bottom trailing", .bottomTrailing), ("bottomRight", .bottomTrailing),
        ]
        for (text, place) in table { XCTAssertEqual(TipLine.placeNamed(text), place, text) }
        XCTAssertNil(TipLine.placeNamed("top"))
    }

    func testABadTipLineIsRefusedWithItsReason() {
        let table: [(String, String)] = [
            ("library Filter | Browse.", "no `:` after the tab"),
            ("my tab: Filter | Browse.", "is not a tab's name"),
            ("library: Filter", "needs a title and a body"),
            ("library: A | B | brain | leading | more", "at most four parts"),
            ("library:  | Browse.", "has no title"),
            ("library: Filter |  ", "has no body"),
            ("library: Filter | Browse. | Brain Icon", "is not an SF Symbol's name"),
            ("library: Filter | Browse. | brain | top", "is not a place"),
        ]
        for (line, expected) in table {
            let said = reason(TipLine.parse(line))
            XCTAssertNotNil(said, line)
            XCTAssertTrue(said?.contains(expected) == true, "\(line): \(said ?? "accepted")")
        }
    }

    // MARK: Palettes

    func testAPaletteLineIsReadInAnySpellingOfHex() throws {
        XCTAssertEqual(try PaletteLine.parse("aurora: #21C7AD #612ECC #0D94E6 #73E6A6").get(),
                       PaletteLine(name: "aurora", colors: [0x21C7AD, 0x612ECC, 0x0D94E6, 0x73E6A6]))
        XCTAssertEqual(try PaletteLine.parse("sea: 0x4FC3F7, 0288d1, #2CA").get().colors, [0x4FC3F7, 0x0288D1, 0x22CCAA])
    }

    func testABadPaletteLineIsRefusedWithItsReason() {
        let table: [(String, String)] = [
            ("aurora #21C7AD #612ECC", "no `:` after the palette's name"),
            ("Aurora: #21C7AD #612ECC", "is not a palette's name"),
            ("class: #21C7AD #612ECC", "is not a palette's name"),
            ("aurora: #21C7A #612ECC", "is not a colour"),
            ("aurora: #21C7AD", "has 1 colour"),
            ("aurora: #111111 #222222 #333333 #444444 #555555 #666666 #777777 #888888 #999999", "has 9 colours"),
        ]
        for (line, expected) in table {
            let said = reason(PaletteLine.parse(line))
            XCTAssertTrue(said?.contains(expected) == true, "\(line): \(said ?? "accepted")")
        }
    }

    // MARK: Pages

    func testAPageLineIsReadWithItsRows() throws {
        let page = try PageLine.parse("eye.fill | aurora | Insight | See how you think. | A cloud of your words. | cloud.fill: Word cloud | Plain row: with a colon").get()
        XCTAssertEqual(page.symbol, "eye.fill")
        XCTAssertEqual(page.palette, "aurora")
        XCTAssertEqual(page.name, "Insight")
        XCTAssertEqual(page.tagline, "See how you think.")
        XCTAssertEqual(page.description, "A cloud of your words.")
        XCTAssertEqual(page.rows, [.init(symbol: "cloud.fill", text: "Word cloud"), .init(symbol: nil, text: "Plain row: with a colon")])
        let plain = try PageLine.parse("map |  | Maps |  | Offline maps.").get()
        XCTAssertNil(plain.palette, "an empty palette is the cover's")
        XCTAssertEqual(plain.tagline, "")
        XCTAssertEqual(plain.rows, [])
    }

    func testABadPageLineIsRefusedWithItsReason() {
        let rows = (1...9).map { "dot: Row \($0)" }.joined(separator: " | ")
        let table: [(String, String)] = [
            ("eye.fill | aurora | Insight | See.", "this one has 4 parts"),
            ("Eye | aurora | Insight | See. | Words.", "is not an SF Symbol's name"),
            ("eye.fill | Aurora Blue | Insight | See. | Words.", "is not a palette's name"),
            ("eye.fill | aurora |  | See. | Words.", "has no name"),
            ("eye.fill | aurora | Insight | See. | Words. | \(rows)", "at most eight"),
        ]
        for (line, expected) in table {
            let said = reason(PageLine.parse(line))
            XCTAssertTrue(said?.contains(expected) == true, "\(line): \(said ?? "accepted")")
        }
    }

    // MARK: Launch

    func testEveryLaunchStateIsRead() throws {
        let table: [(String, LaunchLine.State)] = [
            ("onboarding = welcome", .welcome), ("onboarding = .welcome", .welcome), ("seer = done", .done),
            ("onboarding.tips = tips", .tips(nil)), ("onboarding.tips = tips(library)", .tips("library")),
            ("about = about", .about(.number(0))), ("about.atlas = about(4)", .about(.number(4))),
            ("about.atlas = about(Atlas)", .about(.named("Atlas"))),
        ]
        for (line, state) in table { XCTAssertEqual(try LaunchLine.parse(line).get().state, state, line) }
        XCTAssertEqual(try LaunchLine.parse("onboarding.tips = tips(library)").get().destination, "onboarding.tips")
    }

    func testABadLaunchLineIsRefusedWithItsReason() {
        let table: [(String, String)] = [
            ("onboarding welcome", "a launch line is `destination = state`"),
            ("on boarding = welcome", "is not a destination's name"),
            ("onboarding = sheet", "is not a state the tour opens in"),
            ("about = about(-1)", "pages count from 0"),
            ("about = about()", "names no page"),
            ("onboarding = tips(my tab)", "is not a tab's name"),
        ]
        for (line, expected) in table {
            let said = reason(LaunchLine.parse(line))
            XCTAssertTrue(said?.contains(expected) == true, "\(line): \(said ?? "accepted")")
        }
    }

    // MARK: Animations

    func testAnAnimationIsWrittenAsAPersonWritesIt() throws {
        let table: [(String, String)] = [
            ("spring(0.4, 0.8)", ".spring(response: 0.4, dampingFraction: 0.8)"),
            (".spring(response: 0.35, dampingFraction: 0.8)", ".spring(response: 0.35, dampingFraction: 0.8)"),
            ("Animation.spring(response: 1, damping: 0.5)", ".spring(response: 1, dampingFraction: 0.5)"),
            ("easeOut(0.2)", ".easeOut(duration: 0.2)"),
            (".easeInOut(duration: 1.3)", ".easeInOut(duration: 1.3)"),
            ("linear(42)", ".linear(duration: 42)"),
            ("easeIn(0)", ".easeIn(duration: 0)"),
        ]
        for (text, swift) in table { XCTAssertEqual(try TourAnimation.parse(text).get().swift, swift, text) }
    }

    func testABadAnimationIsRefusedWithItsReason() {
        let table: [(String, String)] = [
            ("bounce(1)", "is not an animation this kit writes"),
            ("spring", "is not an animation"),
            ("spring(0.4)", "a spring takes a response and a damping fraction"),
            ("easeOut(0.2, 0.3)", "easeOut takes its seconds"),
            ("spring(response: 0.4, bounce: 0.2)", "not `bounce`"),
            ("spring(0.4, 3)", "damping fraction is 0.01 to 2"),
            ("easeOut(soon)", "`soon` is not a number"),
            ("linear(90)", "lasts 0 to 60 seconds"),
        ]
        for (text, expected) in table {
            let said = reason(TourAnimation.parse(text))
            XCTAssertTrue(said?.contains(expected) == true, "\(text): \(said ?? "accepted")")
        }
    }

    // MARK: The mark, look and tuning values

    func testTheMarkIsAViewOrASymbol() throws {
        XCTAssertEqual(try MarkValue.parse("SeerMark()").get().0, .view("SeerMark()"))
        let bare = try MarkValue.parse("SeerMark").get()
        XCTAssertEqual(bare.0, .view("SeerMark()"), "a bare type is the view made with no arguments")
        XCTAssertNotNil(bare.1, "and the answer says so")
        XCTAssertEqual(try MarkValue.parse("sparkles").get().0, .symbol("sparkles"))
        XCTAssertEqual(try MarkValue.parse("book.pages").get().0, .symbol("book.pages"))
        XCTAssertEqual(try MarkValue.parse("Image(\"logo\").resizable()").get().0, .view("Image(\"logo\").resizable()"))
        XCTAssertEqual(try MarkValue.parse("AppMark(size: {size})").get().0, .view("AppMark(size: size)"), "{size} is the size it is drawn at")
        XCTAssertNotNil(reason(MarkValue.parse("SeerMark(")), "brackets left open")
        XCTAssertNotNil(reason(MarkValue.parse("\"logo\"")), "a string is not a view")
    }

    func testALookValueIsTheAppsNameOrSwift() throws {
        let accent = try XCTUnwrap(TourLookRoles.named("accent")), title = try XCTUnwrap(TourLookRoles.named("aboutTitle"))
        let design = try XCTUnwrap(TourLookRoles.named("aboutDesign"))
        XCTAssertEqual(try LookValue.parse("accent", as: accent).get(), "Color.accent")
        XCTAssertEqual(try LookValue.parse(".accent", as: accent).get(), "Color.accent")
        XCTAssertEqual(try LookValue.parse("Color(red: 0.68, green: 0.56, blue: 0.38)", as: accent).get(), "Color(red: 0.68, green: 0.56, blue: 0.38)")
        XCTAssertEqual(try LookValue.parse("brandTitle", as: title).get(), "Font.brandTitle")
        XCTAssertEqual(try LookValue.parse("Font.custom(\"Avenir\", size: 44)", as: title).get(), "Font.custom(\"Avenir\", size: 44)")
        for text in ["serif", ".serif", "Font.Design.serif", "Serif"] { XCTAssertEqual(try LookValue.parse(text, as: design).get(), ".serif", text) }
        XCTAssertTrue(reason(LookValue.parse("fancy", as: design))?.contains("serif, rounded, monospaced or default") == true)
        XCTAssertTrue(reason(LookValue.parse("Color(red: 1", as: accent))?.contains("brackets and quotes closed") == true)
        XCTAssertTrue(reason(LookValue.parse(" ", as: accent))?.contains("gives no value") == true)
    }

    func testATuningValueIsReadByItsKind() throws {
        let scale = try XCTUnwrap(TourTuning.named("tip.scale")), close = try XCTUnwrap(TourTuning.named("symbol.close"))
        let cover = try XCTUnwrap(TourTuning.named("about.cover")), show = try XCTUnwrap(TourTuning.named("welcome.show"))
        XCTAssertEqual(try TuningValue.parse("0.88", as: scale).get().swift, "0.88")
        XCTAssertEqual(try TuningValue.parse("xmark.circle", as: close).get().swift, "\"xmark.circle\"")
        XCTAssertEqual(try TuningValue.parse(".aurora", as: cover).get().swift, ".aurora")
        XCTAssertEqual(try TuningValue.parse("spring(0.4, 0.8)", as: show).get().swift, ".spring(response: 0.4, dampingFraction: 0.8)")
        XCTAssertTrue(reason(TuningValue.parse("1.5", as: scale))?.contains("is 0 to 1") == true)
        XCTAssertTrue(reason(TuningValue.parse("big", as: scale))?.contains("is a number from 0 to 1") == true)
        XCTAssertTrue(reason(TuningValue.parse("X Mark", as: close))?.contains("is an SF Symbol's name") == true)
    }

    // MARK: The call as a whole

    func testTheSeerCallIsReadWhole() throws {
        let spec = try Fixture.spec(Fixture.seer())
        XCTAssertEqual(spec.parts, [.welcome, .tips, .about])
        XCTAssertEqual(spec.tabs, ["seer", "library", "models"])
        XCTAssertEqual(spec.tips.map(\.tips.count), [1, 3, 3])
        XCTAssertEqual(spec.pages.map(\.name), ["Threads", "Notes", "Seer", "Atlas", "Models", "Write"])
        XCTAssertEqual(spec.pages.map(\.rows.count), [4, 4, 4, 4, 4, 4])
        XCTAssertEqual(spec.strings["welcome.body"], "Your conversations, organized.\nYour thoughts, remembered.")
        XCTAssertEqual(spec.strings["about.title"], "Everything\nSeer can do.")
        XCTAssertEqual(spec.cover, "aurora")
        XCTAssertEqual(spec.look["accent"], "Color.accent")
        XCTAssertEqual(spec.look["aboutDesign"], ".serif")
        XCTAssertEqual(spec.launch, [.init(destination: "onboarding", state: .welcome),
                                     .init(destination: "onboarding.tips", state: .tips("seer")),
                                     .init(destination: "about", state: .about(0))])
        XCTAssertEqual(spec.mark, .view("SeerMark()"))
        XCTAssertEqual(spec.defaultsKey, "seer.tour")
        XCTAssertEqual(spec.notes, [], "nothing in the Seer call is read generously")
    }

    func testEveryProblemWithACallIsSaidAtOnce() throws {
        let input = TourAgent.Input(
            parts: [.welcome, .tips, .about],
            tips: ["home Search | Find."],
            palettes: ["sea: #4FC3F7"],
            pages: ["map | ocean | Maps | Find your way. | Offline maps."],
            strings: ["welcome.heading = \"Hi\"", "tip.next = \"\"", "tip.counter = \"{count} total\"", "welcome.skip = Later", "welcome.skip = Not now"],
            tuning: ["tip.scale = 2", "tip.size = 3", "about.cover = ocean"],
            look: ["accentColor = Color.red", "accent = Color.red", "accent = Color.blue"],
            launch: ["onboarding = welcome", "onboarding = done", "tips = tips(home)", "about.far = about(3)", "about.name = about(Nowhere)"],
            defaultsKey: "my key", prefix: "tour", imports: ["Seer Kit"]
        )
        let problems = try XCTUnwrap(Fixture.problems(input))
        let expected = [
            "`prefix` `tour` is not a prefix for type names",
            "`defaultsKey` `my key` is not a UserDefaults key",
            "`imports` `Seer Kit` is not a module name",
            "tips line 1 `home Search | Find.`: no `:` after the tab",
            "palettes line 1 `sea: #4FC3F7`: `sea` has 1 colour",
            "strings line 1 `welcome.heading = \"Hi\"`: `welcome.heading` is not a string key: welcome.title",
            "strings line 2 `tip.next = \"\"`: `tip.next` is empty",
            "strings line 3 `tip.counter = \"{count} total\"`: `tip.counter` needs `{n}`",
            "strings line 5 `welcome.skip = Not now`: `welcome.skip` is set twice",
            "tuning line 1 `tip.scale = 2`: `tip.scale` is 0 to 1, not 2",
            "tuning line 2 `tip.size = 3`: `tip.size` is not a tuning key",
            "`about.cover` names `ocean`",
            "look line 1 `accentColor = Color.red`: `accentColor` is not a look role",
            "look line 3 `accent = Color.blue`: `accent` is set twice",
            "launch line 2 `onboarding = done`: `onboarding` is given twice",
            "launch line 3 `tips = tips(home)`: no tip is for `home`: the tabs with tips are none",
            "launch line 4 `about.far = about(3)`: the pager has 2 pages",
            "launch line 5 `about.name = about(Nowhere)`: no page is named `Nowhere`",
        ]
        for phrase in expected {
            XCTAssertTrue(problems.contains { $0.hasPrefix(phrase) || $0.contains(phrase) }, "missing: \(phrase)\n\(problems.joined(separator: "\n"))")
        }
        XCTAssertGreaterThanOrEqual(problems.count, expected.count)
    }

    func testAPageNamingAPaletteTheCallDoesNotGiveIsRefused() throws {
        let problems = try XCTUnwrap(Fixture.problems(.init(palettes: ["sea: #4FC3F7 #0288D1"], pages: ["map | ocean | Maps | Find your way. | Offline maps."])))
        XCTAssertEqual(problems, ["pages line 1 `map | ocean | Maps | Find your way. | Offline maps.`: no palette is named `ocean`: the palettes are `sea`; add a `palettes` line for it, or leave it empty for the cover's"])
    }

    func testAPartLeftOutRefusesItsLaunchStates() throws {
        let problems = try XCTUnwrap(Fixture.problems(.init(parts: [.about], launch: ["onboarding = welcome", "tips = tips", "seer = done"])))
        XCTAssertEqual(problems.count, 3)
        XCTAssertTrue(problems[0].contains("the welcome is not among the parts written"))
        XCTAssertTrue(problems[1].contains("the tips are not among the parts written"))
        XCTAssertTrue(problems[2].contains("neither the welcome nor the tips is written"))
        XCTAssertEqual(Fixture.problems(.init(parts: [])), ["`parts` names no part: name welcome, tips or about, or leave it out for all three"])
    }

    func testAPrefixWhoseModifierSwiftReservesIsRefused() throws {
        let problems = try XCTUnwrap(Fixture.problems(.init(prefix: "Class")))
        XCTAssertEqual(problems, ["`prefix` `Class` names the modifier `.class(tab:)`, which Swift reserves: choose another prefix"])
        XCTAssertNil(Fixture.problems(.init(prefix: "UIKitTour")), "a prefix of capitals reads well as a modifier: .uiKitTour(tab:)")
        XCTAssertEqual(SwiftName.lowerCamel("UIKitTour"), "uiKitTour")
        XCTAssertEqual(SwiftName.lowerCamel("SDK"), "sdk")
        XCTAssertEqual(SwiftName.lowerCamel("Tour"), "tour")
    }

    func testWhatACallLeavesOutIsNoted() throws {
        let spec = try Fixture.spec(.init(parts: [.welcome, .about], tips: ["home: Search | Find anything."]))
        XCTAssertTrue(spec.notes.contains { $0.contains("No `mark`") })
        XCTAssertTrue(spec.notes.contains { $0.contains("The `tips` lines are not written") })
        XCTAssertTrue(spec.notes.contains { $0.contains("No `pages` lines") })
        XCTAssertTrue(spec.notes.contains { $0.contains("No `palettes` lines") })
        XCTAssertEqual(spec.cover, "dawn", "a call with no palettes draws in dawn")
    }

    func testTheLaunchStatesAreMadeConcrete() throws {
        let spec = try Fixture.spec(.init(
            tips: ["home: Search | Find anything.", "plan: Week | Plan the week."],
            pages: ["map |  | Maps | Find your way. | Offline maps.", "cloud |  | Sync | Everywhere. | On every device."],
            launch: ["first = tips", "second = tips(plan)", "maps = about(Maps)", "sync = about(2)", "cover = about"]
        ))
        XCTAssertEqual(spec.launch.map(\.state), [.tips("home"), .tips("plan"), .about(1), .about(2), .about(0)])
    }
}
