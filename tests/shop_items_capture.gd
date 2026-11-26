extends SceneTree

## Loja com itens: todo item do catalogo tem sprite, vitrine por raridade,
## queima no meio, redoma de reserva (travando e travada), item chamuscado e
## o balcao do Mercador. Sem janela so confere o mapeamento item <-> carta.
## godot4 --headless --path . --script tests/shop_items_capture.gd
## godot4 --path . --audio-driver Dummy --script tests/shop_items_capture.gd -- --frames=<dir> [--size=WxH]
const ItemShowcase := preload("res://scripts/presentation/item_showcase.gd")
const DT := 1.0 / 60.0
## Itens novos que ainda esperam o sprite do Codex (tirar daqui quando chegar).
const PENDING_ART: Array[String] = []
var game: Node
var frames_dir := ""
var failures: Array[String] = []
var shot_size := Vector2i(1280, 720)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames_dir = a.substr(9)
		elif a.begins_with("--size="):
			var parts: PackedStringArray = a.substr(7).split("x")
			shot_size = Vector2i(int(parts[0]), int(parts[1]))
	root.size = shot_size
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)


func _tick(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		t += DT
		game.shop_controller.update(DT)


func _shot(name: String) -> void:
	if frames_dir == "":
		return
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [frames_dir, name, root.size.x, root.size.y])


func _card(name: String) -> Dictionary:
	for c in game.CARDS:
		if String(Dictionary(c).get("name", "")) == name:
			return Dictionary(c).duplicate(true)
	failures.append("carta nao encontrada: " + name)
	return {}


## Congela uma animacao da loja num ponto (0..1) para a captura.
func _freeze(kind: String, slot: int, progress: float) -> void:
	var view = game.shop_presentation
	view.begin(kind, game.shop_cards, slot)
	view.elapsed = view.duration * progress


func _run() -> void:
	await process_frame
	# Todo item do catalogo tem sprite.
	var missing: Array = []
	for c in game.CARDS:
		if ItemShowcase.texture(Dictionary(c)) == null and not String(Dictionary(c).get("name", "")) in PENDING_ART:
			missing.append(String(Dictionary(c).get("name", "")))
	_check(missing.is_empty(), "cartas sem sprite de item: %s" % str(missing))
	_check(ItemShowcase.item_name(_card("Porcao")) == "Frasco Coração Piedoso", "nome do objeto da Porcao: %s" % ItemShowcase.item_name(_card("Porcao")))
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
		DisplayServer.window_set_size(shot_size)
		root.size = shot_size
		root.content_scale_size = shot_size
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
		game._open_shop(false)
		game.score = 12840
		game.cards_bought[game.CARD_CINZAS_ID] = 1
		game._recalculate_common_card_stat_bonuses()
		# Raridades altas.
		game.shop_cards = [_card("Horizonte de Ruptura"), _card("Coração de Antimatéria"), _card("Coracao do Paradoxo")]
		game.shop_selected = 1
		game.shop_presentation.reset()
		_tick(1.2)
		await _shot("01_raridades")
		game.shop_selected = 2
		_tick(0.3)
		await _shot("02_lendario")
		# Queima no meio.
		game.shop_cards = [_card("Speed Boost"), _card("Tempestade"), _card("Pulso Desestabilizador")]
		game.shop_selected = 1
		_tick(0.2)
		_freeze("burn", 1, 0.3)
		await _shot("03_queima_acendendo")
		_freeze("burn", 1, 0.62)
		await _shot("04_queima_consumindo")
		_freeze("burn", 1, 0.92)
		await _shot("05_queima_cinza")
		game.shop_presentation.action = ""
		# Reserva: travando e travada; item chamuscado ao lado.
		var charred: Dictionary = _card("Fratura Cronal")
		charred["cinzas_return_buff"] = true
		charred["cinzas_buff_stacks"] = 4
		game.shop_cards = [charred, _card("Sutura Gradual"), _card("Ponto Cego")]
		game.shop_selected = 1
		game.shop_locked_slots[game._shop_locked_key(1)] = {"card": game.shop_cards[1].duplicate(true), "price": 60}
		_freeze("lock", 1, 0.45)
		await _shot("06_reserva_travando")
		game.shop_presentation.action = ""
		_tick(0.2)
		await _shot("07_reserva_e_cinzas")
		game.shop_locked_slots.clear()
		# Balcao do Mercador.
		var dim = game._merchant_dimension()
		dim.active = true
		game.shop_cards = [_card("Petro"), _card("Moeda Estavel"), _card("Arquivo do Impossível")]
		game.shop_selected = 0
		_tick(0.3)
		await _shot("08_balcao_mercador")
		dim.active = false
	game.mode = "menu"
	if failures.is_empty():
		print("SHOP_ITEMS_CAPTURE_OK items=%d" % game.CARDS.size())
		quit(0)
	else:
		for f in failures:
			printerr("SHOP_ITEMS_CAPTURE_FAIL " + f)
		quit(1)
