# Asset guidelines
Placeholder art is drawn in code on a 16x16 cell grid. To replace with real sprites: add PNGs under `assets/sprites/`
(import with Filter=Nearest) and swap the `draw_*` calls in `scripts/rendering/arena_renderer.gd` for `draw_texture_rect`.
Only original or permissively licensed assets; list each in `LICENSES.md`. Do not commit third-party game screenshots.
