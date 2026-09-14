extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PRISMATICA_TOGGLE_REGRESSION_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == "prismatica":
			game.selected_manifestation = i
			break
	game.manifestation_key = "prismatica"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 100.0
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	_check(not game._active_prismatica_secondary().is_empty(), "ultimate_not_active")
	var activation_time := float(game.last_secondary_time)
	game.player_hp = 777
	game._damage_player(250, "smoke_prismatica")
	_check(game.player_hp == 777, "ultimate_invulnerability_missing")
	game._damage_player(250, "boss4_ultimate")
	_check(game.player_hp == 777, "boss_ultimate_bypassed_prismatica")
	game._use_secondary_skill()
	_check(game._active_prismatica_secondary().is_empty(), "ultimate_cancel_failed")
	_check(is_equal_approx(float(game.last_secondary_time), activation_time), "cancel_should_not_restart_cooldown")
	_check(not game.prismatica_ultimate_audio_player.playing, "song_did_not_stop_on_cancel")

	game.manifestation_secondaries.clear()
	game.time_alive += game.SECONDARY_SKILL_COOLDOWN + 0.1
	game._use_secondary_skill()
	_check(not game._active_prismatica_secondary().is_empty(), "ultimate_reactivation_failed")
	var second_activation := float(game.last_secondary_time)
	game.time_alive += game.SECONDARY_PRISMATICA_DURATION + 0.1
	game._update_manifestation_secondaries(game.SECONDARY_PRISMATICA_DURATION + 0.1)
	_check(game._active_prismatica_secondary().is_empty(), "ultimate_did_not_expire")
	_check(is_equal_approx(float(game.last_secondary_time), second_activation), "expiration_should_not_restart_cooldown")
	_check(not game.prismatica_ultimate_audio_player.playing, "song_did_not_stop_on_expiration")

	print("PRISMATICA_TOGGLE_REGRESSION_OK duration=10s cancel=true expire=true")
	quit(0)
