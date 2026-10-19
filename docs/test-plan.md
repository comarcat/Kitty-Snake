# Test plan

## Automated (headless)
```
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd
```
Covers spec cases 1-14 (movement, reverse, one turn/tick, growth, tail rules, collisions, spawn rules, determinism,
arena validation, save recovery, reduce motion, pause) plus speed curve and scissors minimum length.

## Manual acceptance (tick when verified; leave blank if not)
- [ ] Web over HTTP on desktop browser  — *smoke-tested in headless Chromium: loads, plays, pauses, game-over, arenas*
- [ ] Web on mobile browser with touch D-pad
- [ ] Windows portable build on a clean machine/VM (built, **not yet run**)
- [ ] Android APK on a device/emulator (**APK builds in CI; not yet installed or run on any device**)
- [ ] All 4 arenas playable on each target (Web: Backyard + Living Room viewed in-game; all 4 validated by tests)
- [ ] Easy/Normal/Hard speeds feel correct
- [ ] Keyboard / gamepad / touch inputs
- [ ] Pause, restart, game over, high-score persistence after reload
- [ ] Android: rotate/background/resume, safe areas
