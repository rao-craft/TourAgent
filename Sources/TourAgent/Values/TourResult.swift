import Foundation
import GraniteAgents

/// What a call answers, as `granite-answer/1`: the files written, as absolute paths, how the app uses what they
/// declare, and what the call made of the parts it was asked for.
public struct TourResult: AgentAnswer, Equatable {
    /// The first file written.
    public var path: String?
    /// Every file written or removed.
    public var paths: [String]
    /// The views written, by type name.
    public var views: [String]
    /// The first-run layer as the app applies it over its tabs, as a line: `.tour(tab: String)`; nil when neither
    /// the welcome nor the tips were written.
    public var modifier: String?
    /// Each root view's initializer, as a line a page body calls: `TourAbout(onClose: (() -> Void)? = nil)`.
    public var initializers: [String]
    /// Each launch destination the kit opens for, and the state it opens in: `onboarding = welcome`.
    public var launch: [String]
    /// The UserDefaults keys the first run is remembered under.
    public var keys: [String]
    /// One sentence each: what the call left out or the app still has to do, and why.
    public var notes: [String]
    /// Each view and support file written, and each file of an earlier call taken away.
    public var made: [AgentMade]
    /// The views the parts asked for.
    public var expected: [AgentExpected]
    /// What it could only do in part.
    public var problems: [AgentProblem]

    public init(path: String?, paths: [String], views: [String], modifier: String?, initializers: [String], launch: [String],
                keys: [String], notes: [String], made: [AgentMade] = [], expected: [AgentExpected] = [], problems: [AgentProblem] = []) {
        self.path = path; self.paths = paths; self.views = views; self.modifier = modifier; self.initializers = initializers
        self.launch = launch; self.keys = keys; self.notes = notes; self.made = made; self.expected = expected; self.problems = problems
    }
}
