class_name ArenaLayer
extends Node2D
## Static background; drawn once and cached by the canvas until the arena changes.

var arena: Dictionary = {}
var board: GridBoard

func show_arena(p_arena: Dictionary, p_board: GridBoard) -> void:
	arena = p_arena
	board = p_board
	queue_redraw()

func _draw() -> void:
	if not arena.is_empty() and board != null:
		ArenaRenderer.draw_arena(self, arena, board, Vector2.ZERO)
