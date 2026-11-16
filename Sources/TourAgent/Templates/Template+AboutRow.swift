//  WHAT: The template of `TourAboutRow.swift`: one row of a feature page, a symbol in a tinted circle and a line on a
//        frosted card, that gives a little under a tap.

extension Template {
    static let aboutRow = ##"""
    import SwiftUI

    /// A row of a feature page: the row's symbol in a circle of the accent, its text, on a frosted card that gives a
    /// little under a tap.
    struct TourAboutRow: View {
        var row: TourPage.Row

        @State private var tapped = false

        var body: some View {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TourLook.accent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: row.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TourLook.accent)
                }
                .accessibilityHidden(true)

                Text(row.text)
                    .font(TourLook.pageRow)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            .scaleEffect(tapped ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: tapped)
            .onTapGesture {
                TourHaptics.light()
                tapped = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.15))
                    tapped = false
                }
            }
        }
    }

    #Preview {
        VStack(spacing: 9) {
            TourAboutRow(row: TourPage.Row(symbol: "text.magnifyingglass", text: "Search every note at once"))
            TourAboutRow(row: TourPage.Row(symbol: "clock", text: "Recent searches kept for you"))
        }
        .padding(20)
        .background(TourDriftingGradient(colors: TourContent.cover))
    }
    """##
}
