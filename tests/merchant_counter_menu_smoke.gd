extends SceneTree
## Balcão do Mercador: COMPRAR / PERGUNTAR, a explicação da Ruptura e as
## escolhas no diálogo (toque, teclado). Com "capture" salva quadros em
## .agent_logs/merchant_menu/ (precisa de janela).
## godot4 --headless --path . --script tests/merchant_counter_menu_smoke.gd
## godot4 --path . --audio-driver Dummy --script tests/merchant_counter_menu_smoke.gd -- capture

const OUT := "res://.agent_logs/merchant_menu/"
const R := preload("res://scripts/systems/phase/dimension_rupture_controller.gd")

var game: Node
var failures: Array[String] = []
var capture := false


func _initialize() -> void:
	capture = "capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _shot(name: String, size: Vector2i = Vector2i(1280, 720)) -> void:
	if not capture:
		return
	DisplayServer.window_set_size(size)
	root.size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "%s_%dx%d.png" % [name, size.x, size.y]))


func _tick(seconds: float) -> void:
	var dt := 1.0 / 30.0
	for i in range(int(seconds / dt)):
		game.time_alive += dt
		game._dialogue().update(dt)
		game._merchant_dimension().update(dt)
		game._update_comfort_camera(dt)


func _reveal(talk: RTDialogueController) -> void:
	talk.grace = 0.0
	talk.revealed = 99999.0


## Avança até a próxima fala com escolhas (ou o fim). Retorna as falas lidas.
func _read_until_choice(talk: RTDialogueController) -> Array:
	var read: Array = []
	var guard := 0
	while talk.busy() and guard < 80:
		guard += 1
		_reveal(talk)
		read.append({"who": talk.speaker(), "text": talk.full_text()})
		if talk.awaiting_choice():
			return read
		talk.advance_input()
	return read


func _key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	game._dialogue().handle_input(e)


func _run() -> void:
	await process_frame
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	game.startup_thanks_done = true
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	var dim: RTMerchantDimension = game._merchant_dimension()
	var npc: RTMerchantNpc = game._merchant_npc()
	var talk: RTDialogueController = game._dialogue()
	npc.seen.clear()
	npc.visits = 0
	game.shop_cards = [{}, {}, {}, {}]
	dim.enter()
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(0, 60)
	game.camera_follow_initialized = false
	_tick(0.2)
	# Apresentação primeiro, depois o balcão abre o menu (não a loja direto).
	_check(talk.busy() and npc.seen.has("intro"), "apresentação não abriu")
	_read_until_choice(talk)
	_check(not talk.busy(), "apresentação deveria terminar sem escolha")
	_tick(0.1)
	_check(talk.busy() and talk.speaker() == "mercador", "balcão não abriu o menu")
	_reveal(talk)
	_check(talk.awaiting_choice(), "menu sem escolhas")
	_check(talk.choice_labels() == ["COMPRAR", "PERGUNTAR", "NADA AGORA"], "opções do menu: %s" % str(talk.choice_labels()))
	_check(game.mode != "shop", "loja abriu antes da escolha")
	_check(not talk.advance_input(), "toque fora do botão pulou a escolha")
	# O menu de compra gasta o tempo da fenda (a loja também gasta).
	var before: float = dim.timer
	_tick(0.5)
	_check(dim.timer > before, "o menu do balcão congelou o tempo da fenda")
	await _shot("01_menu")
	await _shot("01_menu", Vector2i(1600, 720))

	# Teclado: desce até PERGUNTAR e confirma.
	_key(KEY_DOWN)
	_check(talk.selected == 1, "seta não moveu a seleção")
	_key(KEY_ENTER)
	_check(talk.busy() and talk.choice_labels().size() == 3 and talk.choice_labels()[0] == "IMPULSO, FRAGMENTO E COLAPSO", "menu de perguntas: %s" % str(talk.choice_labels()))
	_reveal(talk)
	await _shot("02_perguntas")

	# Toque no botão do tópico da Ruptura (área desenhada no quadro).
	if capture:
		var rects: Array = talk.choice_rects
		_check(rects.size() == 3, "botões sem área de toque")
		var tap := InputEventScreenTouch.new()
		tap.pressed = true
		tap.position = Rect2(rects[0]).get_center() if rects.size() > 0 else Vector2.ZERO
		talk.grace = 0.0
		talk.handle_input(tap)
	else:
		talk.choose(0)
	_check(talk.busy(), "tópico da Ruptura não começou")
	_reveal(talk)
	talk.advance_input()
	talk.revealed = 30.0
	await _shot("03_ruptura_fala")
	var read: Array = _read_until_choice(talk)
	var all_text := ""
	for line in read:
		all_text += " " + String(line["text"])
	for term in ["Fragmento Instável", "Impulso de Ruptura", "Colapso Dimensional", "velho", "cuidado"]:
		_check(term.to_lower() in all_text.to_lower(), "explicação sem '%s'" % term)
	for n in [int(R.FAST_WINDOW_SECONDS), int(R.STANDARD_WINDOW_SECONDS), int(R.COLLAPSE_TOTAL_SECONDS), int(R.EMERGENCY_ESCAPE_SECONDS)]:
		_check(str(n) in all_text, "explicação sem o número %d" % n)
	_check(read.size() >= 18, "explicação curta demais (%d falas)" % read.size())
	for line in read:
		_check(String(line["text"]).length() <= 190, "fala longa demais para a caixa: " + String(line["text"]).left(40))
	_check(npc.seen.has(RTMerchantNpc.TOPIC_RUPTURE), "tópico não marcado como visto")
	_check(talk.awaiting_choice() and talk.choice_labels()[0] == "COMPRAR", "explicação não voltou ao menu do balcão")
	await _shot("04_volta_menu")

	# Segunda vez: resumo curto com os mesmos números.
	var retold: Array = RTMerchantNpc.rupture_talk(true)
	_check(retold.size() < read.size() and retold.size() >= 4, "resumo deveria ser curto")
	# COMPRAR abre a loja de verdade.
	talk.grace = 0.0
	talk.choose(0)
	_check(not talk.busy(), "conversa ficou aberta depois de COMPRAR")
	_check(game.mode == "shop" or game.mode == "shop_opening" or game.shop_controller.busy(), "COMPRAR não abriu a loja (mode=%s)" % game.mode)

	# Expulsão com o menu aberto não deixa a Geovana travada.
	game.mode = "game"
	if game.shop_controller.has_method("close_shop"):
		game.shop_controller.close_shop()
	game.mode = "game"
	npc.open_menu(dim)
	_check(talk.busy(), "menu não reabriu")
	dim.leave(true)
	_check(not talk.busy(), "conversa sobreviveu à expulsão")

	# Multiplayer (sem narrativa): balcão abre direto.
	_check(RTMerchantNpc.new().narrative_enabled() == false, "npc sem core não narra")

	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	if failures.is_empty():
		print("MERCHANT_COUNTER_MENU_SMOKE_OK")
		quit(0)
	else:
		for f in failures:
			printerr("MERCHANT_COUNTER_MENU_SMOKE_FAIL " + f)
		quit(1)
