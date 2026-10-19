extends Control
## Root: builds the 320x180 pixel viewport, HUD, touch controls and menu screens, and routes flow.

const VIEW_W := 320.0
const VIEW_H := 180.0

var viewport: SubViewport
var game_view: GameView
var view_rect: TextureRect
var hud: Control
var score_label: Label
var best_label: Label
var info_label: Label
var pause_btn: Button
var countdown_label: Label
var touch: TouchControls
var controller: GameController
var adapter: InputAdapter
var arenas: Dictionary
var screens := {}
var current := ""
var settings_return := "title"
var _touch_seen := false
var _game_rect := Rect2()

func _ready() -> void:
	theme = UiKit.make_theme()
	arenas = ArenaData.load_all()
	get_tree().set_auto_accept_quit(true)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	viewport = SubViewport.new()
	viewport.size = Vector2i(int(VIEW_W), int(VIEW_H))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.gui_disable_input = true
	game_view = GameView.new()
	viewport.add_child(game_view)
	add_child(viewport)
	view_rect = TextureRect.new()
	view_rect.texture = viewport.get_texture()
	view_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view_rect.stretch_mode = TextureRect.STRETCH_SCALE
	view_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view_rect)

	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	score_label = _hud_label(HORIZONTAL_ALIGNMENT_LEFT)
	info_label = _hud_label(HORIZONTAL_ALIGNMENT_CENTER)
	best_label = _hud_label(HORIZONTAL_ALIGNMENT_RIGHT)
	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(func(): _on_command(InputAdapter.Cmd.PAUSE))
	add_child(pause_btn)

	touch = TouchControls.new()
	touch.pressed_cmd.connect(func(cmd): _on_command(cmd))
	add_child(touch)

	countdown_label = UiKit.label("", 120, UiKit.GOLD)
	countdown_label.add_theme_color_override("font_outline_color", Color("2b1b3d"))
	countdown_label.add_theme_constant_override("outline_size", 12)
	countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(countdown_label)

	adapter = InputAdapter.new()
	adapter.command.connect(_on_command)
	add_child(adapter)
	controller = GameController.new()
	controller.phase_changed.connect(_on_phase)
	controller.countdown_changed.connect(_on_countdown)
	controller.score_changed.connect(func(s): score_label.text = "Score %d" % s)
	controller.finished.connect(_on_finished)
	add_child(controller)

	_add_screen("title", TitleScreen.new(arenas))
	_add_screen("arena", ArenaScreen.new(arenas))
	_add_screen("difficulty", DifficultyScreen.new())
	_add_screen("settings", SettingsScreen.new())
	_add_screen("scores", ScoresScreen.new(arenas))
	_add_screen("pause", PauseScreen.new())
	_add_screen("gameover", GameOverScreen.new())

	resized.connect(_layout)
	Save.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()
	_show_menu_backdrop()
	show_screen("title")
	_layout()

func _hud_label(align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", UiKit.CREAM)
	hud.add_child(l)
	return l

func _add_screen(id: String, s: MenuScreen) -> void:
	s.navigate.connect(_navigate)
	s.visible = false
	add_child(s)
	screens[id] = s

func show_screen(id: String) -> void:
	current = id
	for k in screens:
		screens[k].visible = (k == id)
	if id != "":
		screens[id].on_show()
	_sync_chrome()

func _show_menu_backdrop() -> void:
	game_view.state = null
	game_view.board = ArenaData.build(arenas[Save.get_setting("last_arena")], 1)["board"]
	game_view.arena = arenas[Save.get_setting("last_arena")]

# --- flow -------------------------------------------------------------------

func _navigate(target: String) -> void:
	match target:
		"play", "restart": start_game()
		"resume": controller.resume()
		"menu":
			controller.phase = "idle"
			_show_menu_backdrop()
			Sfx.stop_music()
			show_screen("title")
		"quit": get_tree().quit()
		"settings":
			settings_return = current
			show_screen("settings")
		"back":
			if current == "settings":
				show_screen(settings_return)
			else:
				_show_menu_backdrop()
				show_screen("title")
		_: show_screen(target)

func start_game() -> void:
	var arena: Dictionary = arenas[Save.get_setting("last_arena")]
	var diff := GameRules.difficulty(Save.get_setting("last_difficulty"))
	game_view.arena = arena
	controller.begin(arena, diff)
	game_view.state = controller.state
	score_label.text = "Score 0"
	best_label.text = "Best %d" % Save.high_score(arena["id"], diff["id"])
	info_label.text = "%s - %s" % [arena["name"], diff["name"]]
	Sfx.play_music(arena)
	show_screen("")

func _on_phase(phase: String) -> void:
	adapter.capture = controller.is_playing()
	if phase == "paused":
		show_screen("pause")
	elif phase == "countdown" or phase == "running":
		show_screen("")
		if phase == "running":
			countdown_label.text = ""
	_sync_chrome()

func _on_countdown(n: int) -> void:
	countdown_label.text = str(n) if n > 0 else ""

func _on_finished(info: Dictionary) -> void:
	adapter.capture = false
	best_label.text = "Best %d" % info["best"]
	await get_tree().create_timer(0.9).timeout
	if controller.phase != "over":
		return
	screens["gameover"].show_result(info)
	show_screen("gameover")

func _on_command(cmd: int) -> void:
	match cmd:
		InputAdapter.Cmd.PAUSE:
			if controller.is_playing():
				controller.pause()
			elif controller.phase == "paused":
				controller.resume()
		InputAdapter.Cmd.TURN_UP, InputAdapter.Cmd.TURN_DOWN, InputAdapter.Cmd.TURN_LEFT, InputAdapter.Cmd.TURN_RIGHT:
			controller.turn(InputAdapter.cmd_to_dir(cmd))

func _on_back() -> void:
	if controller.is_playing():
		controller.pause()
	elif controller.phase == "paused" and current == "pause":
		controller.resume()
	elif current == "gameover":
		_navigate("menu")
	elif current == "title":
		if not (OS.has_feature("web") or OS.has_feature("mobile")):
			get_tree().quit()
	elif current != "":
		_navigate("back")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not _touch_seen:
		_touch_seen = true
		_layout()
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if controller != null and controller.is_playing():
				controller.pause()
		NOTIFICATION_APPLICATION_PAUSED:
			if controller != null and controller.is_playing():
				controller.pause()
			Sfx.set_music_paused(true)
		NOTIFICATION_APPLICATION_RESUMED:
			Sfx.set_music_paused(false)
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back()

func _on_settings_changed() -> void:
	game_view.reduce_motion = Save.get_setting("reduce_motion")
	Sfx.apply_volume()
	if not (OS.has_feature("web") or OS.has_feature("mobile")):
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if Save.get_setting("fullscreen") else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	adapter.swipe_enabled = Save.get_setting("touch_mode") == "swipe"
	_layout()

func _process(_delta: float) -> void:
	if controller.state != null and controller.phase != "idle":
		game_view.alpha = controller.clock.alpha() if controller.phase == "running" else game_view.alpha
		if controller.phase == "countdown":
			game_view.alpha = 1.0

# --- layout -----------------------------------------------------------------

func _touch_mode() -> String:
	var m: String = Save.get_setting("touch_mode")
	var avail := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or _touch_seen
	if m == "auto":
		return "dpad" if avail else "none"
	return "none" if m == "off" else m

func _sync_chrome() -> void:
	var in_game := current == "" or current == "pause"
	var showing_game := controller != null and controller.phase != "idle" and (in_game or current == "gameover" or current == "settings" and settings_return == "pause")
	hud.visible = showing_game
	pause_btn.visible = showing_game and current == ""
	touch.visible = showing_game and current == "" and _touch_mode() == "dpad"
	countdown_label.visible = current == ""
	view_rect.visible = true

func _layout() -> void:
	if view_rect == null:
		return
	var sz := size
	var mode := _touch_mode()
	var has_touch := mode != "none"
	var landscape := sz.x >= sz.y
	var m := 12.0
	var u := clampf(minf(sz.x, sz.y) * 0.16, 56.0, 140.0)
	var pause_s := maxf(52.0, u * 0.6)
	var avail := Rect2(Vector2.ZERO, sz)
	if has_touch:
		if landscape:
			var left := (u * 3.0 + m * 2.0) if mode == "dpad" else m
			avail = Rect2(left, 0, sz.x - left - (pause_s + m * 2.0), sz.y)
		else:
			var top := pause_s + m * 2.0
			var bottom := (u * 3.0 + m * 2.0) if mode == "dpad" else 0.0
			avail = Rect2(0, top, sz.x, sz.y - top - bottom)
	var scale := minf(avail.size.x / VIEW_W, avail.size.y / VIEW_H)
	if scale >= 2.0:
		scale = floorf(scale)
	scale = maxf(scale, 0.5)
	var gsize := Vector2(VIEW_W, VIEW_H) * scale
	_game_rect = Rect2(avail.position + (avail.size - gsize) / 2.0, gsize)
	view_rect.position = _game_rect.position
	view_rect.size = gsize

	var band := 20.0 * scale
	hud.position = _game_rect.position
	hud.size = Vector2(gsize.x, band)
	var fs := int(maxf(12.0, band * 0.6))
	var pad := 6.0 * scale
	var pause_w := 0.0 if has_touch else band
	var parts := [score_label, info_label, best_label]
	for l in parts:
		l.add_theme_font_size_override("font_size", fs)
		l.position = Vector2(pad, 0)
		l.size = Vector2(hud.size.x - pad * 2.0 - pause_w, band)
	if has_touch:
		pause_btn.size = Vector2(pause_s, pause_s)
		pause_btn.position = Vector2(sz.x - pause_s - m, m)
	else:
		pause_btn.size = Vector2(band, band)
		pause_btn.position = _game_rect.position + Vector2(gsize.x - band, 0)
	pause_btn.add_theme_font_size_override("font_size", int(maxf(14.0, pause_btn.size.y * 0.45)))
	if mode == "dpad":
		if landscape:
			touch.layout(u, Vector2(m, sz.y - u * 3.0 - m))
		else:
			touch.layout(u, Vector2((sz.x - u * 3.0) / 2.0, sz.y - u * 3.0 - m))
	countdown_label.position = _game_rect.position
	countdown_label.size = Vector2(gsize.x, gsize.y)
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", int(gsize.y * 0.5))
	_sync_chrome()
