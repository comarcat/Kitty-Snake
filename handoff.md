# Handoff: miautrix.tech package

**Date:** 2026-11-12
**Deliverable:** `exports/kitty-snake-miautrix.zip` (8.2 MB zipped, 35.8 MB unpacked, 9 files)
**Built from:** CI web artifact `kitty-snake-web` of Build run `39329614854`, commit `676e146` (Godot 4.3-stable)
**Packaging script:** `tools/package_miautrix.py`
**Status:** works in a null-origin sandboxed iframe (tested in headless Edge). Nothing is committed yet.

---

## Host requirement (confirm with miautrix.tech)

The host **must** serve the game files with this header:

```
Access-Control-Allow-Origin: *
```

Godot loads `index.wasm` and `index.pck.wasm` with `fetch()`. Inside `<iframe sandbox="allow-scripts">` the page's origin
is `null`, so every request counts as cross-origin. Without that header the game stops on the loading screen with
`TypeError: Failed to fetch`. Nothing inside the zip can fix this. Most hosts that run games in null-origin iframes
already send the header, but check.

---

## Zip contents

| File | Purpose |
|---|---|
| `index.html` | Godot web shell (entry point, at the zip root) |
| `index.js` | Godot loader/runtime (patched, see below) |
| `index.wasm` | Engine binary |
| `index.pck.wasm` | Game data pack (renamed from `index.pck`) |
| `index.audio.worklet.js` | Audio worklet (only used by threaded builds; harmless) |
| `index.png`, `index.icon.png`, `index.apple-touch-icon.png` | Splash and icons |
| `game.json` | Metadata for the admin form |

`game.json`:

```json
{
  "title": "Kitty Snake: Yarn Trails",
  "description": "A colorful retro Snake game starring a kitten. Collect fish, milk, yarn balls and golden fish while a pink yarn trail grows behind you across 4 arenas and 3 difficulties - just don't tie yourself in knots!",
  "controls": "Keyboard: Arrow keys or WASD to move, Esc or P to pause, Enter/Space to confirm. Touch: on-screen D-pad (or swipe, see Settings), pause button, tap to select. Mouse: click menu buttons. Gamepad: D-pad/left stick, Start, A.",
  "version": "0.1.1"
}
```

To change these values, edit `GAME_JSON` in `tools/package_miautrix.py` and rebuild.

---

## How the package meets each requirement

1. **`index.html` at the root, relative paths.** Godot's shell already uses relative paths (`index.js`, `index.png`, ...).
   The script fails if `index.html` contains an absolute (`/...`) or remote (`http...`, `//...`) `src`/`href`.
2. **Self-contained.** No CDN scripts, fonts or APIs. Fonts are built into the engine/pack.
3. **Allowed file types only.**
   - `.pck` is not allowed, so `index.pck` is renamed to `index.pck.wasm`. The script sets `GODOT_CONFIG.mainPack` and
     `fileSizes` in `index.html` to match.
   - Godot's `*.png.import` files are dropped.
   - The build contains no SVG.
4. **Sandbox / null origin.**
   - **Service worker:** Godot's PWA hooks (`_godot_js_pwa_cb`, `_godot_js_pwa_update`) read `navigator.serviceWorker`,
     which throws `SecurityError` in the sandbox. This happens inside a WASM callback, so it **aborted engine startup**.
     PWA is off in this export, so both hooks are patched to `if(false){`.
   - **`alert()`:** `window.alert()` (OS.alert) and the "WebGL context lost" `alert()` now go to `console.warn` /
     `console.error`.
   - **`window.open()`:** `window.open()` (OS.shell_open) now logs to the console instead of opening a popup. The game
     doesn't call it.
   - **Saving:** IndexedDB is denied. Godot's IDBFS mount catches the error (logs `IndexedDB not available: ...`) and keeps
     an in-memory `user://`. `SaveStore` (`scripts/services/save_service.gd`) keeps working, so the game is fully playable
     but high scores and settings reset when the page reloads.
   - **Other APIs:** the game and engine JS don't use `localStorage`, `sessionStorage`, cookies, or `window.top`/`parent`.
     The script fails if any of these, `alert(` or `window.open(` remain in `index.js`.
   - **Service-worker install path:** `serviceWorker` is removed from `GODOT_CONFIG`, so the shell never tries to install
     one or reload the page.
5. **Resizable container.** The export uses `canvasResizePolicy: 2` (fills `window.innerWidth/innerHeight`, follows
   resize). The project uses stretch mode `canvas_items` with aspect `expand`. Supported input: keyboard, gamepad, mouse
   (menus), touch (on-screen D-pad in "auto" mode once a touch is seen, or swipe via Settings).
6. **Limits.** 8.2 MB zip, 35.8 MB unpacked, 9 files. The script checks all three limits.
7. **`game.json`.** At the zip root, see above.

---

## Rebuilding

### Option A: from CI (no local Godot needed)

This is how the current zip was made. Every push runs the GitHub Actions **Build** workflow, which uploads a
`kitty-snake-web` artifact.

```bash
# 1. find the run for the commit you want
gh run list -L 5
# 2. download its web build (replace RUN_ID)
gh run download RUN_ID -n kitty-snake-web -D /path/to/ciweb
# 3. package
python tools/package_miautrix.py /path/to/ciweb exports/kitty-snake-miautrix.zip
```

Check that the run's `headSha` matches the commit you expect: `gh run view RUN_ID --json headSha`. Artifacts expire
after GitHub's retention period (90 days by default).

### Option B: local Godot export

Requires Godot **4.3-stable** with matching export templates. Put it on `PATH` or set `GODOT_BIN`.

```bash
tools/export.sh web                 # or on Windows: .\tools\export.ps1 web
python tools/package_miautrix.py builds/web exports/kitty-snake-miautrix.zip
```

### Script usage

```
python tools/package_miautrix.py [WEB_DIR] [OUT_ZIP]
# defaults: builds/web  exports/kitty-snake-miautrix.zip
```

The script stops with an error instead of writing a broken zip if:
- a patch target string isn't found in `index.js`, which means the Godot version changed. The targets are in
  `JS_PATCHES`. Find the new minified code with `grep -o "function _godot_js_pwa_cb.\{0,200\}" index.js` and update the
  strings;
- a forbidden API is still present, a disallowed file type would be packed, or a size or file-count limit is exceeded.

`exports/` and `builds/` are gitignored, so the zip itself is never committed.

---

## Re-testing in a sandboxed iframe

This reproduces the null-origin host locally. Put the files somewhere outside the repo (e.g. a temp folder).

1. Unzip the package into `test/game/`.
2. Create `test/host.html`:

   ```html
   <!doctype html><meta charset="utf-8"><title>host</title>
   <style>body{margin:0;background:#333}#w{resize:both;overflow:hidden;width:800px;height:450px;border:2px solid #f0f}iframe{width:100%;height:100%;border:0}</style>
   <div id="w"><iframe sandbox="allow-scripts" src="game/index.html"></iframe></div>
   ```

3. Serve `test/` with CORS (plain `python -m http.server` will **not** work, see the host requirement above).
   Save as `serve.py`:

   ```python
   import http.server, sys, functools
   class H(http.server.SimpleHTTPRequestHandler):
       def end_headers(self):
           self.send_header("Access-Control-Allow-Origin", "*"); super().end_headers()
   H.extensions_map[".wasm"] = "application/wasm"
   http.server.ThreadingHTTPServer(("127.0.0.1", 8766),
       functools.partial(H, directory=sys.argv[1])).serve_forever()
   ```

   Run it: `python serve.py test`
4. Open http://127.0.0.1:8766/host.html. Drag the magenta box's corner to resize. In DevTools the only expected log
   besides the Godot banner is `IndexedDB not available: ...`.

### Results of the 2026-11-12 test (headless Edge, swiftshader WebGL)

- Boots to the title menu; no errors besides the expected IndexedDB message.
- Keyboard works in menus and gameplay (played to Game Over).
- Resizing the container to 500×600 reflows the game.
- Without the CORS header: `Failed to fetch` (expected; this is the host requirement).
- Before the service-worker patch: startup aborted with the `serviceWorker` SecurityError (fixed).

### Not yet tested

- Touch input on a real phone or tablet.
- Firefox and Safari. In particular, they may handle the sandboxed `serviceWorker` / IndexedDB access differently.
- The real miautrix.tech upload and its CORS headers.

---

## Open items

- [ ] Confirm miautrix.tech serves game files with `Access-Control-Allow-Origin: *`.
- [ ] Upload the zip and play it in the real host.
- [ ] Test touch on a phone, and Firefox/Safari.
- [ ] Commit `tools/package_miautrix.py`, the `docs/build-and-export.md` addition and this file. Uncommitted work already
      in the tree: `README.md`, `docs/build-and-export.md` (Windows/PowerShell notes) and `tools/export.ps1`.
- [ ] Bump `GAME_JSON["version"]` when 0.1.1 is released or the version changes.
