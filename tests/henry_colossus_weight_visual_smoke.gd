extends SceneTree

## Grava o peso novo do Colosso: combo normal, transformacao com estouro, combo gigante e salto.

const OUT_DIR := "res://.agent_logs/henry_colossus_weight/frames"
const DT := 0.04
var game: Node
var frame_index := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _ring(center: Vector2, count: int, radius: float) -> void:
	for index in range(count):
		game._spawn_enemy(game.ENEMY_COMMON, center + Vector2.from_angle(float(index) * TAU / float(count)) * radius)
		game.enemies[-1]["hp"] = 1.0e7
		game.enemies[-1]["max_hp"] = 1.0e7


func _sim(seconds: float, punch_every: float = 0.0) -> void:
	var owner = game.henry_colossus_ability_controller
	var punch_clock := 0.0
	for _step in range(int(round(seconds / DT))):
		game.time_alive += DT
		punch_clock += DT
		if punch_every > 0.0 and punch_clock >= punch_every:
			punch_clock = 0.0
			game.last_attack_time = game.time_alive
			owner.fire_auto_attack()
		owner.update(DT)
		game.screen_shake_timer = maxf(0.0, game.screen_shake_timer - DT)
		game.queue_redraw()
		await process_frame
		root.get_texture().get_image().save_png("%s/f_%03d.png" % [OUT_DIR, frame_index])
		frame_index += 1


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 2
	game.selected_effect = 2
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.gfx_screen_shake = false
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_damage = 100.0
	game.last_facing = Vector2.RIGHT
	game.enemies.clear()
	var owner = game.henry_colossus_ability_controller
	_ring(game.player_pos + Vector2(110.0, 0.0), 5, 40.0)
	await _sim(1.3, 0.3)
	owner.fury = owner.FURY_MAX
	owner.cast_ultimate()
	_ring(game.player_pos, 8, 120.0)
	await _sim(owner.TRANSFORM_DURATION + 0.5)
	_ring(game.player_pos + Vector2(160.0, 0.0), 5, 50.0)
	await _sim(1.4, 0.34)
	owner.begin_leap(game.player_pos + Vector2(-200.0, 60.0))
	_ring(game.player_pos + Vector2(-200.0, 60.0), 6, 90.0)
	await _sim(owner.LEAP_DURATION + 0.8)
	print("HENRY_COLOSSUS_WEIGHT_VISUAL_OK frames=%d dir=%s" % [frame_index, ProjectSettings.globalize_path(OUT_DIR)])
	game._cleanup_runtime_resources()
	game.free()
	for _f in range(3):
		await process_frame
	quit(0)
