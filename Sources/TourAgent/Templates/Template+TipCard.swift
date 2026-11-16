//  WHAT: The template of `TourTipCard.swift`: one tip in a card, standing at its place on the screen, with its place in
//        the tour, back, dots and Next.
//  PIN:  ONLY THE CARD TAKES TOUCHES. It stands in a clear ZStack aligned to its place, and the clear ground lets every
//        touch through to the app; the card scales in from its corner and fades out.

extension Template {
    static let tipCard = ##"""
    import SwiftUI

    /// A tip in a card, standing at its place: the control's symbol, a title and a line, the tip's place in its tour
    /// ({{x:counterExample}} when the tour has more than one tip), back, the tour's dots, and Next, which reads
    /// {{x:doneExample}} on the last tip. Around the card the screen stays the app's.
    struct TourTipCard: View {
        var tip: TourTip
        /// The tip's place in its tour, from 1.
        var number: Int
        /// How many tips its tour holds.
        var count: Int
        /// The tip before; not drawn on the first tip, or when nil.
        var back: (() -> Void)? = nil
        /// The next tip, or the end of the tour on its last.
        var next: () -> Void

        var body: some View {
            ZStack(alignment: tip.place.alignment) {
                Color.clear
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                card
                    .padding(tip.place.insets)
                    .transition(.asymmetric(
                        insertion: .scale(scale: {{n:tip.scale}}, anchor: tip.place.anchor)
                            .combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }

        private var card: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    if let symbol = tip.symbol {
                        Image(systemName: symbol)
                            .font(TourLook.tipTitle)
                            .foregroundStyle(TourLook.accent.gradient)
                    }

                    Text(tip.title)
                        .font(TourLook.tipTitle)

                    Spacer(minLength: 0)

                    if count > 1 {
                        Text({{x:counter}})
                            .font(TourLook.tipCounter)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(tip.body)
                    .font(TourLook.tipBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if let back, number > 1 {
                        Button(action: back) {
                            Image(systemName: {{y:symbol.back}})
                                .font(TourLook.tipButton)
                                .frame(width: 32, height: 32)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text({{s:tip.back}}))
                    }

                    if count > 1 {
                        HStack(spacing: 5) {
                            ForEach(1...count, id: \.self) { dot in
                                Circle()
                                    .fill(dot == number ? TourLook.accent : Color.secondary.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .accessibilityHidden(true)
                    }

                    Spacer(minLength: 0)

                    Button(action: next) {
                        Text(number < count ? {{s:tip.next}} : {{s:tip.done}})
                            .font(TourLook.tipButton)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(TourLook.accent, in: Capsule())
                            .foregroundStyle(TourLook.onAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(maxWidth: {{n:tip.width}})
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 14, y: 4)
        }
    }

    extension TourTip.Place {
        /// Where the card stands on the screen.
        var alignment: Alignment {
            switch self {
            case .topLeading: return .topLeading
            case .topTrailing: return .topTrailing
            case .bottomLeading: return .bottomLeading
            case .bottomTrailing: return .bottomTrailing
            case .center: return .center
            }
        }

        /// The corner the card grows from as it comes in.
        var anchor: UnitPoint {
            switch self {
            case .topLeading: return .topLeading
            case .topTrailing: return .topTrailing
            case .bottomLeading: return .bottomLeading
            case .bottomTrailing: return .bottomTrailing
            case .center: return .center
            }
        }

        /// The card's distance from the screen's edges: under the bar's control it explains, measured from the top
        /// of the screen, or over the tab bar.
        var insets: EdgeInsets {
            switch self {
            case .topLeading:
                return EdgeInsets(top: {{n:tip.top}}, leading: {{n:tip.side}}, bottom: 0, trailing: 0)
            case .topTrailing:
                return EdgeInsets(top: {{n:tip.top}}, leading: 0, bottom: 0, trailing: {{n:tip.side}})
            case .bottomLeading:
                return EdgeInsets(top: 0, leading: {{n:tip.side}}, bottom: {{n:tip.bottom}}, trailing: 0)
            case .bottomTrailing:
                return EdgeInsets(top: 0, leading: 0, bottom: {{n:tip.bottom}}, trailing: {{n:tip.side}})
            case .center:
                return EdgeInsets(top: 0, leading: {{n:tip.side}}, bottom: 0, trailing: {{n:tip.side}})
            }
        }
    }

    #Preview {
        TourTipCard(
            tip: TourTip(title: "Search", body: "Find anything you have written by a word in it.", symbol: "magnifyingglass", place: .topLeading),
            number: 2,
            count: 3,
            back: {},
            next: {}
        )
    }
    """##
}
