# Bulk Media Optimizer (WebP Converter for macOS)

A simple, fast desktop app for converting images to WebP on macOS (Apple Silicon).
Packaged as a native `.app` and easy-to-install `.dmg`.

<img width="1280" height="640" alt="bulk-media-optimizer-poster" src="https://github.com/user-attachments/assets/8a1f91bd-27c8-4b25-adb1-a3f6673f42f9" />

---
A native utility for bulk-processing media folders:

- Converts images to `.webp`
- Copies existing `.webp` files without recompression
- Copies all non-image files as-is (`.pdf`, `.docx`, videos, archives, etc.)
- Preserves the original folder structure
- Optionally generates an XLSX index for processed images

Built for fast, practical production workflows where you need to prepare large media directories for web/catalog use.

---

## What This App Does

The app recursively scans a selected **source folder** and processes every file into a chosen **destination folder**.

### Processing Rules

1. **Non-WEBP images** (`.jpg`, `.jpeg`, `.png`, `.bmp`, `.tif`, `.tiff`, `.gif`)
- Converted to `.webp`
- Optional max-width resize (aspect ratio preserved)

2. **Existing `.webp` images**
- Copied directly
- No re-encoding / no quality loss from recompression

3. **All non-image files**
- Copied as-is
- Examples: `.pdf`, `.docx`, `.mp4`, `.mov`, `.zip`, etc.

4. **Folder structure**
- Preserved exactly from source to destination

5. **Optional XLSX index** (Useful for uploading / importing the images in bulk.)
- Writes `converted_images.xlsx`
- Includes converted images + copied `.webp` images
- Column A: filename (without extension)
- Column B: absolute file path or URL (`URL base + filename.webp`)

---

## User Flow (Step by Step)

1. **Open the app**
2. **Select Source folder**
- Via `Browse`
- Or drag-and-drop a folder into the app window
3. **Select Destination folder**
- Via `Browse`
- You can create a new folder directly from the picker
4. **Set options**
- `Create XLSX index` (optional)
- `Use URL base for XLSX` + URL base value (optional)
- `Max width` in pixels (optional)
5. **Start conversion**
- Click `Convert`
- Watch live progress + log output
6. **Cancel if needed**
- Click `Cancel` to stop the run
7. **Review output**
- Converted/copied files in destination
- Optional `converted_images.xlsx`

---

## How It Works Internally

### Conversion Pipeline

For image conversion to WebP, the app uses a robust fallback chain:

1. **ImageIO (native Apple framework)**
2. **`sips` fallback** (system image tool)
3. **`cwebp` fallback** (`/opt/homebrew/bin/cwebp`)

This helps conversion succeed across macOS environments where a single encoder path may fail.

### Access / Permission Preflight

Before processing starts, the app verifies:

- Source folder is accessible/readable
- Destination folder is writable

If not, it shows a native alert with guidance to grant access in macOS Privacy settings.

### Concurrency Model

- UI stays responsive during long operations
- Work runs asynchronously
- Progress and logs update in real time

---

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI (native macOS)
- **Platform APIs:** AppKit, UniformTypeIdentifiers
- **Image/encoding APIs:** ImageIO, CoreGraphics
- **External tools:** `sips`, `cwebp` (fallback path)
- **Spreadsheet output:** Minimal XLSX writer (Open XML structure generation)

---

## System Requirements

- macOS 13.0+
- Apple Silicon (M1/M2/M3/M4/M5)

---

## Build & Package

From project root:

```bash
cd "NativeWebPConverter"
./scripts/build_native_app.sh
./scripts/make_native_dmg.sh

## 🚀 Build the App

Run the following command:

```bash
./scripts/build_app.sh
```

Once it finishes, you’ll find the app here:

```
dist/WebP Converter.app
```

---

## ⚡ Performance & Experience

* Native macOS look using the Aqua Tk theme
* Built specifically for Apple Silicon (`arm64`)
* Smooth, responsive UI (conversion runs in the background)
* Lightweight and fast for bulk image processing
