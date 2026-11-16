# tour · the reference

`tour` writes an app's first-run tour as plain SwiftUI: a welcome card over a scrim, each tab's tips one card at a
time, and an about pager of feature pages over a drifting gradient, in the app's words, timings, symbols and look.
This page holds every field, every line's syntax, every string key, tuning key, look role and launch state.

| File | What it holds |
| --- | --- |
| [`tour.input.schema.json`](tour.input.schema.json) | What it takes, as JSON Schema |
| [`tour.answer.schema.json`](tour.answer.schema.json) | What it answers: `granite-answer/1` with its own keys |
| [`examples/seer.json`](examples/seer.json) | The call that reproduces Seer's welcome, tips and About Seer pager |
| [`examples/seer.answer.json`](examples/seer.answer.json) | Its answer |
| [`examples/recipes.json`](examples/recipes.json) | A call for a different app |

## What it takes

Every field may be left out.

| Field | What it is |
| --- | --- |
| `into` | the folder for the views, relative to the project; `Components/Tour` when left out |
| `parts` | the parts to write, all three when left out: `welcome`, `tips`, `about` |
| `mark` | the app's mark on the welcome card and the cover: a view expression like `AppMark()` (`{size}` in it is the size it is drawn at), or an SF Symbol's name; `sparkles` when left out |
| `tips` | one line a tip, in tour order (below) |
| `palettes` | one line a palette the pager's gradient drifts through (below); `dawn` when none is given |
| `pages` | one line a feature page, after the cover (below) |
| `strings` | `key = "text"` lines (below) |
| `tuning` | `key = value` lines (below) |
| `look` | `role = Swift` lines (below) |
| `launch` | `destination = state` lines (below) |
| `defaultsKey` | the UserDefaults key the first run is kept under: `<key>.welcomed` and `<key>.finished`; `tour` when left out |
| `prefix` | the types' prefix, `Tour` when left out: `Kit` writes `KitLayer`, `KitAbout` and the modifier `.kit(tab:)` |
| `imports` | modules the views import, such as the one the mark's view or a look name is declared in |

`directory` is filled by the host with the project folder.

## Lines

**A tip:** `tab: title | body | symbol | place`.
- `tab` is the name the app passes to the layer for the tab that is up: letters, digits, `.`, `_` or `-`.
- `symbol` is an SF Symbol's name and may be left empty.
- `place` is where the card stands: `leading` (or `topLeading`, the default: under the bar's leading control),
  `trailing` (or `topTrailing`), `bottomLeading`, `bottomTrailing` (over the tab bar), or `center`.
- The words are cut only at `|`, so a title or body keeps brackets, quotes and dashes as written.
- `library: Your Memories | Toggle to view only notes marked as memories — moments worth revisiting. | brain | trailing`

**A palette:** `name: #RRGGBB #RRGGBB …`, two to eight colours; the first is the gradient's base, and each drifts
over it. `#2CA` and `0x21C7AD` are read too. Written as `Color(red:green:blue:)`, three places a channel.
- `aurora: #21C7AD #612ECC #0D94E6 #73E6A6`

**A feature page:** `symbol | palette | name | tagline | description | row | row …`.
- `palette` names a palette; empty takes the cover's.
- A row is `symbol: text`, or plain text with `symbol.row`'s symbol. At most eight rows.
- `eye.fill | aurora | Seer | See how you think. | Seer analyzes your notes… | cloud.fill: Word cloud built entirely from your content`

**A launch:** `destination = state`, for the `-destination <name>` launch argument UI tests and screenshots use.

| State | Opens |
| --- | --- |
| `welcome` | the welcome card, as on a first run |
| `tips(<tab>)` | the welcome passed and that tab's tips up, at the first tip |
| `done` | the first run over: the layer draws nothing |
| `about` | the pager on its cover |
| `about(<n>)` or `about(<name>)` | the pager on feature page n (1 is the first after the cover), or the page of that name |

With no destination, the layer opens on what the device remembers. A destination with no line opens with the first
run done, so nothing covers it. A launch into a destination saves nothing.

## Strings

A `strings` line is `key = "text"`; write `\n` for a line break. A key left out says its default.

| Key | Part | Default | Where it shows |
| --- | --- | --- | --- |
| `welcome.title` | welcome | "Welcome" | the welcome card's title |
| `welcome.body` | welcome | "Here is a quick look around.\nIt only takes a moment." | the line under the title |
| `welcome.start` | welcome | "Show me around" | the button that starts the tips |
| `welcome.skip` | welcome | "Skip" | the button that skips the tour |
| `tip.counter` | tips | "{n} of {count}" | a tip's place in its tour; {n} is the tip, {count} the tips |
| `tip.next` | tips | "Next" | the button to the next tip |
| `tip.done` | tips | "Got it" | the button on a tour's last tip |
| `tip.back` | tips | "Previous tip" | the back button, read by VoiceOver |
| `about.name` | about | "About" | the pager's name, as `TourAbout.name`, for the menu item or button that opens it |
| `about.title` | about | "Everything\nthis app can do." | the cover's heading |
| `about.subtitle` | about | "A guided tour of every feature,\nat your own pace." | the cover's line under the heading |
| `about.begin` | about | "Begin the tour" | the cover's button |
| `about.close` | about | "Close" | the close button, read by VoiceOver |
| `about.back` | about | "Previous page" | the back button, read by VoiceOver |
| `about.next` | about | "Next page" | the forward button, read by VoiceOver |
| `about.done` | about | "Done" | the last page's button, read by VoiceOver |

## Tuning

A `tuning` line is `key = value`. An animation is `spring(response, damping)`, `easeOut(seconds)`, `easeIn(seconds)`, `easeInOut(seconds)` or `linear(seconds)`, also as Swift writes it (`.spring(response: 0.4, dampingFraction: 0.8)`). A symbol is an SF Symbol's name; a palette is one the `palettes` lines name.

| Key | Kind | Default | What it sets |
| --- | --- | --- | --- |
| `mark.turn` | number, 0 to 600 | `42` | seconds the mark takes to turn once; 0 keeps it still |
| `welcome.show` | animation | `spring(0.4, 0.8)` | how the welcome card gives way to the tips |
| `welcome.skip` | animation | `easeOut(0.2)` | how the welcome card leaves on Skip |
| `welcome.settle` | animation | `spring(0.4, 0.85)` | the layer's own spring as the welcome comes and goes |
| `welcome.mark` | number, 16 to 400 | `100` | the mark's size on the welcome card |
| `welcome.inset` | number, 0 to 200 | `36` | the welcome card's distance from the screen's edges |
| `welcome.radius` | number, 0 to 80 | `24` | the welcome card's corner radius |
| `scrim.opacity` | number, 0 to 1 | `0.55` | how dark the scrim behind the welcome card is |
| `tip.step` | animation | `spring(0.35, 0.8)` | how a tour moves on Next and back |
| `tip.settle` | animation | `spring(0.35, 0.85)` | the layer's own spring as a tour moves from tip to tip |
| `tip.swap` | animation | `easeInOut(0.25)` | how one tab's tips give way to another's |
| `tip.scale` | number, 0 to 1 | `0.88` | the scale a tip card grows from as it comes in |
| `tip.width` | number, 120 to 600 | `270` | a tip card's widest |
| `tip.top` | number, 0 to 400 | `112` | a tip's distance from the top of the screen |
| `tip.side` | number, 0 to 200 | `16` | a tip's distance from the side of its control |
| `tip.bottom` | number, 0 to 400 | `100` | a bottom tip's distance from the bottom of the screen |
| `about.begin` | animation | `spring(0.4, 0.8)` | how the cover's button opens the first feature page |
| `about.step` | animation | `spring(0.35, 0.8)` | how the chevrons change page |
| `about.blend` | animation | `easeInOut(1.3)` | how the gradient blends into a page's palette |
| `about.cover` | palette | the first palette | the palette behind the cover; the first palette when left out |
| `about.mark` | number, 16 to 400 | `96` | the mark's size on the cover |
| `about.markRadius` | number, 0 to 200 | `22` | the corner radius the cover's mark is clipped to |
| `gradient.speed` | number, 0 to 10 | `0.0525` | how fast the colours drift: their clock is seconds times this |
| `gradient.strength` | number, 0 to 1 | `0.82` | each colour's opacity at its centre, fading to clear |
| `gradient.reach` | number, 0 to 4 | `0.85` | how far each colour reaches, as a share of the longer side |
| `gradient.drift` | number, 0 to 1 | `0.38` | how far each colour's centre wanders from the middle |
| `gradient.opacity` | number, 0 to 1 | `0.9` | the gradient's opacity behind the pager |
| `symbol.back` | symbol | `chevron.left` | the back button of a tip and of the pager |
| `symbol.forward` | symbol | `chevron.right` | the pager's forward button |
| `symbol.finish` | symbol | `checkmark` | the pager's last button, which closes it |
| `symbol.close` | symbol | `xmark` | the pager's close button |
| `symbol.begin` | symbol | `arrow.right` | the symbol beside the cover's button |
| `symbol.row` | symbol | `checkmark.circle` | a feature row's symbol when its line names none |

## Look

A `look` line is `role = Swift`: a colour or a font the app names, like `accent = Color.accent` or `welcomeTitle = Font.brandTitle`. A bare name is `Color.name` or `Font.name`; `aboutDesign` takes serif, rounded, monospaced or default. A role left out keeps its default, so the views build in any app.

| Role | Kind | Default | What it colours or sets |
| --- | --- | --- | --- |
| `accent` | color | `Color.accentColor` | buttons, the current dot and page marker, symbols |
| `onAccent` | color | `Color.white` | text and symbols on the accent |
| `scrim` | color | `Color.black` | the scrim behind the welcome card, at scrim.opacity |
| `welcomeTitle` | font | `Font.title.bold()` | the welcome card's title |
| `welcomeBody` | font | `Font.body` | the welcome card's line |
| `welcomeButton` | font | `Font.headline` | the welcome card's button |
| `welcomeSkip` | font | `Font.subheadline` | the welcome card's Skip |
| `tipTitle` | font | `Font.headline` | a tip's title and symbol |
| `tipCounter` | font | `Font.caption` | a tip's counter |
| `tipBody` | font | `Font.subheadline` | a tip's line |
| `tipButton` | font | `Font.subheadline.bold()` | a tip's buttons |
| `aboutDesign` | design | `.default` | the design the pager's type is drawn in: serif, rounded, monospaced or default |
| `aboutTitle` | font | `Font.system(size: 44, weight: .bold, design: aboutDesign)` | the cover's heading |
| `aboutSubtitle` | font | `Font.system(.title3, design: aboutDesign).italic()` | the cover's line |
| `aboutButton` | font | `Font.system(.headline, design: aboutDesign)` | the cover's button |
| `pageTitle` | font | `Font.system(size: 40, weight: .bold, design: aboutDesign)` | a feature page's name |
| `pageTagline` | font | `Font.system(.title3, design: aboutDesign).italic()` | a feature page's tagline |
| `pageBody` | font | `Font.system(.body, design: aboutDesign)` | a feature page's description |
| `pageRow` | font | `Font.system(.subheadline, design: aboutDesign)` | a feature page's rows |


## What it makes

| Kind | What | Into | Never |
| --- | --- | --- | --- |
| `view` | the layer the app applies over its tabs with `.tour(tab:)` (`TourLayer`, `TourWelcomeCard`, `TourTipCard`, `TourMark`) and the about pager it presents as a sheet (`TourAbout`, `TourAboutCover`, `TourAboutPage`, `TourAboutRow`, `TourDriftingGradient`) | `Components/Tour/*` | routes or presents the app's own screens; never a page, a service or a model type |
| `support` | what the views read: `TourLook` (colours and fonts), `TourLaunch` (the launch state), `TourContent` (tips, pages, and the palettes as `TourPalette`), `TourHaptics` | `Components/Tour/*` | a change to the app's own types |

Each part writes only its files: `welcome` the layer, the welcome card and the mark; `tips` the layer and the tip
card; `about` the pager, its cover, page, row, gradient and the mark. A later call into the same folder takes away
the kit's files its parts no longer use, and never a file of the app's.

## How the app uses it

- **The layer.** `.tour(tab: tab)` on the app's `TabView`, passing the tab that is up as the tips name it: a String,
  or an enum whose raw value is one. It draws over the whole screen, tab bar included, and takes touches only where
  it draws: the welcome's scrim takes all of them, a tip card only its own.
- **The pager.** `.sheet(isPresented: $about) { TourAbout() }`, with no detents: it fills the sheet, shows a drag
  indicator, and closes itself with `dismiss`, or calls `onClose` when given one. `TourAbout.name` is its name for
  the menu item that opens it.
- **The answer's initializers:** `TourLayer(tab: String, start: TourLaunch.Start = TourLaunch.start)` and
  `TourAbout(onClose: (() -> Void)? = nil)`.

## What it answers

A `granite-answer/1` answer: `paths`, `made` (each file written, rewritten, unchanged or taken away) against
`expected` (the views the parts are built from), and its own keys: `views`, `modifier`, `initializers`, `launch`
(each destination and its state), `keys` (the UserDefaults keys) and `notes` (how to apply the layer and present the
pager, and what the call left out).

## How it refuses

With an `AgentRefusal` of kind `call`: every line it cannot read, at once, each named by its field, its line number
and what it accepts, and nothing is written. Fix the lines and call again.
