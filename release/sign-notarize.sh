#!/bin/bash
set -euo pipefail

# Builds, signs (Developer ID + hardened runtime), notarizes, and staples
# Macsomnia.app, then produces a distributable Macsomnia-<version>.zip.
#
# Prerequisites (one-time):
#   1. A "Developer ID Application" certificate in the login keychain.
#   2. Stored notary credentials:
#        xcrun notarytool store-credentials "macsomnia-notary" \
#          --apple-id <id> --team-id <TEAMID> --password <app-specific-pw>
#
# Notary auth — use ONE of:
#   NOTARY_PROFILE  a stored notarytool keychain profile (local; default macsomnia-notary)
#   APPLE_ID + APPLE_TEAM_ID + APPLE_APP_PW   explicit credentials (CI)
#
# Other env overrides:
#   DEVID          signing identity (default: auto-detected Developer ID Application)
#   VERSION        release version for the zip name (default: from Info.plist)

cd "$(dirname "$0")/.."

APP="Macsomnia.app"

# --- Resolve signing identity -------------------------------------------------
if [ -z "${DEVID:-}" ]; then
    DEVID="$(security find-identity -v -p codesigning \
        | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -1)"
fi
if [ -z "$DEVID" ]; then
    echo "ERROR: no 'Developer ID Application' identity found." >&2
    echo "Create one in Xcode → Settings → Accounts → Manage Certificates." >&2
    exit 1
fi
echo "Signing identity: $DEVID"

# --- Build the (unsigned) bundle ---------------------------------------------
./make-app.sh >/dev/null
echo "Built $APP"

VERSION="${VERSION:-$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")}"
ZIP="Macsomnia-${VERSION}.zip"

# --- Sign (hardened runtime + secure timestamp) ------------------------------
# Flat bundle (no nested code), so a single signing pass seals the executable
# and resources.
codesign --force --options runtime --timestamp --sign "$DEVID" "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "Signed and verified."

# --- Notarize ----------------------------------------------------------------
ditto -c -k --keepParent "$APP" "$ZIP"
echo "Submitting $ZIP to notary service (this can take a few minutes)…"
if [ -n "${APPLE_ID:-}" ]; then
    xcrun notarytool submit "$ZIP" \
        --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PW" --wait
else
    xcrun notarytool submit "$ZIP" --keychain-profile "${NOTARY_PROFILE:-macsomnia-notary}" --wait
fi

# --- Staple + repackage the stapled app --------------------------------------
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

# --- Final Gatekeeper check --------------------------------------------------
echo "=== Gatekeeper assessment ==="
spctl -a -vvv -t exec "$APP" || true

SHA="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo
echo "Done: $ZIP"
echo "SHA-256: $SHA   (use this in the Homebrew cask)"
