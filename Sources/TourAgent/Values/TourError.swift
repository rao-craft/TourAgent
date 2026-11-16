import Foundation
import GraniteAgents

/// What a call can say instead of writing.
public enum TourError: Error, Equatable, CustomStringConvertible, AgentRefusing {
    /// Every problem with the call at once, so all are fixed in one call: nothing was written.
    case problems([String])

    /// Every one of them is the call's to fix.
    public var refusal: AgentRefusal {
        switch self {
        case .problems(let reasons): return AgentRefusal(.call, reasons)
        }
    }

    public var description: String {
        switch self {
        case .problems(let reasons):
            let count = reasons.count == 1 ? "1 problem" : "\(reasons.count) problems"
            return "\(count) with the call, so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
