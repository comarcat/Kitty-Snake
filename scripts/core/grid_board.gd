class_name GridBoard
extends RefCounted
## Logical grid: bounds plus obstacle cells. No rendering knowledge.

var cols: int
var rows: int
var obstacles: Dictionary = {}  # Vector2i -> "primary" | "secondary"

func _init(p_cols: int = 20, p_rows: int = 10) -> void:
	cols = p_cols
	rows = p_rows

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows

func is_blocked(c: Vector2i) -> bool:
	return obstacles.has(c)

func add_obstacle(c: Vector2i, kind: String = "primary") -> void:
	obstacles[c] = kind

func cell_count() -> int:
	return cols * rows

## Flood fill over non-obstacle cells (plus optional extra blocked cells).
func reachable_from(start: Vector2i, extra_blocked: Dictionary = {}) -> Dictionary:
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if seen.has(n) or not in_bounds(n) or is_blocked(n) or extra_blocked.has(n):
				continue
			seen[n] = true
			stack.append(n)
	return seen
