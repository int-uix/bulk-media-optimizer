# 🖼️ WebP Converter (macOS • Apple Silicon)

A simple, fast desktop app for converting images to WebP on macOS (Apple Silicon).
Packaged as a native `.app` and easy-to-install `.dmg`.

---

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

## 📦 Create the Installer (.DMG)

To package the app for distribution:

```bash
./scripts/make_dmg.sh
```

Output file:

```
dist/WebP-Converter-apple-silicon.dmg
```

---

## ⚡ Performance & Experience

* Native macOS look using the Aqua Tk theme
* Built specifically for Apple Silicon (`arm64`)
* Smooth, responsive UI (conversion runs in the background)
* Lightweight and fast for bulk image processing

💡 *Future upgrade:* A SwiftUI interface for a fully native macOS experience.

---

## 🔐 Optional: Code Signing & Notarization

If you plan to distribute the app, Apple recommends signing and notarizing it.

Steps:

1. Sign the `.app`
2. Sign the `.dmg`
3. Notarize using `notarytool`
4. Staple the notarization ticket

👉 I can help you automate this into a one-command script when you're ready.
