//  WHAT: The template of `TourHaptics.swift`: the light impact a step answers with, and the soft one of Skip.

extension Template {
    static let haptics = ##"""
    import SwiftUI
    #if os(iOS)
    import UIKit
    #endif

    /// The taps the tour answers with: a light impact for each step, a soft one for Skip.
    @MainActor
    enum TourHaptics {
        /// A tap that acts: start, next, back, begin, a page's row.
        static func light() {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        //@if part.welcome

        /// A tap that leaves: Skip.
        static func soft() {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            #endif
        }
        //@endif
    }
    """##
}
