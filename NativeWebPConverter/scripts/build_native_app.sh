#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/WebP Converter.app"
ICON_DIR="$ROOT_DIR/resources/AppIcon.iconset"
ICON_ICNS="$ROOT_DIR/resources/AppIcon.icns"
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
PNG_ICON="$PROJECT_ROOT/app-icon.png"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

if [ -f "$PNG_ICON" ]; then
  rm -rf "$ICON_DIR"
  mkdir -p "$ICON_DIR"
  sips -z 16 16 "$PNG_ICON" --out "$ICON_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$PNG_ICON" --out "$ICON_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$PNG_ICON" --out "$ICON_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$PNG_ICON" --out "$ICON_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$PNG_ICON" --out "$ICON_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$PNG_ICON" --out "$ICON_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$PNG_ICON" --out "$ICON_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$PNG_ICON" --out "$ICON_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$PNG_ICON" --out "$ICON_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$PNG_ICON" --out "$ICON_DIR/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICON_DIR" -o "$ICON_ICNS"
fi

xcrun swiftc \
  -O \
  -target arm64-apple-macos13.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework UniformTypeIdentifiers \
  -framework ImageIO \
  -framework CoreGraphics \
  "$ROOT_DIR"/Sources/*.swift \
  -o "$APP_DIR/Contents/MacOS/WebP Converter"

cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

if [ -f "$ROOT_DIR/resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo "Built native app: $APP_DIR"
