//  WHAT: Every user-facing string the tour shows, by key, with its natural English default. A `strings` line sets
//        one (`welcome.title = "Welcome to Seer"`); the views are written with the text in place, as a person writes
//        `Text("Welcome to Seer")`.

import Foundation

/// One string the tour shows.
struct TourString: Sendable {
    let key: String
    /// What it says when no line sets it.
    let fallback: String
    /// Where it shows, in a few words.
    let what: String
    /// The part that shows it: a line for a part the call leaves out changes nothing.
    let part: TourPart
}

enum TourStrings {
    static let all: [TourString] = [
        TourString(key: "welcome.title", fallback: "Welcome", what: "the welcome card's title", part: .welcome),
        TourString(key: "welcome.body", fallback: "Here is a quick look around.\nIt only takes a moment.", what: "the line under the title", part: .welcome),
        TourString(key: "welcome.start", fallback: "Show me around", what: "the button that starts the tips", part: .welcome),
        TourString(key: "welcome.skip", fallback: "Skip", what: "the button that skips the tour", part: .welcome),
        TourString(key: "tip.counter", fallback: "{n} of {count}", what: "a tip's place in its tour; {n} is the tip, {count} the tips", part: .tips),
        TourString(key: "tip.next", fallback: "Next", what: "the button to the next tip", part: .tips),
        TourString(key: "tip.done", fallback: "Got it", what: "the button on a tour's last tip", part: .tips),
        TourString(key: "tip.back", fallback: "Previous tip", what: "the back button, read by VoiceOver", part: .tips),
        TourString(key: "about.name", fallback: "About", what: "the pager's name, as `TourAbout.name`, for the menu item or button that opens it", part: .about),
        TourString(key: "about.title", fallback: "Everything\nthis app can do.", what: "the cover's heading", part: .about),
        TourString(key: "about.subtitle", fallback: "A guided tour of every feature,\nat your own pace.", what: "the cover's line under the heading", part: .about),
        TourString(key: "about.begin", fallback: "Begin the tour", what: "the cover's button", part: .about),
        TourString(key: "about.close", fallback: "Close", what: "the close button, read by VoiceOver", part: .about),
        TourString(key: "about.back", fallback: "Previous page", what: "the back button, read by VoiceOver", part: .about),
        TourString(key: "about.next", fallback: "Next page", what: "the forward button, read by VoiceOver", part: .about),
        TourString(key: "about.done", fallback: "Done", what: "the last page's button, read by VoiceOver", part: .about),
    ]

    static let keys = all.map(\.key)

    static func named(_ key: String) -> TourString? { all.first { $0.key == key } }

    /// The tokens `tip.counter` may hold, and the Swift each becomes in the card.
    static let counterTokens = ["{n}": "number", "{count}": "count"]
}
