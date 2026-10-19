# Architecture

One Godot 4.3 project (GDScript, Compatibility renderer) shared by Web, Windows and Android.
Decision: no C#, no plugins, no platform-specific gameplay branches. Platform differences live only in
input (`InputAdapter`, `TouchControls`), layout (`main.gd`), lifecycle notifications and export presets.

| Layer | Files | Rule |
|---|---|---|
| Core simulation | `scripts/core/*` | Pure `RefCounted`; no nodes, timing, input or audio. Signals out. |
| Data | `data/arenas`, `data/items`, `data/difficulties` | JSON; ASCII arena maps (legend in `arena_data.gd`). |
| Controllers | `scripts/controllers/*` | `GameController` (countdown, ticks, pause, scoring), `InputAdapter` (commands). |
| Rendering | `scripts/rendering/*` | Read-only observers of `GameState`; yarn is drawn from cell positions and never affects collision. |
| Services | `scripts/services/*` | `Save` (versioned JSON in `user://`), `Sfx` (procedural audio). Autoloads. |
| UI | `scripts/ui/*` | Menus built in code; `main.gd` owns layout and flow. |

Display: 640x360 SubViewport (40px HUD band + 640x320 board, 32px cells for 16-bit-style detail) shown at integer scale when >= 1x. Background art is cached; input can trigger an "early tick" once the head is past mid-cell (TickDriver) so turns feel instant while motion stays continuous (VisualTrack). Menus/HUD text/touch
controls are native-resolution UI so they stay crisp and touch-sized. Touch controls reserve screen space beside the
board (landscape) or below it (portrait) and never overlap cells.

Input rule: `TurnQueue` holds up to 2 turns, rejects duplicates and reversals relative to the last queued direction,
and one turn is consumed per logic tick. (Spec asked for "first valid input wins"; a 2-deep buffer keeps tight
corners responsive while still consuming one turn per tick.)

Start behavior: a 3-2-1 countdown; a turn queued during the countdown applies on the first tick.
