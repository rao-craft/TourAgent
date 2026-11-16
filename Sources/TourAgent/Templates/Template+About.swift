//  WHAT: The template of `TourAbout.swift`: the about pager the app presents as a sheet: a close button, the cover and
//        a page a feature over the drifting gradient, and a row of back, page markers and forward.
//  PIN:  THE PAGER FILLS THE SHEET. A GeometryReader frames the column at the sheet's size, so the close button sits
//        at the sheet's top and the row of controls above its bottom, with the gradient under everything.

extension Template {
    static let about = ##"""
    import SwiftUI

    /// The about pager: a cover, then a page a feature, over a gradient that drifts and blends into each page's
    /// palette. The app presents it as a sheet; it closes by its close button, its last page's button, or a drag.
    struct TourAbout: View {
        /// The pager's name, for the menu item or button that opens it.
        static let name = {{s:about.name}}

        /// Called by the close button and the last page's button; when nil, the sheet that presents it is dismissed.
        var onClose: (() -> Void)? = nil

        @State private var page: Int
        @State private var colors: [Color]
        @Environment(\.dismiss) private var dismiss

        init(onClose: (() -> Void)? = nil) {
            self.onClose = onClose
            let first = min(max(TourLaunch.aboutPage, 0), TourContent.pages.count)
            _page = State(initialValue: first)
            _colors = State(initialValue: Self.palette(of: first))
        }

        /// The number of pages, the cover with them.
        private var count: Int { TourContent.pages.count + 1 }

        /// The colours behind page `number`: the cover's, or the feature's.
        private static func palette(of number: Int) -> [Color] {
            number == 0 ? TourContent.cover : TourContent.pages[number - 1].palette
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    TourDriftingGradient(colors: colors)
                        .opacity({{n:gradient.opacity}})
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        closeBar

                        pager

                        controls
                            .padding(.bottom, 28)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .multilineTextAlignment(.center)
                .presentationDragIndicator(.visible)
                .onChange(of: page) { _, number in
                    withAnimation({{a:about.blend}}) {
                        colors = Self.palette(of: number)
                    }
                }
            }
        }

        private var closeBar: some View {
            HStack {
                Spacer()
                Button {
                    close()
                } label: {
                    Image(systemName: {{y:symbol.close}})
                        .imageScale(.medium)
                        .fontWeight(.semibold)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
                .padding(.trailing, 20)
                .accessibilityLabel(Text({{s:about.close}}))
            }
        }

        @ViewBuilder
        private var pager: some View {
            #if os(iOS)
            TabView(selection: $page) {
                TourAboutCover(begin: count > 1 ? { begin() } : nil)
                    .tag(0)

                ForEach(TourContent.pages.indices, id: \.self) { index in
                    TourAboutPage(page: TourContent.pages[index])
                        .tag(index + 1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            Group {
                if page == 0 {
                    TourAboutCover(begin: count > 1 ? { begin() } : nil)
                } else {
                    TourAboutPage(page: TourContent.pages[page - 1])
                }
            }
            .id(page)
            .frame(maxHeight: .infinity)
            #endif
        }

        private var controls: some View {
            HStack(spacing: 24) {
                Button {
                    back()
                } label: {
                    Image(systemName: {{y:symbol.back}})
                        .font(.subheadline.bold())
                        .padding(13)
                        .background(.ultraThinMaterial, in: Circle())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .opacity(page > 0 ? 1 : 0.2)
                .disabled(page == 0)
                .accessibilityLabel(Text({{s:about.back}}))

                HStack(spacing: 5) {
                    ForEach(0..<count, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? TourLook.accent : Color.secondary.opacity(0.3))
                            .frame(width: index == page ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: page)
                    }
                }
                .accessibilityHidden(true)

                Button {
                    forward()
                } label: {
                    let last = page == count - 1
                    Image(systemName: last ? {{y:symbol.finish}} : {{y:symbol.forward}})
                        .font(.subheadline.bold())
                        .padding(13)
                        .background {
                            if last {
                                Circle().fill(TourLook.accent)
                            } else {
                                Circle().fill(.ultraThinMaterial)
                            }
                        }
                        .foregroundStyle(last ? TourLook.onAccent : Color.primary)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(page == count - 1 ? {{s:about.done}} : {{s:about.next}}))
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }

        /// The cover's button: the first feature page.
        private func begin() {
            TourHaptics.light()
            withAnimation({{a:about.begin}}) {
                page = 1
            }
        }

        private func back() {
            guard page > 0 else { return }
            TourHaptics.light()
            withAnimation({{a:about.step}}) {
                page -= 1
            }
        }

        /// The next page, or closed on the last.
        private func forward() {
            TourHaptics.light()
            if page < count - 1 {
                withAnimation({{a:about.step}}) {
                    page += 1
                }
            } else {
                close()
            }
        }

        private func close() {
            if let onClose {
                onClose()
            } else {
                dismiss()
            }
        }
    }

    #Preview {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                TourAbout()
            }
    }
    """##
}
