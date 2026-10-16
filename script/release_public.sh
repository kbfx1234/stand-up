#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/StandUp.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/StandUp"
RELEASE_DIR="$ROOT_DIR/release"
VERSION="${VERSION:-0.4.0}"
DMG_PATH="$RELEASE_DIR/Stand-Up-$VERSION.dmg"
SIGNING_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
NOTARY_PROFILE="${NOTARYTOOL_PROFILE:-}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "Missing DEVELOPER_ID_APPLICATION. Set it to the Developer ID Application identity." >&2
  security find-identity -v -p codesigning >&2 || true
  exit 2
fi
if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "Missing NOTARYTOOL_PROFILE. Store credentials with xcrun notarytool store-credentials first." >&2
  exit 2
fi

"$ROOT_DIR/script/build_and_run.sh" --release
codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BINARY"
codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

mkdir -p "$RELEASE_DIR"
rm -f "$DMG_PATH" "$DMG_PATH.sha256"
hdiutil create -volname "Stand Up" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vv --type open "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "Created notarized release: $DMG_PATH"
