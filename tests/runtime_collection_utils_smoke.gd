extends SceneTree

const RuntimeCollectionUtils = preload("res://scripts/systems/runtime_collection_utils.gd")

var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RUNTIME_COLLECTION_UTILS_FAIL " + message)


func _initialize() -> void:
	var items: Array = [
		{"id": "first", "life": 1.0},
		{"id": "expired", "life": 0.0},
		{"id": "last", "life": 0.25},
		{"id": "negative", "life": -1.0},
	]
	var first_ref: Dictionary = items[0]
	var last_ref: Dictionary = items[2]
	var items_alias: Array = items
	var removed := RuntimeCollectionUtils.compact_positive_float_field(items, &"life")

	_check(removed == 2, "wrong removed count")
	_check(items.size() == 2, "wrong compacted size")
	_check(items_alias.size() == 2, "compaction replaced the backing array")
	_check(items[0] == first_ref and items[1] == last_ref, "stable order or dictionary identity changed")

	var unchanged: Array = [{"time": 0.1}, {"time": 2.0}]
	_check(RuntimeCollectionUtils.compact_positive_float_field(unchanged, &"time") == 0, "live collection reported removals")
	_check(unchanged.size() == 2, "live collection resized")

	if failed:
		quit(1)
		return
	print("RUNTIME_COLLECTION_UTILS_OK")
	quit(0)
