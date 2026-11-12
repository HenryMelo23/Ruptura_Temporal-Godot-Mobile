extends SceneTree

## Capturas da oficina do Mercador: chegada, conversa em estilo RPG,
## cronometro da fenda e o colapso.

var game: Node
const OUT := "res://.agent_logs/merchant/"
var seq := 0


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
	seq += 1
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%02d_%s.png" % [seq, name]))


func _tick(seconds: float) -> void:
	var dt := 1.0 / 30.0
	var n: int = int(seconds / dt)
	for i in range(n):
		game.time_alive += dt
		game._dialogue().update(dt)
		game._merchant_dimension().update(dt)
		game._update_comfort_camera(dt)


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var dim: RTMerchantDimension = game._merchant_dimension()
	var npc: RTMerchantNpc = game._merchant_npc()
	npc.seen.clear()
	npc.visits = 0
	game.shop_cards = [{}, {}, {}, {}]
	dim.enter()
	game.player_pos = RTMerchantDimension.PLAYER_ENTRY
	game.camera_follow_initialized = false
	_tick(0.4)
	await _shot("chegada")

	# Conversa estilo RPG
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(0, 90)
	_tick(0.1)
	_tick(1.2)
	await _shot("conversa")
	var talk: RTDialogueController = game._dialogue()
	talk.revealed = 99999.0
	await _shot("conversa_completa")
	while talk.busy():
		talk.grace = 0.0
		talk.revealed = 99999.0
		talk.advance_input()
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(0, 230)
	_tick(0.4)
	npc.say("Olha o estoque, olha o estoque!", 9.0)
	_tick(0.3)
	await _shot("balao")

	# Tela de cartas com o fundo da oficina (nao existe mais bracelete aqui).
	game.score = 4000
	game.player_pos = RTMerchantDimension.MERCHANT_POS
	dim.counter_armed = true
	dim.update(0.05)
	game.shop_presentation.update(1.0)
	_tick(0.1)
	await _shot("balcao_cartas")
	game.shop_controller.finish()
	game.mode = "game"
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(0, 230)

	# Cronometro quase no fim
	dim.timer = dim.limit - 6.0
	_tick(0.3)
	await _shot("fenda_urgente")
	dim.timer = dim.limit - 0.02
	_tick(0.2)
	await _shot("colapso")
	print("MERCHANT_VISUAL_DONE shots=%d limite=%.0fs" % [seq, dim.limit])
	quit(0)
