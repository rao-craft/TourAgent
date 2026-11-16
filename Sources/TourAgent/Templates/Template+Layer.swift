//  WHAT: The template of `TourLayer.swift`: the first-run layer over the app's tabs (the welcome card, then each tab's
//        tips), what it remembers, and the modifier the app applies it with.
//  PIN:  IT TAKES TOUCHES ONLY WHERE IT DRAWS. The welcome's scrim draws everywhere and takes everything; a tip card
//        stands on a clear ground that lets touches through, so the app under it stays usable; with nothing up, the
//        layer takes no touch at all.
//  PIN:  THE CARDS MOVE ON THE LAYER'S OWN SPRINGS. The welcome and the tip index settle on `welcome.settle` and
//        `tip.settle`, a tab change on `tip.swap`, over whatever the buttons asked for.

extension Template {
    static let layer = ##"""
    import SwiftUI

    /// The first-run layer over the app's tabs: the welcome card the first time they are up, then each tab's tips the
    /// first time that tab is up, one card at a time. It takes touches only where it draws and keeps what is done in
    /// UserDefaults; a launch into a destination opens the state `TourLaunch` names and saves nothing.
    struct TourLayer: View {
        /// The tab that is up, as the tips name it.
        var tab: String
        //@if part.welcome
        @State private var welcomed: Bool
        //@endif
        //@if part.tips
        @State private var finished: Set<String>
        @State private var index = 0
        //@endif

        /// Whether what is done is kept: a launch into a destination saves nothing.
        private let remembers: Bool

        init(tab: String, start: TourLaunch.Start = TourLaunch.start) {
            self.tab = tab
            let defaults = UserDefaults.standard
            switch start {
            case .remembered:
                //@if part.welcome
                _welcomed = State(initialValue: defaults.bool(forKey: Self.welcomedKey))
                //@endif
                //@if part.tips
                _finished = State(initialValue: Set(defaults.stringArray(forKey: Self.finishedKey) ?? []))
                //@endif
                remembers = true
            //@if part.welcome
            case .welcome:
                _welcomed = State(initialValue: false)
                //@if part.tips
                _finished = State(initialValue: [])
                //@endif
                remembers = false
            //@endif
            //@if part.tips
            case .tips(let first):
                //@if part.welcome
                _welcomed = State(initialValue: true)
                //@endif
                _finished = State(initialValue: Set(TourContent.tabs).subtracting([first]))
                remembers = false
            //@endif
            case .done:
                //@if part.welcome
                _welcomed = State(initialValue: true)
                //@endif
                //@if part.tips
                _finished = State(initialValue: Set(TourContent.tabs))
                //@endif
                remembers = false
            }
        }
        //@if part.welcome

        /// Whether the welcome was passed.
        static let welcomedKey = {{x:welcomedKey}}
        //@endif
        //@if part.tips

        /// The tabs whose tour is done.
        static let finishedKey = {{x:finishedKey}}

        /// The tips of the tab that is up, while its tour is not done.
        private var tips: [TourTip] {
            //@if part.welcome
            guard welcomed, !finished.contains(tab) else { return [] }
            //@else
            guard !finished.contains(tab) else { return [] }
            //@endif
            return TourContent.tips[tab] ?? []
        }
        //@endif

        /// Whether the layer draws anything: the welcome, or a tip.
        private var presenting: Bool {
            //@if part.welcome
            //@if part.tips
            !welcomed || index < tips.count
            //@else
            !welcomed
            //@endif
            //@else
            index < tips.count
            //@endif
        }

        var body: some View {
            ZStack {
                //@if part.welcome
                if !welcomed {
                    TourWelcomeCard(start: { start() }, skip: { skip() })
                        .transition(.opacity)
                        .zIndex(100)
                }
                //@endif
                //@if part.tips

                if index < tips.count {
                    TourTipCard(tip: tips[index], number: index + 1, count: tips.count, back: { back() }, next: { next() })
                        .zIndex(99)
                }
                //@endif
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(presenting)
            //@if part.welcome
            .animation({{a:welcome.settle}}, value: welcomed)
            //@endif
            //@if part.tips
            .animation({{a:tip.settle}}, value: index)
            .animation({{a:tip.swap}}, value: tab)
            .onChange(of: tab) {
                index = 0
            }
            //@endif
        }
        //@if part.welcome

        /// The first button: the welcome closes and the tab's tips begin.
        private func start() {
            TourHaptics.light()
            withAnimation({{a:welcome.show}}) {
                welcomed = true
            }
            save()
        }

        /// Skip: the welcome closes and every tour counts as done.
        private func skip() {
            TourHaptics.soft()
            withAnimation({{a:welcome.skip}}) {
                welcomed = true
                //@if part.tips
                finished = Set(TourContent.tabs)
                //@endif
            }
            save()
        }
        //@endif
        //@if part.tips

        /// The next tip, or the end of the tab's tour for good on its last.
        private func next() {
            TourHaptics.light()
            withAnimation({{a:tip.step}}) {
                if index < tips.count - 1 {
                    index += 1
                } else {
                    finished.insert(tab)
                    index = 0
                }
            }
            save()
        }

        /// The tip before.
        private func back() {
            guard index > 0 else { return }
            TourHaptics.light()
            withAnimation({{a:tip.step}}) {
                index -= 1
            }
        }
        //@endif

        /// What is done, kept for the next launch.
        private func save() {
            guard remembers else { return }
            //@if part.welcome
            UserDefaults.standard.set(welcomed, forKey: Self.welcomedKey)
            //@endif
            //@if part.tips
            UserDefaults.standard.set(finished.sorted(), forKey: Self.finishedKey)
            //@endif
        }
    }

    extension View {
        /// The first-run layer over this view, the app's tabs: the welcome card, then the tips of `tab`, the tab that
        /// is up.
        func {{x:modifier}}(tab: String) -> some View {
            overlay {
                TourLayer(tab: tab)
            }
        }

        /// The first-run layer over this view, for tabs named by an enum whose raw value names their tips.
        func {{x:modifier}}<Tab: RawRepresentable>(tab: Tab) -> some View where Tab.RawValue == String {
            overlay {
                TourLayer(tab: tab.rawValue)
            }
        }
    }
    //@if part.welcome

    #Preview("Welcome") {
        Color.gray.opacity(0.15)
            .ignoresSafeArea()
            .overlay {
                TourLayer(tab: {{x:previewTab}}, start: .welcome)
            }
    }
    //@endif
    //@if part.tips

    #Preview("Tips") {
        Color.gray.opacity(0.15)
            .ignoresSafeArea()
            .overlay {
                TourLayer(tab: {{x:previewTab}}, start: .tips({{x:previewTab}}))
            }
    }
    //@endif
    """##
}
