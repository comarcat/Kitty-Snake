class_name GameController
extends Node
## Orchestrates a run: countdown, pause, finish + scoring. Tick logic lives in TickDriver.

signal phase_changed(phase: String)
signal countdown_changed(n: int)
signal score_changed(score: int)
signal finished(info: Dictionary)

const COUNTDOWN := 3.0

var driver: TickDriver
var state: GameState
var arena: Dictionary = {}
var difficulty: Dictionary = {}
var phase := "idle"  # idle | countdown | running | paused | over
var _resume_phase := "running"
var _cd := 0.0
var _last_n := -1

func begin(p_arena: Dictionary, p_diff: Dictionary, p_seed: int = -1) -> void:
	arena = p_arena
	difficulty = p_diff
	var built := ArenaData.build(arena, int(difficulty["obstacle_level"]))
	var seed_val := p_seed if p_seed >= 0 else int(Time.get_ticks_usec() & 0x7fffffff)
	state = GameState.new(built["board"], ItemRules.load_items(), seed_val, built["spawn"])
	state.score_changed.connect(func(s): score_changed.emit(s))
	state.item_collected.connect(_on_item)
	driver = TickDriver.new(state, difficulty)
	_cd = COUNTDOWN
	_last_n = -1
	_set_phase("countdown")

func is_playing() -> bool:
	return phase == "countdown" or phase == "running"

func visual_alpha() -> float:
	return driver.alpha() if (phase == "running" or phase == "paused") else 1.0

func visual_points() -> Array[Vector2]:
	return driver.track.points(state, visual_alpha(), TickDriver.CELL_PX)

func turn(dir: Vector2i) -> void:
	if state == null:
		return
	if phase == "running":
		if driver.turn(dir):
			_finish()
	elif phase == "countdown":
		state.queue_turn(dir)

func pause() -> void:
	if is_playing():
		_resume_phase = phase
		driver.clock.paused = true
		_set_phase("paused")

func resume() -> void:
	if phase == "paused":
		driver.clock.paused = false
		_set_phase(_resume_phase)

func _set_phase(p: String) -> void:
	phase = p
	phase_changed.emit(p)

func _on_item(item: Dictionary, _cell: Vector2i) -> void:
	match item["id"]:
		"golden": Sfx.play("gold")
		"scissors": Sfx.play("snip")
		_: Sfx.play("eat")

func _process(delta: float) -> void:
	match phase:
		"countdown":
			_cd -= delta
			var n := int(ceil(_cd))
			if n != _last_n:
				_last_n = n
				countdown_changed.emit(maxi(n, 0))
				Sfx.play("click")
			if _cd <= 0.0:
				_set_phase("running")
		"running":
			if driver.advance(delta):
				_finish()

func _finish() -> void:
	_set_phase("over")
	var new_best: bool = Save.submit_score(arena["id"], difficulty["id"], state.score)
	Sfx.play("win" if state.cleared else "die")
	finished.emit({
		"score": state.score,
		"best": Save.high_score(arena["id"], difficulty["id"]),
		"new_best": new_best and state.score > 0,
		"cleared": state.cleared,
		"reason": state.death_reason,
	})
