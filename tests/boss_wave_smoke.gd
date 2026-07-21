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
	assert(is_equal_approx(float(wave["open_size"]), game.BOSS_STAGE_WAVE_OPENING))

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
	assert(game.player_hp <= 384.0)

	game.boss_stage_timer = 0.0
	var radius_before = float(wave["radius"])
	game._update_boss_transition_waves(0.25)
	assert(float(wave["radius"]) > radius_before)

	game._start_boss_stage()
	game.boss_stage_safe_angle = 0.0
	game._update_boss_stage(game.BOSS_STAGE_SLAM_TIME + game.BOSS_STAGE_WAVE_INTERVAL * 3.0 + 0.02)
	assert(game.boss_transition_waves.size() == game.BOSS_STAGE_WAVE_COUNT)
	assert(game.boss_transition_waves.all(func(item): return String(item.get("kind", "")) == "dupla_abertura"))
	for index in range(1, game.boss_transition_waves.size()):
		var previous_angle := float(game.boss_transition_waves[index - 1]["open_angle"])
		var current_angle := float(game.boss_transition_waves[index]["open_angle"])
		assert(abs(wrapf(current_angle - previous_angle, -PI, PI)) >= PI * 0.40)

	game.boss_hp = game.boss_hp_max * 0.20
	game._start_boss_stage()
	game.boss_stage_safe_angle = 0.0
	game._update_boss_stage(game.BOSS_STAGE_SLAM_TIME + game.BOSS_STAGE_ENRAGED_WAVE_INTERVAL * 4.0 + 0.02)
	assert(game.boss_transition_waves.size() == game.BOSS_STAGE_ENRAGED_WAVE_COUNT)
	var enraged_wave: Dictionary = game.boss_transition_waves[0]
	assert(bool(enraged_wave["enraged"]))
	assert(is_equal_approx(float(enraged_wave["open_size"]), game.BOSS_STAGE_ENRAGED_OPENING))
	enraged_wave["age"] = float(enraged_wave["warning"])
	enraged_wave["radius"] = 220.0
	game.player_hp = 450.0
	game.player_pos = game.boss_pos + Vector2.DOWN * 220.0
	game._update_boss_transition_waves(0.0)
	assert(game.player_hp < 450.0 and game.player_hp > 400.0)
	assert(game.boss_wave_slow_timer >= game.BOSS_STAGE_ENRAGED_SLOW_TIME - 0.01)
	assert(game._environment_player_slow_mult() <= 0.38)
	var enraged_opening_degrees := rad_to_deg(float(enraged_wave["open_size"]))

	game.enemies.clear()
	game.enemy_bullets.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(220, 220))
	game._spawn_enemy(game.ENEMY_STALKER, Vector2(320, 260))
	game.enemy_bullets.append({"pos": Vector2(300, 300), "life": 1.0})
	game.boss_active = false
	game.boss_ready = true
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game._start_boss_call()
	assert(game.enemies.is_empty())
	assert(game.enemy_bullets.is_empty())

	print("BOSS_WAVE_SMOKE_OK waves=%d speed=%.0f enraged_opening=%.1fdeg" % [
		game.boss_transition_waves.size(),
		game.BOSS_STAGE_WAVE_SPEED,
		enraged_opening_degrees
	])
	quit(0)
