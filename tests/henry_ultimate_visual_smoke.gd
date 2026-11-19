extends SceneTree

## Ignicao Total: grava a linha do tempo inteira (carga, 3 impactos com rachaduras e colunas).
## Uso: godot --path . --script res://tests/henry_ultimate_visual_smoke.gd

const OUT_DIR := "res://.agent_logs/henry_ultimate/frames"
const DT := 0.05
var game: Node
var frame_index := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.set_process(false)
	game.startup_thanks_done = true
	game.active_character_key = game.CHARACTER_HENRY
	game.run_tutorial_enabled = false
	game._start_game()
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	for index in range(14):
		var a := float(index) * TAU / 14.0
		var r := 120.0 + float(index % 3) * 80.0
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(a) * r)
		game.enemies[-1]["hp"] = 1.0e7
		game.enemies[-1]["max_hp"] = 1.0e7
		game.enemies[-1]["stun"] = 999.0
	game.henry_incendiary_ability_controller.cast_ultimate()
	var ctrl = game.henry_incendiary_ability_controller
	for _step in range(int(ctrl.ULT_TOTAL / DT) + 12):
		game.time_alive += DT
		ctrl.update(DT)
		game.queue_redraw()
		await process_frame
		root.get_texture().get_image().save_png("%s/f_%03d.png" % [OUT_DIR, frame_index])
		frame_index += 1
	print("HENRY_ULTIMATE_VISUAL_OK frames=%d pulses=%d dir=%s" % [frame_index, game.henry_ultimate_pulses_released, ProjectSettings.globalize_path(OUT_DIR)])
	game._cleanup_runtime_resources()
	game.free()
	for _f in range(3):
		await process_frame
	quit(0)
