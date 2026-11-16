import Foundation
import GraniteAgents
import XCTest
@testable import TourAgent

/// The package as an app finds it: by its record, with the schema a model is shown, the guide a host prompts with,
/// the schema files beside it, and a call made through the roster.
final class TourAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let tour = try XCTUnwrap(GraniteRoster.discovered().package("tour"), "the record is in this test binary")
        XCTAssertEqual(tour.module, "TourAgent")
        XCTAssertEqual(tour.summary, TourAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let tour = AnyAgentPackage(TourAgent.self)
        let lines = GraniteSchema.array(.string)
        XCTAssertEqual(tour.schema, .object([
            .init(name: "into", schema: .string, required: false),
            .init(name: "parts", schema: .array(.choice(["welcome", "tips", "about"])), required: false),
            .init(name: "mark", schema: .string, required: false),
            .init(name: "tips", schema: lines, required: false),
            .init(name: "palettes", schema: lines, required: false),
            .init(name: "pages", schema: lines, required: false),
            .init(name: "strings", schema: lines, required: false),
            .init(name: "tuning", schema: lines, required: false),
            .init(name: "look", schema: lines, required: false),
            .init(name: "launch", schema: lines, required: false),
            .init(name: "defaultsKey", schema: .string, required: false),
            .init(name: "prefix", schema: .string, required: false),
            .init(name: "imports", schema: lines, required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(tour.takesDirectory)
        XCTAssertEqual(Set(tour.fields.keys), Set(tour.schema.fields.map(\.name)).subtracting(["directory"]),
                       "a note beside every field the model sees")
        XCTAssertEqual(tour.lanes, 2)
        XCTAssertEqual(tour.makes.map(\.kind), ["view", "support"])
    }

    func testEveryKeyRoleAndStateIsNamedBesideItsField() {
        for key in TourStrings.keys { XCTAssertTrue(TourAgent.fields["strings"]?.contains(key) == true, key) }
        for key in TourTuning.keys { XCTAssertTrue(TourAgent.fields["tuning"]?.contains(key) == true, key) }
        for role in TourLookRoles.roles { XCTAssertTrue(TourAgent.fields["look"]?.contains(role) == true, role) }
        for state in ["welcome", "tips(<tab>)", "done", "about", "about(<page"] {
            XCTAssertTrue(TourAgent.fields["launch"]?.contains(state) == true, state)
        }
    }

    func testTheGuideTeachesEveryLineAndOneCallPerMode() {
        let guide = AnyAgentPackage(TourAgent.self).guide
        for word in ["tips", "palettes", "pages", "strings", "tuning", "look", "launch", "mark", "parts", "prefix",
                     "defaultsKey", ".tour(tab:", "TourAbout()", "onClose", "#Preview", "UserDefaults.standard.string(forKey: \"destination\")",
                     "spring(0.4, 0.8)", "easeOut(0.2)", "bottomTrailing"] {
            XCTAssertTrue(guide.contains(word), "the guide says \(word)")
        }
        // Every string key, tuning key and look role is in the guide, so the model never has to guess one.
        for key in TourStrings.keys + TourTuning.keys + TourLookRoles.roles { XCTAssertTrue(guide.contains(key), "the guide names \(key)") }
        let examples = guide.components(separatedBy: "{\"").count - 1
        XCTAssertEqual(examples, 3, "three example calls: a whole tour, the pager alone, the layer beside the app's own names")
        XCTAssertFalse(guide.contains("Seer"), "no app's words to copy")
    }

    func testTheGuidesExamplesAreCallsTheKitReads() throws {
        let guide = AnyAgentPackage(TourAgent.self).guide
        var calls: [String] = []
        var rest = Substring(guide)
        while let start = rest.range(of: "{\"") {
            var depth = 0, quoted = false, escaped = false, end = start.lowerBound
            for index in rest[start.lowerBound...].indices {
                let character = rest[index]
                if quoted {
                    if escaped { escaped = false } else if character == "\\" { escaped = true } else if character == "\"" { quoted = false }
                    continue
                }
                if character == "\"" { quoted = true } else if character == "{" { depth += 1 } else if character == "}" {
                    depth -= 1
                    if depth == 0 { end = index; break }
                }
            }
            calls.append(String(rest[start.lowerBound...end]))
            rest = rest[rest.index(after: end)...]
        }
        XCTAssertEqual(calls.count, 3)
        for call in calls {
            let input = try JSONDecoder().decode(TourAgent.Input.self, from: Data(call.utf8))
            XCTAssertNil(Fixture.problems(input), call)
        }
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming the files.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        var input = try JSONSerialization.jsonObject(with: Data(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"))) as? [String: Any] ?? [:]
        input["directory"] = folder.path
        let answer = try await AnyAgentPackage(TourAgent.self).perform(JSONSerialization.data(withJSONObject: input),
                                                                        host: AgentHost(directory: folder.path, ask: "the first-run tour"))
        let result = try JSONDecoder().decode(TourResult.self, from: answer)
        let tour = folder.appendingPathComponent("Components/Tour").path
        XCTAssertEqual(result.path, result.paths.first)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(tour + "/"), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        XCTAssertEqual(result.paths.map { ($0 as NSString).lastPathComponent }, [
            "TourLook.swift", "TourLaunch.swift", "TourContent.swift", "TourHaptics.swift", "TourLayer.swift",
            "TourWelcomeCard.swift", "TourTipCard.swift", "TourMark.swift", "TourAbout.swift", "TourAboutCover.swift",
            "TourAboutPage.swift", "TourAboutRow.swift", "TourDriftingGradient.swift",
        ])
        XCTAssertEqual(result.modifier, ".tour(tab: String)")
        XCTAssertEqual(result.initializers, ["TourLayer(tab: String, start: TourLaunch.Start = TourLaunch.start)", "TourAbout(onClose: (() -> Void)? = nil)"])
        XCTAssertEqual(result.keys, ["seer.tour.welcomed", "seer.tour.finished"])
        XCTAssertEqual(result.launch, ["onboarding = welcome", "onboarding.tips = tips(seer)", "about = about"])
        let raw = try XCTUnwrap(JSONSerialization.jsonObject(with: answer) as? [String: Any])
        XCTAssertEqual(raw["format"] as? String, "granite-answer/1")
    }

    /// A host over the wire may name its folder only in `AgentHost`: every file lands there all the same.
    func testTheHostsFolderIsUsedWhenTheCallNamesNone() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["parts": ["about"], "pages": ["map |  | Maps | Find your way. | Offline maps of every trail."]])
        let answer = try await AnyAgentPackage(TourAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(TourResult.self, from: answer)
        XCTAssertFalse(result.paths.isEmpty)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path + "/"), "\(path) is not under the host's folder")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
    }

    /// A refusal reaches the host as one: the call's to fix, every reason in it.
    func testARefusalReachesTheHostWithEveryReason() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["tips": ["home Search"], "tuning": ["tip.scale = 9"]])
        do {
            _ = try await AnyAgentPackage(TourAgent.self).perform(input, host: AgentHost(directory: folder.path))
            XCTFail("the call is refused")
        } catch {
            let refusal = try XCTUnwrap(AgentRefusal.of(error), "\(error)")
            XCTAssertEqual(refusal.kind, .call)
            XCTAssertEqual(refusal.reasons.count, 2, refusal.reasons.joined(separator: "\n"))
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [], "nothing was written")
    }

    // MARK: The schema files

    /// `Schema/tour.input.schema.json` says what the package's schema says, every field's note included.
    /// `TOUR_WRITE_SCHEMA=1` writes it again from the package.
    func testTheInputSchemaFileIsThePackagesSchema() throws {
        let tour = AnyAgentPackage(TourAgent.self)
        var expected = try XCTUnwrap(JSONSerialization.jsonObject(with: tour.schema.jsonSchema(notes: tour.fields, hiding: ["directory"])) as? [String: Any])
        expected["$id"] = "https://github.com/rao-craft/TourAgent/blob/main/Schema/tour.input.schema.json"
        expected["$schema"] = "https://json-schema.org/draft/2020-12/schema"
        expected["description"] = "Every field a call to tour may give; `directory` is Craft's, never the model's."
        expected["title"] = "What tour takes (craft-agent/1)"
        try check(expected, file: "Schema/tour.input.schema.json")
    }

    /// `Schema/tour.answer.schema.json` names the kinds the package makes.
    func testTheAnswerSchemaFileNamesTheKindsItMakes() throws {
        let kinds = TourAgent.makes.map(\.kind)
        let item: [String: Any] = [
            "type": "object",
            "required": ["kind", "name"],
            "properties": ["kind": ["type": "string", "enum": kinds], "name": ["type": "string"]],
        ]
        let expected: [String: Any] = [
            "$id": "https://github.com/rao-craft/TourAgent/blob/main/Schema/tour.answer.schema.json",
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "allOf": [["$ref": "https://github.com/riteshpakala/Granite/blob/main/Schema/granite-agent-answer.schema.json"]],
            "description": "A granite-answer/1 answer; what tour makes and expects is one of its own kinds.",
            "properties": [
                "made": ["type": "array", "items": item],
                "expected": ["type": "array", "items": item],
                "modifier": ["type": ["string", "null"], "description": "the modifier the app applies the first-run layer with, as a line"],
                "initializers": ["type": "array", "items": ["type": "string"], "description": "each root view's initializer, as a line a page body calls"],
                "launch": ["type": "array", "items": ["type": "string"], "description": "each launch destination and the state it opens in"],
                "keys": ["type": "array", "items": ["type": "string"], "description": "the UserDefaults keys the first run is kept under"],
                "views": ["type": "array", "items": ["type": "string"], "description": "the views written, by type name"],
            ],
            "title": "What tour answers (granite-answer/1)",
        ]
        try check(expected, file: "Schema/tour.answer.schema.json")
    }

    /// The example answer in `Schema/examples` is the Seer call's, as the roster stamps it, its paths relative to the
    /// project. `TOUR_WRITE_SCHEMA=1` writes it again.
    func testTheSeerExampleAnswerIsTheSeerCallsAnswer() async throws {
        let folder = try Fixture.folder()
        var input = try JSONSerialization.jsonObject(with: Data(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"))) as? [String: Any] ?? [:]
        input["directory"] = folder.path
        let answer = try await AnyAgentPackage(TourAgent.self).perform(JSONSerialization.data(withJSONObject: input), host: AgentHost(directory: folder.path))
        let text = String(decoding: answer, as: UTF8.self).replacingOccurrences(of: folder.path + "/", with: "")
        let expected = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        try check(expected, file: "Schema/examples/seer.answer.json")
    }

    private func check(_ expected: [String: Any], file: String) throws {
        let url = Fixture.package.appendingPathComponent(file)
        if ProcessInfo.processInfo.environment["TOUR_WRITE_SCHEMA"] == "1" {
            let data = try JSONSerialization.data(withJSONObject: expected, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try (String(decoding: data, as: UTF8.self) + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
        let found = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? NSDictionary, file)
        XCTAssertEqual(found, expected as NSDictionary, "\(file) is not what the package says: run with TOUR_WRITE_SCHEMA=1")
    }
}
