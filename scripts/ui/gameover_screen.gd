class_name GameOverScreen
extends MenuScreen

var result: Label
var best: Label

func _init() -> void:
	super("Game Over")
	result = UiKit.label("", 40)
	best = UiKit.label("", 30, UiKit.GOLD)
	box.add_child(result)
	box.add_child(best)
	add_nav("Retry", "restart")
	add_nav("Main Menu", "menu")

func show_result(info: Dictionary) -> void:
	title_label.text = "You cleared the board!" if info["cleared"] else "Game Over"
	result.text = "Score: %d" % info["score"]
	best.text = ("New best! %d" if info["new_best"] else "Best: %d") % info["best"]
