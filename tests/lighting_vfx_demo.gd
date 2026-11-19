extends SceneTree

## Captura a iluminacao nova: luzes no chao, vinheta, banho de cor da fase,
## sombras macias, clarao de disparo, rastro dos tiros e impacto.
## Saida: .agent_logs/lighting/<nn>_<nome>.png

var game: Node
const OUT := "res://.agent_logs/lighting/"
var shot_index := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _shot(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	shot_index += 1
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%02d_%s.png" % [shot_index, name]))


func _step(seconds: float) -> void:
	var dt := 1.0 / 30.0
	var t := 0.0
	while t < seconds:
		game._process(dt)
		t += dt


func _spawn_enemies(count: int, distance: float) -> void:
	game.enemies.clear()
	for i in range(count):
		var ang: float = -0.5 + float(i) * 0.5
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(ang) * distance)


func _fire_burst(shots: int) -> void:
	for i in range(shots):
		game.last_attack_time = game.time_alive - game._current_attack_interval()
		game._try_attack()
		_steps_small()


func _steps_small() -> void:
	for i in range(2):
		game._process(1.0 / 30.0)


func _setup_phase(phase: int) -> void:
	game._advance_to_phase(phase)
	game.mode = "game"
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 99999
	game.player_hp = 99999
	game.player_pos = game.WORLD_SIZE * 0.5
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.bullets.clear()
	game.effects.clear()
	game.camera_follow_initialized = false
	_step(0.2)


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)

	# Fase 1: disparo, rastro e impacto.
	_setup_phase(1)
	_spawn_enemies(4, 300.0)
	game.last_attack_time = game.time_alive - game._current_attack_interval()
	game._try_attack()
	game._process(1.0 / 30.0)
	await _shot("muzzle")
	_step(0.18)
	game.last_attack_time = game.time_alive - game._current_attack_interval()
	game._try_attack()
	_step(0.1)
	await _shot("voo_tiros")
	_step(0.35)
	await _shot("impacto")

	# Fase 3: banho de cor + vinheta + sombras no cenario escuro.
	_setup_phase(3)
	_spawn_enemies(5, 260.0)
	_step(0.4)
	await _shot("fase3_ambiente")

	# Fase 7: clima quente.
	_setup_phase(7)
	_spawn_enemies(4, 280.0)
	game.last_attack_time = game.time_alive - game._current_attack_interval()
	game._try_attack()
	_step(0.12)
	await _shot("fase7_ambiente")
	print("LIGHTING_VFX_DEMO_DONE shots=%d lights_layer=%s" % [shot_index, str(game.world_light_layer != null)])
	quit(0)
