#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Stand Up"
APP_BUNDLE="$ROOT_DIR/dist/StandUp.app"
DMG_DIR="$ROOT_DIR/release"
DMG_PATH="$DMG_DIR/Stand-Up-0.3.2.dmg"

"$ROOT_DIR/script/build_and_run.sh" --release
mkdir -p "$DMG_DIR"
rm -f "$DMG_PATH"
/usr/bin/hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "Created $DMG_PATH"
