class_name GameView
extends Node2D
## Renders the 320x180 logical canvas (20px HUD band + 320x160 board). Read-only observer of GameState.

const HUD_H := 20.0
const BOARD_ORIGIN := Vector2(0, HUD_H)

var arena: Dictionary = {}
var board: GridBoard
var state: GameState
var alpha := 1.0
var reduce_motion := false
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color("2b1b3d"))
	if arena.is_empty():
		return
	var b: GridBoard = state.board if state != null else board
	if b == null:
		return
	ArenaRenderer.draw_arena(self, arena, b, BOARD_ORIGIN)
	if state == null:
		return
	draw_set_transform(BOARD_ORIGIN, 0.0, Vector2.ONE)
	for p in state.pickups:
		var c: Vector2i = p["cell"]
		ArenaRenderer.draw_item(self, p["item"]["id"], (Vector2(c) + Vector2(0.5, 0.5)) * 16.0, time, not reduce_motion)
	_draw_yarn()
	var head := YarnMath.body_points(state.prev_body, state.body, alpha, 16.0)[0]
	ArenaRenderer.draw_kitten(self, head.round(), state.dir, time, not state.alive)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_yarn() -> void:
	var raw := YarnMath.body_points(state.prev_body, state.body, alpha, 16.0)
	if raw.size() < 2:
		return
	var pts := YarnMath.apply_wiggle(YarnMath.smooth(raw), time, reduce_motion)
	var snapped := PackedVector2Array()
	for p in pts:
		snapped.append(p.round())
	draw_polyline(snapped, Color("a8336b"), 6.0)
	draw_polyline(snapped, Color("ff8fc1"), 4.0)
	draw_polyline(snapped, Color("ffc2dd"), 1.0)
	draw_circle(snapped[snapped.size() - 1], 3.0, Color("ff8fc1"))
