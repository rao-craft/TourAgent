import Foundation
import XCTest
@testable import TourAgent

/// The templates as the kit's own source: every combination of parts and flags renders to Swift that parses, with
/// no marker or placeholder left; every key, string and role a call can set is read by some file; every type a
/// template declares is one a prefix renames.
final class TemplateTests: XCTestCase {
    /// Every part alone and together, with a mark that turns or keeps still, drawn from a view or a symbol, and a
    /// gradient whose clock starts at 0 or later and holds or drifts on a destination launch: each call's files land,
    /// which means each parsed.
    func testEveryCombinationOfPartsAndFlagsWritesFilesThatParse() throws {
        let partSets: [[TourPart]] = [[.welcome], [.tips], [.about], [.welcome, .tips], [.welcome, .about], [.tips, .about],
                                      [.welcome, .tips, .about]]
        for parts in partSets {
            var variants = [("AppMark()", "42", "12.5", "false"), ("sparkles", "0", "0", "false")]
            if parts.contains(.about) { variants += [("AppMark()", "0", "12.5", "true"), ("sparkles", "42", "0", "true")] }
            for (mark, turn, start, hold) in variants {
                let input = TourAgent.Input(parts: parts, mark: mark, tips: ["home: Search | Find anything. | magnifyingglass"],
                                            pages: ["map |  | Maps | Find your way. | Offline maps. | location: Where you are"],
                                            tuning: ["mark.turn = \(turn)", "gradient.start = \(start)", "gradient.hold = \(hold)"])
                let result = try Fixture.write(input, into: Fixture.folder())
                for file in Fixture.all(result.paths) {
                    XCTAssertFalse(file.text.contains("//@"), "\(parts) \(mark): \(file.name) keeps a marker")
                    XCTAssertFalse(file.text.contains("{{"), "\(parts) \(mark): \(file.name) keeps a placeholder")
                    XCTAssertFalse(file.text.contains("\n\n\n"), "\(parts) \(mark): \(file.name) keeps a run of blank lines")
                    XCTAssertTrue(file.text.contains("#Preview") || file.name.hasSuffix("Look.swift") || file.name.hasSuffix("Launch.swift")
                                  || file.name.hasSuffix("Content.swift") || file.name.hasSuffix("Haptics.swift"),
                                  "\(file.name) has no preview")
                }
                let mark = try Fixture.text(result.paths, "TourMark.swift", ifAny: parts.contains(.welcome) || parts.contains(.about))
                if let mark {
                    XCTAssertEqual(mark.contains("rotationEffect"), turn != "0", "the mark turns only when mark.turn is more than 0")
                    XCTAssertEqual(mark.contains("AppMark()"), input.mark == "AppMark()")
                }
                if let gradient = try Fixture.text(result.paths, "TourDriftingGradient.swift", ifAny: parts.contains(.about)) {
                    let held = hold == "true"
                    XCTAssertEqual(gradient.contains("let time = 12.5 + timeline.date.timeIntervalSince(start) * 0.0525"), start != "0" && !held,
                                   "the colours' clock starts at gradient.start")
                    XCTAssertEqual(gradient.contains("let time = timeline.date.timeIntervalSince(start) * 0.0525"), start == "0" && !held,
                                   "a clock that starts at 0 is written without it")
                    XCTAssertEqual(gradient.contains("let time = Self.holds ? 12.5 : 12.5 + timeline.date.timeIntervalSince(start) * 0.0525"),
                                   start != "0" && held, "a held gradient stands at gradient.start")
                    XCTAssertEqual(gradient.contains("let time = Self.holds ? 0 : timeline.date.timeIntervalSince(start) * 0.0525"),
                                   start == "0" && held, "a held gradient whose clock starts at 0")
                    XCTAssertEqual(gradient.contains("holds"), held, "only gradient.hold writes the hold")
                    XCTAssertEqual(gradient.contains("paused: reduceMotion || Self.holds"), held)
                    XCTAssertEqual(gradient.contains(#"private static let holds = !(TourLaunch.destination ?? "").isEmpty"#), held)
                }
            }
        }
    }

    func testEveryPlaceholderATemplateNamesIsOneACallFills() throws {
        let values = TourPlan.values(try Fixture.spec(Fixture.seer()))
        for file in TourCatalog.files {
            guard let template = file.template else { continue }
            let missing = TemplateRender.placeholders(in: template).filter { values[$0] == nil }
            XCTAssertEqual(missing, [], "Template of \(file.stem)")
        }
    }

    /// A key a call can set that no file reads would be a lie in the schema.
    func testEveryKeyStringAndRoleIsReadBySomeFile() {
        let templates = TourCatalog.files.compactMap(\.template).joined(separator: "\n")
        for key in TourTuning.all {
            let read: Bool
            switch key.kind {
            case .number: read = templates.contains("{{n:\(key.key)}}") || key.key == "scrim.opacity"
            case .animation: read = templates.contains("{{a:\(key.key)}}")
            case .symbol: read = templates.contains("{{y:\(key.key)}}") || key.key == "symbol.row"
            case .palette: read = key.key == "about.cover"
            case .flag: read = templates.contains("//@if \(key.key)s")
            }
            XCTAssertTrue(read, "no file reads tuning \(key.key)")
        }
        for string in TourStrings.all {
            XCTAssertTrue(templates.contains("{{s:\(string.key)}}") || string.key == "tip.counter", "no file reads string \(string.key)")
        }
        for role in TourLookRoles.all where role.kind != .design {
            XCTAssertTrue(templates.contains("TourLook.\(role.role)"), "no view reads look role \(role.role)")
        }
    }

    func testEveryTypeTheKitDeclaresIsOneAPrefixRenames() throws {
        let result = try Fixture.write(Fixture.seer(), into: Fixture.folder())
        let code = Fixture.all(result.paths).map(\.text).joined(separator: "\n")
        let declared = Set(code.matchesOf(#"(?m)^\s*(?:private |fileprivate )?(?:struct|enum|class) Tour([A-Za-z]+)"#))
        XCTAssertFalse(declared.isEmpty)
        XCTAssertEqual(declared.subtracting(TourCatalog.typeStems), [], "declared but never renamed by a prefix")
    }

    func testABlockIsKeptOrDroppedByItsCondition() throws {
        let source = """
        a
        //@if part.tips && !part.welcome
        b
        //@else
        c
        //@endif
        //@if layer || part.about
        d
        //@endif
        """
        XCTAssertEqual(try TemplateRender.render(source, flags: ["part.tips"]), "a\nb\n")
        XCTAssertEqual(try TemplateRender.render(source, flags: ["part.tips", "part.welcome", "layer"]), "a\nc\nd\n")
        XCTAssertThrowsError(try TemplateRender.render("//@if layer\na", flags: []))
        XCTAssertThrowsError(try TemplateRender.render("a\n//@endif", flags: []))
    }

    func testTidyDropsTheBlankLinesADroppedBlockLeaves() {
        XCTAssertEqual(TemplateRender.tidy(["struct A {", "", "    var b = 1", "", "", "    var c = 2", "", "}", "", ""]),
                       "struct A {\n    var b = 1\n\n    var c = 2\n}\n")
    }

    func testAPlaceholderTheCallsWordsSpellIsNeverFilled() throws {
        let filled = try TemplateRender.fill(#"Text({{s:welcome.title}})"#, values: ["s:welcome.title": #""{{s:welcome.body}}""#, "s:welcome.body": "x"])
        XCTAssertEqual(filled, #"Text("{{s:welcome.body}}")"#)
        XCTAssertThrowsError(try TemplateRender.fill("{{n:nothing}}", values: [:]))
    }
}

private extension Fixture {
    /// The text of `name` among `paths` when `expected`; nil when the call was not expected to write it.
    static func text(_ paths: [String], _ name: String, ifAny expected: Bool) throws -> String? {
        guard expected else {
            XCTAssertFalse(paths.contains { $0.hasSuffix("/" + name) }, "\(name) written for parts that do not use it")
            return nil
        }
        return try text(paths, name)
    }
}
