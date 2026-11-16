//  WHAT: Every colour and font the tour's views read, by role, with the system value it keeps when no `look` line
//        maps it, so the views build in any app. `accent = Color.accent` maps a role to the app's own name.

import Foundation

/// One role of the tour's look.
struct TourLookRole: Sendable {
    enum Kind: String, Sendable {
        case color = "Color"
        case font = "Font"
        /// A font design (`serif`, `rounded`, `monospaced`, `default`) the about pager's type is drawn in.
        case design = "Font.Design"
    }

    let role: String
    let kind: Kind
    /// The Swift it reads when no line maps it.
    let fallback: String
    let what: String
    /// The part whose views read it; nil for every part.
    let part: TourPart?
}

enum TourLookRoles {
    static let all: [TourLookRole] = [
        TourLookRole(role: "accent", kind: .color, fallback: "Color.accentColor", what: "buttons, the current dot and page marker, symbols", part: nil),
        TourLookRole(role: "onAccent", kind: .color, fallback: "Color.white", what: "text and symbols on the accent", part: nil),
        TourLookRole(role: "scrim", kind: .color, fallback: "Color.black", what: "the scrim behind the welcome card, at scrim.opacity", part: .welcome),
        TourLookRole(role: "welcomeTitle", kind: .font, fallback: "Font.title.bold()", what: "the welcome card's title", part: .welcome),
        TourLookRole(role: "welcomeBody", kind: .font, fallback: "Font.body", what: "the welcome card's line", part: .welcome),
        TourLookRole(role: "welcomeButton", kind: .font, fallback: "Font.headline", what: "the welcome card's button", part: .welcome),
        TourLookRole(role: "welcomeSkip", kind: .font, fallback: "Font.subheadline", what: "the welcome card's Skip", part: .welcome),
        TourLookRole(role: "tipTitle", kind: .font, fallback: "Font.headline", what: "a tip's title and symbol", part: .tips),
        TourLookRole(role: "tipCounter", kind: .font, fallback: "Font.caption", what: "a tip's counter", part: .tips),
        TourLookRole(role: "tipBody", kind: .font, fallback: "Font.subheadline", what: "a tip's line", part: .tips),
        TourLookRole(role: "tipButton", kind: .font, fallback: "Font.subheadline.bold()", what: "a tip's buttons", part: .tips),
        TourLookRole(role: "aboutDesign", kind: .design, fallback: ".default", what: "the design the pager's type is drawn in: serif, rounded, monospaced or default", part: .about),
        TourLookRole(role: "aboutTitle", kind: .font, fallback: "Font.system(size: 44, weight: .bold, design: aboutDesign)", what: "the cover's heading", part: .about),
        TourLookRole(role: "aboutSubtitle", kind: .font, fallback: "Font.system(.title3, design: aboutDesign).italic()", what: "the cover's line", part: .about),
        TourLookRole(role: "aboutButton", kind: .font, fallback: "Font.system(.headline, design: aboutDesign)", what: "the cover's button", part: .about),
        TourLookRole(role: "pageTitle", kind: .font, fallback: "Font.system(size: 40, weight: .bold, design: aboutDesign)", what: "a feature page's name", part: .about),
        TourLookRole(role: "pageTagline", kind: .font, fallback: "Font.system(.title3, design: aboutDesign).italic()", what: "a feature page's tagline", part: .about),
        TourLookRole(role: "pageBody", kind: .font, fallback: "Font.system(.body, design: aboutDesign)", what: "a feature page's description", part: .about),
        TourLookRole(role: "pageRow", kind: .font, fallback: "Font.system(.subheadline, design: aboutDesign)", what: "a feature page's rows", part: .about),
    ]

    static let roles = all.map(\.role)

    static func named(_ role: String) -> TourLookRole? { all.first { $0.role == role } }

    /// The designs `aboutDesign` takes.
    static let designs = ["default", "serif", "rounded", "monospaced"]
}
