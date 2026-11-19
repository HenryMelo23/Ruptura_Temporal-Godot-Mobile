extends SceneTree

## Capturas da Matriarca: rastejar, mergulho (monte, aviso, erupcao) e ataques.
## Uso: godot --path . --script res://tests/boss6_locomotion_visual_smoke.gd

const OUT_DIR := "res://.agent_logs/boss6_spit_tail/frames"
const DT := 0.05
var game: Node
var frame_index := 0
var tail_mode := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game._advance_to_phase(6)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.mode = "game"
	game.enemies.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = game._boss_hp_for_phase(6)
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.boss6_stage_controller.arena_center()
	game.boss6_controller.reset()
	game.boss6_wait_timer = 99.0
	game.player_hp_max = 99999.0
	game.player_hp = 99999.0
	var center: Vector2 = game.boss_pos
	game.player_pos = center + Vector2(-480.0, 40.0)
	game.boss6_ai_state["burrow_cd"] = 99.0
	game.boss6_stage = 2
	game.boss_hp = game.boss_hp_max * 0.6
	game.boss6_event_80_triggered = true
	game.boss6_event_60_triggered = true
	game._boss6_start_ability(game.BOSS6_ABILITY_ACID_BLOOM)
	await _simulate(2.6, center)
	game.boss6_state = game.BOSS6_STATE_IDLE
	game.boss6_wait_timer = 99.0
	game.boss_attacks.clear()
	game.boss6_ai_state["facing"] = -1.0
	game.boss6_ai_state["burrow_cd"] = 99.0
	tail_mode = true
	game.player_pos = game.boss_pos + Vector2(190.0, 60.0)
	game._boss6_start_ability(game.BOSS6_ABILITY_TAIL)
	await _simulate(2.0, center)
	print("BOSS6_SPIT_TAIL_VISUAL_OK frames=%d dir=%s" % [frame_index, ProjectSettings.globalize_path(OUT_DIR)])
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _simulate(seconds: float, center: Vector2) -> void:
	for _step in range(int(round(seconds / DT))):
		game.time_alive += DT
		# Jogador anda devagar em arco para obrigar a Matriarca a se mexer.
		if not tail_mode:
			var a: float = PI + game.time_alive * 0.6
			game.player_pos = center + Vector2(cos(a), sin(a) * 0.6) * 320.0
		game._update_boss_phase6(DT)
		game._update_effects(DT)
		game.damage_flash_timer = 0.0
		game.screen_shake_timer = maxf(0.0, game.screen_shake_timer - DT)
		game.queue_redraw()
		await process_frame
		root.get_texture().get_image().save_png("%s/f_%03d.png" % [OUT_DIR, frame_index])
		frame_index += 1
