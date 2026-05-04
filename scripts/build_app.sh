#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

# Fallback to default icon if custom one doesn't exist yet
if [ ! -f "resources/AppIcon.icns" ]; then
  mkdir -p resources
  cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarInfo.icns" "resources/AppIcon.icns"
fi

rm -rf build dist

pyinstaller \
  --noconfirm \
  --clean \
  --windowed \
  --onedir \
  --name "WebP Converter" \
  --target-arch arm64 \
  --icon "resources/AppIcon.icns" \
  --hidden-import tkinterdnd2 \
  --collect-submodules tkinterdnd2 \
  convert_to_webp.py

echo "Built app at: $ROOT_DIR/dist/WebP Converter.app"
