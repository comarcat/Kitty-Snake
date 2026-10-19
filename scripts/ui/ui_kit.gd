class_name UiKit
extends RefCounted

const BG := Color("2b1b3d")
const PANEL := Color("43295f")
const PINK := Color("ff8fc1")
const CREAM := Color("fff1d6")
const GOLD := Color("ffd166")

static func _box(c: Color, border: Color = Color.TRANSPARENT, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	return sb

static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 28
	th.set_stylebox("normal", "Button", _box(PANEL, Color("6d4a8f"), 3))
	th.set_stylebox("hover", "Button", _box(PANEL.lightened(0.15), PINK, 3))
	th.set_stylebox("pressed", "Button", _box(PINK.darkened(0.3), PINK, 3))
	th.set_stylebox("focus", "Button", _box(PANEL.lightened(0.12), GOLD, 4))
	th.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.3)))
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		th.set_color(k, "Button", CREAM)
	th.set_color("font_color", "Label", CREAM)
	th.set_color("font_color", "CheckBox", CREAM)
	th.set_constant("h_separation", "CheckBox", 12)
	return th

static func label(text: String, size: int = 28, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
