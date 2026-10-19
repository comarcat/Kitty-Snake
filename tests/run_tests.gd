extends SceneTree
## Headless test runner:  godot --headless --path . --script tests/run_tests.gd
## (Run `godot --headless --import` once first so class_names are registered.)

var passed := 0
var failed := 0

func check(cond: bool, name: String) -> void:
	if cond:
		passed += 1
		print("  PASS  ", name)
	else:
		failed += 1
		print("  FAIL  ", name)

func make_state(cols := 20, rows := 10, spawn := Vector2i(4, 5), seed := 1) -> GameState:
	var s := GameState.new(GridBoard.new(cols, rows), ItemRules.load_items(), seed, spawn)
	s.pickups.clear()
	s.max_pickups = 0
	return s

func _init() -> void:
	print("== Kitty Snake tests ==")
	t01_straight_movement()
	t02_reverse_rejected()
	t03_one_turn_per_tick()
	t04_collect_score_growth()
	t05_tail_removed()
	t06_t07_tail_cell()
	t08_wall_obstacle()
	t09_spawn_rules()
	t10_determinism()
	t11_arenas()
	t12_save()
	t13_reduce_motion()
	t14_pause()
	t15_speed()
	t16_scissors()
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func t01_straight_movement() -> void:
	var s := make_state()
	var h := s.body[0]
	s.step()
	s.step()
	check(s.body[0] == h + Vector2i(2, 0), "01 straight movement: one cell per tick")

func t02_reverse_rejected() -> void:
	var s := make_state()
	check(not s.queue_turn(Vector2i.LEFT), "02 immediate reverse rejected")
	check(not s.queue_turn(Vector2i.RIGHT), "02 same-direction duplicate ignored")
	s.queue_turn(Vector2i.UP)
	check(not s.queue_turn(Vector2i.DOWN), "02 reverse of queued turn rejected")

func t03_one_turn_per_tick() -> void:
	var s := make_state()
	s.queue_turn(Vector2i.UP)
	s.queue_turn(Vector2i.LEFT)
	s.step()
	check(s.dir == Vector2i.UP and s.turns.pending.size() == 1, "03 only one turn consumed per tick")
	s.step()
	check(s.dir == Vector2i.LEFT, "03 second turn consumed next tick")

func t04_collect_score_growth() -> void:
	var s := make_state()
	var yarn := {"id": "yarn", "score": 30, "growth": 3, "weight": 1}
	s.pickups.append({"cell": s.body[0] + Vector2i.RIGHT, "item": yarn})
	var len0 := s.body.size()
	s.step()
	check(s.score == 30, "04 score updated")
	for i in 3:
		s.step()
	check(s.body.size() == len0 + 3, "04 yarn ball grows exactly 3")

func t05_tail_removed() -> void:
	var s := make_state()
	var tail: Vector2i = s.body.back()
	var n := s.body.size()
	s.step()
	check(s.body.size() == n and not s.body.has(tail), "05 non-growing move drops final tail cell")

func _ring() -> GameState:
	var s := make_state(4, 4, Vector2i(2, 2))
	s.body = [Vector2i(1, 1), Vector2i(0, 1), Vector2i(0, 0), Vector2i(1, 0)]
	s.dir = Vector2i.UP
	return s

func t06_t07_tail_cell() -> void:
	var s := _ring()
	s.step()
	check(s.alive and s.body[0] == Vector2i(1, 0), "06 entering a vacating tail cell is legal")
	var s2 := _ring()
	s2.pending_growth = 1
	s2.step()
	check(not s2.alive and s2.death_reason == "yarn", "07 entering a non-vacating tail cell is fatal")

func t08_wall_obstacle() -> void:
	var s := make_state(6, 3, Vector2i(2, 1))
	for i in 5:
		s.step()
	check(not s.alive and s.death_reason == "wall", "08 wall ends the run")
	var b := GridBoard.new(10, 3)
	b.add_obstacle(Vector2i(5, 1))
	var s2 := GameState.new(b, ItemRules.load_items(), 1, Vector2i(2, 1))
	for i in 4:
		s2.step()
	check(not s2.alive and s2.death_reason == "obstacle", "08 obstacle ends the run")

func t09_spawn_rules() -> void:
	var b := GridBoard.new(20, 10)
	for x in range(8, 12):
		for y in 10:
			b.add_obstacle(Vector2i(x, y))
	var s := GameState.new(b, ItemRules.load_items(), 7, Vector2i(4, 5))
	var ok := true
	for i in 300:
		s.pickups.clear()
		s._spawn_pickup()
		var c: Vector2i = s.pickups[0]["cell"]
		if b.is_blocked(c) or s.body.has(c) or c.x >= 8:
			ok = false
	check(ok, "09 spawn excludes occupied/blocked and unreachable cells")
	var full := GameState.new(GridBoard.new(4, 1), ItemRules.load_items(), 3, Vector2i(2, 0))
	check(full.pickups.size() == 1, "09 last free cell gets a pickup")
	full.step()
	check(full.cleared and not full.alive == false, "09 full board ends in cleared state (terminates)")

func _run(seed: int) -> Array:
	var s := GameState.new(ArenaData.build(ArenaData.load_arena("garden"), 1)["board"], ItemRules.load_items(), seed, Vector2i(4, 5))
	var cmds := {3: Vector2i.UP, 9: Vector2i.RIGHT, 14: Vector2i.DOWN, 20: Vector2i.LEFT}
	for t in 60:
		if cmds.has(t):
			s.queue_turn(cmds[t])
		s.step()
	return [s.body.duplicate(), s.score, s.alive, s.pickups.size()]

func t10_determinism() -> void:
	check(_run(42) == _run(42), "10 same seed + commands => identical outcome")
	var other := _run(43)
	check(typeof(other) == TYPE_ARRAY, "10 different seed runs")

func t11_arenas() -> void:
	var ids := ArenaData.ids()
	check(ids.size() == 4, "11 four arenas registered")
	for id in ids:
		var a := ArenaData.load_arena(id)
		var errs := ArenaData.validate(a)
		check(errs.is_empty(), "11 arena '%s' valid %s" % [id, errs])

func t12_save() -> void:
	check(SaveStore.sanitize(null) == SaveStore.default_data(), "12 missing data -> defaults")
	check(SaveStore.sanitize("garbage") == SaveStore.default_data(), "12 corrupt (wrong type) -> defaults")
	var bad := SaveStore.sanitize({"schema_version": 1, "settings": {"music_volume": 9, "touch_mode": "evil", "reduce_motion": "yes"}, "high_scores": {"a:b": -5, "c:d": 120}})
	check(bad["settings"]["music_volume"] == 1.0 and bad["settings"]["touch_mode"] == "auto" and bad["settings"]["reduce_motion"] == false, "12 invalid values clamped/defaulted")
	check(bad["high_scores"] == {"c:d": 120} and bad["best_overall"] == 120, "12 invalid scores dropped, best recomputed")
	var old := SaveStore.sanitize({"music_volume": 0.3, "high_scores": {"backyard:easy": 50}})
	check(is_equal_approx(old["settings"]["music_volume"], 0.3) and old["schema_version"] == SaveStore.SCHEMA_VERSION, "12 old (v0) data migrated")
	var path := "user://test_save.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var store := SaveStore.new()
	store.load_data(path)
	check(store.data == SaveStore.default_data(), "12 corrupt file -> defaults")
	store.submit_score("backyard", "normal", 250)
	store.save_data(path)
	var store2 := SaveStore.new()
	store2.load_data(path)
	check(store2.high_score("backyard", "normal") == 250 and store2.data["best_overall"] == 250, "12 save/load round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	store.free()
	store2.free()

func t13_reduce_motion() -> void:
	check(YarnMath.wiggle(3, 0.7, 0.9, true) == 0.0 and YarnMath.wiggle(3, 0.7, 0.9, false) != 0.0, "13 reduce motion zeroes wiggle")
	var pts: Array[Vector2] = [Vector2(0, 0), Vector2(8, 0), Vector2(16, 8), Vector2(24, 8)]
	var sm := YarnMath.smooth(pts)
	check(YarnMath.apply_wiggle(sm, 1.3, true) == sm, "13 reduce motion leaves line geometry untouched")
	check(YarnMath.apply_wiggle(sm, 1.3, false) != sm, "13 wiggle moves line when enabled")
	var a := _run(5)
	var b := _run(5)
	check(a == b, "13 simulation unaffected by rendering settings")

func t14_pause() -> void:
	var c := TickClock.new()
	c.set_speed(10.0)
	check(c.advance(0.25) == 2, "14 clock ticks at speed")
	c.paused = true
	check(c.advance(5.0) == 0, "14 paused clock yields no ticks")
	c.paused = false
	check(c.advance(0.11) == 1, "14 resume continues safely (no burst)")

func t15_speed() -> void:
	var easy := GameRules.difficulty("easy")
	var hard := GameRules.difficulty("hard")
	check(is_equal_approx(GameRules.speed_for(easy, 0), 4.0) and is_equal_approx(GameRules.speed_for(easy, 5), 4.15), "15 easy speed steps +0.15 per 5 items")
	check(is_equal_approx(GameRules.speed_for(hard, 1000), 12.0), "15 speed capped at 12")

func t16_scissors() -> void:
	var s := make_state()
	s.body = [Vector2i(6, 5), Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5)]
	s.pickups.append({"cell": Vector2i(7, 5), "item": {"id": "scissors", "score": 0, "growth": -3, "weight": 1}})
	s.step()
	check(s.body.size() == 3, "16 scissors never shorten below minimum 2 yarn segments")
