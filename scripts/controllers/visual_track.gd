class_name VisualTrack
extends RefCounted
## Turns logical body cells into smoothly interpolated pixel positions.
## After an early (input-triggered) tick it blends from where the sprites visually were,
## so motion never jumps.

var blend_from: Array[Vector2] = []

func clear() -> void:
	blend_from = []

func snapshot(state: GameState, alpha: float, cell: float) -> void:
	blend_from = points(state, alpha, cell)

func points(state: GameState, alpha: float, cell: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in state.body.size():
		var from: Vector2
		if not blend_from.is_empty():
			from = blend_from[mini(i, blend_from.size() - 1)]
		else:
			var p: Vector2i = state.prev_body[i] if i < state.prev_body.size() else state.prev_body.back()
			from = (Vector2(p) + Vector2(0.5, 0.5)) * cell
		var to := (Vector2(state.body[i]) + Vector2(0.5, 0.5)) * cell
		pts.append(from.lerp(to, alpha))
	return pts
