extends SceneTree

## Frames para GIF: Rebobinar (corre, e puxado de volta) e Eco Profetico
## (sigilo na rota prevista, detona). Saida: .agent_logs/umbra_skills/gif/

var game: Node
const OUT := "res://.agent_logs/umbra_skills/gif2/"
var frame := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _shot() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "f_%03d.png" % frame))
	frame += 1


func _sim(seconds: float, move: Vector2, shots_every: int = 3) -> void:
	var dt := 1.0 / 30.0
	var n: int = int(seconds / dt)
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()
	for i in range(n):
		if game.player_stun_timer <= 0.0:
			game.player_pos += move * dt
		game.player_stun_timer = maxf(0.0, game.player_stun_timer - dt)
		game.time_alive += dt
		game.boss_phase += dt * 7.2
		game._sample_umbra_player_history(dt)
		skills.update(dt)
		game.player_hp = game.player_hp_max
		game.damage_flash_timer = 0.0
		game._update_comfort_camera(dt)
		if i % shots_every == 0:
			await _shot()


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._advance_to_phase(5)
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 30000.0
	game.boss_hp = 24000.0
	game.player_hp_max = 999999
	game.player_hp = 999999
	var c: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.boss_pos = c + Vector2(330, -60)
	game.player_pos = c + Vector2(-330, 80)
	game._reset_phase5_state()
	game.camera_follow_initialized = false
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()
	# Rebobinar
	await _sim(0.4, Vector2(220, -40))
	skills.cooldowns["REBOBINAR"] = 0.0
	game._spawn_umbra_action("REBOBINAR")
	await _sim(1.55, Vector2(260, -60), 2)
	await _sim(0.6, Vector2.ZERO, 2)
	# Eco profetico (combo nao: jogador correndo)
	game.player_pos = c + Vector2(-300, 140)
	game.phase5_player_history.clear()
	await _sim(0.4, Vector2(230, 0))
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	game._spawn_umbra_action("ECO_PROFETICO")
	await _sim(1.1, Vector2(230, 0), 2)
	await _sim(0.5, Vector2(230, 0), 2)
	# Combo: rebobinar + eco no ponto de retorno
	game.player_pos = c + Vector2(-250, -60)
	skills.cooldowns["REBOBINAR"] = 0.0
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	game._spawn_umbra_action("REBOBINAR")
	await _sim(0.4, Vector2(250, 60), 2)
	game._spawn_umbra_action("ECO_PROFETICO")
	await _sim(1.3, Vector2(250, 60), 2)
	await _sim(0.6, Vector2.ZERO, 2)
	print("UMBRA_GIF_FRAMES ", frame)
	quit(0)
