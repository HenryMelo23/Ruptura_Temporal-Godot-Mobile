extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game._advance_to_phase(4)
	game.mode = "game"
	game.current_phase = 4
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 12000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.boss4_entry_target
	game.player_hp_max = 1000000.0
	game.player_hp = game.player_hp_max
	game.player_defense = 100000.0
	game.player_pos = Vector2(520.0, 450.0)
	game.boss4_controller.reset()
	var frames := 1800
	var delta := 1.0 / 60.0
	var seen_stages: Dictionary = {}
	var max_displacement := 0.0
	var started := Time.get_ticks_usec()
	for frame in range(frames):
		if frame == 450:
			game.boss_hp = game.boss_hp_max * 0.70
		elif frame == 900:
			game.boss_hp = game.boss_hp_max * 0.45
		elif frame == 1350:
			game.boss_hp = game.boss_hp_max * 0.20
		game._update_boss_phase4(delta)
		game._update_phase4_enemy_hazards(delta)
		game._update_enemy_bullets(delta)
		game._update_effects(delta)
		seen_stages[game.boss4_stage] = true
		max_displacement = maxf(max_displacement, game.boss_pos.distance_to(game.boss4_entry_target))
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var average_us := elapsed_ms * 1000.0 / float(frames)
	assert(seen_stages.has(1) and seen_stages.has(2) and seen_stages.has(3) and seen_stages.has(4))
	assert(max_displacement > 40.0)
	assert(game.phase4_enemy_hazards.size() < 160)
	assert(game.enemy_bullets.size() < 80)
	print("BOSS4_CONTINUOUS_PERFORMANCE_OK simulated=30s frames=1800 elapsed_ms=%.2f avg_update_us=%.2f max_displacement=%.1f hazards=%d bullets=%d" % [elapsed_ms, average_us, max_displacement, game.phase4_enemy_hazards.size(), game.enemy_bullets.size()])
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
	for frame in range(4):
		await process_frame
	quit(0)
