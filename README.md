# JSON Utilities

A lightweight, native macOS app for everyday JSON chores: format, minify,
marshal/unmarshal, deep-unmarshal nested stringified JSON, and diff two payloads.
Built with SwiftUI. The UI is a port of the design in `JSON Utilities.dc.html`.

## Requirements

- macOS 13+
- Swift 5.9+ (Command Line Tools are sufficient for development)

Full Xcode is **not** required to build and run locally. It *is* required later
to produce a signed, notarized `.app` for distribution.

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
    Highlight.swift         Tokens -> coloured AttributedString
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
- The editable input pane currently uses SwiftUI's `TextEditor`. A line-numbered
  gutter and live syntax highlighting for the input will come via an `NSTextView`
  bridge (SwiftUI's `TextEditor` can't do either).
