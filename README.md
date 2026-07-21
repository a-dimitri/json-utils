# JSON Utilities

A lightweight, native macOS app for everyday JSON chores: format, minify,
marshal/unmarshal, deep-unmarshal nested stringified JSON, and diff two payloads.
Built with SwiftUI. The UI is a port of the design in `JSON Utilities.dc.html`.

## Requirements

- macOS 13+
- A **Swift 6.x** toolchain (the package is `swift-tools-version:6.0` and builds
  in Swift 6 language mode with full strict concurrency).

Full Xcode is **not** required. If you only have the older Command Line Tools,
install a Swift 6 toolchain from [swift.org](https://www.swift.org/install/macos/)
and put it on your `PATH` (under Command Line Tools, `TOOLCHAINS`/`xcrun` selection
is ignored, so prepend the toolchain's `usr/bin` directly):

```sh
export PATH="$HOME/Library/Developer/Toolchains/swift-6.1-RELEASE.xctoolchain/usr/bin:$PATH"
```

Xcode *is* required later to produce a signed, notarized `.app` for distribution.

## Layout

```
Sources/
  JSONKit/          Pure logic, no SwiftUI — fast to compile, easy to test
    JSONValue.swift   Order-preserving JSON model + serializer
    JSONParser.swift  Recursive-descent parser (keeps key order & number lexemes)
    Operation.swift   The 6 operations + JSONTools.run
    Differ.swift      LCS line diff
    Tokenizer.swift   Syntax-highlight tokenizer (tolerant of invalid input)
  JsonUtilities/    SwiftUI app
    JsonUtilitiesApp.swift  Entry point + menu commands
    AppModel.swift          Observable state
    Theme.swift             The 4 palettes (Midnight/Graphite/Frost/Paper)
    CodeTextView.swift      NSTextView bridge: line-number gutter + live highlighting
    RootView.swift          Toolbar, panes, status bar
    DiffView.swift          Diff sheet
    Samples.swift           Seed content
  JSONKitTests/     Assertion-based tests (XCTest is unavailable under CLT)
```

## Develop

```sh
swift build              # compile everything
swift run JsonUtilities  # launch the app
swift run JSONKitTests   # run the logic tests
```

## Design notes

- We use a **hand-written JSON model** instead of `JSONSerialization`/`Codable`
  because those lose object key order and rewrite number formatting — unacceptable
  for a formatter. `JSONValue` preserves key order and exact number lexemes.
- The editors are `NSTextView` wrapped in `NSViewRepresentable` (`CodeTextView`),
  giving a line-number gutter (via `NSRulerView`) and live JSON syntax
  highlighting — neither of which SwiftUI's `TextEditor` can do.
