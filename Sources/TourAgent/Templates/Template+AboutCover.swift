//  WHAT: The template of `TourAboutCover.swift`: the pager's first page, the mark over a heading and a line, and the
//        button that begins the tour, each rising into place as it appears.
//  PIN:  THE MARK STARTS THE ENTRANCE. Its appearing sets `appeared` on the cover's spring, a tenth of a second late;
//        the heading and the button follow on the same spring, later still. The mark rises to about.mark.opacity and
//        about.mark.scale, from clear and 0.7 of that scale; at 1 and 1 the lines are the plain entrance (Seer's call
//        rests it faint and small, at 0.22 and 0.76, as the original draws it).

extension Template {
    static let aboutCover = ##"""
    import SwiftUI

    /// The about pager's cover: the app's mark, a heading and a line, and the button that opens the first feature
    /// page. Its parts rise and fade in as it appears.
    struct TourAboutCover: View {
        /// The button that begins the tour; not drawn when nil.
        var begin: (() -> Void)? = nil

        @State private var appeared = false

        var body: some View {
            VStack(spacing: 0) {
                Spacer()

                TourMark(size: {{n:about.mark}}, cornerRadius: {{n:about.markRadius}})
                    .shadow(radius: 8)
                    .opacity(appeared ? {{n:about.mark.opacity}} : 0)
                    //@if about.mark.scales
                    .scaleEffect(appeared ? {{n:about.mark.scale}} : 0.7 * {{n:about.mark.scale}})
                    //@else
                    .scaleEffect(appeared ? 1 : 0.7)
                    //@endif
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                            appeared = true
                        }
                    }

                Spacer()
                    .frame(height: 32)

                VStack(spacing: 12) {
                    Text({{s:about.title}})
                        .font(TourLook.aboutTitle)
                        .foregroundStyle(.thickMaterial)
                        .shadow(radius: 8)

                    Text({{s:about.subtitle}})
                        .font(TourLook.aboutSubtitle)
                        .foregroundStyle(.regularMaterial)
                        .shadow(radius: 8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.18), value: appeared)

                Spacer()

                if let begin {
                    Button(action: begin) {
                        HStack(spacing: 8) {
                            Text({{s:about.begin}})
                                .font(TourLook.aboutButton)
                            Image(systemName: {{y:symbol.begin}})
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.28), value: appeared)
                }

                Spacer()
                    .frame(height: 64)
            }
            .padding(.horizontal, 36)
        }
    }

    #Preview {
        ZStack {
            TourDriftingGradient(colors: TourContent.cover)
                .opacity({{n:gradient.opacity}})
                .ignoresSafeArea()
            TourAboutCover(begin: {})
        }
        .multilineTextAlignment(.center)
    }
    """##
}
