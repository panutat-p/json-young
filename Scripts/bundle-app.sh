#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-debug}"
APP_NAME="JSON Young"
APP_DIR="$ROOT/.build/$APP_NAME.app"

if [[ "$CONFIG" == "release" ]]; then
  BINARY="$ROOT/.build/release/json-linter"
  ENTITLEMENTS="$ROOT/.build/arm64-apple-macosx/release/json-linter-entitlement.plist"
else
  BINARY="$ROOT/.build/debug/json-linter"
  ENTITLEMENTS="$ROOT/.build/arm64-apple-macosx/debug/json-linter-entitlement.plist"
fi

if [[ ! -f "$BINARY" ]]; then
  echo "Binary not found: $BINARY" >&2
  echo "Run 'swift build' or 'swift build -c release' first." >&2
  exit 1
fi

chmod +x "$ROOT/Scripts/build-app-icon.sh"
"$ROOT/Scripts/build-app-icon.sh"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BINARY" "$APP_DIR/Contents/MacOS/json-linter"
chmod +x "$APP_DIR/Contents/MacOS/json-linter"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/PkgInfo" "$APP_DIR/Contents/PkgInfo"
cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

if [[ -f "$ENTITLEMENTS" ]]; then
  codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_DIR"
else
  codesign --force --deep --sign - "$APP_DIR"
fi

xattr -cr "$APP_DIR"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f "$APP_DIR"
fi

echo "$APP_DIR"
