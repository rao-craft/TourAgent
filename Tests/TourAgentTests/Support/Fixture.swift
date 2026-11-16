import Foundation
@testable import TourAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tour-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The package's own folder, found from this file.
    static let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// An example call in `Schema/examples`, as a host sends it.
    static func example(_ name: String) throws -> TourAgent.Input {
        let data = try Data(contentsOf: package.appendingPathComponent("Schema/examples/\(name).json"))
        return try JSONDecoder().decode(TourAgent.Input.self, from: data)
    }

    /// The call that reproduces Seer's welcome, tips and about pager.
    static func seer() throws -> TourAgent.Input { try example("seer") }

    /// `input` written into `folder`, answered.
    @discardableResult
    static func write(_ input: TourAgent.Input, into folder: URL) throws -> TourResult {
        var call = input
        call.directory = folder.path
        return try TourAgent.write(call, note: { _ in }, yield: { _ in })
    }

    /// The text of the file `name` among `paths`.
    static func text(_ paths: [String], _ name: String) throws -> String {
        guard let path = paths.first(where: { $0.hasSuffix("/" + name) }) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: name])
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Every file `paths` names that is still on disk, joined: what a check over an app's Swift reads.
    static func all(_ paths: [String]) -> [(name: String, text: String)] {
        paths.compactMap { path in
            (try? String(contentsOfFile: path, encoding: .utf8)).map { ((path as NSString).lastPathComponent, $0) }
        }
    }

    /// The problems a call's lines have, or nil when it is read.
    static func problems(_ input: TourAgent.Input) -> [String]? {
        switch TourSpec.read(input) {
        case .success: return nil
        case .failure(.problems(let reasons)): return reasons
        }
    }

    /// The spec a call reads as; fails the test when it is refused.
    static func spec(_ input: TourAgent.Input) throws -> TourSpec {
        try TourSpec.read(input).get()
    }
}
