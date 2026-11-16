import CryptoKit
import Foundation
import XCTest
@testable import TourAgent

/// PIN: ADDITIVE ONLY. A tuning key is a word a call says, and a call that says none of the new ones writes what it
/// wrote before them, byte for byte. Each call here is held to the bytes the agent wrote at 67aebc3, the commit before
/// `about.mark.opacity` and `about.mark.scale`: Seer's call as it stood then, the same with those two at their
/// defaults of 1, Seer's call as it stood at 56b4cde (its clock from 24.05, not held: those bytes held through
/// 67aebc3 too), the recipe call and the three part calls of the gated build. A call's digest is the SHA-256 of its
/// files' paths and SHA-256s, one a line.
final class SameBytesTests: XCTestCase {
    static let before: [String: String] = [
        "seer": "9ce610bf22bf664178bb0ad561159450b2dc436b6e1e05d82c988dc5c18c80cb",
        "seer.defaults": "9ce610bf22bf664178bb0ad561159450b2dc436b6e1e05d82c988dc5c18c80cb",
        "seer.unheld": "c53fe86444b8903316d10a1e1636d3042c6e621cdf8613480b037412380d9fc5",
        "recipes": "a8e985b5490ea824107454bd172de2f09f1305b4a8c94e2b3b40ec2bcf67d29e",
        "parts.about": "051e99b81fe1e6e159bfcfabaa9a96cdd2c08383b70b4ef02bd5da6a4f6ff2d4",
        "parts.tips": "0d7a7201bdbe84b291826399838f2445fad15e772fe1468500c2a623948018de",
        "parts.welcome": "b31250b7b6b5ba653ff18e51b766a55d02db9a1a10ccb087af0bff0b2bd4c7a8",
    ]

    func testEveryCallWithoutTheNewKeysWritesTheBytesItWroteBefore() throws {
        let scenarios = try Self.scenarios()
        XCTAssertEqual(Set(scenarios.map(\.name)), Set(Self.before.keys))
        for (name, input) in scenarios {
            let folder = try Fixture.folder()
            let result = try Fixture.write(input, into: folder)
            let files = try result.paths.sorted().map { path -> String in
                let bytes = try Data(contentsOf: URL(fileURLWithPath: path))
                return path.replacingOccurrences(of: folder.path + "/", with: "") + " " + Self.hex(SHA256.hash(data: bytes))
            }
            let digest = Self.hex(SHA256.hash(data: Data(files.joined(separator: "\n").utf8)))
            XCTAssertEqual(digest, Self.before[name], "\(name) wrote other bytes than before:\n" + files.joined(separator: "\n"))
        }
    }

    /// The calls: Seer's less the mark's opacity and scale (its call at 67aebc3), the same with those at 1, Seer's at
    /// 56b4cde (its clock from 24.05 and no hold), the recipe call, and the part calls the gated build writes.
    static func scenarios() throws -> [(name: String, input: TourAgent.Input)] {
        let seer = try Fixture.seer()
        var before = seer
        before.tuning = seer.tuning?.filter { !$0.hasPrefix("about.mark.opacity") && !$0.hasPrefix("about.mark.scale") }
        var defaults = before
        defaults.tuning = (before.tuning ?? []) + ["about.mark.opacity = 1", "about.mark.scale = 1"]
        var unheld = before
        unheld.tuning = before.tuning?.compactMap { line -> String? in
            if line.hasPrefix("gradient.hold") { return nil }
            return line.hasPrefix("gradient.start") ? "gradient.start = 24.05" : line
        }
        let recipes = try Fixture.example("recipes"), parts = TourApps.partCalls
        return [("seer", before), ("seer.defaults", defaults), ("seer.unheld", unheld), ("recipes", recipes),
                ("parts.about", parts[0]), ("parts.tips", parts[1]), ("parts.welcome", parts[2])]
    }

    static func hex(_ digest: SHA256.Digest) -> String {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
