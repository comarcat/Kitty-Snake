class_name GameRules
extends RefCounted

const DIFFICULTIES_PATH := "res://data/difficulties/difficulties.json"
static var _cfg: Dictionary = {}

static func config() -> Dictionary:
	if _cfg.is_empty():
		var parsed: Variant = JsonUtil.read(DIFFICULTIES_PATH)
		_cfg = parsed if typeof(parsed) == TYPE_DICTIONARY else {"speed_cap": 12.0, "items_per_speedup": 5, "difficulties": []}
	return _cfg

static func difficulties() -> Array:
	return config()["difficulties"]

static func difficulty(id: String) -> Dictionary:
	for d in difficulties():
		if d["id"] == id:
			return d
	return difficulties()[1]

## Cells per second after `collected` items.
static func speed_for(diff: Dictionary, collected: int) -> float:
	var cfg := config()
	var steps := int(collected / int(cfg["items_per_speedup"]))
	return minf(float(cfg["speed_cap"]), float(diff["speed"]) + steps * float(diff["step"]))
