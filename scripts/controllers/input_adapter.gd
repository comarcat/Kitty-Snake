class_name InputAdapter
extends Node
## Converts keyboard, gamepad and swipe input into abstract commands.
## On-screen D-pad buttons call push() directly. Commands are buffered by the game
## (TurnQueue) and consumed only on logic ticks.

signal command(cmd: int)

enum Cmd { TURN_UP, TURN_DOWN, TURN_LEFT, TURN_RIGHT, PAUSE, CONFIRM, BACK }

const DEADZONE := 0.55
const SWIPE_MIN := 28.0

var capture := false      # true while gameplay owns the input (consumes game keys)
var swipe_enabled := false
var _stick := Vector2i.ZERO
var _swipe_start := Vector2.ZERO
var _swiping := false

static func cmd_to_dir(cmd: int) -> Vector2i:
	match cmd:
		Cmd.TURN_UP: return Vector2i.UP
		Cmd.TURN_DOWN: return Vector2i.DOWN
		Cmd.TURN_LEFT: return Vector2i.LEFT
		Cmd.TURN_RIGHT: return Vector2i.RIGHT
	return Vector2i.ZERO

func push(cmd: int) -> void:
	command.emit(cmd)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var cmd := -1
		match event.physical_keycode:
			KEY_UP, KEY_W: cmd = Cmd.TURN_UP
			KEY_DOWN, KEY_S: cmd = Cmd.TURN_DOWN
			KEY_LEFT, KEY_A: cmd = Cmd.TURN_LEFT
			KEY_RIGHT, KEY_D: cmd = Cmd.TURN_RIGHT
			KEY_ESCAPE, KEY_P: cmd = Cmd.PAUSE
		if cmd >= 0 and capture:
			push(cmd)
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		var cmd := -1
		match event.button_index:
			JOY_BUTTON_DPAD_UP: cmd = Cmd.TURN_UP
			JOY_BUTTON_DPAD_DOWN: cmd = Cmd.TURN_DOWN
			JOY_BUTTON_DPAD_LEFT: cmd = Cmd.TURN_LEFT
			JOY_BUTTON_DPAD_RIGHT: cmd = Cmd.TURN_RIGHT
			JOY_BUTTON_START: cmd = Cmd.PAUSE
		if cmd == Cmd.PAUSE or (cmd >= 0 and capture):
			push(cmd)
	elif event is InputEventJoypadMotion and capture:
		var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", DEADZONE)
		var d := Vector2i.ZERO
		if v.length() > 0.0:
			d = Vector2i(signi(roundi(v.x)), 0) if absf(v.x) > absf(v.y) else Vector2i(0, signi(roundi(v.y)))
		if d != _stick and d != Vector2i.ZERO:
			if d.x > 0: push(Cmd.TURN_RIGHT)
			elif d.x < 0: push(Cmd.TURN_LEFT)
			elif d.y > 0: push(Cmd.TURN_DOWN)
			else: push(Cmd.TURN_UP)
		_stick = d
	elif event is InputEventScreenTouch and swipe_enabled and capture:
		_swiping = event.pressed
		_swipe_start = event.position
	elif event is InputEventScreenDrag and swipe_enabled and capture and _swiping:
		var delta: Vector2 = event.position - _swipe_start
		if delta.length() >= SWIPE_MIN:
			if absf(delta.x) > absf(delta.y):
				push(Cmd.TURN_RIGHT if delta.x > 0 else Cmd.TURN_LEFT)
			else:
				push(Cmd.TURN_DOWN if delta.y > 0 else Cmd.TURN_UP)
			_swipe_start = event.position
