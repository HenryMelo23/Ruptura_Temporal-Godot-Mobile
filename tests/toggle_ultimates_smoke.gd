extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("TOGGLE_ULTIMATES_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.time_alive = 100.0
	game.player_hp_max = 1000.0
	game.player_hp = 1000
	game.manifestation_key = "eletrica"
	_check(is_equal_approx(float(game._secondary_skill_cooldown()), 10.0), "electric_ultimate_cooldown_should_be_10s")
	game.last_secondary_time = -999.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(100.0, 0.0))
	game.enemies[0]["hp"] = 100000.0

	var cooldown_before = game.last_secondary_time
	game._use_secondary_skill()
	_check(not game._active_eletrica_secondary().is_empty(), "electric_ultimate_not_started")
	_check(game.last_secondary_time == cooldown_before, "electric_start_should_not_begin_cooldown")
	var electric = game._active_eletrica_secondary()
	var enemy_hp_before = float(game.enemies[0]["hp"])
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_DELAY)
	_check(game.player_hp == 1000, "electric_drained_before_tension_max")
	var safe_progress := clampf(game.SECONDARY_ELETRICA_DRAIN_DELAY / game.SECONDARY_ELETRICA_DRAIN_DELAY, 0.0, 1.0)
	var expected_shock_damage = float(game.enemies[0]["max_hp"]) * game.SECONDARY_ELETRICA_SHOCK_MAX_HP_RATE * (1.0 + 0.15 * safe_progress) + game.player_damage * game.SECONDARY_ELETRICA_SHOCK_DAMAGE_RATE * (1.0 + 0.25 * safe_progress)
	_check(is_equal_approx(float(game.enemies[0]["hp"]), enemy_hp_before - expected_shock_damage), "electric_shock_damage_changed")
	_check(float(game.enemies[0]["stun"]) >= game.SECONDARY_ELETRICA_SHOCK_STUN, "electric_stun_missing")
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_INTERVAL)
	_check(game.player_hp == 990, "electric_first_drain_tick_wrong")
	_check(game.secondary_drain_flash_timer > 0.0, "electric_drain_flash_missing")
	game._update_secondary_eletrica(electric, game.SECONDARY_ELETRICA_DRAIN_INTERVAL)
	_check(game.player_hp == 981, "electric_second_drain_tick_wrong")

	game.time_alive += game.SECONDARY_ELETRICA_DRAIN_DELAY + game.SECONDARY_ELETRICA_DRAIN_INTERVAL * 2.0
	game._use_secondary_skill()
	_check(game._active_eletrica_secondary().is_empty(), "electric_cancel_failed")
	_check(is_equal_approx(game.last_secondary_time, game.time_alive), "electric_cancel_did_not_start_cooldown")
	var electric_cancel_time = game.last_secondary_time
	game._use_secondary_skill()
	_check(game._active_eletrica_secondary().is_empty(), "electric_restarted_during_cooldown")
	_check(game.last_secondary_time == electric_cancel_time, "electric_cooldown_stamp_changed")

	game.manifestation_secondaries.clear()
	game.time_alive += game._secondary_skill_cooldown() + 0.1
	game._use_secondary_skill()
	_check(not game._active_eletrica_secondary().is_empty(), "electric_restart_after_cooldown_failed")
	game.enemies.clear()
	game.time_alive += 3.1
	game._update_manifestation_secondaries(3.1)
	_check(game._active_eletrica_secondary().is_empty(), "electric_should_auto_finish_without_targets")
	game.time_alive += game._secondary_skill_cooldown() + 0.1
	game._use_secondary_skill()
	_check(not game._active_eletrica_secondary().is_empty(), "electric_restart_after_empty_finish_failed")
	game._use_secondary_skill()
	_check(game._active_eletrica_secondary().is_empty(), "electric_manual_cancel_after_empty_failed")
	_check(is_equal_approx(game.last_secondary_time, game.time_alive), "electric_empty_manual_cancel_cooldown_wrong")

	game.manifestation_secondaries.clear()
	game.manifestation_key = "prismatica"
	game.time_alive += game.SECONDARY_SKILL_COOLDOWN + 0.1
	var prism_cooldown_before = game.last_secondary_time
	game._use_secondary_skill()
	_check(not game._active_prismatica_secondary().is_empty(), "prism_start_failed")
	_check(game.last_secondary_time != prism_cooldown_before, "prism_start_did_not_stamp")
	game.player_hp = 777
	game._damage_player(250, "smoke_prismatica")
	_check(game.player_hp == 777, "prism_invulnerability_missing")
	var prism_activation_time = game.last_secondary_time
	game._use_secondary_skill()
	_check(game._active_prismatica_secondary().is_empty(), "prism_cancel_failed")
	_check(is_equal_approx(game.last_secondary_time, prism_activation_time), "prism_cancel_should_keep_stamp")

	game.manifestation_secondaries.clear()
	game.time_alive += game.SECONDARY_SKILL_COOLDOWN + 0.1
	game._use_secondary_skill()
	_check(not game._active_prismatica_secondary().is_empty(), "prism_restart_failed")
	var prism_second_activation_time = game.last_secondary_time
	game.time_alive += game.SECONDARY_PRISMATICA_DURATION + 0.1
	game._update_manifestation_secondaries(game.SECONDARY_PRISMATICA_DURATION + 0.1)
	_check(game._active_prismatica_secondary().is_empty(), "prism_duration_finish_failed")
	_check(is_equal_approx(game.last_secondary_time, prism_second_activation_time), "prism_duration_stamp_changed")

	print("TOGGLE_ULTIMATES_SMOKE_OK electric_tick=0.4s electric_drain_after=18s cancel=true cooldown_on_stop=true prism_cancel=true")
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
