extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS1_CRONOGUEJO_AUDIO_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _configure_phase1() -> void:
	game._start_game()
	game.current_phase = 1
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 3000.0
	game.boss_hp = 3000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(360.0, 0.0)
	game.player_hp_max = 450
	game.player_hp = 450
	game.boss_entry_timer = 0.0
	game.boss_stage_timer = 0.0
	game.boss_attacks.clear()
	game.boss_transition_waves.clear()
	game.boss1_time_wave.clear()
	game.boss1_rewind_sequence.clear()
	game.boss1_absorb_timer = 0.0
	game.boss1_absorb_cooldown = 99.0
	game.boss1_absorb_damage = 0.0
	game.boss1_absorb_bursts_fired = 0


func _check_audio_keys() -> void:
	for key in [
		"boss1_anti_bubble",
		"boss1_dash",
		"boss1_absorb_end",
		"boss1_tide_near",
		"boss1_spin",
		"boss1_bubble_hit",
		"boss1_pre_stop",
		"boss1_entry_fall",
		"boss1_stop_loop"
	]:
		_check(game._audio_key_available(key), "missing registered audio key " + key)


func _run() -> void:
	_configure_phase1()
	_check_audio_keys()

	game._add_boss_bubble(game.player_pos)
	_check(game.boss_attacks.size() == 1, "bubble attack was not queued")
	_check(float(game.boss_attacks[0].get("age", 0.0)) <= -game.BOSS1_BUBBLE_WARNING_LEAD + 0.01, "bubble warning lead was not scheduled")
	game._update_boss_attacks(game.BOSS1_BUBBLE_WARNING_LEAD + 0.02)
	_check(bool(game.boss_attacks[0].get("start_sfx_played", false)), "bubble execution sfx did not trigger after warning lead")

	_configure_phase1()
	var tide := {"kind": "tide", "age": 2.1, "duration": 4.2, "horizontal": true, "positive": true, "hit": false}
	var line: float = game._boss_tide_line(tide)
	game.player_pos = Vector2(game.WORLD_SIZE.x * 0.5, line + game.BOSS1_TIDE_NEAR_SFX_DISTANCE - 12.0)
	game.boss_attacks = [tide]
	game._update_boss_attacks(0.02)
	_check(bool(game.boss_attacks[0].get("near_sfx_played", false)), "horizontal tide near-player sfx did not trigger")

	_configure_phase1()
	game._add_boss_rush()
	_check(game.boss_attacks.size() == 1, "rush attack was not queued")
	game.boss_attacks[0]["age"] = float(game.boss_attacks[0].get("warn", 0.62)) + game.BOSS1_DASH_SFX_DELAY - 0.01
	game._update_boss_attacks(0.03)
	_check(bool(game.boss_attacks[0].get("dash_sfx_played", false)), "dash sfx did not trigger 200ms after dash")

	_configure_phase1()
	game._play_boss1_pre_stop_warning()
	_check(game.boss1_stop_pre_played, "pre-stop warning flag was not set")
	_check(game.boss1_stop_music_duck_active, "pre-stop did not start music duck")
	game._start_boss1_absorb()
	_check(game.boss1_absorb_stop_started, "absorb stop loop flag was not set")
	_check(game.boss1_absorb_timer > 0.0, "absorb did not start")
	game.boss1_absorb_timer = game.BOSS1_STOP_END_LEAD
	game._update_boss1_absorb(0.05)
	_check(game.boss1_absorb_end_sfx_played, "absorb ending sfx did not trigger 500ms before end")
	game.boss1_absorb_timer = 0.05
	game._update_boss1_absorb(0.10)
	_check(game.boss1_absorb_cooldown == game.BOSS1_ABSORB_COOLDOWN, "absorb cooldown did not reset after finish")
	_check(game.boss1_stop_music_duck_mode == "in", "music duck did not switch to restore mode after absorb")

	print("BOSS1_CRONOGUEJO_AUDIO_SMOKE_OK keys=true bubble_warning=true tide=true dash=true absorb=true")
	quit(0)
