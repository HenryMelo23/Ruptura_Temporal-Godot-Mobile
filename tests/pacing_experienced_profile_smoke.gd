extends SceneTree

var game: Node
var failures: Array[String] = []
var original_profile_text: String = ""
var had_original_profile: bool = false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _backup_profile() -> void:
	had_original_profile = FileAccess.file_exists(game.PLAYER_PROFILE_PATH)
	if not had_original_profile:
		original_profile_text = ""
		return
	var file := FileAccess.open(game.PLAYER_PROFILE_PATH, FileAccess.READ)
	if file != null:
		original_profile_text = file.get_as_text()
		file.close()


func _restore_profile() -> void:
	if had_original_profile:
		var file := FileAccess.open(game.PLAYER_PROFILE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(original_profile_text)
			file.close()
	elif FileAccess.file_exists(game.PLAYER_PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.PLAYER_PROFILE_PATH))


func _mark_valid_run_from(seconds: float) -> void:
	game.mode = "game"
	game.time_alive = seconds
	game._update_valid_run_progress()


func _run() -> void:
	_backup_profile()
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.online_local_spectator = false
	game.current_phase = 1
	game.phase_started_at = 0.0

	game.player_valid_runs_completed = 0
	game._reset_run_pacing_state()
	_check(game.run_pacing_profile == game.PACING_PROFILE_ONBOARDING, "first valid run must use onboarding pacing")
	_check(is_equal_approx(game._larapio_base_spawn_time(), game.LARAPIO_SPAWN_TIME), "onboarding Larapio time changed")
	_check(is_equal_approx(game._arauto_spawn_time(), game.ARAUTO_SPAWN_TIME), "onboarding Arauto time changed")
	_check(is_equal_approx(game._phase1_stalker_unlock_time(), game.PHASE1_STALKER_UNLOCK_TIME), "onboarding phase 1 stalker unlock changed")
	_mark_valid_run_from(game.PACING_VALID_RUN_THRESHOLD_SECONDS - 0.5)
	_check(game.player_valid_runs_completed == 0, "short restart counted as a valid run")
	_mark_valid_run_from(game.PACING_VALID_RUN_THRESHOLD_SECONDS)
	_check(game.player_valid_runs_completed == 1, "first valid run was not persisted in the counter")
	_mark_valid_run_from(game.PACING_VALID_RUN_THRESHOLD_SECONDS + 10.0)
	_check(game.player_valid_runs_completed == 1, "same run incremented valid counter twice")

	game.player_valid_runs_completed = 1
	game._reset_run_pacing_state()
	_check(game.run_pacing_profile == game.PACING_PROFILE_ONBOARDING, "second valid run must still use onboarding pacing")
	_mark_valid_run_from(game.PACING_VALID_RUN_THRESHOLD_SECONDS)
	_check(game.player_valid_runs_completed == 2, "second valid run was not counted")

	game._reset_run_pacing_state()
	_check(game.run_pacing_profile == game.PACING_PROFILE_EXPERIENCED, "third run must use experienced pacing")
	_check(is_equal_approx(game._larapio_base_spawn_time(), game.PACING_EXPERIENCED_LARAPIO_SPAWN_TIME), "experienced Larapio target mismatch")
	_check(is_equal_approx(game._arauto_spawn_time(), game.PACING_EXPERIENCED_ARAUTO_SPAWN_TIME), "experienced Arauto target mismatch")
	_check(is_equal_approx(game._phase1_stalker_unlock_time(), game.PACING_EXPERIENCED_FIRST_PRESSURE_TIME), "experienced first pressure timing mismatch")
	_check(is_equal_approx(game._phase1_projector_unlock_time(), game.PHASE1_PROJECTOR_UNLOCK_TIME * game.PACING_EXPERIENCED_TIME_MULT), "experienced phase 1 projector timing mismatch")
	_check(is_equal_approx(game._phase2_kamikaze_unlock_time(), 45.0), "experienced phase 2 first pressure timing mismatch")
	_check(is_equal_approx(game._phase2_pyro_unlock_time(), 180.0), "experienced phase 2 pyro timing mismatch")
	_check(is_equal_approx(game._phase3_common_only_time(), game.PACING_EXPERIENCED_FIRST_PRESSURE_TIME), "experienced phase 3 first pressure timing mismatch")
	_check(is_equal_approx(game._phase3_guardiao_unlock_time(), 270.0), "experienced phase 3 guardiao timing mismatch")
	_check(is_equal_approx(game._phase4_adapt_time(), game.PACING_EXPERIENCED_FIRST_PRESSURE_TIME), "experienced phase 4 first pressure timing mismatch")

	game.run_pacing_first_special_enemy_time = -1.0
	game.run_pacing_first_special_enemy_kind = ""
	game.time_alive = 88.0
	game._record_pacing_enemy_spawn(game.ENEMY_COMMON)
	_check(game.run_pacing_first_special_enemy_time < 0.0, "common enemy was incorrectly recorded as first special")
	game._record_pacing_enemy_spawn(game.ENEMY_STALKER)
	_check(is_equal_approx(game.run_pacing_first_special_enemy_time, 88.0), "first special enemy time was not recorded")
	_check(game.run_pacing_first_special_enemy_kind == game.ENEMY_STALKER, "first special enemy kind was not recorded")

	game.run_pacing_larapio_first_time = -1.0
	game.run_pacing_arauto_first_time = -1.0
	game.time_alive = 120.0
	game.run_pacing_larapio_first_time = game.time_alive
	game.time_alive = 360.0
	game.run_pacing_arauto_first_time = game.time_alive
	var report: Dictionary = game._pacing_report()
	_check(String(report.get("profile", "")) == game.PACING_PROFILE_EXPERIENCED, "pacing report missing profile")
	_check(is_equal_approx(float(report.get("larapio_first_time", -1.0)), 120.0), "pacing report missing Larapio time")
	_check(is_equal_approx(float(report.get("arauto_first_time", -1.0)), 360.0), "pacing report missing Arauto time")

	game.player_valid_runs_completed = 4
	game._save_player_profile()
	game.player_valid_runs_completed = 0
	game._load_player_profile()
	_check(game.player_valid_runs_completed == 4, "valid run counter did not survive save/load")

	game.run_pacing_profile = game.PACING_PROFILE_ONBOARDING
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	game._apply_remote_boss_visual_snapshot({"pacing_profile": game.PACING_PROFILE_EXPERIENCED})
	_check(game.run_pacing_profile == game.PACING_PROFILE_EXPERIENCED, "client did not accept authority pacing profile")

	_restore_profile()
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
	assert(failures.is_empty(), "PACING_EXPERIENCED_PROFILE_SMOKE_FAILED")
	print("PACING_EXPERIENCED_PROFILE_SMOKE_OK onboarding_runs=2 valid_threshold=60s larapio=120s arauto=360s first_pressure=90s")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
