extends SceneTree

const DEFAULT_DURATION_SECONDS := 180.0
const SAMPLE_INTERVAL_SECONDS := 30.0
const ENEMY_COUNT := 6

var game: Node
var duration_seconds := DEFAULT_DURATION_SECONDS
var disable_autosave := false
var disable_progress_persistence := false
var cycling_kills := false
var frame_samples_by_minute: Array[Array] = [[], [], []]
var collection_start: Dictionary = {}
var collection_max: Dictionary = {}
var resource_start: Dictionary = {}
var resource_end: Dictionary = {}


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--duration="):
			duration_seconds = maxf(1.0, float(argument.trim_prefix("--duration=")))
		elif argument == "--disable-autosave":
			disable_autosave = true
		elif argument == "--disable-progress-persistence":
			disable_progress_persistence = true
		elif argument == "--cycling-kills":
			cycling_kills = true
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _fixture() -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.online_connected = false
	game.dedicated_server_mode = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.henry_entry_timer = 0.0
	game.spawn_timer = 999999.0
	game.player_hp_max = 1000000.0
	game.player_hp = game.player_hp_max
	game.run_retry_invulnerability_timer = 999999.0
	game.shop_auto_enabled = false
	game.heal_orbs.clear()
	game.enemies.clear()
	for index in range(ENEMY_COUNT):
		var angle := float(index) * TAU / float(ENEMY_COUNT)
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(angle) * 250.0)
		var enemy: Dictionary = game.enemies[-1]
		enemy["hp"] = 18.0 if cycling_kills else 1000000000.0
		enemy["max_hp"] = enemy["hp"]
		enemy["speed"] = 42.0 if cycling_kills else 0.0
		enemy["damage"] = 0.0
	game.gfx_fps_limit = 60
	game.gfx_memory_saver = false
	game.gfx_low_resource = false
	game.gfx_particles = true
	game._apply_graphics_settings()
	if disable_autosave:
		game.interrupted_run_autosave_timer = 1000000000.0
	if disable_progress_persistence:
		_neutralize_progress_persistence()


func _collection_sizes() -> Dictionary:
	var result: Dictionary = {}
	for property_value in game.get_property_list():
		var property: Dictionary = property_value
		var property_type := int(property.get("type", TYPE_NIL))
		if property_type != TYPE_ARRAY and property_type != TYPE_DICTIONARY:
			continue
		var property_name := StringName(property.get("name", &""))
		if property_name == &"":
			continue
		var value: Variant = game.get(property_name)
		if value is Array or value is Dictionary:
			result[String(property_name)] = value.size()
		if value is Array:
			var nested_sizes: Dictionary = {}
			for item_value in value:
				if not item_value is Dictionary:
					continue
				var item: Dictionary = item_value
				for nested_key in item:
					var nested_value: Variant = item[nested_key]
					if nested_value is Array or nested_value is Dictionary:
						nested_sizes[String(nested_key)] = int(nested_sizes.get(String(nested_key), 0)) + nested_value.size()
			for nested_key in nested_sizes:
				result["%s[].%s" % [String(property_name), nested_key]] = int(nested_sizes[nested_key])
	return result


func _resource_snapshot() -> Dictionary:
	return {
		"static_mb": snappedf(float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0, 0.01),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"vram_mb": snappedf(float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / 1048576.0, 0.01)
	}


func _sample_collections() -> void:
	var sizes := _collection_sizes()
	if collection_start.is_empty():
		collection_start = sizes.duplicate()
	for key in sizes:
		collection_max[key] = maxi(int(collection_max.get(key, 0)), int(sizes[key]))


func _percentile(values: Array, ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(round(float(sorted.size() - 1) * ratio)), 0, sorted.size() - 1)])


func _run() -> void:
	_fixture()
	for _frame in range(90):
		await process_frame
	_sample_collections()
	resource_start = _resource_snapshot()
	var started_usec := Time.get_ticks_usec()
	var previous_frame_usec := started_usec
	var next_sample := SAMPLE_INTERVAL_SECONDS
	var next_forced_kill := 0.75
	while float(Time.get_ticks_usec() - started_usec) / 1000000.0 < duration_seconds:
		if disable_autosave:
			game.interrupted_run_autosave_timer = 1000000000.0
		if disable_progress_persistence:
			_neutralize_progress_persistence()
		if cycling_kills:
			game.heal_orbs.clear()
			while game.enemies.size() < ENEMY_COUNT:
				var spawn_index: int = int(game.enemies.size())
				var angle := float(spawn_index) * TAU / float(ENEMY_COUNT) + float(game.enemies_killed % 17) * 0.13
				game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(angle) * 250.0)
				var replacement: Dictionary = game.enemies[-1]
				replacement["hp"] = 18.0
				replacement["max_hp"] = 18.0
				replacement["speed"] = 42.0
				replacement["damage"] = 0.0
		await process_frame
		var now_usec := Time.get_ticks_usec()
		var elapsed := float(now_usec - started_usec) / 1000000.0
		if cycling_kills and elapsed >= next_forced_kill and not game.enemies.is_empty():
			var victim: Dictionary = game.enemies[0]
			victim["hp"] = 0.0
			game._kill_enemy(victim)
			next_forced_kill += 0.75
			if disable_progress_persistence:
				_neutralize_progress_persistence()
		var minute_index := clampi(int(floor(elapsed / 60.0)), 0, 2)
		frame_samples_by_minute[minute_index].append(float(now_usec - previous_frame_usec) / 1000.0)
		previous_frame_usec = now_usec
		if elapsed >= next_sample:
			_sample_collections()
			print("SINGLEPLAYER_LONG_RUN_SAMPLE variant=%s elapsed=%.1f resources=%s" % [_variant_name(), elapsed, JSON.stringify(_resource_snapshot())])
			next_sample += SAMPLE_INTERVAL_SECONDS
	_sample_collections()
	resource_end = _resource_snapshot()
	var collection_end := _collection_sizes()
	var growth: Dictionary = {}
	for key in collection_end:
		var delta := int(collection_end[key]) - int(collection_start.get(key, 0))
		var peak_delta := int(collection_max.get(key, 0)) - int(collection_start.get(key, 0))
		if delta > 2 or peak_delta > 16:
			growth[key] = {"start": int(collection_start.get(key, 0)), "end": int(collection_end[key]), "max": int(collection_max.get(key, 0))}
	var pacing: Array = []
	for minute_index in range(3):
		var minute_samples: Array = frame_samples_by_minute[minute_index]
		pacing.append({
			"minute": minute_index + 1,
			"frames": minute_samples.size(),
			"p50_ms": snappedf(_percentile(minute_samples, 0.50), 0.01),
			"p95_ms": snappedf(_percentile(minute_samples, 0.95), 0.01),
			"max_ms": snappedf(_percentile(minute_samples, 1.0), 0.01)
		})
	print("SINGLEPLAYER_LONG_RUN_ACCUMULATION_OK variant=%s duration=%.1f kills=%d pacing=%s resource_start=%s resource_end=%s growth=%s" % [
		_variant_name(),
		duration_seconds,
		int(game.enemies_killed),
		JSON.stringify(pacing),
		JSON.stringify(resource_start),
		JSON.stringify(resource_end),
		JSON.stringify(growth)
	])
	_cleanup(0)


func _variant_name() -> String:
	var suffix := "_cycling_kills" if cycling_kills else ""
	if disable_progress_persistence:
		return "no_progress_persistence" + suffix
	if disable_autosave:
		return "no_autosave" + suffix
	return "baseline" + suffix


func _neutralize_progress_persistence() -> void:
	game.player_progress_applying_snapshot = true
	game.player_progress_pending_events.clear()
	game.player_progress_pending_unlock_index.clear()
	game.player_progress_deferred_unlock_progress.clear()
	game.player_progress_sync_sent_event_ids.clear()
	game.player_progress_quarantined_events.clear()
	game.card_unlock_save_timer = 1000000000.0
	game.card_unlocks_dirty = false
