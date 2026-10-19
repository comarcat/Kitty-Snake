class_name GameState
extends RefCounted
## Deterministic grid simulation. No rendering, input devices, audio or timing.

signal item_collected(item: Dictionary, cell: Vector2i)
signal score_changed(new_score: int)
signal item_spawned(item: Dictionary, cell: Vector2i)
signal game_over(reason: String)
signal board_cleared

const MIN_BODY := 3  # head + 2 yarn segments

var board: GridBoard
var item_table: Array = []
var rng := RandomNumberGenerator.new()
var body: Array[Vector2i] = []       # head first
var prev_body: Array[Vector2i] = []  # positions before the last tick (for interpolation)
var dir: Vector2i = Vector2i.RIGHT
var turns := TurnQueue.new()
var pending_growth := 0
var score := 0
var collected := 0
var alive := true
var cleared := false
var death_reason := ""
var pickups: Array = []  # [{"cell": Vector2i, "item": Dictionary}]
var max_pickups := 1
var ticks := 0

func _init(p_board: GridBoard, p_items: Array, p_seed: int, spawn: Vector2i) -> void:
	board = p_board
	item_table = p_items.filter(func(i): return i.get("enabled", true))
	rng.seed = p_seed
	body = [spawn, spawn + Vector2i.LEFT, spawn + Vector2i.LEFT * 2]
	prev_body = body.duplicate()
	_fill_pickups()

func is_finished() -> bool:
	return not alive or cleared

func queue_turn(d: Vector2i) -> bool:
	return turns.try_push(d, dir)

func step() -> void:
	if is_finished():
		return
	prev_body = body.duplicate()
	var t := turns.pop()
	if t != Vector2i.ZERO:
		dir = t
	var nxt := body[0] + dir
	if not board.in_bounds(nxt):
		_die("wall")
		return
	if board.is_blocked(nxt):
		_die("obstacle")
		return
	# The tail cell only vacates this tick if no growth is pending.
	var vacates := pending_growth <= 0
	var check_len := body.size() - 1 if vacates else body.size()
	for i in check_len:
		if body[i] == nxt:
			_die("yarn")
			return
	var pick: Variant = _take_pickup(nxt)
	body.push_front(nxt)
	var shrink := 0
	if pick != null:
		var item: Dictionary = pick
		var g := int(item["growth"])
		if g > 0:
			pending_growth += g
		else:
			shrink = -g
		score += int(item["score"])
		collected += 1
		item_collected.emit(item, nxt)
		score_changed.emit(score)
	if pending_growth > 0:
		pending_growth -= 1
	else:
		body.pop_back()
	while shrink > 0 and body.size() > MIN_BODY:
		body.pop_back()
		shrink -= 1
	ticks += 1
	_fill_pickups()
	if pickups.is_empty() and _empty_cells().is_empty():
		cleared = true
		board_cleared.emit()

func _die(reason: String) -> void:
	alive = false
	death_reason = reason
	game_over.emit(reason)

func _take_pickup(cell: Vector2i) -> Variant:
	for i in pickups.size():
		if pickups[i]["cell"] == cell:
			var item: Dictionary = pickups[i]["item"]
			pickups.remove_at(i)
			return item
	return null

func _has_pickup(cell: Vector2i) -> bool:
	for p in pickups:
		if p["cell"] == cell:
			return true
	return false

func _empty_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in board.rows:
		for x in board.cols:
			var c := Vector2i(x, y)
			if board.is_blocked(c) or body.has(c) or _has_pickup(c):
				continue
			out.append(c)
	return out

func _fill_pickups() -> void:
	while pickups.size() < max_pickups:
		if not _spawn_pickup():
			break

## Picks a weighted item and an empty, reachable cell. False if the board is full.
func _spawn_pickup() -> bool:
	var empty := _empty_cells()
	if empty.is_empty() or item_table.is_empty():
		return false
	var body_cells := {}
	for c in body:
		body_cells[c] = true
	var reach := board.reachable_from(body[0], body_cells)
	var cands: Array[Vector2i] = []
	for c in empty:
		if reach.has(c):
			cands.append(c)
	if cands.is_empty():
		cands = empty
	var cell: Vector2i = cands[rng.randi_range(0, cands.size() - 1)]
	var item := _weighted_item()
	pickups.append({"cell": cell, "item": item})
	item_spawned.emit(item, cell)
	return true

func _weighted_item() -> Dictionary:
	var total := 0.0
	for i in item_table:
		total += float(i["weight"])
	var r := rng.randf() * total
	for i in item_table:
		r -= float(i["weight"])
		if r <= 0.0:
			return i
	return item_table.back()
