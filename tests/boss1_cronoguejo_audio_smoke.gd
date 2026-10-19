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
		"boss1_stop_loop",
		"boss1_entry_announce",
		"boss1_death",
		"shop_spend"
	]:
		_check(game._audio_key_available(key), "missing registered audio key " + key)


func _sfx_was_played(key: String) -> bool:
	if not game.audio_streams.has(key):
		return false
	for player in game.sfx_players:
		if player.stream == game.audio_streams[key]:
			return true
	return false


func _run() -> void:
	_configure_phase1()
	_check_audio_keys()
	var boss1_playlist: Array = game._boss_music_tracks(1)
	var expected_boss1_playlist := ["Pendulum_of_Resolve.mp3", "The_Weight_of_the_Aftermath.mp3"]
	_check(boss1_playlist == expected_boss1_playlist, "Boss 1 playlist did not replace the retired track")
	for track in expected_boss1_playlist:
		_check(game._audio_key_available(track), "Boss 1 loop track was not registered: " + track)
	game._play_music(expected_boss1_playlist[0])
	if game.music_crossfade_active:
		game._finish_music_crossfade()
	game.boss_active = true
	game.boss_dead = false
	game._on_music_finished()
	if game.music_crossfade_active:
		game._finish_music_crossfade()
	_check(game.current_music in expected_boss1_playlist, "Boss 1 loop did not remain in its two-track playlist")
	game.boss_entry_timer = game.BOSS_ENTRY_TIME
	game.boss_empurrou_player = false
	game.boss1_entry_announce_sfx_played = false
	game._update_boss1_uninterruptible_state(0.24)
	_check(game.boss1_entry_announce_sfx_played, "entry announce did not fire one second before landing")
	_check(_sfx_was_played("boss1_entry_announce"), "entry announce sound was not emitted")
	game._update_boss1_uninterruptible_state(game.BOSS_ENTRY_TIME)
	_check(game.boss_empurrou_player, "entry landing did not resolve")
	_check(game.screen_shake_strength >= 24.0, "entry landing did not apply impact shake")
	_check(_sfx_was_played("boss_impact"), "entry landing did not emit the shared impact sound")

	_configure_phase1()
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game.boss_hp = 1.0
	game._damage_boss(10.0, "audio_smoke", false, false)
	_check(game.boss_dead, "boss death setup did not resolve")
	_check(_sfx_was_played("boss1_death"), "boss death sound was not emitted")

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
	game._play_music(expected_boss1_playlist[0])
	if game.music_crossfade_active:
		game._finish_music_crossfade()
	game._play_boss1_pre_stop_warning()
	_check(game.boss1_stop_pre_played, "pre-stop warning flag was not set")
	_check(game.boss1_stop_music_duck_active, "pre-stop did not start music duck")
	var music_bus: int = AudioServer.get_bus_index(RTAudioLifecycle.BOSS1_TIME_STOP_MUSIC_BUS)
	_check(music_bus >= 0, "time-stop music bus was not configured")
	_check(AudioServer.is_bus_effect_enabled(music_bus, 0), "time-stop low-pass filter was not enabled")
	game._update_boss1_stop_music_duck(game.BOSS1_STOP_MUSIC_FADE_TIME + 0.02)
	var expected_floor: float = game._music_target_volume() * game.BOSS1_STOP_MUSIC_AUDIBLE_FLOOR
	_check(db_to_linear(game.music_player.volume_db) >= expected_floor - 0.01, "time-stop music became inaudible instead of using its audible floor")
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
	game._update_boss1_stop_music_duck(game.BOSS1_STOP_MUSIC_FADE_TIME + 0.02)
	_check(not AudioServer.is_bus_effect_enabled(music_bus, 0), "time-stop low-pass filter stayed enabled after recovery")

	print("BOSS1_CRONOGUEJO_AUDIO_SMOKE_OK keys=true entry=true bubble_warning=true tide=true dash=true absorb=true muffled_music=true")
	game._stop_battle_music_for_screen_transition()
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	quit(0)
