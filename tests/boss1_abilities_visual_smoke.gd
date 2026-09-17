extends "res://tests/boss1_rewind_visual_smoke.gd"


func _save_frame(filename: String) -> void:
	var before := var_to_bytes([game.boss_attacks, game.boss_transition_waves, game.boss1_time_wave, game.boss_hp, game.player_hp, game.player_pos, game.time_alive])
	await super._save_frame(filename)
	assert(before == var_to_bytes([game.boss_attacks, game.boss_transition_waves, game.boss1_time_wave, game.boss_hp, game.player_hp, game.player_pos, game.time_alive]), "VFX rendering changed combat state")


func _run() -> void:
	var tag := "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			tag = arg.trim_prefix("--tag=")
	output_dir = "res://.agent_logs/boss1_vfx_" + tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game._start_game()
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 5000.0
	game.boss_hp = 1200.0
	game.time_alive = 12.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(160, 90)
	game.enemies.clear()
	game.effects.clear()
	game.gfx_shadows = true
	if "--low" in OS.get_cmdline_user_args():
		game.gfx_memory_saver = true
		game.gfx_low_resource = true
	var target: Vector2 = game.boss_pos + Vector2(-120, 130)
	var cases: Dictionary = {
		"bubble": {"kind": "bubble", "target": target, "age": 1.8, "duration": 3.2},
		"pressure": {"kind": "pressure_bubbles", "age": 0.5, "dir": Vector2.LEFT},
		"boiling": {"kind": "boiling_bubbles", "age": 1.4, "drops": [{"age": 1.43, "launch": game.boss_pos, "apex": game.boss_pos + Vector2(0, -210), "target": target, "phase": 1.0}]},
		"tide": {"kind": "tide", "age": 2.1, "duration": 4.2, "horizontal": true, "positive": true},
		"sand": {"kind": "sand", "age": 1.4, "duration": 4.2, "target": target},
		"rush": {"kind": "rush", "age": 0.4, "state": "telegraph", "dir": Vector2.LEFT, "warn": 0.62},
		"rush_dash": {"kind": "rush", "age": 0.8, "state": "dash", "dir": Vector2.LEFT},
		"retaliation": {"kind": "absorb_retaliation", "age": 0.4, "fired": 2, "bursts": 4}
	}
	for key in cases:
		game.boss_attacks = [cases[key]]
		game.enemy_bullets = [{"type": "boss_pressure_bubble", "pos": target, "dir": Vector2.LEFT, "radius": 22.0, "phase": 0.4}] if key == "pressure" else []
		await _save_frame(key + ".png")
	game.boss_attacks.clear()
	game.enemy_bullets.clear()
	game.boss1_absorb_timer = 3.2
	await _save_frame("absorb.png")
	game.boss1_absorb_timer = 0.0
	game.boss1_time_wave = {"origin": game.boss_pos, "radius": 270.0, "direction": 1.0, "max_radius": 1000.0, "age": 1.2, "variant": 0}
	await _save_frame("time_wave.png")
	game.boss1_time_wave.clear()
	game.boss_stage_timer = game.BOSS_STAGE_JUMP_TIME - game.BOSS_STAGE_SLAM_TIME - 0.22
	game.boss_transition_waves = [{"kind": "dupla_abertura", "pos": game.boss_pos, "radius": 270.0, "width": 20.0, "open_angle": 0.0, "open_size": 0.8, "age": 1.2, "warning": 0.2, "idx": 0}]
	await _save_frame("slam_wave.png")
	game.boss_stage_timer = 0.0
	game.boss_transition_waves.clear()
	_build_visual_history()
	for progress in [0.0, 0.35, 0.75]:
		game.boss1_rewind_sequence = {"elapsed": game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME * progress, "variant": 0}
		game._apply_boss1_rewind_sample(game._boss1_rewind_interpolated_sample(progress))
		await _save_frame("rewind_%d.png" % int(progress * 100))
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	print("BOSS1_ABILITIES_VISUAL_OK " + ProjectSettings.globalize_path(output_dir))
	quit(0)
