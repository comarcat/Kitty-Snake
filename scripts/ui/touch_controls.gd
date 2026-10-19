class_name TouchControls
extends Control
## Large on-screen D-pad. Lives outside the game canvas so it never covers board cells.

signal pressed_cmd(cmd: int)

class DPadKey extends Button:
	var arrow := Vector2.UP
	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.28
		var perp := Vector2(-arrow.y, arrow.x)
		draw_colored_polygon(PackedVector2Array([c + arrow * r, c - arrow * r * 0.7 + perp * r, c - arrow * r * 0.7 - perp * r]), Color("fff1d6"))

var keys: Array[DPadKey] = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var defs := [
		[Vector2.UP, InputAdapter.Cmd.TURN_UP],
		[Vector2.DOWN, InputAdapter.Cmd.TURN_DOWN],
		[Vector2.LEFT, InputAdapter.Cmd.TURN_LEFT],
		[Vector2.RIGHT, InputAdapter.Cmd.TURN_RIGHT],
	]
	for d in defs:
		var k := DPadKey.new()
		k.arrow = d[0]
		k.focus_mode = Control.FOCUS_NONE
		k.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		var cmd: int = d[1]
		k.button_down.connect(func(): pressed_cmd.emit(cmd))
		add_child(k)
		keys.append(k)

## Places the cross inside a 3u x 3u box at `origin`.
func layout(unit: float, origin: Vector2) -> void:
	var cells := [Vector2(1, 0), Vector2(1, 2), Vector2(0, 1), Vector2(2, 1)]
	for i in 4:
		keys[i].position = origin + cells[i] * unit
		keys[i].size = Vector2(unit, unit) - Vector2(6, 6)
		keys[i].position += Vector2(3, 3)
