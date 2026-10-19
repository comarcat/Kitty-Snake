#!/usr/bin/env bash
# Usage: tools/export.sh [web|windows|android-debug|all]   (default: all except android)
# Requires Godot 4.3-stable on PATH as `godot` plus matching export templates.
set -euo pipefail
cd "$(dirname "$0")/.."
target="${1:-all}"
godot --headless --path . --import >/dev/null 2>&1 || true
web()     { mkdir -p builds/web;     godot --headless --path . --export-release "Web" builds/web/index.html; }
windows() { mkdir -p builds/windows; godot --headless --path . --export-release "Windows Desktop" builds/windows/KittySnake.exe
            (cd builds/windows && rm -f ../KittySnake-windows.zip && zip -q ../KittySnake-windows.zip KittySnake.exe KittySnake.pck); }
android() { mkdir -p builds/android; godot --headless --path . --export-debug "Android Debug" builds/android/KittySnake-debug.apk; }
case "$target" in
  web) web;; windows) windows;; android-debug) android;;
  all) web; windows;;
  *) echo "unknown target $target"; exit 2;;
esac
