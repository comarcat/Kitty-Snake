class_name PauseScreen
extends MenuScreen

func _init() -> void:
	super("Paused")
	add_nav("Resume", "resume")
	add_nav("Restart", "restart")
	add_nav("Settings", "settings")
	add_nav("Main Menu", "menu")
