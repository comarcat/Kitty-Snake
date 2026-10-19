class_name TurnQueue
extends RefCounted
## Buffered turns. Capacity 2, one consumed per logic tick.
## Duplicates and reversals (relative to the last queued direction) are rejected,
## which also removes double events from simultaneous touch + keyboard.

const CAPACITY := 2
var pending: Array[Vector2i] = []

func try_push(new_dir: Vector2i, current_dir: Vector2i) -> bool:
	var ref: Vector2i = pending.back() if not pending.is_empty() else current_dir
	if new_dir == Vector2i.ZERO or new_dir == ref or new_dir == -ref:
		return false
	if pending.size() >= CAPACITY:
		return false
	pending.append(new_dir)
	return true

func pop() -> Vector2i:
	if pending.is_empty():
		return Vector2i.ZERO
	return pending.pop_front()

func clear() -> void:
	pending.clear()
