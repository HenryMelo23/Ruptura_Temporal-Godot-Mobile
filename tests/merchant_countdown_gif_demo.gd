extends SceneTree

## Grava a contagem regressiva da fenda: barra fora do HUD, numero pulsando,
## bordas vermelhas, seta para a saida e o colapso.
## Saida: .agent_logs/merchant/gifc/f####.png

const OUT := "res://.agent_logs/merchant/gifc/"
var game: Node
var frame := 0


func _initialize() -> void:
	root.size = Vector2i(960, 540)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _shot() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	frame += 1
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "f%04d.png" % frame))


func _record(seconds: float, walk_to: Vector2 = Vector2.INF) -> void:
	var dt := 1.0 / 16.0
	for i in range(int(seconds / dt)):
		if walk_to != Vector2.INF:
			var to: Vector2 = walk_to - game.player_pos
			if to.length() > 8.0:
				game.player_pos += to.normalized() * 230.0 * dt
		game.time_alive += dt
		game._dialogue().update(dt)
		game._merchant_dimension().update(dt)
		game._update_comfort_camera(dt)
		game._update_effects(dt)
		await _shot()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game.startup_thanks_done = true
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.score = 600
	var npc: RTMerchantNpc = game._merchant_npc()
	npc.persist = false
	npc.seen["intro"] = true
	npc.capsules_saved = 0
	npc.mission_done = false
	var dim: RTMerchantDimension = game._merchant_dimension()
	dim.enter()
	dim.talked_this_visit = true
	# Passeio pela oficina, longe do Mercador (perto dele a loja abriria).
	game.player_pos = Vector2(1180.0, 880.0)
	game.camera_follow_initialized = false
	dim.counter_armed = false
	dim.timer = 0.0
	await _record(2.6, Vector2(1180.0, 360.0))
	await _record(2.6, Vector2(300.0, 360.0))
	await _record(2.0, Vector2(300.0, 820.0))
	print("MERCHANT_COUNTDOWN_GIF_DONE frames=%d" % frame)
	quit(0)
