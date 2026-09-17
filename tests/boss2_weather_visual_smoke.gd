extends "res://tests/boss1_rewind_visual_smoke.gd"


func _save_frame(filename: String) -> void:
	var before := var_to_bytes([game.boss_attacks, game.enemy_bullets, game.player_hp, game.boss_hp, game.player_pos])
	await super._save_frame(filename)
	assert(before == var_to_bytes([game.boss_attacks, game.enemy_bullets, game.player_hp, game.boss_hp, game.player_pos]), "Drawing changed combat state")


func _run() -> void:
	var tag := "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			tag = arg.trim_prefix("--tag=")
	output_dir = "res://.agent_logs/boss2_weather_" + tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game._start_game()
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.effects.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 2000.0
	game.time_alive = 12.0
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(230, 50)
	game.boss_pos = game.WORLD_SIZE * 0.5 + Vector2(-100, -40)
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game.gfx_memory_saver = game.gfx_low_resource
	game.rng.seed = 2048
	game.current_phase = 1
	game._start_boss1_rain()
	for i in range(240):
		game._update_environment_weather(1.0 / 60.0)
	game.effects.clear()
	await _save_frame("rain.png")
	game.current_phase = 2
	game._convert_rain_to_snow()
	for i in range(240):
		game._update_environment_weather(1.0 / 60.0)
	game.effects.clear()
	await _save_frame("snow.png")
	for i in range(60):
		game._update_environment_weather(1.0 / 60.0)
	await _save_frame("snow_motion.png")
	game._start_boss2_ultimate()
	game.effects.clear()
	game.boss2_ultimate_spit_timer = 0.7
	game.boss2_ultimate_wind_active = 0.0
	game.boss2_ultimate_wind_timer = 0.8
	game.boss2_ultimate_fan_timer = 0.7
	var target: Vector2 = game.player_pos + Vector2(-95, -65)
	var cases := {
		"hail": {"kind": "ice_pillar", "target": target, "radius": 60.0, "warn": 1.1, "duration": 1.48},
		"freeze": {"kind": "flash_freeze", "target": target, "radius": 185.0, "warn": 1.95, "duration": 2.5},
		"breath": {"kind": "frost_breath", "dir": Vector2.RIGHT, "warn": 2.45, "duration": 5.0},
		"stomp": {"kind": "glacial_stomp", "cracks": [{"a": target + Vector2(-190, -50), "b": target + Vector2(260, 80), "width": 30.0}], "warn": 1.5, "duration": 3.0},
		"prison": {"kind": "ice_prison", "center": target, "radius": 140.0, "crystals": [{"pos": target + Vector2(140, 0)}, {"pos": target + Vector2(-140, 0)}], "warn": 1.7, "duration": 3.0},
		"spin": {"kind": "spin_spit_up", "targets": [{"pos": target, "radius": 60.0, "delay": 0.2}], "warn": 1.5, "duration": 3.0},
		"avalanche": {"kind": "avalanche", "targets": [target], "warn": 2.45, "duration": 4.95},
		"shield": {"kind": "shield", "angle": 0.5, "warn": 0.0, "duration": 4.0},
		"blizzard": {"kind": "blizzard", "waves": [{"x": target.x, "direction": "right", "width": 78.0}], "warn": 2.45, "duration": 6.65}
	}
	game._spawn_boss2_frost_bullet(game.player_pos + Vector2(100, -50), Vector2.LEFT, 10.0)
	for key in cases:
		var attack: Dictionary = cases[key]
		attack["age"] = float(attack["warn"]) * 0.7
		game.boss_attacks = [attack]
		await _save_frame(key + "_warning.png")
		attack["age"] = float(attack["warn"]) + (0.9 if key == "avalanche" else 0.08)
		await _save_frame(key + "_active.png")
	game._cleanup_runtime_resources()
	game.free()
	for i in range(4):
		await process_frame
	print("BOSS2_WEATHER_VISUAL_OK " + output_dir)
	quit(0)
