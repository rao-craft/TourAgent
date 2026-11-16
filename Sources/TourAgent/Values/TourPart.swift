import Foundation

/// A part of the tour a call may leave out; every one is written when the call names none.
public enum TourPart: String, Codable, Sendable, CaseIterable {
    /// The welcome card over a scrim, the first time the tabs are up.
    case welcome
    /// Each tab's tips, one card at a time, the first time that tab is up.
    case tips
    /// The about pager: a cover, then a page a feature, over a drifting gradient.
    case about
}
