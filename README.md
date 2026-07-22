# JSON Utilities

A lightweight, native macOS app for everyday JSON chores.

- **Format** / **Minify** — pretty-print or compact JSON, preserving key order
- **Marshal** / **Unmarshal** — encode JSON as a string / decode JSON-in-a-string
- **Deep Unmarshal** — recursively expand stringified JSON nested inside values
- **Diff** — line-by-line comparison of two payloads
- Four colour themes, line-numbered editors, live syntax highlighting, and a
  validity indicator.

## Install

1. Download the latest **[JSON-Utilities-macos.zip](https://github.com/a-dimitri/json-utils/releases/latest/download/JSON-Utilities-macos.zip)**
   from the [Releases page](https://github.com/a-dimitri/json-utils/releases/latest) and unzip it.
2. Move **JSON Utilities.app** to `/Applications`.
3. The app is ad-hoc signed (not notarized), so on first launch macOS Gatekeeper
   will warn about an unidentified developer. Either **right-click the app → Open**
   once, or clear the quarantine flag:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/JSON Utilities.app"
   ```

Requires macOS 13 or later (Apple Silicon).

## Build from source

Requires a **Swift 6.x** toolchain on your `PATH`.

```sh
swift run JsonUtilities      # build & launch
swift run JSONKitTests       # run the logic tests
./scripts/build-app.sh       # produce dist/JSON Utilities.app (+ zip)
```

## Layout

```
Sources/
  JSONKit/          Pure logic: parser/serializer, operations, differ, tokenizer
  JsonUtilities/    SwiftUI app: model, themes, editors, views
  JSONKitTests/     Logic tests (run with: swift run JSONKitTests)
scripts/build-app.sh  Builds and signs the .app bundle
icons/                App icon sources
```
