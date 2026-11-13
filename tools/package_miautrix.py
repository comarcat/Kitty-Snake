#!/usr/bin/env python3
"""Package a Godot Web export (builds/web) as a single .zip for miautrix.tech.

Usage:  python tools/package_miautrix.py [WEB_DIR] [OUT_ZIP]
        defaults: builds/web  exports/kitty-snake-miautrix.zip

What it does to make the stock Godot 4.3 export host-compatible:
  * renames index.pck -> index.pck.wasm (".pck" is not an allowed file type) and
    points the loader at it via GODOT_CONFIG.mainPack / fileSizes;
  * patches index.js: window.alert(), the "WebGL context lost" alert() and
    window.open() (OS.shell_open) become console messages (sandboxed iframe);
  * drops *.import and any file type outside the allow-list;
  * writes game.json at the zip root;
  * verifies index.html is at the root, no absolute/remote URLs, limits.
Godot's IndexedDB (user://) mount already fails soft: IDBFS errors are caught,
the game keeps an in-memory filesystem and SaveStore keeps working unsaved.
"""
import json
import re
import sys
import zipfile
from pathlib import Path

ALLOWED = set(
    "html htm js mjs css json png jpg jpeg gif webp ico mp3 ogg wav m4a mp4 webm "
    "woff woff2 ttf otf txt wasm".split()
)
PCK_NAME = "index.pck.wasm"

GAME_JSON = {
    "title": "Kitty Snake: Yarn Trails",
    "description": (
        "A colorful retro Snake game starring a kitten. Collect fish, milk, yarn balls "
        "and golden fish while a pink yarn trail grows behind you across 4 arenas and "
        "3 difficulties - just don't tie yourself in knots!"
    ),
    "controls": (
        "Keyboard: Arrow keys or WASD to move, Esc or P to pause, Enter/Space to confirm. "
        "Touch: on-screen D-pad (or swipe, see Settings), pause button, tap to select. "
        "Mouse: click menu buttons. Gamepad: D-pad/left stick, Start, A."
    ),
    "version": "0.1.1",
}

JS_PATCHES = [
    ("window.alert(GodotRuntime.parseString(p_text))",
     "console.warn(GodotRuntime.parseString(p_text))"),
    ('alert("WebGL context lost, please reload the page")',
     'console.error("WebGL context lost, please reload the page")'),
    ('window.open(GodotRuntime.parseString(p_uri),"_blank")',
     'console.warn("shell_open blocked in sandbox: "+GodotRuntime.parseString(p_uri))'),
    # Reading navigator.serviceWorker throws SecurityError in a null-origin sandbox and
    # aborts engine startup. PWA is disabled in this export, so skip the hooks.
    ('function _godot_js_pwa_cb(p_update_cb){if("serviceWorker"in navigator){',
     'function _godot_js_pwa_cb(p_update_cb){if(false){'),
    ('function _godot_js_pwa_update(){if("serviceWorker"in navigator&&GodotPWA.hasUpdate){',
     'function _godot_js_pwa_update(){if(false){'),
]


def fail(msg):
    sys.exit(f"ERROR: {msg}")


def main():
    web = Path(sys.argv[1] if len(sys.argv) > 1 else "builds/web")
    out = Path(sys.argv[2] if len(sys.argv) > 2 else "exports/kitty-snake-miautrix.zip")
    if not (web / "index.html").is_file() or not (web / "index.pck").is_file():
        fail(f"{web} is not a Godot web export (need index.html and index.pck)")

    files = {}  # zip name -> bytes
    for p in sorted(web.iterdir()):
        if not p.is_file():
            continue
        ext = p.suffix.lower().lstrip(".")
        if p.name == "index.pck":
            files[PCK_NAME] = p.read_bytes()
        elif ext in ALLOWED:
            files[p.name] = p.read_bytes()
        else:
            print(f"skip {p.name}")

    # --- index.js: neutralise alert()/window.open() ---
    js = files["index.js"].decode("utf-8")
    for old, new in JS_PATCHES:
        if old not in js:
            fail(f"index.js patch target not found: {old!r} (Godot version changed?)")
        js = js.replace(old, new)
    for bad in (r"\balert\(", r"window\.open\(", r"window\.top", r"window\.parent",
                r"\blocalStorage\b", r"\bsessionStorage\b", r"document\.cookie"):
        if re.search(bad, js):
            fail(f"index.js still contains {bad}")
    files["index.js"] = js.encode("utf-8")

    # --- index.html: point the loader at the renamed pack ---
    html = files["index.html"].decode("utf-8")
    m = re.search(r"const GODOT_CONFIG = (\{.*?\});\n", html)
    if not m:
        fail("GODOT_CONFIG not found in index.html")
    cfg = json.loads(m.group(1))
    sizes = cfg.get("fileSizes", {})
    sizes[PCK_NAME] = sizes.pop("index.pck", len(files[PCK_NAME]))
    cfg["fileSizes"] = sizes
    cfg["mainPack"] = PCK_NAME
    cfg.pop("serviceWorker", None)  # never register a SW / reload inside the iframe
    html = html.replace(m.group(1), json.dumps(cfg, separators=(",", ":")))
    if re.search(r"""(src|href)\s*=\s*["'](/|https?:|//)""", html):
        fail("index.html references an absolute or remote URL")
    files["index.html"] = html.encode("utf-8")

    files["game.json"] = (json.dumps(GAME_JSON, indent=2) + "\n").encode("utf-8")

    # --- checks ---
    for name in files:
        if Path(name).suffix.lower().lstrip(".") not in ALLOWED:
            fail(f"disallowed file type: {name}")
    unpacked = sum(len(b) for b in files.values())
    if len(files) > 2000 or unpacked > 200 * 1024 * 1024:
        fail("too many files or unpacked size > 200 MB")

    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name in sorted(files):
            z.writestr(name, files[name])
    zsize = out.stat().st_size
    if zsize > 50 * 1024 * 1024:
        fail(f"zip is {zsize} bytes (> 50 MB)")
    print(f"wrote {out}: {len(files)} files, {unpacked/1e6:.1f} MB unpacked, {zsize/1e6:.1f} MB zipped")


if __name__ == "__main__":
    main()
