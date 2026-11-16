//  WHAT: The kit's files: each one's name, whether it is a view or what the views read, the parts that write it, and
//        its template (or none, for the files written from the call's lines: the look, the launch, the content).

import Foundation

struct TourFile: Sendable {
    enum Kind: String, Sendable {
        /// A view the app or another view shows.
        case view
        /// What the views read: the look, the launch state, the content, the haptics.
        case support
    }

    /// The name after the prefix: `Layer` is `TourLayer.swift`, declaring `TourLayer`.
    let stem: String
    let kind: Kind
    /// The parts that write it: any one of them.
    let parts: Set<TourPart>
    /// Its template; nil when it is written from the call's lines.
    let template: String?
}

enum TourCatalog {
    /// The prefix the templates are written with.
    static let templatePrefix = "Tour"

    static let files: [TourFile] = [
        TourFile(stem: "Look", kind: .support, parts: Set(TourPart.allCases), template: nil),
        TourFile(stem: "Launch", kind: .support, parts: Set(TourPart.allCases), template: nil),
        TourFile(stem: "Content", kind: .support, parts: [.tips, .about], template: nil),
        TourFile(stem: "Haptics", kind: .support, parts: Set(TourPart.allCases), template: Template.haptics),
        TourFile(stem: "Layer", kind: .view, parts: [.welcome, .tips], template: Template.layer),
        TourFile(stem: "WelcomeCard", kind: .view, parts: [.welcome], template: Template.welcomeCard),
        TourFile(stem: "TipCard", kind: .view, parts: [.tips], template: Template.tipCard),
        TourFile(stem: "Mark", kind: .view, parts: [.welcome, .about], template: Template.mark),
        TourFile(stem: "About", kind: .view, parts: [.about], template: Template.about),
        TourFile(stem: "AboutCover", kind: .view, parts: [.about], template: Template.aboutCover),
        TourFile(stem: "AboutPage", kind: .view, parts: [.about], template: Template.aboutPage),
        TourFile(stem: "AboutRow", kind: .view, parts: [.about], template: Template.aboutRow),
        TourFile(stem: "DriftingGradient", kind: .view, parts: [.about], template: Template.driftingGradient),
    ]

    /// Every type the kit declares, without its prefix: what a prefix renames.
    static let typeStems = ["Look", "Launch", "Content", "Tip", "Page", "Palette", "Haptics", "Layer", "WelcomeCard", "TipCard",
                            "Mark", "About", "AboutCover", "AboutPage", "AboutRow", "DriftingGradient", "GradientBlobs",
                            "GradientBlob"]

    /// The files `parts` write, in the catalog's order.
    static func files(for parts: [TourPart]) -> [TourFile] {
        files.filter { !$0.parts.isDisjoint(with: parts) }
    }

    /// The views a part is asked for by: the root a page or the tabs show, and the views it is built from.
    static func views(of part: TourPart) -> [String] {
        switch part {
        case .welcome: return ["Layer", "WelcomeCard", "Mark"]
        case .tips: return ["Layer", "TipCard"]
        case .about: return ["About", "AboutCover", "AboutPage", "AboutRow", "DriftingGradient", "Mark"]
        }
    }
}
