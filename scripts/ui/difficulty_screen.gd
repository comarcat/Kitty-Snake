class_name DifficultyScreen
extends MenuScreen

func _init() -> void:
	super("Difficulty")
	for d in GameRules.difficulties():
		var id: String = d["id"]
		add_button("%s  (speed %s)" % [d["name"], d["speed"]], func():
			Save.set_setting("last_difficulty", id)
			navigate.emit("back"))
	add_nav("Back", "back")
