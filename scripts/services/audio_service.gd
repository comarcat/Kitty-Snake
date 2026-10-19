extends Node
## Procedurally generated chiptune SFX and music (no audio assets needed). Autoloaded as `Sfx`.

const RATE := 22050

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_cache: Dictionary = {}
var _next := 0

func _ready() -> void:
	_sfx = {
		"eat": _make([76, 83], 0.07, "square", 0.35),
		"gold": _make([72, 76, 79, 84, 88], 0.07, "square", 0.35),
		"snip": _make([90, 80], 0.04, "noise", 0.3),
		"die": _make([62, 58, 54, 50, 46], 0.12, "tri", 0.6),
		"click": _make([84], 0.04, "square", 0.25),
		"win": _make([72, 76, 79, 84, 79, 84, 88], 0.1, "square", 0.35),
	}
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)

func _volume(key: String) -> float:
	var save := get_node_or_null("/root/Save")
	return float(save.get_setting(key)) if save != null else 0.8

func play(name: String) -> void:
	var v := _volume("sfx_volume")
	if v <= 0.0 or not _sfx.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[name]
	p.volume_db = linear_to_db(v)
	p.play()

func play_music(arena: Dictionary) -> void:
	var id: String = arena.get("id", "menu")
	if not _music_cache.has(id):
		var m: Dictionary = arena["music"]
		var notes: Array = []
		for n in m["melody"]:
			notes.append(int(m["root"]) + int(n))
		_music_cache[id] = _make(notes, float(m["step"]), m["wave"], 0.5, true)
	if _music.stream != _music_cache[id] or not _music.playing:
		_music.stream = _music_cache[id]
		apply_volume()
		_music.play()

func apply_volume() -> void:
	var v := _volume("music_volume") * 0.3
	_music.volume_db = linear_to_db(v) if v > 0.0 else -80.0

func set_music_paused(p: bool) -> void:
	_music.stream_paused = p

func stop_music() -> void:
	_music.stop()

func _make(notes: Array, note_len: float, wave: String, vol: float, loop: bool = false) -> AudioStreamWAV:
	var per := int(note_len * RATE)
	var data := PackedByteArray()
	data.resize(per * notes.size() * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var idx := 0
	for n in notes:
		var f := 440.0 * pow(2.0, (float(n) - 69.0) / 12.0)
		for i in per:
			var ph := fmod(float(i) * f / RATE, 1.0)
			var v := 0.0
			match wave:
				"square": v = 1.0 if ph < 0.5 else -1.0
				"tri": v = 4.0 * absf(ph - 0.5) - 1.0
				"noise": v = rng.randf() * 2.0 - 1.0
			var env := minf(1.0, float(i) / 120.0) * (1.0 - float(i) / per * (0.5 if loop else 1.0))
			data.encode_s16(idx * 2, int(clampf(v * vol * env, -1.0, 1.0) * 32000.0))
			idx += 1
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = idx
	return s
