class_name SettingsScreen
extends MenuScreen

var music: HSlider
var sfx: HSlider
var reduce: CheckBox
var full: CheckBox
var touch: OptionButton
var _loading := false

func _init() -> void:
	super("Settings")
	music = _slider("Music volume", "music_volume")
	sfx = _slider("SFX volume", "sfx_volume")
	reduce = _check("Reduce motion (no yarn wiggle)", "reduce_motion")
	full = _check("Fullscreen", "fullscreen")
	if OS.has_feature("web") or OS.has_feature("mobile"):
		full.visible = false
	var row := HBoxContainer.new()
	row.add_child(UiKit.label("Touch controls", 28))
	row.add_child(Control.new())
	row.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	touch = OptionButton.new()
	for t in ["Auto", "D-pad", "Swipe", "Off"]:
		touch.add_item(t)
	touch.custom_minimum_size = Vector2(200, 56)
	touch.item_selected.connect(func(i):
		if not _loading:
			Save.set_setting("touch_mode", SaveStore.TOUCH_MODES[i]))
	row.add_child(touch)
	box.add_child(row)
	add_nav("Back", "back")

func _slider(text: String, key: String) -> HSlider:
	var row := HBoxContainer.new()
	var l := UiKit.label(text, 28)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(240, 48)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v):
		if not _loading:
			Save.set_setting(key, v)
			Sfx.apply_volume()
			if key == "sfx_volume":
				Sfx.play("eat"))
	row.add_child(s)
	box.add_child(row)
	return s

func _check(text: String, key: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.custom_minimum_size = Vector2(480, 56)
	c.toggled.connect(func(on):
		if not _loading:
			Save.set_setting(key, on))
	box.add_child(c)
	return c

func on_show() -> void:
	_loading = true
	music.value = Save.get_setting("music_volume")
	sfx.value = Save.get_setting("sfx_volume")
	reduce.button_pressed = Save.get_setting("reduce_motion")
	full.button_pressed = Save.get_setting("fullscreen")
	touch.select(SaveStore.TOUCH_MODES.find(Save.get_setting("touch_mode")))
	_loading = false
	focus_first()
