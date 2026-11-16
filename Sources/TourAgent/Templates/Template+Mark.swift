//  WHAT: The template of `TourMark.swift`: the app's mark (its own view, or a symbol) at a size, clipped when asked,
//        and turning slowly unless the person asked for less motion.
//  PIN:  THE WELCOME'S SHADOW TURNS WITH THE MARK. `casting` draws the shadow before the turn, as the welcome card's
//        mark has it; the cover's mark takes its shadow after the turn, from outside.

extension Template {
    static let mark = ##"""
    import SwiftUI
    {{x:imports}}

    /// The app's mark as the tour draws it: at a size, clipped to a corner radius when one is given, and turning.
    struct TourMark: View {
        /// Its width and height.
        var size: CGFloat
        /// The corner radius it is clipped to; nil leaves it as it draws itself.
        var cornerRadius: CGFloat? = nil
        /// Whether it casts the soft shadow that turns with it, as on the welcome card.
        var casting = false
        //@if turns

        @State private var rotation: Double = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        //@endif

        var body: some View {
            shaded
                //@if turns
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: {{n:mark.turn}}).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                //@endif
                .accessibilityHidden(true)
        }

        @ViewBuilder
        private var shaded: some View {
            if casting {
                framed
                    .shadow(color: Color.primary.opacity(0.3), radius: 3, x: 1, y: 1)
            } else {
                framed
            }
        }

        @ViewBuilder
        private var framed: some View {
            if let cornerRadius {
                mark
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: cornerRadius))
            } else {
                mark
                    .frame(width: size, height: size)
            }
        }

        @ViewBuilder
        private var mark: some View {
            //@if mark.view
            {{x:mark}}
            //@else
            Image(systemName: {{x:markSymbol}})
                .resizable()
                .scaledToFit()
                .foregroundStyle(TourLook.accent.gradient)
            //@endif
        }
    }

    #Preview {
        HStack(spacing: 32) {
            TourMark(size: {{n:welcome.mark}}, casting: true)
            TourMark(size: {{n:about.mark}}, cornerRadius: {{n:about.markRadius}})
                .shadow(radius: 8)
        }
        .padding()
    }
    """##
}
