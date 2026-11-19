extends SceneTree

## Loja no visor do bracelete: abertura, compra, reroll, queima, reserva e cartas
## queimadas com fogo crescente. -- --frames=<dir> [--size=WxH]
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seq := 0
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--size="):
			var parts: PackedStringArray = a.substr(7).split("x")
			root.size = Vector2i(int(parts[0]), int(parts[1]))
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("SHOP_VISOR_FAIL " + msg)


func _frames(seconds: float, every: int = 2) -> void:
	var t := 0.0
	var i := 0
	while t < seconds:
		t += DT
		game.shop_controller.update(DT)
		i += 1
		if frames_dir != "" and i % every == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, int(640.0 * float(root.size.y) / float(root.size.x)), Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1


func _shot(name: String) -> void:
	if frames_dir == "":
		return
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [frames_dir, name])


func _cards() -> Array:
	var out: Array = []
	for c in game.CARDS:
		var card: Dictionary = Dictionary(c)
		if game._is_common_card(card) and game._card_texture(card) != null:
			out.append(card.duplicate(true))
		if out.size() >= 6:
			break
	return out


func _run() -> void:
	await process_frame
	game._start_game()
	game.startup_thanks_done = true
	if game.startup_thanks_frame_view != null:
		game.startup_thanks_frame_view.visible = false
	game.set_process(false)
	game.is_multiplayer = false
	game.run_tutorial_enabled = false
	game._reset_card_counts()
	game.mode = "game"
	game.previous_mode = "game"
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var pool := _cards()
	# --- sem Cinzas: botoes de queimar/reservar nao aparecem
	game._open_shop(false)
	game.shop_cards = [pool[0], pool[1], pool[2]]
	game.shop_selected = 0
	game.score = 12840
	game.shop_presentation.reset()
	await _frames(0.7)
	_check(not game.buttons.has("shop_burn_0"), "queimar apareceu sem Cinzas no deck")
	_check(not game.buttons.has("shop_reserve_0"), "reservar apareceu sem a carta")
	await _shot("visor_sem_cinzas")
	# --- com Cinzas
	game.cards_bought[game.CARD_CINZAS_ID] = 1
	game._recalculate_common_card_stat_bonuses()
	await _frames(0.2)
	_check(game.buttons.has("shop_burn_0"), "queimar nao apareceu com Cinzas")
	await _shot("visor_com_cinzas")
	# compra
	game.shop_selected = 1
	game._buy_selected_card()
	await _frames(0.9)
	# reroll
	game.shop_rerolls = 3
	game._reroll_shop()
	await _frames(0.9)
	# queima
	game.shop_cards[0] = pool[3]
	game.shop_selected = 0
	var burned: bool = game._burn_shop_card(0)
	await _frames(1.1)
	# cartas ja queimadas com poucas e muitas cargas
	var light: Dictionary = pool[4].duplicate(true)
	light["cinzas_return_buff"] = true
	light["cinzas_buff_stacks"] = 2
	var heavy: Dictionary = pool[5].duplicate(true)
	heavy["cinzas_return_buff"] = true
	heavy["cinzas_buff_stacks"] = 10
	game.shop_cards = [light, game.shop_cards[1], heavy]
	await _frames(0.8)
	await _shot("cartas_queimadas")
	# reserva (simulada: anima com a vaga travada)
	game.shop_locked_slots[1] = true if typeof(game.shop_locked_slots) == TYPE_DICTIONARY else null
	game.shop_controller.begin("lock", game.shop_cards, 1)
	await _frames(0.7)
	await _shot("reserva")
	print("SHOP_VISOR_DEMO_OK no_card_hides=true burn_visible=true burned=%s frames=%d" % [str(burned), seq])
	quit(1 if failed else 0)
