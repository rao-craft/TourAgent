import Foundation

/// What a run says as it goes.
public enum TourFrame: Sendable {
    /// The call was read: how many tips and feature pages, and how many files it writes.
    case read(tips: Int, pages: Int, files: Int)
    /// The files are written.
    case written(TourResult)

    public var result: TourResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
