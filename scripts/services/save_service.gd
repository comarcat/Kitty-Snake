class_name SaveStore
extends Node
## Versioned JSON save in user:// (browser IndexedDB on web). Autoloaded as `Save`.

signal settings_changed

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://kitty_snake_save.json"
const TOUCH_MODES := ["auto", "dpad", "swipe", "off"]

var data: Dictionary = default_data()
var storage_ok := true

static func default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"settings": {
			"music_volume": 0.8, "sfx_volume": 0.8, "reduce_motion": false,
			"fullscreen": false, "touch_mode": "auto",
			"last_arena": "backyard", "last_difficulty": "normal",
		},
		"high_scores": {},
		"best_overall": 0,
	}

## Validates any parsed value; never throws. Missing/old/corrupt fields fall back to defaults.
static func sanitize(raw: Variant) -> Dictionary:
	var out := default_data()
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	var src: Dictionary = raw
	var version := int(src.get("schema_version", 0)) if typeof(src.get("schema_version", 0)) in [TYPE_INT, TYPE_FLOAT] else 0
	# v0 (pre-schema) stored settings flat at the top level.
	var s_src: Variant = src.get("settings", src if version < 1 else {})
	var s: Dictionary = out["settings"]
	if typeof(s_src) == TYPE_DICTIONARY:
		for k in ["music_volume", "sfx_volume"]:
			if typeof(s_src.get(k)) in [TYPE_FLOAT, TYPE_INT]:
				s[k] = clampf(float(s_src[k]), 0.0, 1.0)
		for k in ["reduce_motion", "fullscreen"]:
			if typeof(s_src.get(k)) == TYPE_BOOL:
				s[k] = s_src[k]
		if typeof(s_src.get("touch_mode")) == TYPE_STRING and s_src["touch_mode"] in TOUCH_MODES:
			s["touch_mode"] = s_src["touch_mode"]
		for k in ["last_arena", "last_difficulty"]:
			if typeof(s_src.get(k)) == TYPE_STRING and String(s_src[k]).length() < 40:
				s[k] = s_src[k]
	var hs_src: Variant = src.get("high_scores", {})
	var best := 0
	if typeof(hs_src) == TYPE_DICTIONARY:
		for k in hs_src:
			if typeof(k) == TYPE_STRING and typeof(hs_src[k]) in [TYPE_INT, TYPE_FLOAT] and hs_src[k] >= 0:
				out["high_scores"][k] = int(hs_src[k])
				best = maxi(best, int(hs_src[k]))
	var bo: Variant = src.get("best_overall", 0)
	if typeof(bo) in [TYPE_INT, TYPE_FLOAT] and bo >= 0:
		best = maxi(best, int(bo))
	out["best_overall"] = best
	return out

func _ready() -> void:
	load_data()

func load_data(path: String = SAVE_PATH) -> void:
	var raw: Variant = null
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			raw = JSON.parse_string(f.get_as_text())
			f.close()
	data = sanitize(raw)

func save_data(path: String = SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		storage_ok = false
		push_warning("Save storage unavailable; progress will not persist this session.")
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	storage_ok = true
	return true

func get_setting(key: String) -> Variant:
	return data["settings"][key]

func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	save_data()
	settings_changed.emit()

static func score_key(arena_id: String, diff_id: String) -> String:
	return "%s:%s" % [arena_id, diff_id]

func high_score(arena_id: String, diff_id: String) -> int:
	return int(data["high_scores"].get(score_key(arena_id, diff_id), 0))

## Records a finished run; returns true if it is a new best for that arena/difficulty.
func submit_score(arena_id: String, diff_id: String, score: int) -> bool:
	var key := score_key(arena_id, diff_id)
	var is_best := score > int(data["high_scores"].get(key, 0))
	if is_best:
		data["high_scores"][key] = score
	if score > int(data["best_overall"]):
		data["best_overall"] = score
	if is_best:
		save_data()
	return is_best
