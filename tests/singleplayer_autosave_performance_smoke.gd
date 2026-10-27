extends SceneTree

const TRANSIENT_PROJECTILES := 1200
const TRANSIENT_EFFECTS := 1800
const TELEMETRY_EVENTS := 5000

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SINGLEPLAYER_AUTOSAVE_PERFORMANCE_FAIL " + message)
	_cleanup(1)


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


func _populate_late_run_fixture() -> void:
	for index in TRANSIENT_PROJECTILES:
		game.bullets.append({
			"p": Vector2(index % 120, index % 80),
			"v": Vector2(640.0, -32.0),
			"life": 1.4,
			"damage": 42.0,
			"source": "player_attack",
			"trail": [Vector2(index % 90, index % 70), Vector2(index % 91, index % 71)]
		})
	for index in TRANSIENT_EFFECTS:
		game.effects.append({
			"p": Vector2(index % 130, index % 95),
			"life": 0.45,
			"duration": 0.45,
			"kind": "projectile_trail",
			"color": Color(0.2, 0.9, 1.0, 0.8)
		})
	for index in TELEMETRY_EVENTS:
		game.run_damage_events.append({
			"time": float(index) * 0.2,
			"amount": 7.5,
			"source": "phase_enemy_projectile",
			"phase": 4,
			"position": Vector2(index % 200, index % 140)
		})


func _elapsed_ms(start_usec: int) -> float:
	return float(Time.get_ticks_usec() - start_usec) / 1000.0


func _run() -> void:
	game._start_game()
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.online_connected = false
	game.is_dead = false
	game.player_hp = maxf(1.0, float(game.player_hp_max))
	game.mode = "game"
	# The synthetic late-run payload intentionally omits renderer-only fields.
	game.preview_capture_mode = true
	game.visible = false
	game.set_process(false)
	_populate_late_run_fixture()

	var started := Time.get_ticks_usec()
	var snapshot: Dictionary = game._build_interrupted_run_snapshot()
	var build_ms := _elapsed_ms(started)
	started = Time.get_ticks_usec()
	var encoded := var_to_str(snapshot)
	var encode_ms := _elapsed_ms(started)
	started = Time.get_ticks_usec()
	var binary_encoded := var_to_bytes(snapshot)
	var binary_encode_ms := _elapsed_ms(started)
	started = Time.get_ticks_usec()
	var compact_snapshot: Dictionary = game.save_controller._build_interrupted_run_snapshot(true)
	var compact_build_ms := _elapsed_ms(started)
	started = Time.get_ticks_usec()
	var compact_binary := var_to_bytes(compact_snapshot)
	var compact_encode_ms := _elapsed_ms(started)
	game.interrupted_run_autosave_timer = 0.0
	started = Time.get_ticks_usec()
	game._update_interrupted_run_autosave(0.02)
	var dispatch_ms := _elapsed_ms(started)
	while game.save_controller.interrupted_run_save_thread != null:
		await process_frame
		game.save_controller._poll_interrupted_run_save(false)
	var save_ms := _elapsed_ms(started)
	var save_size := FileAccess.get_file_as_bytes(game.INTERRUPTED_RUN_SAVE_PATH).size()
	var loaded: Dictionary = game._load_interrupted_run_snapshot()

	_check(not snapshot.is_empty(), "snapshot was empty")
	_check(encoded.length() > 0, "snapshot encoding was empty")
	_check(FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "autosave file was not created")
	_check(bool(loaded.get("compact_autosave", false)), "periodic autosave did not use compact mode")
	var loaded_fields: Dictionary = loaded.get("fields", {})
	_check(not loaded_fields.has("bullets") and not loaded_fields.has("effects"), "transient combat visuals leaked into periodic autosave")
	_check(Array(loaded_fields.get("run_damage_events", [])).size() <= 256, "periodic autosave retained unbounded telemetry")
	_check(compact_binary.size() * 3 < binary_encoded.size(), "compact autosave did not materially reduce payload")
	print(
		"SINGLEPLAYER_AUTOSAVE_PERFORMANCE_OK legacy_build_ms=%.2f legacy_text_encode_ms=%.2f legacy_binary_encode_ms=%.2f legacy_text_bytes=%d legacy_binary_bytes=%d compact_build_ms=%.2f compact_encode_ms=%.2f autosave_dispatch_ms=%.2f autosave_total_ms=%.2f autosave_bytes=%d bullets=%d effects=%d telemetry=%d" % [
			build_ms,
			encode_ms,
			binary_encode_ms,
			encoded.to_utf8_buffer().size(),
			binary_encoded.size(),
			compact_build_ms,
			compact_encode_ms,
			dispatch_ms,
			save_ms,
			save_size,
			game.bullets.size(),
			game.effects.size(),
			game.run_damage_events.size()
		]
	)
	_cleanup(0)
