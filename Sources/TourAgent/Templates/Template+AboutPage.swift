//  WHAT: The template of `TourAboutPage.swift`: a feature page of the pager, its symbol, name, tagline, description and
//        rows rising in one after another each time it appears.

extension Template {
    static let aboutPage = ##"""
    import SwiftUI

    /// A feature page of the about pager: the feature's symbol, its name and tagline, a description, and rows that
    /// say what it does. Its parts rise and fade in, top first, each time it appears.
    struct TourAboutPage: View {
        var page: TourPage

        @State private var appeared = false

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 4)

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 76, height: 76)
                        Image(systemName: page.symbol)
                            .font(.system(size: 30))
                            .foregroundStyle(TourLook.accent.gradient)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 5)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: appeared)
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(page.name)
                            .font(TourLook.pageTitle)
                            .foregroundStyle(.thickMaterial)
                            .shadow(radius: 8)

                        if !page.tagline.isEmpty {
                            Text(page.tagline)
                                .font(TourLook.pageTagline)
                                .foregroundStyle(.regularMaterial)
                                .shadow(radius: 8)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.06), value: appeared)

                    if !page.description.isEmpty {
                        Text(page.description)
                            .font(TourLook.pageBody)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.1), value: appeared)
                    }

                    VStack(spacing: 9) {
                        ForEach(page.rows.indices, id: \.self) { index in
                            TourAboutRow(row: page.rows[index])
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 8)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.82)
                                        .delay(0.15 + Double(index) * 0.07),
                                    value: appeared
                                )
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
        }
    }

    #Preview {
        ZStack {
            TourDriftingGradient(colors: TourContent.cover)
                .opacity({{n:gradient.opacity}})
                .ignoresSafeArea()
            TourAboutPage(page: TourPage(
                name: "Search",
                tagline: "Find anything.",
                description: "Every word you have written, found as you type.",
                symbol: "magnifyingglass",
                palette: TourContent.cover,
                rows: [
                    TourPage.Row(symbol: "text.magnifyingglass", text: "Search every note at once"),
                    TourPage.Row(symbol: "clock", text: "Recent searches kept for you"),
                ]
            ))
        }
        .multilineTextAlignment(.center)
    }
    """##
}
