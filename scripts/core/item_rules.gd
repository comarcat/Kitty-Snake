class_name ItemRules
extends RefCounted

const ITEMS_PATH := "res://data/items/items.json"
static var _cache: Array = []

static func load_items() -> Array:
	if _cache.is_empty():
		var parsed: Variant = JsonUtil.read(ITEMS_PATH)
		if typeof(parsed) == TYPE_DICTIONARY:
			_cache = parsed["items"]
	return _cache

static func enabled_items() -> Array:
	return load_items().filter(func(i): return i.get("enabled", true))
