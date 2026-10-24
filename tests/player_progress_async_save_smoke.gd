extends SceneTree

var game: Node
var cache_existed := false
var cache_bytes := PackedByteArray()
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	failed = true
	push_error("PLAYER_PROGRESS_ASYNC_SAVE_FAIL " + message)


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	cache_existed = FileAccess.file_exists(game.PLAYER_PROGRESS_CACHE_PATH)
	cache_bytes = FileAccess.get_file_as_bytes(game.PLAYER_PROGRESS_CACHE_PATH) if cache_existed else PackedByteArray()
	game.player_progress_pending_events.clear()
	game.player_progress_quarantined_events.clear()
	var raw_overflow: Array = []
	for index in range(5000):
		raw_overflow.append({
			"event": game.RTPlayerProgressSync.unlock_progress_event(
				game.player_profile_id,
				index + 1,
				"ppd_async_fixture",
				"stationary_seconds",
				1.0,
				false,
				game.GAME_VERSION_CODE
			),
			"reason": "queue_capacity",
			"at": index,
		})
	game.player_progress_quarantined_events = game.RTPlayerProgressSync.compact_quarantined_events(raw_overflow)
	game.card_unlocks_dirty = true
	var started := Time.get_ticks_usec()
	game.save_controller._save_card_unlocks_async()
	var launch_ms := float(Time.get_ticks_usec() - started) / 1000.0
	_check(launch_ms < 50.0, "async launch blocked the gameplay frame: %.2fms" % launch_ms)
	var deadline := Time.get_ticks_msec() + 5000
	while game.save_controller.card_unlock_save_thread != null and Time.get_ticks_msec() < deadline:
		game.save_controller._poll_card_unlock_save(false)
		await process_frame
	_check(game.save_controller.card_unlock_save_thread == null, "background cache write did not complete")
	_check(FileAccess.file_exists(game.PLAYER_PROGRESS_CACHE_PATH), "background cache file was not created")
	var raw := FileAccess.get_file_as_string(game.PLAYER_PROGRESS_CACHE_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	var trusted: Dictionary = game.RTPlayerProgressSync.validate_cache(parsed, game._player_progress_install_secret())
	_check(not trusted.is_empty(), "background cache signature was invalid")
	var quarantined: Array = trusted.get("quarantined_events", [])
	_check(quarantined.size() == 1, "background save expanded the compact overflow queue")
	var compacted_event: Dictionary = Dictionary(quarantined[0]).get("event", {}) if not quarantined.is_empty() else {}
	_check(is_equal_approx(float(compacted_event.get("amount", 0.0)), 5000.0), "background save changed the overflow total")
	var stored_bytes := raw.to_utf8_buffer().size()
	_check(stored_bytes < 32768, "background cache exceeded compact size budget: %d" % stored_bytes)
	_restore_cache()
	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
	for _frame in range(3):
		await process_frame
	if not failed:
		print("PLAYER_PROGRESS_ASYNC_SAVE_OK launch_ms=%.2f cache_bytes=%d overflow_events=5000 compacted=1" % [launch_ms, stored_bytes])
	quit(1 if failed else 0)


func _restore_cache() -> void:
	game.save_controller._poll_card_unlock_save(true)
	var absolute_path := ProjectSettings.globalize_path(game.PLAYER_PROGRESS_CACHE_PATH)
	if cache_existed:
		var file := FileAccess.open(absolute_path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(cache_bytes)
			file.close()
		return
	DirAccess.remove_absolute(absolute_path)
