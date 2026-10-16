#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
case "$MODE" in run|--dev|--debug|--logs|--telemetry|--verify|--build|--release|--preview|--preview-reminder|--install) ;;
  *) echo 'usage: build_and_run.sh [--dev|--verify|--build|--release|--preview|--preview-reminder|--install|--debug|--logs|--telemetry]' >&2; exit 2;;
esac
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
APP_NAME="StandUp"
BUNDLE_ID="local.demo.StandUp"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
APP_RESOURCES="$APP_BUNDLE/Contents/Resources"
INSTALL_BUNDLE="/Applications/Stand Up.app"
# Stop only this local bundle, preserving its session through applicationWillTerminate.
if pgrep -f "^$APP_BINARY" >/dev/null; then
  /usr/bin/osascript -e 'tell application id "local.demo.StandUp" to quit'
fi
if [[ "$MODE" == "--install" ]] && pgrep -f "^$INSTALL_BUNDLE/Contents/MacOS/$APP_NAME$" >/dev/null; then
  /usr/bin/osascript -e 'tell application "Stand Up" to quit' >/dev/null 2>&1 || true
  sleep 1
  /usr/bin/pkill -TERM -f "^$INSTALL_BUNDLE/Contents/MacOS/$APP_NAME$" >/dev/null 2>&1 || true
  sleep 1
fi
BUILD_CONFIGURATION="debug"
if [[ "$MODE" == "--install" || "$MODE" == "--release" ]]; then
  BUILD_CONFIGURATION="release"
fi
swift build -c "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)/$APP_NAME"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$ROOT_DIR/Resources/StandUp.icns" "$APP_RESOURCES/StandUp.icns"
chmod +x "$APP_BINARY"
cat >"$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>Stand Up</string>
<key>CFBundleIconFile</key><string>StandUp.icns</string>
<key>CFBundleShortVersionString</key><string>0.4.0</string>
<key>CFBundleVersion</key><string>8</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string></array>
<key>LSUIElement</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP_BUNDLE"
case "$MODE" in
  --build|--release) ;;
  --install)
    /usr/bin/osascript -e 'tell application id "local.demo.StandUp" to quit' >/dev/null 2>&1 || true
    /usr/bin/ditto "$APP_BUNDLE" "$INSTALL_BUNDLE"
    codesign --verify --deep --strict "$INSTALL_BUNDLE"
    /usr/bin/open -a "$INSTALL_BUNDLE"
    echo "Installed and launched: $INSTALL_BUNDLE"
    ;;
  --dev) /usr/bin/open -n "$APP_BUNDLE" --args --dev ;;
  --preview) mkdir -p work/previews; /usr/bin/open -n -W "$APP_BUNDLE" --args --preview "$ROOT_DIR/work/previews" ;;
  --preview-reminder) /usr/bin/open -n "$APP_BUNDLE" --args --preview-reminder ;;
  --debug) lldb -- "$APP_BINARY" ;;
  --logs|--telemetry) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "StandUp"' ;;
  --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 2; pgrep -f "^$APP_BINARY" >/dev/null; echo 'StandUp bundle launched; process verified.' ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac
