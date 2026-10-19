class_name ArenaScreen
extends MenuScreen

var arenas: Dictionary
var cards := {}

func _init(p_arenas: Dictionary) -> void:
	super("Choose Arena")
	arenas = p_arenas
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	box.add_child(grid)
	for id in ArenaData.ids():
		var a: Dictionary = arenas[id]
		var card := Button.new()
		card.custom_minimum_size = Vector2(240, 190)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var prev := ArenaPreview.new()
		prev.setup(a)
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(prev)
		v.add_child(holder)
		var name_l := UiKit.label(a["name"], 26)
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cards[id] = name_l
		v.add_child(name_l)
		card.add_child(v)
		card.pressed.connect(func():
			Sfx.play("click")
			Save.set_setting("last_arena", id)
			navigate.emit("back"))
		grid.add_child(card)
	add_nav("Back", "back")

func on_show() -> void:
	var sel: String = Save.get_setting("last_arena")
	for id in cards:
		cards[id].text = ("> %s <" if id == sel else "%s") % arenas[id]["name"]
	focus_first()
