extends SceneTree

## Grava a oficina do Mercador quadro a quadro: chegada pela fenda, caminhada
## ate o balcao, fala em estilo RPG, balao ambiente e colapso da fenda.
## Saida: .agent_logs/merchant/gif/f####.png

const OUT := "res://.agent_logs/merchant/gif/"
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


## Avanca o jogo e grava: `seconds` de simulacao a 20 quadros por segundo.
func _record(seconds: float, walk_to: Vector2 = Vector2.INF) -> void:
	var dt := 1.0 / 20.0
	var steps: int = int(seconds / dt)
	for i in range(steps):
		if walk_to != Vector2.INF:
			var to: Vector2 = walk_to - game.player_pos
			if to.length() > 8.0:
				game.player_pos += to.normalized() * 240.0 * dt
		game._process(dt)
		await _shot()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game.startup_thanks_done = true
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.score = 900
	game.enemies.clear()
	var npc: RTMerchantNpc = game._merchant_npc()
	npc.persist = false
	npc.seen.clear()
	npc.visits = 0
	var dimension: RTMerchantDimension = game._merchant_dimension()
	dimension.enter()
	await _record(1.0)

	# Caminha ate o Mercador: a fala de apresentacao abre sozinha.
	await _record(2.6, RTMerchantDimension.MERCHANT_POS + Vector2(0.0, 150.0))
	for line in range(5):
		await _record(1.5)
		game._dialogue().advance_input()
	game._dialogue().clear()

	# Balao ambiente e volta para o portal de saida.
	npc.say("Olha o estoque, olha o estoque!", 3.0)
	await _record(2.0)
	await _record(2.2, RTMerchantDimension.PLAYER_ENTRY)

	# Fenda no limite: tremor e colapso.
	dimension.timer = dimension.limit - 2.5
	await _record(4.0)
	print("MERCHANT_GIF_DONE frames=%d" % frame)
	quit(0)
