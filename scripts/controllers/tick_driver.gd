class_name TickDriver
extends RefCounted
## Drives GameState: fixed logic ticks plus "early ticks" so a turn is applied as soon
## as the head is past the middle of its cell instead of waiting for the next full tick.
## Still exactly one cell per tick and one buffered turn consumed per tick.

const EARLY_ALPHA := 0.5
const CELL_PX := 32.0

var state: GameState
var clock := TickClock.new()
var track := VisualTrack.new()
var difficulty: Dictionary

func _init(p_state: GameState, p_diff: Dictionary) -> void:
	state = p_state
	difficulty = p_diff
	clock.set_speed(GameRules.speed_for(difficulty, 0))
	clock.accumulator = clock.interval  # first step happens right after the countdown, no standing hitch

## Returns true if the run finished during this call.
func advance(delta: float) -> bool:
	for _i in clock.advance(delta):
		_tick(false)
		if state.is_finished():
			return true
	return false

## Queues a turn; may run an early tick. Returns true if the run finished.
func turn(dir: Vector2i) -> bool:
	var queued := state.queue_turn(dir)
	if queued and not clock.paused and not state.is_finished() \
			and state.turns.pending.size() == 1 and clock.alpha() >= EARLY_ALPHA:
		_tick(true)
	return state.is_finished()

func alpha() -> float:
	return clock.alpha()

func points() -> Array[Vector2]:
	return track.points(state, clock.alpha(), CELL_PX)

func _tick(early: bool) -> void:
	if early:
		track.snapshot(state, clock.alpha(), CELL_PX)
		clock.reset()
	else:
		track.clear()
	state.step()
	clock.set_speed(GameRules.speed_for(difficulty, state.collected))
	if state.is_finished():
		track.clear()
