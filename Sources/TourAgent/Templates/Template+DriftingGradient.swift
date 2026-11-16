//  WHAT: The template of `TourDriftingGradient.swift`: a gradient drawn again every frame from a few colours, the
//        first a base and each a radial gradient drifting around the middle.
//  PIN:  A NEW PALETTE IS ANIMATED IN BY ITS OWNER. The pager changes `colors` inside `withAnimation(about.blend)`;
//        the gradient only draws what it is given. With Reduce Motion on, the colours stop drifting.

extension Template {
    static let driftingGradient = ##"""
    import SwiftUI

    /// A gradient drawn again every frame: its first colour as a base, and over it a radial gradient from each colour
    /// to clear, whose centres drift slowly around the middle.
    struct TourDriftingGradient: View {
        var colors: [Color]

        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate * {{n:gradient.speed}}
                TourGradientBlobs(colors: colors, time: time)
            }
            .accessibilityHidden(true)
        }
    }

    /// The gradient at one moment: the base, and a blob a colour.
    private struct TourGradientBlobs: View {
        let colors: [Color]
        let time: Double

        var body: some View {
            GeometryReader { geometry in
                let radius = max(geometry.size.width, geometry.size.height) * {{n:gradient.reach}}
                ZStack {
                    (colors.first ?? .white)
                    ForEach(0..<colors.count, id: \.self) { index in
                        TourGradientBlob(
                            color: colors[index],
                            index: index,
                            total: colors.count,
                            time: time,
                            radius: radius
                        )
                    }
                }
            }
        }
    }

    /// One colour: a radial gradient from it to clear, its centre on its own path around the middle.
    private struct TourGradientBlob: View {
        let color: Color
        let index: Int
        let total: Int
        let time: Double
        let radius: CGFloat

        private var center: UnitPoint {
            let phase = Double(index) / Double(max(total, 1)) * .pi * 2
            let x = cos(time * 0.70 + phase) * {{n:gradient.drift}} + 0.50
            let y = sin(time * 0.53 + phase + 1.20) * {{n:gradient.drift}} + 0.50
            return UnitPoint(x: x, y: y)
        }

        var body: some View {
            RadialGradient(
                colors: [color.opacity({{n:gradient.strength}}), color.opacity(0)],
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        }
    }

    #Preview {
        TourDriftingGradient(colors: TourContent.cover)
            .ignoresSafeArea()
    }
    """##
}
