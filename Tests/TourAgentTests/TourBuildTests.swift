import Foundation
import XCTest
@testable import TourAgent

/// The kit compiled as apps would: the Seer call written into a Swift 6 app and a Swift 5 app with stand-ins for
/// Seer's names, each part alone under a prefix of its own, and the recipe app's call, built with `swift build` for
/// the Mac and with `xcodebuild` for the iPhone simulator; then every screen of the Seer app drawn offscreen.
/// Gated (`TOUR_BUILD=1`): the builds take a few minutes. `TOUR_KEEP=<folder>` builds there and keeps the package
/// and the drawings (`<folder>/shots`) for a look.
final class TourBuildTests: XCTestCase {
    func testTheSeerCallBuildsForMacAndIPhoneInBothLanguageModes() throws {
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["TOUR_BUILD"] == "1", "set TOUR_BUILD=1 to build the output")
        let package: URL
        if let keep = environment["TOUR_KEEP"], !keep.isEmpty {
            package = URL(fileURLWithPath: keep, isDirectory: true)
            try? FileManager.default.removeItem(at: package)
            try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        } else {
            package = try Fixture.folder()
        }

        var written = 0
        func write(_ input: TourAgent.Input, into target: String) throws {
            var call = input
            call.into = "Sources/\(target)/" + (input.into ?? TourSpec.defaultInto)
            written += try Fixture.write(call, into: package).paths.count
        }
        func add(_ text: String, _ name: String, to target: String) throws {
            let folder = package.appendingPathComponent("Sources/\(target)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try text.write(to: folder.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }

        for target in ["SeerSix", "SeerFive"] {
            try write(Fixture.seer(), into: target)
            try add(TourApps.seerStandIns, "StandIns.swift", to: target)
            try add(TourApps.seerUse, "SeerTabs.swift", to: target)
        }
        try add(TourApps.seerCheck, "SeerCheck.swift", to: "SeerSix")
        for call in TourApps.partCalls { try write(call, into: "Parts") }
        try add(TourApps.partsUse, "PartsTabs.swift", to: "Parts")
        try write(Fixture.example("recipes"), into: "Recipes")
        try add(TourApps.recipesUse, "RecipeTabs.swift", to: "Recipes")
        XCTAssertGreaterThan(written, 50)

        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(
            name: "TourApps",
            platforms: [.iOS(.v17), .macOS(.v14)],
            products: [.library(name: "TourApps", targets: ["SeerSix", "SeerFive", "Parts", "Recipes"])],
            targets: [
                .target(name: "SeerSix", swiftSettings: [.swiftLanguageMode(.v6)]),
                .target(name: "SeerFive", swiftSettings: [.swiftLanguageMode(.v5)]),
                .target(name: "Parts", swiftSettings: [.swiftLanguageMode(.v5)]),
                .target(name: "Recipes", swiftSettings: [.swiftLanguageMode(.v6)]),
                .executableTarget(name: "Check", dependencies: ["SeerSix"], swiftSettings: [.swiftLanguageMode(.v6)]),
            ]
        )
        """.write(to: package.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try add("""
        import Foundation
        import SeerSix

        let folder = CommandLine.arguments.dropFirst().first.map { URL(fileURLWithPath: $0, isDirectory: true) }
        if let folder { try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        let result = MainActor.assumeIsolated { SeerCheck.run(into: folder) }
        print("drew \\(result.drawn.count) screens")
        if !result.failed.isEmpty {
            print("did not draw: \\(result.failed)")
            exit(1)
        }
        """, "main.swift", to: "Check")

        // The Mac: every target, Swift 6 and Swift 5, with no warning in what the kit wrote.
        let mac = try run(["swift", "build", "--package-path", package.path])
        XCTAssertEqual(mac.status, 0, String(mac.log.suffix(6_000)))
        let warnings = mac.log.split(separator: "\n").filter { $0.contains("/Tour/") && $0.contains("warning:") }
        XCTAssertTrue(warnings.isEmpty, warnings.joined(separator: "\n"))

        // Every screen of the Seer app drawn: nothing traps.
        var check = ["swift", "run", "--package-path", package.path, "Check"]
        if environment["TOUR_KEEP"] != nil { check.append(package.appendingPathComponent("shots").path) }
        let drawn = try run(check)
        XCTAssertEqual(drawn.status, 0, String(drawn.log.suffix(4_000)))
        XCTAssertTrue(drawn.log.contains("drew 8 screens"), String(drawn.log.suffix(4_000)))

        // The iPhone simulator.
        let phone = try run(["xcodebuild", "-scheme", "TourApps", "-destination", "generic/platform=iOS Simulator",
                             "-derivedDataPath", package.appendingPathComponent("dd").path,
                             "-skipPackagePluginValidation", "-skipMacroValidation", "build"], in: package)
        XCTAssertTrue(phone.log.contains("** BUILD SUCCEEDED **"), String(phone.log.suffix(6_000)))
    }

    private func run(_ arguments: [String], in folder: URL? = nil) throws -> (status: Int32, log: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        if let folder { process.currentDirectoryURL = folder }
        let out = Pipe()
        process.standardOutput = out
        process.standardError = out
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
