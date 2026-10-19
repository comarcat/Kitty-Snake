# Changelog

## 0.1.1 (unreleased)
- Fix head/yarn stutter: animation progress is now read at draw time (was one frame stale) and positions are no longer snapped to coarse pixels.
- More responsive controls: a turn is applied immediately once the head is past the middle of its cell (early tick), with continuous visual blending. Base speeds raised: Easy 5 / Normal 7 / Hard 10 cells/s (cap 13).
- First step now happens right after the countdown (no standing hitch).
- 16-bit-style art pass: 640x360 canvas with 32px cells, shaded sprites with outlines, textured grounds, new kitten, items, yarn and obstacles; cached background layer.

## 0.1.0
- Deterministic grid simulation, fixed-tick clock, buffered turn queue.
- Four data-driven arenas, three difficulties, weighted items (scissors behind a flag).
- Interpolated, smoothed, wiggling yarn with Reduce Motion; procedural placeholder art and chiptune audio.
- Title, arena, difficulty, settings, high-score, pause and game-over screens; keyboard, gamepad, touch D-pad and swipe input.
- Web, Windows and Android debug APK build successfully in GitHub Actions (artifacts attached to each run). Android APK is not yet run on a device; Windows build not yet run on Windows.
