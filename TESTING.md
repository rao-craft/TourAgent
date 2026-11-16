# Testing TourAgent

How `tour` is tested: its own suite, and its gated build of real output, the Seer call among it.

## The suite

```
swift test                                        # the record, the schema, the lines, the templates, the files
TOUR_BUILD=1 swift test --filter TourBuildTests   # the output built for real (gated, about a minute and a half)
TOUR_WRITE_SCHEMA=1 swift test                    # writes the schema files and the Seer answer again
```

- **`LineTests`:** every line, read and refused: tips and their places, palettes in any spelling of hex, pages and
  their rows, launch states, animations, the mark, look values, tuning values; every problem with a call said at
  once; the Seer call read whole with nothing to note.
- **`TemplateTests`:** every part alone and together, with a mark that turns or keeps still, drawn from a view or a
  symbol, a gradient that starts later or holds, and a cover's mark fainter and smaller: each call's files parse, with
  no marker, placeholder or run of blank lines left, and a preview in each view. Every tuning key, string and look
  role is read by some file; every type a template declares is one a prefix renames.
- **`TourEmitTests`:** which files each part writes; a prefix renames every type and the modifier but never the
  call's words; the Seer call's output against Seer's scorecard and spec (below); the original's look pinned value
  for value; the same bytes a second time, answered `unchanged`; files a later call no longer asks for taken away and
  the app's own kept; a refused call writes nothing.
- **`TourAgentTests`:** the record, the schema files, the field notes, the guide's examples, a call through Granite's
  roster as a host makes it, and a refusal reaching the host.
- **`SameBytesTests`:** additive only. Calls that say none of the newer tuning keys (Seer's call as it stood at
  67aebc3 and at 56b4cde, the same with the mark's keys at 1, the recipe call and the part calls) are held to the
  bytes 67aebc3 wrote, by a digest of each file's path and SHA-256.
- **`TourBuildTests` (gated):** a package of four apps written by the kit, built with `swift build` for the Mac and
  with `xcodebuild` for `generic/platform=iOS Simulator`:
  - **SeerSix** (Swift 6) and **SeerFive** (Swift 5): the Seer call, stand-ins for `Color.accent` and `SeerMark()`,
    and tabs that use `.tour(tab:)` with an enum and with a String, and `.sheet { TourAbout() }`;
  - **Parts**: each part alone under a prefix of its own (the pager with a symbol for a mark, the tips, the welcome
    with a mark that keeps still);
  - **Recipes**: `Schema/examples/recipes.json` with its own mark.

  No warning may come from what the kit wrote. Then a check draws the Seer app's welcome, tips, pager and rows
  offscreen in light and dark (`TOUR_KEEP=<folder>` builds in that folder and keeps the drawings in `shots/`). No
  simulator is booted.

## Conformance on Seer

The Seer call (`Schema/examples/seer.json`) is the call that reproduces the original Seer app's welcome card, tips
and About Seer pager, copied from Seer's spec. On 2026-11-15:

- **It builds.** `TOUR_BUILD=1 swift test --filter TourBuildTests` passed: the Seer output compiled for the Mac in
  Swift 6 and Swift 5 with no warning in the kit's files, drew its eight screens offscreen, and built for the iPhone
  simulator (`** BUILD SUCCEEDED **`).
- **Every scorecard code fact holds.** All ten `code` items of the areas `onboarding` and `about` match the output:
  B-onboarding-4 to 9 and B-about-4 to 7 (the welcome's copy, the scrim at 0.55, every tip title, body and symbol,
  "Got it" and the 0.88 scale, the six taglines, the rows, the page symbols, radial gradients from 0.82).
  `TourEmitTests` checks each pattern as the scorer reads it.
- **Every quoted string of the spec is in the code.** The 66 distinct strings in double quotes in the spec's Welcome,
  Tours and About Seer sections, a line break as `\n`.
- **The original's subviews, value for value.** The templates mirror the original's views: the same composition,
  modifiers and values (the welcome card inset 36 at the sides with a 24-radius regular-material card; the tip card on
  a clear ground at 112 by 16; the pager framed by a GeometryReader, the close button 12 by 20, the 24-apart row of
  chevrons and markers; the cover and feature pages and their entrance springs; the gradient's blobs).
  `TourEmitTests.testTheSeerOutputKeepsTheOriginalsLook` pins them.

The screens themselves are compared on the iPhone by the measure's visual loop, which shoots every destination
light and dark and sets each beside the original's.
