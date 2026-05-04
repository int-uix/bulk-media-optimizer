# WebP Converter (macOS, Apple Silicon)

This project packages `convert_to_webp.py` as a native `.app` and `.dmg` for macOS Apple Silicon.

## 1) Build the app

```bash
./scripts/build_app.sh
```

Output app:

- `dist/WebP Converter.app`

## 2) Build the DMG

```bash
./scripts/make_dmg.sh
```

Output DMG:

- `dist/WebP-Converter-apple-silicon.dmg`

## Native feel and speed notes

- Uses macOS Aqua Tk theme via system Tk.
- Built as `arm64` for Apple Silicon.
- Processing runs in a worker thread, so UI remains responsive.
- If you want an even more native look later, the next step is a SwiftUI front-end with the same conversion logic.

## Optional: code signing and notarization (for smoother install)

After you have an Apple Developer account:

1. Sign the app
2. Sign the DMG
3. Notarize with `notarytool`
4. Staple notarization ticket

I can add a one-command notarization script when you're ready.
