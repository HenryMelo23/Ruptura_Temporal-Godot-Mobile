extends SceneTree

## Grava a luta do boss 4 (saltos, Lingua-Arpao, Salto Esmagador) quadro a quadro.
## Uso: godot --path . --script res://tests/boss4_hop_tongue_visual_smoke.gd [-- --low]

const OUT_DIR := "res://.agent_logs/boss4_rework_v2/frames"
const DT := 1.0 / 20.0

var game: Node
var frame_index := 0


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
	game._advance_to_phase(4)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.mode = "game"
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 4000.0
	game.boss_hp = 3900.0
	game.player_hp_max = 3000.0
	game.player_hp = 3000.0
	game.boss_pos = game.boss4_entry_target
	game.player_pos = game.boss_pos + Vector2(-330.0, 40.0)
	game.boss4_controller.reset()
	game.last_dash_time = -99.0
	var ctrl = game.boss4_controller
	game.boss4_attack_timer = 99.0
	# Dois saltos em direcao ao jogador.
	game.boss4_ai_state["hop_t"] = 99.0
	await _simulate(1.9)
	# Lingua que acerta: puxa e da o tapa.
	ctrl.force_action_for_test("tongue")
	game.boss4_attack_timer = 99.0
	await _simulate(1.5)
	# Salto Esmagador com onda de choque.
	game.player_pos = game.boss_pos + Vector2(-300.0, -60.0)
	ctrl.force_action_for_test("jump")
	game.boss4_attack_timer = 99.0
	await _simulate(2.4)
	# Lingua que erra: gruda e o sapo se puxa.
	game.player_pos = game.boss_pos + Vector2(-280.0, 150.0)
	ctrl.force_action_for_test("tongue")
	game.boss4_attack_timer = 99.0
	await _simulate(0.32, false)
	game.player_pos = game.boss_pos + Vector2(-80.0, -260.0)
	await _simulate(1.3)
	print("BOSS4_HOP_TONGUE_VISUAL_OK frames=%d dir=%s" % [frame_index, ProjectSettings.globalize_path(OUT_DIR)])
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _simulate(seconds: float, _track: bool = true) -> void:
	var steps: int = int(round(seconds / DT))
	for _step in range(steps):
		game.time_alive += DT
		game.boss4_controller.update(DT)
		game.Boss4AnimationPresentation.update(game, DT)
		game._update_phase4_enemy_hazards(DT)
		game._update_effects(DT)
		game.screen_shake_timer = maxf(0.0, game.screen_shake_timer - DT)
		game.damage_flash_timer = maxf(0.0, game.damage_flash_timer - DT)
		game.hud_feedback.update(game, DT)
		game.queue_redraw()
		await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/f_%03d.png" % [OUT_DIR, frame_index])
		frame_index += 1
