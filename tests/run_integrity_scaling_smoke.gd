extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("RUN_INTEGRITY_SCALING_SMOKE_FAIL " + message)
	_cleanup(1)


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.enemies.clear()
		game.enemy_bullets.clear()
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _spawn_and_kill_common(uid: int) -> void:
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(160 + uid % 8 * 36, 170 + uid % 5 * 30))
	_check(not game.enemies.is_empty(), "enemy did not spawn")
	var enemy: Dictionary = game.enemies.back()
	game._kill_enemy(enemy)


func _run() -> void:
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.online_connected = false
	game.forced_initial_phase = 1
	game._start_game()
	game.mode = "game"
	game.current_phase = 1
	game.phase_started_at = 0.0
	game.time_alive = 180.0
	game.elapsed_unpaused = 180.0
	game.enemies.clear()
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_name = "SMOKE_BOSS"
	game.boss_hp_max = 100.0
	game.boss_hp = 1.0
	var base_limit: int = game._enemy_limit()

	game._damage_boss(999.0, "smoke", false, false)
	_check(game.boss_dead, "boss did not die")
	_check(game.enemy_scaling_unlocked, "boss death did not unlock scaling")
	_check(String(game.enemy_scaling_unlock_reason) == game.ENEMY_SCALING_UNLOCK_REASON_BOSS, "boss scaling reason wrong")
	_check(game._enemy_limit() == base_limit, "boss death changed limit before normal kills")

	game.spawn_timer = 0.0
	game.enemies.clear()
	game._spawn_wave()
	_check(game.enemies.size() > 0, "normal spawn stayed blocked after boss death")
	game.enemies.clear()

	for i in range(19):
		_spawn_and_kill_common(1000 + i)
	_check(game._enemy_limit() == base_limit, "limit increased before 20 normal kills")
	_spawn_and_kill_common(2000)
	_check(game._enemy_limit() == base_limit + 1, "limit did not increase at 20 normal kills")

	var anchor_before: int = game.enemy_scaling_unlock_kill_anchor
	var reason_before := String(game.enemy_scaling_unlock_reason)
	game._register_boss_defeated_for_scaling(1)
	game._sync_enemy_limit_scaling_state()
	_check(game.enemy_scaling_unlock_kill_anchor == anchor_before, "duplicate boss death reset kill anchor")
	_check(String(game.enemy_scaling_unlock_reason) == reason_before, "duplicate unlock changed reason")

	game.time_alive = game.PHASE1_LIMIT_BREAK_TIME + 1.0
	game._sync_enemy_limit_scaling_state()
	_check(game.enemy_scaling_unlock_kill_anchor == anchor_before, "time unlock duplicated boss unlock")

	game.score += 77777
	_check(not game._debug_integrity_validate_now(), "score tamper was not detected")

	game.forced_initial_phase = 1
	game._start_game()
	game.mode = "game"
	var counter = game.rt_integrity.protected_values["score_current"]
	counter._encoded += 31
	_check(not game._debug_integrity_validate_now(), "protected counter tamper was not detected")

	print("RUN_INTEGRITY_SCALING_SMOKE_OK boss_unlock=true post_boss_spawn=true limit_20_kills=true tamper_detected=true")
	_cleanup(0)
