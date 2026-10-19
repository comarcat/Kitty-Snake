class_name MenuScreen
extends Control
## Base for full-screen menus: dimmed backdrop, centred column, title, helper to add buttons.

signal navigate(target: String)

var box: VBoxContainer
var title_label: Label

func _init(title: String = "") -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.07, 0.2, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	title_label = UiKit.label(title, 56, UiKit.PINK)
	box.add_child(title_label)

func add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(440, 64)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	box.add_child(b)
	return b

func add_nav(text: String, target: String) -> Button:
	return add_button(text, func(): navigate.emit(target))

func focus_first() -> void:
	var b := _first_button(box)
	if b != null:
		b.grab_focus()

func _first_button(n: Node) -> Button:
	for c in n.get_children():
		if c is Button and c.focus_mode != Control.FOCUS_NONE and not c.disabled:
			return c
		var r := _first_button(c)
		if r != null:
			return r
	return null

func on_show() -> void:
	focus_first()
