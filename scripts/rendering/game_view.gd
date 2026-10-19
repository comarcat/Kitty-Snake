class_name GameView
extends Node2D
## Renders the 640x360 logical canvas (40px HUD band + 640x320 board). Read-only observer.

const HUD_H := 40.0
const BOARD_ORIGIN := Vector2(0, HUD_H)
const CELL := 32.0

var layer := ArenaLayer.new()
var state: GameState
var controller: GameController
var reduce_motion := false
var time := 0.0

func _ready() -> void:
	layer.position = BOARD_ORIGIN
	layer.show_behind_parent = true  # cached background must sit behind items, yarn and kitten
	add_child(layer)

func show_arena(arena: Dictionary, board: GridBoard) -> void:
	layer.show_arena(arena, board)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, HUD_H), Color("2b1b3d"))
	draw_rect(Rect2(0, HUD_H - 3, 640, 3), Color("43295f"))
	draw_rect(Rect2(0, HUD_H - 4, 640, 1), Color("6d4a8f"))
	if state == null or controller == null or controller.driver == null:
		return
	draw_set_transform(BOARD_ORIGIN, 0.0, Vector2.ONE)
	for p in state.pickups:
		var c: Vector2i = p["cell"]
		ArenaRenderer.draw_item(self, p["item"]["id"], (Vector2(c) + Vector2(0.5, 0.5)) * CELL, time, not reduce_motion)
	var pts := controller.visual_points()
	_draw_yarn(pts)
	ArenaRenderer.draw_kitten(self, pts[0].round(), state.dir, time, not state.alive, not reduce_motion)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

const Y_OUT := Color("9a2a66")
const Y_MAIN := Color("ff6fae")
const Y_LIGHT := Color("ffc2dc")
const Y_TWIST := Color("d94a8c")

func _draw_yarn(raw: Array[Vector2]) -> void:
	if raw.size() < 2:
		return
	var pts := YarnMath.apply_wiggle(YarnMath.smooth(raw), time, reduce_motion)
	var line := PackedVector2Array(pts)
	draw_polyline(line, Y_OUT, 13.0)
	draw_polyline(line, Y_MAIN, 9.0)
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(p + Vector2(-2, -2))
	draw_polyline(hi, Y_LIGHT, 2.0)
	var i := 3
	while i < pts.size() - 2:  # twisted-thread marks
		var tan := (pts[i + 1] - pts[i - 1]).normalized()
		var nrm := Vector2(-tan.y, tan.x)
		draw_line(pts[i] - nrm * 4.0 - tan * 1.5, pts[i] + nrm * 4.0 + tan * 1.5, Y_TWIST, 2.0)
		i += 3
	var end := pts[pts.size() - 1]
	draw_circle(end, 8.0, Y_OUT)
	draw_circle(end, 6.5, Y_MAIN)
	draw_arc(end, 4.0, 0.3, 3.2, 8, Y_TWIST, 2.0)
	draw_circle(end + Vector2(-2, -2), 2.0, Y_LIGHT)
