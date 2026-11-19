extends SceneTree

## Gelo do Sineiro: geada acumulando, congelamento e patinacao no chao gelado.
## Grava frames em .agent_logs/sineiro_ice/ e imprime o que foi visto.

const DT := 1.0 / 60.0
const OUT := "res://.agent_logs/sineiro_ice/"
var game: Node
var seq := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _grab() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
	img.save_png(ProjectSettings.globalize_path(OUT + "f_%03d.png" % seq))
	seq += 1


## Avanca o mundo movendo o jogador com um comando simulado, passando pela
## mesma inercia de gelo que o jogo usa.
func _advance(seconds: float, command: Vector2, every: int = 4) -> void:
	var n: int = int(seconds / DT)
	for i in range(n):
		game.time_alive += DT
		game.elapsed_unpaused += DT
		var move: Vector2 = game._apply_ice_slip(command, DT)
		if move.length() > 0.05:
			game.last_facing = move.normalized()
			game.player_pos = game._clamp_player_world(game.player_pos + game.last_facing * game.player_speed * game._environment_player_slow_mult() * game._ice_slip_speed_mult() * DT)
		game._update_frost(DT)
		game.sineiro_boreal_controller.update(DT)
		game.enemy_manager.update_enemies(DT)
		game._update_enemy_bullets(DT)
		game._update_effects(DT)
		game._update_comfort_camera(DT)
		if i % every == 0:
			await _grab()


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.forced_initial_phase = 2
	game.run_tutorial_enabled = false
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 400000
	game.player_hp = 400000
	# Vulneravel de proposito: a geada precisa pegar.
	game.run_retry_invulnerability_timer = 0.0
	game.enemies.clear()
	game.spawn_timer = 999.0
	game.camera_follow_initialized = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var ctrl = game.sineiro_boreal_controller
	var enemy: Dictionary = ctrl.spawn_now()
	if not enemy.is_empty():
		enemy["pos"] = game.player_pos + Vector2(420.0, -60.0)

	var max_stacks := 0
	var froze := false
	var slipped := false
	var cmd := Vector2.RIGHT
	var t := 0.0
	while t < 22.0:
		# Zigue-zague: no gelo a virada fica lenta e o corpo escorrega.
		cmd = Vector2.RIGHT if int(t / 1.6) % 2 == 0 else Vector2.LEFT
		await _advance(0.4, cmd)
		t += 0.4
		max_stacks = maxi(max_stacks, int(game.player_frost_stacks))
		if game.player_stun_timer > 0.0:
			froze = true
		if game.player_ice_slip_timer > 0.0:
			slipped = true
		game.player_hp = game.player_hp_max
	print("SINEIRO_ICE_DEMO_DONE frames=%d max_geada=%d congelou=%s patinou=%s" % [seq, max_stacks, str(froze), str(slipped)])
	quit(0)
