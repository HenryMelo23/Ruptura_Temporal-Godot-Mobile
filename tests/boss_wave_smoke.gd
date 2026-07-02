extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_hp_max = 450.0
	game.player_hp = 450.0
	game._start_boss_stage()
	game.boss_stage_safe_angle = 0.0

	game._update_boss_stage(game.BOSS_STAGE_SLAM_TIME + 0.01)
	assert(game.boss_transition_waves.size() == 1)
	var wave: Dictionary = game.boss_transition_waves[0]
	assert(String(wave["kind"]) == "dupla_abertura")
	assert(is_equal_approx(float(wave["speed"]), game.BOSS_STAGE_WAVE_SPEED))
	assert(float(wave["open_size"]) >= PI * 0.47)

	wave["age"] = float(wave["warning"])
	wave["radius"] = 220.0
	game.player_pos = game.boss_pos + Vector2.RIGHT * 220.0
	game._update_boss_transition_waves(0.0)
	assert(is_equal_approx(game.player_hp, 450.0))
	assert(not bool(wave["hit"]))

	game.player_pos = game.boss_pos + Vector2.DOWN * 220.0
	game._update_boss_transition_waves(0.0)
	assert(game.player_hp < 450.0)
	assert(bool(wave["hit"]))

	game.boss_stage_timer = 0.0
	var radius_before = float(wave["radius"])
	game._update_boss_transition_waves(0.25)
	assert(float(wave["radius"]) > radius_before)

	game._start_boss_stage()
	game.boss_stage_safe_angle = 0.0
	game._update_boss_stage(game.BOSS_STAGE_SLAM_TIME + game.BOSS_STAGE_WAVE_INTERVAL * 2.0 + 0.02)
	assert(game.boss_transition_waves.size() == game.BOSS_STAGE_WAVE_COUNT)
	assert(game.boss_transition_waves.all(func(item): return String(item.get("kind", "")) == "dupla_abertura"))

	print("BOSS_WAVE_SMOKE_OK waves=%d speed=%.0f safe_opening=%.1fdeg" % [
		game.boss_transition_waves.size(),
		game.BOSS_STAGE_WAVE_SPEED,
		rad_to_deg(float(game.boss_transition_waves[0]["open_size"]))
	])
	quit(0)
