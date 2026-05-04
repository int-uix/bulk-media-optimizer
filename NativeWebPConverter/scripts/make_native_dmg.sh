#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/build/WebP Converter.app"
DMG_DIR="$ROOT_DIR/build/dmg"
DMG_PATH="$ROOT_DIR/build/WebP-Converter-Native-apple-silicon.dmg"

if [ ! -d "$APP_PATH" ]; then
  echo "App not found at $APP_PATH"
  echo "Run: ./scripts/build_native_app.sh"
  exit 1
fi

rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "WebP Converter" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_PATH"

echo "Built native DMG: $DMG_PATH"
