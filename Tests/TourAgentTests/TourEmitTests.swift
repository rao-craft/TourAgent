import Foundation
import XCTest
@testable import TourAgent

/// What a call writes: the files each part asks for and their names, the Seer call's output against Seer's scorecard
/// and its spec's words, the original's look pinned in place, the same bytes a second time, and nothing written on a
/// refusal.
final class TourEmitTests: XCTestCase {
    private func names(_ result: TourResult) -> [String] {
        result.paths.map { ($0 as NSString).lastPathComponent }
    }

    func testEachPartWritesItsFilesAndNoOthers() throws {
        let table: [([TourPart], [String])] = [
            ([.welcome], ["Look", "Launch", "Haptics", "Layer", "WelcomeCard", "Mark"]),
            ([.tips], ["Look", "Launch", "Content", "Haptics", "Layer", "TipCard"]),
            ([.about], ["Look", "Launch", "Content", "Haptics", "Mark", "About", "AboutCover", "AboutPage", "AboutRow", "DriftingGradient"]),
            ([.welcome, .tips], ["Look", "Launch", "Content", "Haptics", "Layer", "WelcomeCard", "TipCard", "Mark"]),
            ([.tips, .about], ["Look", "Launch", "Content", "Haptics", "Layer", "TipCard", "Mark", "About", "AboutCover", "AboutPage", "AboutRow", "DriftingGradient"]),
        ]
        for (parts, stems) in table {
            let folder = try Fixture.folder()
            let result = try Fixture.write(TourAgent.Input(parts: parts, tips: ["home: Search | Find anything. | magnifyingglass"],
                                                           pages: ["map |  | Maps | Find your way. | Offline maps."]), into: folder)
            XCTAssertEqual(names(result), stems.map { "Tour\($0).swift" }, "\(parts)")
            let views = TourCatalog.files.filter { $0.kind == .view && stems.contains($0.stem) }.map { "Tour" + $0.stem }
            XCTAssertEqual(Set(result.views), Set(views), "\(parts)")
        }
    }

    func testAPrefixRenamesEveryTypeTheModifierAndTheFiles() throws {
        let folder = try Fixture.folder()
        var input = try Fixture.seer()
        input.prefix = "Seer"
        input.tips = (input.tips ?? []) + ["seer: TourLayer | A tip that names TourLayer keeps its words. | sparkles"]
        let result = try Fixture.write(input, into: folder)
        XCTAssertTrue(names(result).allSatisfy { $0.hasPrefix("Seer") }, "\(names(result))")
        XCTAssertEqual(result.modifier, ".seer(tab: String)")
        XCTAssertEqual(result.initializers, ["SeerLayer(tab: String, start: SeerLaunch.Start = SeerLaunch.start)", "SeerAbout(onClose: (() -> Void)? = nil)"])
        let code = Fixture.all(result.paths).map(\.text).joined(separator: "\n")
        // The code with its string literals emptied: the call's words may name anything.
        let swift = code.replacingOccurrences(of: #""(?:[^"\\\n]|\\.)*""#, with: #""""#, options: .regularExpression)
        let stems = TourCatalog.typeStems.joined(separator: "|")
        let left = swift.matchesOf(#"(?<![A-Za-z0-9_])(Tour(?:"# + stems + #"))(?![A-Za-z0-9_])"#)
        XCTAssertEqual(left, [], "a kit type kept the template's prefix")
        XCTAssertTrue(code.contains("func seer(tab: String) -> some View"))
        XCTAssertTrue(code.contains(#"title: "TourLayer""#), "a tip's words are never renamed")
        XCTAssertTrue(code.contains("A tip that names TourLayer keeps its words."))
    }

    /// Every `code` item of Seer's scorecard areas `onboarding` and `about`, as the scorer reads it: each pattern
    /// matches some Swift file the call wrote.
    func testTheSeerCallsOutputHoldsEveryScorecardCodeFact() throws {
        let items: [(String, [String])] = [
            ("B-onboarding-4", ["Show me around", #"Your conversations, organized\."#, #"Your thoughts, remembered\."#]),
            ("B-onboarding-5", [#"black\.opacity\(0\.55\)"#]),
            ("B-onboarding-6", ["Filter by Category", "Your Memories", "Add a Note", "Your AI Models", "Your Profile", "Your Wallet"]),
            ("B-onboarding-7", [#"See how your thoughts connect over time\."#, #"moments worth revisiting\."#,
                                #"Tap any to explore, or long-press to generate\."#, #"withdraw when ready\."#]),
            ("B-onboarding-8", [#"line\.3\.horizontal\.decrease\.circle"#, #"wallet\.bifold"#, #"\"brain\""#, #"\"infinity\""#]),
            ("B-onboarding-9", ["Got it", #"scale[A-Za-z]*\([^)\n]*0\.88"#]),
            ("B-about-4", [#"Think in conversations\."#, #"Capture what matters\."#, #"See how you think\."#,
                           #"Your memory, mapped\."#, #"Choose your engine\."#, #"Compose with intention\."#]),
            ("B-about-5", ["Resonance tracking shows what you explore most", "Instant full-text search across all notes",
                           "Builds an AI model of how you think", "Pinch and pan to navigate the network",
                           "Updates as new model versions release", "Export and share your writing easily"]),
            ("B-about-6", [#"bubble\.left\.and\.bubble\.right\.fill"#, #"point\.3\.connected\.trianglepath\.dotted"#,
                           #"pencil\.and\.outline"#, #"eye\.fill"#]),
            ("B-about-7", ["(?i)radialGradient", #"opacity\(0\.82\)"#]),
        ]
        let files = try Fixture.all(Fixture.write(Fixture.seer(), into: Fixture.folder()).paths)
        for (id, patterns) in items {
            for pattern in patterns {
                let expression = try NSRegularExpression(pattern: pattern)
                let found = files.contains { file in
                    expression.firstMatch(in: file.text, range: NSRange(file.text.startIndex..., in: file.text)) != nil
                }
                XCTAssertTrue(found, "\(id): no file matches \(pattern)")
            }
        }
    }

    /// The words in double quotes in the spec's Welcome, Tours and About Seer sections, which the screenshots' text
    /// is read against: each is in the code, a line break as `\n`.
    func testEveryQuotedStringOfSeersSpecIsInTheOutput() throws {
        let quoted = [
            #"Welcome to Seer"#,
            #"Your conversations, organized.\nYour thoughts, remembered."#,
            #"Show me around"#,
            #"Skip"#,
            #"1 of 3"#,
            #"Next"#,
            #"Got it"#,
            #"Threads"#,
            #"Access your conversation threads and resonance signals. See how your thoughts connect over time."#,
            #"Filter by Category"#,
            #"Browse and organize your notes by category. Tap to open the category picker."#,
            #"Your Memories"#,
            #"Toggle to view only notes marked as memories — moments worth revisiting."#,
            #"Add a Note"#,
            #"Create a new note or import existing content. Your Library, your way."#,
            #"Your AI Models"#,
            #"Each card is a personalized model built from your notes and conversations. Tap any to explore, or long-press to generate."#,
            #"Your Profile"#,
            #"View your account details and manage your Seer identity."#,
            #"Your Wallet"#,
            #"Track credits earned from your models, see cashout history, and withdraw when ready."#,
            #"About Seer"#,
            #"Everything\nSeer can do."#,
            #"A guided tour of every feature,\nat your own pace."#,
            #"Begin the tour"#,
            #"Think in conversations."#,
            #"Each chat is a living thread — ask, explore, return. Seer maintains context within threads so your thinking stays connected over time."#,
            #"Start separate threads for different topics"#,
            #"Return and continue any past conversation"#,
            #"Resonance tracking shows what you explore most"#,
            #"Reading history keeps every session accessible"#,
            #"Notes"#,
            #"Capture what matters."#,
            #"A private library of thoughts, ideas, and observations. Organized by category, searched instantly, and stored entirely on your device."#,
            #"Write and edit notes with rich formatting"#,
            #"Organize by custom categories with colors"#,
            #"Lock individual notes for privacy"#,
            #"Instant full-text search across all notes"#,
            #"Seer"#,
            #"See how you think."#,
            #"Seer analyzes your notes and conversations to surface the words, phrases, and themes that define your perspective — rendered as a living cloud."#,
            #"Word cloud built entirely from your content"#,
            #"Phrase cloud reveals your recurring ideas"#,
            #"Contribution tracking across time"#,
            #"Builds an AI model of how you think"#,
            #"Atlas"#,
            #"Your memory, mapped."#,
            #"A spatial graph of how your ideas connect. Atlas uses hierarchical indexing to build a living network of your knowledge — explore clusters and discover hidden links."#,
            #"Interactive graph of all your content"#,
            #"Clusters group ideas that think alike"#,
            #"Pinch and pan to navigate the network"#,
            #"Connections discovered automatically"#,
            #"Models"#,
            #"Choose your engine."#,
            #"Browse and select the AI models that power Seer. Switch between them to match your needs — speed, depth, or specialty."#,
            #"Multiple AI model options available"#,
            #"Switch models globally or per session"#,
            #"Detailed model info and capabilities"#,
            #"Updates as new model versions release"#,
            #"Write"#,
            #"Compose with intention."#,
            #"A focused writing environment with a rich keyboard toolbar. Format, structure, and refine your thoughts without leaving your flow."#,
            #"Rich text formatting toolbar above keyboard"#,
            #"Lists, headers, and text emphasis"#,
            #"Keyboard shortcuts for power users"#,
            #"Export and share your writing easily"#,
        ]
        let code = try Fixture.all(Fixture.write(Fixture.seer(), into: Fixture.folder()).paths).map(\.text).joined(separator: "\n")
        for words in quoted {
            XCTAssertTrue(code.contains(words), "not in the output: \(words)")
        }
    }

    /// The original's views, value for value: what the screenshots are compared by. A change here is a change to
    /// Seer's look, and the inventory says where each value comes from.
    func testTheSeerOutputKeepsTheOriginalsLook() throws {
        let paths = try Fixture.write(Fixture.seer(), into: Fixture.folder()).paths
        let table: [(String, [String])] = [
            ("TourLayer.swift", [".zIndex(100)", ".zIndex(99)", ".ignoresSafeArea(edges: .top)", ".allowsHitTesting(presenting)",
                                 ".animation(.spring(response: 0.4, dampingFraction: 0.85), value: welcomed)",
                                 ".animation(.spring(response: 0.35, dampingFraction: 0.85), value: index)",
                                 ".animation(.easeInOut(duration: 0.25), value: tab)",
                                 "withAnimation(.spring(response: 0.4, dampingFraction: 0.8))", "withAnimation(.easeOut(duration: 0.2))",
                                 "withAnimation(.spring(response: 0.35, dampingFraction: 0.8))"]),
            ("TourWelcomeCard.swift", ["VStack(spacing: 24)", "TourMark(size: 100, casting: true)", ".padding(.bottom, 2)", "VStack(spacing: 8)",
                                       "VStack(spacing: 12)", ".frame(maxWidth: .infinity)", ".padding(.vertical, 14)",
                                       ".clipShape(RoundedRectangle(cornerRadius: 14))", ".padding(.vertical, 4)", ".padding(28)",
                                       ".background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))",
                                       ".shadow(color: .black.opacity(0.2), radius: 24, y: 8)", ".padding(.horizontal, 36)"]),
            ("TourMark.swift", [".shadow(color: Color.primary.opacity(0.3), radius: 3, x: 1, y: 1)", ".rotationEffect(.degrees(rotation))",
                                ".linear(duration: 42).repeatForever(autoreverses: false)", ".clipShape(.rect(cornerRadius: cornerRadius))", "SeerMark()"]),
            ("TourTipCard.swift", ["ZStack(alignment: tip.place.alignment)", ".allowsHitTesting(false)",
                                   "insertion: .scale(scale: 0.88, anchor: tip.place.anchor)", "removal: .opacity",
                                   "VStack(alignment: .leading, spacing: 14)", "HStack(spacing: 10)", "Spacer(minLength: 0)",
                                   #"Text("\(number) of \(count)")"#, ".foregroundStyle(.tertiary)", ".fixedSize(horizontal: false, vertical: true)",
                                   "HStack(spacing: 8)", ".frame(width: 32, height: 32)", ".background(.ultraThinMaterial, in: Circle())",
                                   "HStack(spacing: 5)", "Color.secondary.opacity(0.3)", ".frame(width: 5, height: 5)",
                                   ".padding(.horizontal, 18)", ".padding(.vertical, 8)", ".background(TourLook.accent, in: Capsule())",
                                   ".padding(16)", ".frame(maxWidth: 270)", ".background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))",
                                   ".shadow(color: .black.opacity(0.15), radius: 14, y: 4)",
                                   "EdgeInsets(top: 112, leading: 16, bottom: 0, trailing: 0)", "EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 16)"]),
            ("TourAbout.swift", ["GeometryReader { geometry in", "ZStack(alignment: .top)", ".opacity(0.9)", "VStack(spacing: 0)",
                                 ".padding(.bottom, 28)", ".frame(width: geometry.size.width, height: geometry.size.height)",
                                 ".multilineTextAlignment(.center)", ".presentationDragIndicator(.visible)",
                                 "withAnimation(.easeInOut(duration: 1.3))", ".tabViewStyle(.page(indexDisplayMode: .never))",
                                 ".imageScale(.medium)", ".fontWeight(.semibold)", ".padding(10)", ".padding(.top, 12)", ".padding(.trailing, 20)",
                                 "HStack(spacing: 24)", ".padding(13)", ".opacity(page > 0 ? 1 : 0.2)", ".disabled(page == 0)",
                                 ".frame(width: index == page ? 20 : 6, height: 6)",
                                 ".animation(.spring(response: 0.3, dampingFraction: 0.75), value: page)",
                                 ".animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)",
                                 ".padding(.horizontal, 32)", ".padding(.top, 16)", #"static let name = "About Seer""#,
                                 ".toolbar(.hidden, for: .navigationBar)"]),
            ("TourAboutCover.swift", ["TourMark(size: 96, cornerRadius: 22)", ".shadow(radius: 8)", ".opacity(appeared ? 0.22 : 0)",
                                      ".scaleEffect(appeared ? 0.76 : 0.7 * 0.76)",
                                      "withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1))", ".frame(height: 32)",
                                      ".foregroundStyle(.thickMaterial)", ".foregroundStyle(.regularMaterial)", ".offset(y: appeared ? 0 : 20)",
                                      ".delay(0.18)", "HStack(spacing: 8)", ".padding(.horizontal, 28)", ".padding(.vertical, 14)",
                                      ".background(.ultraThinMaterial, in: Capsule())", ".shadow(color: .black.opacity(0.1), radius: 10, y: 4)",
                                      ".offset(y: appeared ? 0 : 12)", ".delay(0.28)", ".frame(height: 64)", ".padding(.horizontal, 36)"]),
            ("TourAboutPage.swift", ["VStack(spacing: 20)", "Spacer(minLength: 4)", ".frame(width: 76, height: 76)", ".font(.system(size: 30))",
                                     ".shadow(color: .black.opacity(0.12), radius: 14, y: 5)", ".scaleEffect(appeared ? 1 : 0.5)",
                                     ".animation(.spring(response: 0.5, dampingFraction: 0.75), value: appeared)", ".offset(y: appeared ? 0 : 14)",
                                     ".lineSpacing(3)", ".padding(.vertical, 18)", ".background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))",
                                     ".shadow(color: .black.opacity(0.06), radius: 10, y: 4)", "VStack(spacing: 9)", ".delay(0.15 + Double(index) * 0.07)",
                                     "Spacer(minLength: 20)", ".padding(.horizontal, 20)", ".scrollIndicators(.hidden)"]),
            ("TourAboutRow.swift", ["HStack(spacing: 14)", ".fill(TourLook.accent.opacity(0.12))", ".frame(width: 38, height: 38)",
                                    ".font(.system(size: 14, weight: .semibold))", ".multilineTextAlignment(.leading)", ".padding(.vertical, 12)",
                                    ".background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))",
                                    ".shadow(color: .black.opacity(0.05), radius: 6, y: 2)", ".scaleEffect(tapped ? 0.97 : 1)",
                                    ".animation(.spring(response: 0.2, dampingFraction: 0.6), value: tapped)", ".seconds(0.15)"]),
            ("TourDriftingGradient.swift", ["@State private var start = Date.now", "paused: reduceMotion || Self.holds",
                                            "let time = Self.holds ? 24.41 : 24.41 + timeline.date.timeIntervalSince(start) * 0.0525",
                                            #"private static let holds = !(TourLaunch.destination ?? "").isEmpty"#,
                                            "max(geometry.size.width, geometry.size.height) * 0.85", "(colors.first ?? .white)",
                                            "cos(time * 0.70 + phase) * 0.38 + 0.50", "sin(time * 0.53 + phase + 1.20) * 0.38 + 0.50",
                                            "colors: [color.opacity(0.82), color.opacity(0)]", "startRadius: 0", "endRadius: radius"]),
            ("TourLook.swift", ["static var accent: Color { Color.accent }", "static var scrim: Color { Color.black.opacity(0.55) }",
                                "Font.title.bold()", "static var aboutDesign: Font.Design { .serif }",
                                "Font.system(size: 44, weight: .bold, design: aboutDesign)", "Font.system(.title3, design: aboutDesign).italic()"]),
            ("TourContent.swift", ["static let cover: [Color] = TourPalette.aurora", "Color(red: 0.129, green: 0.78, blue: 0.678)",
                                   "palette: TourPalette.sunrise", "place: .topTrailing", "place: .center"]),
        ]
        for (name, snippets) in table {
            let text = try Fixture.text(paths, name)
            for snippet in snippets {
                XCTAssertTrue(text.contains(snippet), "\(name) lost `\(snippet)`")
            }
        }
    }

    func testTheSameCallWritesTheSameBytesAndSaysSo() throws {
        let folder = try Fixture.folder()
        let first = try Fixture.write(Fixture.seer(), into: folder)
        let bytes = try first.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
        let second = try Fixture.write(Fixture.seer(), into: folder)
        XCTAssertEqual(second.paths, first.paths)
        XCTAssertEqual(try second.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }, bytes)
        XCTAssertTrue(first.made.allSatisfy { $0.state == .written }, "\(first.made)")
        XCTAssertTrue(second.made.allSatisfy { $0.state == .unchanged }, "\(second.made)")
        let other = try Fixture.write(Fixture.seer(), into: Fixture.folder())
        XCTAssertEqual(try other.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }, bytes, "the same call writes the same bytes in any folder")
    }

    func testFilesACallNoLongerAsksForAreTakenAwayAndTheAppsAreKept() throws {
        let folder = try Fixture.folder()
        let all = try Fixture.write(Fixture.seer(), into: folder)
        let tour = (all.paths[0] as NSString).deletingLastPathComponent
        let own = (tour as NSString).appendingPathComponent("TourNotes.swift")
        try "struct TourNotes {}\n".write(toFile: own, atomically: true, encoding: .utf8)
        var aboutOnly = try Fixture.seer()
        aboutOnly.parts = [.about]
        aboutOnly.launch = ["about = about"]
        let result = try Fixture.write(aboutOnly, into: folder)
        let removed = result.made.filter { $0.state == .removed }.compactMap { $0.path.map { ($0 as NSString).lastPathComponent } }
        XCTAssertEqual(Set(removed), ["TourLayer.swift", "TourWelcomeCard.swift", "TourTipCard.swift"])
        for name in removed { XCTAssertFalse(FileManager.default.fileExists(atPath: (tour as NSString).appendingPathComponent(name)), name) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: own), "a file of the app's own is never taken away")
    }

    func testARefusedCallWritesNothing() throws {
        let folder = try Fixture.folder()
        var input = try Fixture.seer()
        input.tips = ["seer: Threads"]
        input.tuning = ["tip.scale = 4"]
        XCTAssertThrowsError(try Fixture.write(input, into: folder)) { error in
            guard case TourError.problems(let reasons) = error else { return XCTFail("\(error)") }
            // The tip line, the number, and the launch line that named the tip's tab: every reason at once.
            XCTAssertEqual(reasons.count, 3, "\(reasons)")
            XCTAssertTrue(reasons.contains { $0.hasPrefix("launch line 2") }, "\(reasons)")
        }
        let left = try FileManager.default.subpathsOfDirectory(atPath: folder.path)
        XCTAssertEqual(left, [], "a refusal writes nothing")
    }

    func testTheAnswerSaysWhatTheAppCallsAndKeeps() throws {
        let result = try Fixture.write(Fixture.seer(), into: Fixture.folder())
        XCTAssertEqual(result.modifier, ".tour(tab: String)")
        XCTAssertEqual(result.initializers, ["TourLayer(tab: String, start: TourLaunch.Start = TourLaunch.start)", "TourAbout(onClose: (() -> Void)? = nil)"])
        XCTAssertEqual(result.keys, ["seer.tour.welcomed", "seer.tour.finished"])
        XCTAssertEqual(result.launch, ["onboarding = welcome", "onboarding.tips = tips(seer)", "about = about"])
        XCTAssertEqual(result.expected.map(\.name), ["TourLayer", "TourWelcomeCard", "TourMark", "TourTipCard", "TourAbout",
                                                    "TourAboutCover", "TourAboutPage", "TourAboutRow", "TourDriftingGradient"])
        XCTAssertTrue(result.notes.contains { $0.hasPrefix("Apply `.tour(tab:)` to the app's tab view") }, "\(result.notes)")
        XCTAssertTrue(result.notes.contains { $0.hasPrefix("Present `TourAbout()` as a sheet") }, "\(result.notes)")
    }

    func testAPaletteIsWrittenAsTheColoursSwiftUITakes() {
        XCTAssertEqual(SwiftLiteral.color(0x21C7AD), "Color(red: 0.129, green: 0.78, blue: 0.678)")
        XCTAssertEqual(SwiftLiteral.color(0xFFFFFF), "Color(red: 1, green: 1, blue: 1)")
        XCTAssertEqual(SwiftLiteral.color(0x000000), "Color(red: 0, green: 0, blue: 0)")
    }
}
