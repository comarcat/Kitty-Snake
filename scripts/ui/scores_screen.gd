class_name ScoresScreen
extends MenuScreen

var grid: GridContainer
var arenas: Dictionary
var overall: Label

func _init(p_arenas: Dictionary) -> void:
	super("High Scores")
	arenas = p_arenas
	overall = UiKit.label("", 30, UiKit.GOLD)
	box.add_child(overall)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 28)
	box.add_child(grid)
	add_nav("Back", "back")

func on_show() -> void:
	for c in grid.get_children():
		c.queue_free()
	overall.text = "Overall best: %d" % int(Save.data["best_overall"])
	grid.add_child(UiKit.label("Arena", 24, UiKit.PINK))
	for d in GameRules.difficulties():
		grid.add_child(UiKit.label(d["name"], 24, UiKit.PINK))
	for id in ArenaData.ids():
		var l := UiKit.label(arenas[id]["name"], 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(l)
		for d in GameRules.difficulties():
			grid.add_child(UiKit.label(str(Save.high_score(id, d["id"])), 24))
	focus_first()
