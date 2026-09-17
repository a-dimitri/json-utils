#!/usr/bin/env bash
#
# Builds a distributable, ad-hoc-signed "JSON Utilities.app" bundle.
#
#   scripts/build-app.sh
#
# Requires a Swift 6.x toolchain on PATH. Produces:
#   dist/JSON Utilities.app        the app bundle
#   dist/JSON-Utilities-macos.zip  a zipped copy for distribution
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXECUTABLE="JsonUtilities"
APP_NAME="JSON Utilities"
BUNDLE_ID="io.github.a-dimitri.JsonUtilities"
VERSION="1.0.2"

DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
ZIP="$DIST/JSON-Utilities-macos.zip"

echo "==> Building release binary"
swift build -c release --product "$EXECUTABLE"
BIN="$(swift build -c release --product "$EXECUTABLE" --show-bin-path)/$EXECUTABLE"

echo "==> Assembling bundle at: $APP"
rm -rf "$APP" "$ZIP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE"

echo "==> Generating app icon from iconset"
iconutil --convert icns "$ROOT/icons/AppIcon.iconset" --output "$APP/Contents/Resources/AppIcon.icns"

echo "==> Writing Info.plist"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>      <string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>CFBundleVersion</key>         <string>$VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSApplicationCategoryType</key> <string>public.app-category.developer-tools</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=2 "$APP"

echo "==> Zipping for distribution"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "==> Done"
echo "    App: $APP"
echo "    Zip: $ZIP"
