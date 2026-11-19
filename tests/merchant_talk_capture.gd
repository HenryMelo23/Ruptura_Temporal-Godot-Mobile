extends SceneTree

## Capturas do Mercador animado e dos retratos falando na oficina.
## Uso (com tela): godot --path . --script res://tests/merchant_talk_capture.gd
## Saida: res://.codex/merchant_talk/<n>_<rotulo>.png

var game: Node
var shots := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _shot(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var dir := ProjectSettings.globalize_path("res://.codex/merchant_talk")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir + "/%02d_%s.png" % [shots, label])
	shots += 1


func _step(seconds: float) -> void:
	var dt := 1.0 / 30.0
	var e := 0.0
	while e < seconds:
		game._update_game(dt)
		e += dt


func _run() -> void:
	await process_frame
	game.run_tutorial_enabled = false
	game.active_character_key = game.CHARACTER_GEOVANA
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._finish_startup_thanks()
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.is_multiplayer = false
	game.spawn_timer = 99999.0
	game.enemies.clear()
	game.shop_rift_controller.allow_rift = true
	game.shop_auto_enabled = true
	var npc = game._merchant_npc()
	npc.seen["intro"] = true
	var rc = game.shop_rift_controller
	rc.clear_active()
	game.shop_rift_next_allowed_time = 0.0
	var pos: Vector2 = game.player_pos + Vector2(30, 0)
	rc.spawn("test", pos)
	game.shop_rift["state"] = rc.STATE_OPEN
	game.player_pos = pos
	rc.update(0.016)
	await _step(4.5)
	game._dialogue().clear()
	var dim = game._merchant_dimension()
	# Longe: consertando.
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(420, 260)
	for i in range(4):
		await _step(0.12)
		await _shot("work")
	# Perto: parado respirando.
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(175, 40)
	dim.counter_armed = false
	for i in range(3):
		await _step(0.2)
		await _shot("idle")
	# Conversa (longe do balcao para a loja nao abrir).
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(420, 260)
	game._dialogue().start([
		{"who": "mercador", "text": "Você é a melhor coisa que me aconteceu em muito tempo. Você volta, você paga, você não tenta me comer.", "mood": "animado"},
		{"who": "geovana", "text": "Você ficou com a minha essência.", "mood": "irritada"},
		{"who": "mercador", "text": "Eu? Não, não, não. Repara bem no que aconteceu.", "mood": "triste"},
	])
	for i in range(3):
		await _step(0.15)
		await _shot("fala_mercador")
	game._dialogue().revealed = 999.0
	await _step(0.05)
	await _shot("fala_mercador_fim")
	game._dialogue().current = game._dialogue().queue.pop_front()
	game._dialogue().revealed = 0.0
	for i in range(2):
		await _step(0.15)
		await _shot("fala_geovana")
	print("MERCHANT_TALK_CAPTURE_OK shots=%d" % shots)
	quit(0)
