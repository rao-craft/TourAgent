//  WHAT: Every timing, size and symbol the tour uses, by key, with its default: one `tuning` line sets one
//        (`tip.scale = 0.88`, `welcome.show = spring(0.4, 0.8)`, `symbol.close = xmark`). The views are written with
//        the value in place, in the form a person writes it: `.scale(scale: 0.88, anchor: …)`.

import Foundation

/// One value the tour is tuned by.
struct TourTuningKey: Sendable {
    enum Kind: Sendable {
        /// A number, from the low end to the high end.
        case number(Double, Double)
        /// An animation: `spring(0.4, 0.8)`, `easeOut(0.2)`, `linear(1)`.
        case animation
        /// An SF Symbol's name.
        case symbol
        /// One of the call's palettes, by name.
        case palette
    }

    let key: String
    let kind: Kind
    /// The value as a line writes it; nil for the cover's palette, which is the first palette when left out.
    let fallback: String?
    let what: String
}

enum TourTuning {
    static let all: [TourTuningKey] = [
        TourTuningKey(key: "mark.turn", kind: .number(0, 600), fallback: "42", what: "seconds the mark takes to turn once; 0 keeps it still"),
        TourTuningKey(key: "welcome.show", kind: .animation, fallback: "spring(0.4, 0.8)", what: "how the welcome card gives way to the tips"),
        TourTuningKey(key: "welcome.skip", kind: .animation, fallback: "easeOut(0.2)", what: "how the welcome card leaves on Skip"),
        TourTuningKey(key: "welcome.settle", kind: .animation, fallback: "spring(0.4, 0.85)", what: "the layer's own spring as the welcome comes and goes"),
        TourTuningKey(key: "welcome.mark", kind: .number(16, 400), fallback: "100", what: "the mark's size on the welcome card"),
        TourTuningKey(key: "welcome.inset", kind: .number(0, 200), fallback: "36", what: "the welcome card's distance from the screen's edges"),
        TourTuningKey(key: "welcome.radius", kind: .number(0, 80), fallback: "24", what: "the welcome card's corner radius"),
        TourTuningKey(key: "scrim.opacity", kind: .number(0, 1), fallback: "0.55", what: "how dark the scrim behind the welcome card is"),
        TourTuningKey(key: "tip.step", kind: .animation, fallback: "spring(0.35, 0.8)", what: "how a tour moves on Next and back"),
        TourTuningKey(key: "tip.settle", kind: .animation, fallback: "spring(0.35, 0.85)", what: "the layer's own spring as a tour moves from tip to tip"),
        TourTuningKey(key: "tip.swap", kind: .animation, fallback: "easeInOut(0.25)", what: "how one tab's tips give way to another's"),
        TourTuningKey(key: "tip.scale", kind: .number(0, 1), fallback: "0.88", what: "the scale a tip card grows from as it comes in"),
        TourTuningKey(key: "tip.width", kind: .number(120, 600), fallback: "270", what: "a tip card's widest"),
        TourTuningKey(key: "tip.top", kind: .number(0, 400), fallback: "112", what: "a tip's distance from the top of the screen"),
        TourTuningKey(key: "tip.side", kind: .number(0, 200), fallback: "16", what: "a tip's distance from the side of its control"),
        TourTuningKey(key: "tip.bottom", kind: .number(0, 400), fallback: "100", what: "a bottom tip's distance from the bottom of the screen"),
        TourTuningKey(key: "about.begin", kind: .animation, fallback: "spring(0.4, 0.8)", what: "how the cover's button opens the first feature page"),
        TourTuningKey(key: "about.step", kind: .animation, fallback: "spring(0.35, 0.8)", what: "how the chevrons change page"),
        TourTuningKey(key: "about.blend", kind: .animation, fallback: "easeInOut(1.3)", what: "how the gradient blends into a page's palette"),
        TourTuningKey(key: "about.cover", kind: .palette, fallback: nil, what: "the palette behind the cover; the first palette when left out"),
        TourTuningKey(key: "about.mark", kind: .number(16, 400), fallback: "96", what: "the mark's size on the cover"),
        TourTuningKey(key: "about.markRadius", kind: .number(0, 200), fallback: "22", what: "the corner radius the cover's mark is clipped to"),
        TourTuningKey(key: "gradient.speed", kind: .number(0, 10), fallback: "0.0525", what: "how fast the colours drift: their clock is seconds times this"),
        TourTuningKey(key: "gradient.strength", kind: .number(0, 1), fallback: "0.82", what: "each colour's opacity at its centre, fading to clear"),
        TourTuningKey(key: "gradient.reach", kind: .number(0, 4), fallback: "0.85", what: "how far each colour reaches, as a share of the longer side"),
        TourTuningKey(key: "gradient.drift", kind: .number(0, 1), fallback: "0.38", what: "how far each colour's centre wanders from the middle"),
        TourTuningKey(key: "gradient.opacity", kind: .number(0, 1), fallback: "0.9", what: "the gradient's opacity behind the pager"),
        TourTuningKey(key: "symbol.back", kind: .symbol, fallback: "chevron.left", what: "the back button of a tip and of the pager"),
        TourTuningKey(key: "symbol.forward", kind: .symbol, fallback: "chevron.right", what: "the pager's forward button"),
        TourTuningKey(key: "symbol.finish", kind: .symbol, fallback: "checkmark", what: "the pager's last button, which closes it"),
        TourTuningKey(key: "symbol.close", kind: .symbol, fallback: "xmark", what: "the pager's close button"),
        TourTuningKey(key: "symbol.begin", kind: .symbol, fallback: "arrow.right", what: "the symbol beside the cover's button"),
        TourTuningKey(key: "symbol.row", kind: .symbol, fallback: "checkmark.circle", what: "a feature row's symbol when its line names none"),
    ]

    static let keys = all.map(\.key)

    static func named(_ key: String) -> TourTuningKey? { all.first { $0.key == key } }
}
