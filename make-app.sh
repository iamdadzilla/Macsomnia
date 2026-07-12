#!/bin/bash
set -euo pipefail

# Builds a release binary and wraps it in Macsomnia.app with an Info.plist
# marking it as a menu-bar (accessory) app.
#
# Env: VERSION overrides the bundle version (default 1.0).

VERSION="${VERSION:-1.0}"
APP="Macsomnia.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

swift build -c release
rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/release/Macsomnia" "$MACOS/Macsomnia"

# App icon (regenerate with ./icon/build-icns.sh). Optional — skip if absent.
if [ -f "Macsomnia.icns" ]; then
    cp "Macsomnia.icns" "$RESOURCES/Macsomnia.icns"
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>Macsomnia</string>
    <key>CFBundleDisplayName</key>       <string>Macsomnia</string>
    <key>CFBundleIdentifier</key>        <string>net.jperry.Macsomnia</string>
    <key>CFBundleVersion</key>           <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleExecutable</key>        <string>Macsomnia</string>
    <key>CFBundleIconFile</key>          <string>Macsomnia</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>LSUIElement</key>               <true/>
</dict>
</plist>
PLIST

echo "Built $APP. Move it to /Applications and open it."
