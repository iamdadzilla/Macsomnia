#!/bin/bash
set -euo pipefail

# Builds a release binary and wraps it in KeepAwake.app with an Info.plist
# marking it as a menu-bar (accessory) app.

APP="KeepAwake.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

swift build -c release
rm -rf "$APP"
mkdir -p "$MACOS"
cp ".build/release/KeepAwake" "$MACOS/KeepAwake"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>KeepAwake</string>
    <key>CFBundleDisplayName</key>       <string>KeepAwake</string>
    <key>CFBundleIdentifier</key>        <string>net.jperry.KeepAwake</string>
    <key>CFBundleVersion</key>           <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleExecutable</key>        <string>KeepAwake</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>LSUIElement</key>               <true/>
</dict>
</plist>
PLIST

echo "Built $APP. Move it to /Applications and open it."
