#!/bin/bash
set -euo pipefail

# Regenerates Macsomnia.icns from make-icon.swift.
# Run from anywhere; writes Macsomnia.icns to the repo root.

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ICONSET="$HERE/AppIcon.iconset"
MASTER="$HERE/icon_master.png"

swift "$HERE/make-icon.swift" "$MASTER" 1024

rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    sips -z "$s" "$s"           "$MASTER" --out "$ICONSET/icon_${s}x${s}.png"      >/dev/null
    sips -z "$((s*2))" "$((s*2))" "$MASTER" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o "$ROOT/Macsomnia.icns"
echo "Built $ROOT/Macsomnia.icns"
