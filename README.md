# TourAgent

Give an app its first run without drawing it by hand. Say what the welcome card says, what each tab's tips point
at, and which features the about pager shows, and `tour` writes the layer that greets a new user over the app's tabs
and the pager the app opens from a menu. What it writes is plain SwiftUI that works in any app, with no Granite
dependency in it.

## What you can ask

```
$tour the first-run tour for Seer: the welcome card, each tab's tips, and the About Seer pager
$tour a welcome card and tips for the recipe app's two tabs, kept under recipes.tour
$tour only the about pager, six feature pages over the aurora and sunrise palettes, in a serif face
$tour tips for the notes tab beside the app's own Tour types, prefixed Intro
```

Craft writes the call from your request, shows it on its agent map as `tour-1`, and builds and tests what it writes
with the turn.

## What you get

- **A welcome card over a scrim.** The app's mark turning slowly, a title and a line, a full-width button that starts
  the tips and a Skip under it, on a frosted card in the middle of a dimmed screen.
- **Tips, one card at a time.** Each tab's tour the first time that tab is up: the control's symbol, a title and a
  line, "1 of 3", dots, back and Next, and "Got it" on the last. A card stands under the control it explains and
  grows in from that corner; around it, the app stays usable.
- **An about pager.** A cover with the mark, a large heading and a begin button, then a page a feature with its
  symbol, tagline, description and rows, over a gradient that drifts and blends into each page's palette.
- **Your words, timings and look.** Every string, spring, size and symbol is a line in the call with a natural
  default; your colours and fonts are mapped by name, and a role left out keeps the system's.
- **What a first run needs to be testable.** Each `-destination` launch argument opens the state you name, the
  welcome, a tab's tips or the pager, with nothing else in the way, and saves nothing.
- **Views ready to drop in.** They take values and closures, hold no global state and never route: the app applies
  the layer with `.tour(tab:)` and presents `TourAbout()` as a sheet. Every view has a `#Preview`, and every
  icon-only control is labelled for VoiceOver.

## How it works

- It reads each line and refuses one it cannot read with the reason and what the line accepts, every bad line at
  once, and writes nothing.
- It writes from templates and asks no model, so the same call makes the same files every time.
- Every file is parsed with `swiftc -parse` before any lands, and they land together. A later call into the same
  folder takes away the kit's files its parts no longer use, and never one of the app's.
- What it makes is built and tested with the turn.

## Works well with

`tour` writes the first run; the other Rao Craft Agents fill in the rest. `design` names the colours and fonts it
maps, and `granite` writes the tabs it lies over, the page whose menu opens `TourAbout()`, and the navigation that
opens each launch destination's tab or sheet.

## Get it

In Craft, install Tour from the Agent Store, or run
`craft agents add https://github.com/rao-craft/TourAgent.git`, then say `$tour` in a request.

## Requirements

- A Mac on macOS 14 or later, with Xcode.
- The views target iOS 17 and macOS 14 and compile in Swift 5 and Swift 6 language modes. They are plain SwiftUI:
  no Granite, and no package to add.
- MIT licensed.
