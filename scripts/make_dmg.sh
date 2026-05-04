#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="dist/WebP Converter.app"
DMG_DIR="dist/dmg"
VOL_NAME="WebP Converter"
DMG_PATH="dist/WebP-Converter-apple-silicon.dmg"

if [ ! -d "$APP_PATH" ]; then
  echo "App not found at $APP_PATH"
  echo "Run: ./scripts/build_app.sh"
  exit 1
fi

rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$VOL_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_PATH"

echo "Built DMG at: $ROOT_DIR/$DMG_PATH"
