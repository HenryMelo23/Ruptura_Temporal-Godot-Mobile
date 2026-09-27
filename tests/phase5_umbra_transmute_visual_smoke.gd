extends SceneTree

const OUT_DIR := "res://.codex/umbra_transmute"

const CASES := [
	{"action": "TRANSMUTAR_VORTICE", "dimension": "vortice", "skill": "VORTICE", "kind": "vortex"},
	{"action": "TRANSMUTAR_GRAVIDADE", "dimension": "gravidade", "skill": "PRISAO", "kind": "sopro_artico"},
	{"action": "TRANSMUTAR_NECROSE", "dimension": "necrose", "skill": "MIASMA", "kind": "miasma"},
	{"action": "TRANSMUTAR_RESSONANCIA", "dimension": "ressonancia", "skill": "DESCARGA_ELETRICA", "kind": "discharge"},
	{"action": "TRANSMUTAR_HEMORRAGIA", "dimension": "hemorragia", "skill": "CAMINHO_ESPINHOS", "kind": "thorns"},
	{"action": "TRANSMUTAR_ATRITO", "dimension": "atrito", "skill": "LASER_SOBRECARGA", "kind": "umbra_overload_laser"},
	{"action": "TRANSMUTAR_RASTRO", "dimension": "rastro", "skill": "PRAGA_RATOS", "kind": "rats"},
]

var game: Node
var captures: Array[String] = []
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fail(message: String) -> void:
	failed = true
	push_error("PHASE5_UMBRA_TRANSMUTE_VISUAL_FAIL " + message)


func _assert_ok(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _run() -> void:
	await process_frame
	var display_name := DisplayServer.get_name().to_lower()
	if display_name.contains("headless"):
		print("PHASE5_UMBRA_TRANSMUTE_VISUAL_SKIP display=" + display_name)
		_cleanup()
		quit(0)
		return

	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_setup_boss5_arena()
	game.set_process(false)
	game.set_physics_process(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	_assert_transmute_availability()
	for case in CASES:
		await _exercise_case(Dictionary(case))
		if failed:
			break

	_assert_ok(captures.size() == CASES.size() * 2, "not all map/skill paths reached capture")
	print("PHASE5_UMBRA_TRANSMUTE_VISUAL_%s cooldown=%.1fs captures=%d" % ["FAIL" if failed else "OK", game.BOSS5_TRANSMUTE_COOLDOWN, captures.size()])
	_cleanup()
	for _i in range(3):
		await process_frame
	quit(1 if failed else 0)


func _setup_boss5_arena() -> void:
	game._start_game()
	game._finish_startup_thanks()
	game._advance_to_phase(5)
	game.mode = "game"
	game.current_phase = 5
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_name = "UMBRA"
	game.boss_hp_max = 22000.0
	game.boss_hp = game.boss_hp_max
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.screen_shake_timer = 0.0
	game.screen_shake_strength = 0.0
	game.time_alive = 180.0
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(-210, 112)
	game.boss_pos = game.WORLD_SIZE * 0.5 + Vector2(210, -84)
	game.boss5_target = game.boss_pos
	game.phase5_player_history.clear()
	for i in range(8):
		game.phase5_player_history.append(game.player_pos + Vector2(i * 14, sin(float(i)) * 22.0))
	game._load_umbra_mobile_memory()


func _assert_transmute_availability() -> void:
	_reset_case_state()
	var available: Array = game._umbra_available_actions()
	for case in CASES:
		_assert_ok(available.has(case["action"]), "missing available transmutation " + case["action"])
	var decision := String(game._umbra_choose_action())
	_assert_ok(available.has(decision), "AI selected an unavailable action " + decision)


func _reset_case_state() -> void:
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.phase5_telegraphs.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.boss5_dimension = "base"
	game.boss5_last_dimension = ""
	game.boss5_dimension_timer = 0.0
	game.phase5_transmute_active = false
	game.phase5_transmute_timer = 0.0
	game.phase5_transmute_particles.clear()
	game.boss5_transmute_hangover = 0.0
	game.boss5_cadence_bonus = 0.0
	game.boss5_rat_extras = 0
	game.boss5_siphon_timer = 0.0
	game.boss5_decision_timer = 1000.0
	game.boss5_action_timer = 1000.0
	game.boss5_transmute_cooldown = 0.0
	for key in game.boss5_ability_cooldowns.keys():
		game.boss5_ability_cooldowns[key] = 0.0


func _exercise_case(case: Dictionary) -> void:
	_reset_case_state()
	var action := String(case["action"])
	var dimension := String(case["dimension"])
	var skill := String(case["skill"])
	var kind := String(case["kind"])

	_assert_ok(game._umbra_available_actions().has(action), action + " should be available before casting")
	game._spawn_umbra_action(action)
	_assert_ok(game.boss5_dimension == dimension, action + " did not set dimension=" + dimension)
	var surface_key := String(game._boss5_dimension_map_key(dimension))
	_assert_ok(surface_key != "map_phase_5", action + " did not choose a transmuted map surface")
	_assert_ok(game._get_texture(surface_key) != null, action + " transmuted map texture is missing: " + surface_key)
	_assert_ok(game._current_map_texture() == game._get_texture(surface_key), action + " did not swap current map surface to " + surface_key)
	_assert_ok(absf(float(game.boss5_transmute_cooldown) - float(game.BOSS5_TRANSMUTE_COOLDOWN)) < 0.01, action + " did not start configured cooldown")
	_assert_ok(not game._umbra_available_actions().has(action), action + " should be blocked during cooldown/current dimension")
	_assert_ok(not game._umbra_available_actions().has(skill), dimension + " should respect post-transmutation hangover")
	await _capture(dimension + "_transicao", "mapa")

	_tick_boss_timers(float(game.boss5_transmute_hangover) + 0.01)
	_assert_ok(game._umbra_available_actions().has(skill), dimension + " should expose skill after hangover: " + skill)

	game._spawn_umbra_action(skill)
	_validate_skill_spawn(skill, kind)
	for _i in range(18):
		game._update_phase5_hazards(1.0 / 60.0)
		game._update_phase5_rats(1.0 / 60.0)
	await _capture(dimension, skill)
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.phase5_telegraphs.clear()
	var halfway: float = game.boss5_transmute_cooldown * 0.5
	_tick_boss_timers(halfway)
	_assert_ok(absf(float(game.boss5_transmute_cooldown) - halfway) < 0.01, action + " cooldown did not tick halfway")
	_tick_boss_timers(halfway + 0.01)
	_assert_ok(float(game.boss5_transmute_cooldown) <= 0.01, action + " cooldown did not finish")


func _tick_boss_timers(seconds: float) -> void:
	# Exercise real timers without allowing movement/contact to alter cadence.
	var old_pos: Vector2 = game.boss_pos
	var old_target: Vector2 = game.boss5_target
	game.boss_entry_timer = seconds + 1.0
	game._update_boss_phase5(seconds)
	game.boss_entry_timer = 0.0
	game.boss_pos = old_pos
	game.boss5_target = old_target


func _validate_skill_spawn(skill: String, kind: String) -> void:
	if kind == "rats":
		_assert_ok(game.phase5_rats.size() == 4, skill + " should spawn the four initial corner rats")
		var corners: Array = []
		for rat in game.phase5_rats:
			if not corners.has(rat["corner_idx"]):
				corners.append(rat["corner_idx"])
		_assert_ok(corners.size() == 4, skill + " did not cover every corner")
		return
	var found := false
	for hazard in game.phase5_hazards:
		var data := Dictionary(hazard)
		if String(data.get("kind", "")) != kind:
			continue
		found = true
		break
	_assert_ok(found, skill + " did not spawn hazard kind=" + kind)


func _capture(dimension: String, skill: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_assert_ok(image != null and not image.is_empty(), "empty viewport for " + dimension)
	var output := "%s/%s_%s.png" % [OUT_DIR, dimension, skill.to_lower()]
	var absolute := ProjectSettings.globalize_path(output)
	_assert_ok(image.save_png(absolute) == OK, "could not save screenshot " + absolute)
	captures.append(absolute)
	print("UMBRA_TRANSMUTE_CAPTURE dimension=%s skill=%s path=%s" % [dimension, skill, absolute])


func _cleanup() -> void:
	if game == null:
		return
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	if "music_player" in game and game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if "rain_audio_player" in game and game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	if "sfx_players" in game:
		for player in game.sfx_players:
			if player != null:
				player.stop()
				player.stream = null
	if "textures" in game:
		game.textures.clear()
	if "audio_streams" in game:
		game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
	game = null
