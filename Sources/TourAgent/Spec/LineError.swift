import Foundation

/// Why one line of the call is not understood: said with the line, it is one of a refusal's reasons.
struct LineError: Error, Equatable, CustomStringConvertible {
    let reason: String

    init(_ reason: String) { self.reason = reason }

    var description: String { reason }
}
