# Build and export

Pinned: **Godot 4.3-stable** + matching export templates (Compatibility renderer, single-threaded Web export so no COOP/COEP headers are needed).

## Setup
```
# editor + templates: https://github.com/godotengine/godot/releases/tag/4.3-stable
# templates go to ~/.local/share/godot/export_templates/4.3.stable (Linux) or via Editor > Manage Export Templates
godot --headless --path . --import
```

## Export (presets are in export_presets.cfg; no secrets)
```
tools/export.sh web            # builds/web/index.html
tools/export.sh windows        # builds/windows/KittySnake.exe + .pck, builds/KittySnake-windows.zip
tools/export.sh android-debug  # builds/android/KittySnake-debug.apk
```

### Web
Serve over HTTP(S), never `file://`: `tools/serve_web.sh` then open http://localhost:8080. Any static host works
(itch.io, GitHub Pages, Netlify). Output is relocatable (relative URLs), so subpaths work. Size: `index.wasm` ~35 MB raw
(~9 MB gzip/brotli — enable compression on the host), `index.pck` ~77 KB. High scores use browser IndexedDB via `user://`;
private mode or cleared site data simply resets them.

### Windows
Unsigned x86_64 build: `KittySnake.exe` + `KittySnake.pck` must stay together (zip provided). Windows SmartScreen will warn
about an unknown publisher; code signing/installer are out of MVP scope. Saves go to `%APPDATA%\Godot\app_userdata\Kitty Snake: Yarn Trails`.

### Android
Needs JDK 17, Android SDK (platform-tools, build-tools 34, platform 34, cmdline-tools), Godot export templates, and the
debug keystore configured in Editor Settings > Export > Android. The GitHub Actions workflow (`.github/workflows/build.yml`)
does all of this automatically and uploads the APK as an artifact. Package ID is the placeholder `com.example.kittysnake`
(change in `export_presets.cfg`); versionCode 1 / versionName 0.1.0; no INTERNET permission. Landscape (sensor) orientation.
Install: `adb install KittySnake-debug.apk` or copy the APK to the phone and open it (allow "install unknown apps").
**Release/AAB:** preset "Android Release" requires Gradle build template and your own keystore — set
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD` env vars; never commit keystores.

### iOS
Skipped on purpose: it requires a paid Apple Developer membership and a Mac. The code base would not need changes to add it later.
