class_name TickClock
extends RefCounted
## Fixed logic-tick accumulator, independent of render FPS.

const MAX_CATCH_UP := 3
var interval := 0.25
var accumulator := 0.0
var paused := false

func set_speed(cells_per_second: float) -> void:
	interval = 1.0 / maxf(cells_per_second, 0.1)

## Returns how many logic ticks should run now.
func advance(delta: float) -> int:
	if paused:
		return 0
	accumulator += delta
	var n := 0
	while accumulator >= interval and n < MAX_CATCH_UP:
		accumulator -= interval
		n += 1
	if n == MAX_CATCH_UP:
		accumulator = 0.0
	return n

func alpha() -> float:
	return clampf(accumulator / interval, 0.0, 1.0)
