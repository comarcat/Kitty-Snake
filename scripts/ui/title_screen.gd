class_name TitleScreen
extends MenuScreen

var play_btn: Button
var arena_btn: Button
var diff_btn: Button
var arenas: Dictionary

func _init(p_arenas: Dictionary) -> void:
	super("Kitty Snake")
	arenas = p_arenas
	box.add_child(UiKit.label("Yarn Trails", 34, UiKit.GOLD))
	play_btn = add_nav("Play", "play")
	arena_btn = add_nav("Arena", "arena")
	diff_btn = add_nav("Difficulty", "difficulty")
	add_nav("Settings", "settings")
	add_nav("High Scores", "scores")
	if not (OS.has_feature("web") or OS.has_feature("mobile")):
		add_nav("Quit", "quit")

func on_show() -> void:
	arena_btn.text = "Arena: %s" % arenas[Save.get_setting("last_arena")]["name"]
	diff_btn.text = "Difficulty: %s" % GameRules.difficulty(Save.get_setting("last_difficulty"))["name"]
	focus_first()
