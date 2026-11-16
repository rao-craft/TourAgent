//  WHAT: The template of `TourWelcomeCard.swift`: the card the first run opens on, over a scrim that takes every
//        touch, with a button that starts the tips and one that skips them.
//  PIN:  THE CARD IS CENTRED BY ITS ZSTACK AND INSET ONLY AT THE SIDES. The scrim fills the screen; the card sits in
//        the middle at its own height, `welcome.inset` from each side.

extension Template {
    static let welcomeCard = ##"""
    import SwiftUI

    /// The welcome card over a scrim: the app's mark, a title and a line, a button that starts the tips and one that
    /// skips them. The scrim covers the whole screen and takes its touches; only the two buttons leave it.
    struct TourWelcomeCard: View {
        /// The first button: the card closes and the tab's tips begin.
        var start: () -> Void
        /// Skip: the card closes and every tour counts as done; not drawn when nil.
        var skip: (() -> Void)? = nil

        var body: some View {
            ZStack {
                TourLook.scrim
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 24) {
                    TourMark(size: {{n:welcome.mark}}, casting: true)
                        .padding(.bottom, 2)

                    VStack(spacing: 8) {
                        Text({{s:welcome.title}})
                            .font(TourLook.welcomeTitle)

                        Text({{s:welcome.body}})
                            .font(TourLook.welcomeBody)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        Button(action: start) {
                            Text({{s:welcome.start}})
                                .font(TourLook.welcomeButton)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TourLook.accent)
                                .foregroundStyle(TourLook.onAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)

                        if let skip {
                            Button(action: skip) {
                                Text({{s:welcome.skip}})
                                    .font(TourLook.welcomeSkip)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: {{n:welcome.radius}}))
                .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
                .padding(.horizontal, {{n:welcome.inset}})
            }
        }
    }

    #Preview {
        ZStack {
            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            TourWelcomeCard(start: {}, skip: {})
        }
    }
    """##
}
