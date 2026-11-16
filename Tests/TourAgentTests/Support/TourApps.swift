import Foundation
@testable import TourAgent

/// The apps the gated build writes the kit into: stand-ins for the names a call maps (Seer's `Color.accent` and
/// `SeerMark()`, the recipe app's `RecipeMark()`), and code that uses what the kit writes as an app would.
enum TourApps {
    /// Seer's design names and mark, as DesignAgent and the app give them.
    static let seerStandIns = """
    import SwiftUI

    extension Color {
        /// Seer's bronze, as DesignAgent names it.
        static let accent = Color(red: 0xAE / 255, green: 0x90 / 255, blue: 0x60 / 255)
    }

    /// A stand-in for Seer's medallion: a pale disc, a steel ring, a dark groove and a dome.
    struct SeerMark: View {
        var body: some View {
            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                ZStack {
                    Circle().fill(Color(red: 0.68, green: 0.67, blue: 0.67))
                    Circle()
                        .fill(LinearGradient(colors: [Color(red: 0.65, green: 0.63, blue: 0.61), Color(red: 0.44, green: 0.42, blue: 0.41)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: side * 0.83, height: side * 0.83)
                    Circle().fill(Color(red: 0.22, green: 0.21, blue: 0.2)).frame(width: side * 0.37, height: side * 0.37)
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 0.53, green: 0.51, blue: 0.5), Color(red: 0.38, green: 0.36, blue: 0.35)],
                                             center: .top, startRadius: 0, endRadius: side * 0.31))
                        .frame(width: side * 0.31, height: side * 0.31)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
    """

    /// Seer's tabs with the layer over them and the pager as a sheet: the tab as an enum, and as a String.
    static let seerUse = """
    import SwiftUI

    enum SeerTab: String, Hashable {
        case library, seer, models
    }

    struct SeerTabs: View {
        @State private var tab: SeerTab = .seer
        @State private var about = TourLaunch.destination == "about"

        var body: some View {
            TabView(selection: $tab) {
                Button(TourAbout.name, systemImage: "book.pages") { about = true }
                    .tag(SeerTab.library)
                Text("Seer")
                    .tag(SeerTab.seer)
                Text("Models")
                    .tag(SeerTab.models)
            }
            .tour(tab: tab)
            .sheet(isPresented: $about) {
                TourAbout()
            }
        }
    }

    struct SeerNamedTabs: View {
        @State private var tab = "seer"
        @State private var about = false

        var body: some View {
            TabView(selection: $tab) {
                Text("Seer").tag("seer")
            }
            .tour(tab: tab)
            .sheet(isPresented: $about) {
                TourAbout(onClose: { about = false })
            }
        }
    }
    """

    /// Every screen of the kit drawn offscreen at an iPhone's size, light and dark: what proves nothing traps, and
    /// pictures to set beside the original's when a folder is given.
    static let seerCheck = """
    import SwiftUI
    import ImageIO
    import UniformTypeIdentifiers

    public enum SeerCheck {
        @MainActor
        public static func run(into folder: URL?) -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []

            func draw<Content: View>(_ name: String, height: CGFloat = 874, @ViewBuilder _ content: () -> Content) {
                for scheme in [ColorScheme.light, .dark] {
                    let view = content()
                        .frame(width: 402, height: height)
                        .environment(\\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 3
                    guard let image = renderer.cgImage else {
                        failed.append(name)
                        continue
                    }
                    let file = "\\(name)-\\(scheme == .dark ? "dark" : "light")"
                    drawn.append(file)
                    guard let folder else { continue }
                    let url = folder.appendingPathComponent(file + ".png")
                    if let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                        CGImageDestinationAddImage(destination, image, nil)
                        CGImageDestinationFinalize(destination)
                    }
                }
            }

            /// The tabs as the shots show them under the layer: a bar with the app's name and a floating tab bar.
            @ViewBuilder
            func tabs(_ scheme: ColorScheme? = nil) -> some View {
                ZStack {
                    Color(white: 0.97)
                    VStack {
                        Text("Seer").font(.system(size: 36, design: .serif)).padding(.top, 70)
                        Spacer()
                        Capsule().fill(Color(white: 0.9)).frame(width: 270, height: 60).padding(.bottom, 24)
                    }
                }
            }

            draw("onboarding") {
                tabs().overlay { TourLayer(tab: "seer", start: .welcome) }
            }
            draw("onboarding.tips") {
                tabs().overlay { TourLayer(tab: "library", start: .tips("library")) }
            }
            draw("about", height: 812) {
                TourAbout()
            }
            // A page scrolls, and a scroll view draws nothing offscreen: its rows are drawn on their own.
            draw("about.rows", height: 812) {
                ZStack {
                    TourDriftingGradient(colors: TourContent.pages[0].palette)
                        .opacity(0.9)
                    VStack(spacing: 9) {
                        ForEach(TourContent.pages[0].rows.indices, id: \\.self) { index in
                            TourAboutRow(row: TourContent.pages[0].rows[index])
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            return (drawn, failed)
        }
    }
    """

    /// The parts on their own, each with a prefix of its own: the pager alone with a symbol for a mark, the tips
    /// alone, and the welcome alone with a mark that keeps still.
    static let partCalls: [TourAgent.Input] = [
        TourAgent.Input(
            parts: [.about], mark: "book.pages",
            palettes: ["sea: #4FC3F7 #0288D1 #80DEEA #26A69A"],
            pages: ["map | sea | Maps | Find your way. | Offline maps of every trail. | location: Where you are | Trails kept offline"],
            look: ["aboutDesign = rounded"], launch: ["guide = about(1)"], prefix: "Kit"),
        TourAgent.Input(
            parts: [.tips],
            tips: ["notes: Search | Find any note by a word in it. | magnifyingglass | trailing",
                   "notes: New Note | Start writing. | square.and.pencil | bottomTrailing"],
            launch: ["notes.tips = tips(notes)"], prefix: "Hint"),
        TourAgent.Input(
            parts: [.welcome], mark: "sparkles",
            strings: ["welcome.title = \"Hello\""], tuning: ["mark.turn = 0"],
            launch: ["hello = welcome"], defaultsKey: "hello", prefix: "Hello"),
    ]

    /// The parts used as an app uses them.
    static let partsUse = """
    import SwiftUI

    struct PartsTabs: View {
        @State private var tab = "notes"
        @State private var guide = false

        var body: some View {
            TabView(selection: $tab) {
                Text("Notes").tag("notes")
            }
            .hint(tab: tab)
            .hello(tab: tab)
            .sheet(isPresented: $guide) {
                KitAbout()
            }
        }
    }
    """

    /// The recipe app's mark and its tabs.
    static let recipesUse = """
    import SwiftUI

    struct RecipeMark: View {
        var body: some View {
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.orange)
        }
    }

    enum RecipeTab: String {
        case recipes, plan
    }

    struct RecipeTabs: View {
        @State private var tab = RecipeTab.recipes
        @State private var about = false

        var body: some View {
            TabView(selection: $tab) {
                Text("Recipes").tag(RecipeTab.recipes)
                Text("Plan").tag(RecipeTab.plan)
            }
            .tour(tab: tab)
            .sheet(isPresented: $about) {
                TourAbout()
            }
        }
    }
    """
}
