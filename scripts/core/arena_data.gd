class_name ArenaData
extends RefCounted
## Loads data-driven arenas (ASCII maps) and validates them.
## Map legend: '.' empty, '#' obstacle (primary style), 'w' obstacle (secondary style),
## 'n' primary obstacle on Normal+Hard, 'h' primary obstacle on Hard only, 'S' kitten spawn.

const COLS := 20
const ROWS := 10
const INDEX_PATH := "res://data/arenas/arenas.json"

static func ids() -> Array:
	var parsed: Variant = JsonUtil.read(INDEX_PATH)
	return parsed["arenas"] if typeof(parsed) == TYPE_DICTIONARY else []

static func load_arena(id: String) -> Dictionary:
	var parsed: Variant = JsonUtil.read("res://data/arenas/%s.json" % id)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func load_all() -> Dictionary:
	var out := {}
	for id in ids():
		out[id] = load_arena(id)
	return out

## Returns {"board": GridBoard, "spawn": Vector2i}.
static func build(arena: Dictionary, obstacle_level: int) -> Dictionary:
	var board := GridBoard.new(COLS, ROWS)
	var spawn := Vector2i(-1, -1)
	var map: Array = arena["map"]
	for y in map.size():
		var row: String = map[y]
		for x in row.length():
			var c := Vector2i(x, y)
			match row[x]:
				"#": board.add_obstacle(c, "primary")
				"w": board.add_obstacle(c, "secondary")
				"n":
					if obstacle_level >= 1:
						board.add_obstacle(c, "primary")
				"h":
					if obstacle_level >= 2:
						board.add_obstacle(c, "primary")
				"S": spawn = c
	return {"board": board, "spawn": spawn}

## Returns a list of human-readable problems (empty = valid).
static func validate(arena: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var map: Array = arena.get("map", [])
	if map.size() != ROWS:
		errors.append("map must have %d rows" % ROWS)
		return errors
	for y in map.size():
		if String(map[y]).length() != COLS:
			errors.append("row %d must have %d chars" % [y, COLS])
	if not errors.is_empty():
		return errors
	var spawns := 0
	for row in map:
		spawns += String(row).count("S")
	if spawns != 1:
		errors.append("expected exactly one S, found %d" % spawns)
		return errors
	for level in 3:
		var built := build(arena, level)
		var board: GridBoard = built["board"]
		var spawn: Vector2i = built["spawn"]
		if spawn.x < 2:
			errors.append("spawn needs 2 cells of yarn room to its left")
			continue
		for dx in range(-2, 4):
			var c := spawn + Vector2i(dx, 0)
			if board.is_blocked(c) or not board.in_bounds(c):
				errors.append("level %d: spawn corridor blocked at %s" % [level, c])
		var reach := board.reachable_from(spawn)
		var free := board.cell_count() - board.obstacles.size()
		if reach.size() != free:
			errors.append("level %d: %d free cells unreachable" % [level, free - reach.size()])
		if reach.size() < 10:
			errors.append("level %d: too few reachable cells" % level)
	return errors
