class_name ArenaPreview
extends Control

var arena: Dictionary
var board: GridBoard
const S := 0.62

func setup(p_arena: Dictionary) -> void:
	arena = p_arena
	board = ArenaData.build(arena, 1)["board"]
	custom_minimum_size = Vector2(320 * S, 160 * S)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if board != null:
		ArenaRenderer.draw_arena(self, arena, board, Vector2.ZERO, S)
