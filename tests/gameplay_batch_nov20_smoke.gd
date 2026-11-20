extends SceneTree

## Lote de 2026-11-20: sem botao de chamar boss (toque/desktop), Mercador pula
## a explicacao da fenda a partir da 5a partida, movimento sem direcao durante
## a conversa, PERGUNTAR nao gasta o tempo da fenda, choque da corrente da
## Eletrica e chefes imunes na animacao de entrada.
## godot4 --headless --path . --script tests/gameplay_batch_nov20_smoke.gd

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")

var game: Node
var failures: Array[String] = []
var guards: Array = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GAMEPLAY_BATCH_NOV20_FAIL " + message)


func _initialize() -> void:
	for path in ["user://hud_config.save", "user://interrupted_run.save", "user://merchant_npc.cfg"]:
		guards.append(UserFileGuard.new(path))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fresh_run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()


func _run() -> void:
	await process_frame
	_fresh_run()
	_check_boss_button_removed()
	_fresh_run()
	_check_veteran_skips_mission_talk()
	_fresh_run()
	_check_no_direction_in_dialogue()
	_fresh_run()
	_check_question_menu_pauses_rift()
	_fresh_run()
	_check_eletrica_current_stun()
	_fresh_run()
	_check_boss_entry_immunity()
	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for guard in guards:
		guard.restore()
	if failures.is_empty():
		print("GAMEPLAY_BATCH_NOV20_SMOKE_OK")
		quit(0)
	else:
		print("GAMEPLAY_BATCH_NOV20_SMOKE_FAILED %d" % failures.size())
		quit(1)


# ------------------------------------------------------------------ item 1
func _check_boss_button_removed() -> void:
	_check(not game.experimental_phase_controller.should_show_boss_button(), "botao de boss ainda aparece")
	var viewport := Vector2(1280, 720)
	game._update_button_layout(viewport)
	if not game.buttons.has("boss"):
		return
	game.boss_ready = true
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	var tap: Vector2 = Rect2(game.buttons["boss"]).get_center()
	game.player_control_controller.handle_touch_press(0, tap, viewport)
	_check(float(game.boss_call_timer) < 0.0 and game.mode == "game", "toque na antiga area do botao ainda chama o boss")


# ------------------------------------------------------------------ item 2
func _talk_until_idle(talk: RTDialogueController) -> int:
	var lines := 0
	while talk.busy() and lines < 60:
		talk.grace = 0.0
		talk.revealed = 99999.0
		if talk.awaiting_choice():
			talk.choose(talk.choices().size() - 1)
		else:
			talk.advance_input()
		lines += 1
	return lines


func _check_veteran_skips_mission_talk() -> void:
	var npc: RTMerchantNpc = game._merchant_npc()
	var talk: RTDialogueController = game._dialogue()
	var dim: RTMerchantDimension = game._merchant_dimension()
	for veteran in [false, true]:
		npc.forget_story()
		npc.seen["intro"] = true
		npc.visits = 1
		npc.runs_started = RTMerchantNpc.SKIP_MISSION_TALK_FROM_RUN - (0 if veteran else 1)
		npc.begin_run(false) # retomar partida nao conta
		_check(npc.runs_started == RTMerchantNpc.SKIP_MISSION_TALK_FROM_RUN - (0 if veteran else 1), "retomar partida contou como partida nova")
		talk.clear()
		npc.greet(dim)
		_check(npc.mission_offered, "missao das capsulas nao foi oferecida (veterana=%s)" % str(veteran))
		if veteran:
			_check(not talk.busy(), "5a partida ainda abriu a explicacao da fenda")
			_check(npc.bubble.contains("Cápsulas"), "5a partida sem lembrete no balao")
		else:
			_check(talk.busy() and _talk_until_idle(talk) >= 8, "4a partida nao explicou a fenda")
	var before := npc.runs_started
	npc.begin_run(true)
	_check(npc.runs_started == before + 1, "partida nova nao contou")


# ------------------------------------------------------------------ item 3
func _check_no_direction_in_dialogue() -> void:
	var talk: RTDialogueController = game._dialogue()
	game.move_touch_index = 0
	game.touch_move = Vector2(1, 0)
	_check(game._read_move().length() > 0.5, "fixture: joystick sem direcao fora da conversa")
	talk.start([{"who": "mercador", "text": "Teste."}])
	_check(game._read_move() == Vector2.ZERO, "conversa aberta ainda recebe direcao de movimento")
	talk.clear()
	_check(game._read_move().length() > 0.5, "direcao nao voltou depois da conversa")
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO


# ------------------------------------------------------------------ item 4
func _check_question_menu_pauses_rift() -> void:
	var npc: RTMerchantNpc = game._merchant_npc()
	var talk: RTDialogueController = game._dialogue()
	var dim: RTMerchantDimension = game._merchant_dimension()
	game.shop_cards = [{}, {}, {}, {}]
	dim.enter()
	for _i in range(3):
		game._rift_transition().update(5.0)
	npc.seen["intro"] = true
	talk.clear()
	npc.open_menu(dim)
	talk.revealed = 99999.0
	talk.grace = 0.0
	_check(talk.spends_rift_time(), "menu de compra deveria gastar o tempo da fenda")
	var t0: float = dim.timer
	dim.update(0.5)
	_check(dim.timer > t0, "menu de compra congelou a fenda")
	talk.choose(1) # PERGUNTAR
	_check(talk.busy() and not talk.spends_rift_time(), "lista de perguntas marcada como gasto de tempo")
	var t1: float = dim.timer
	dim.update(1.0)
	_check(is_equal_approx(dim.timer, t1), "PERGUNTAR gastou o tempo da fenda")
	talk.revealed = 99999.0
	talk.grace = 0.0
	talk.choose(0) # tópico da Ruptura
	var t2: float = dim.timer
	dim.update(1.0)
	_check(is_equal_approx(dim.timer, t2), "resposta do Mercador gastou o tempo da fenda")
	talk.clear()
	dim.leave(false)


# ------------------------------------------------------------------ item 5
func _check_eletrica_current_stun() -> void:
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(200, 0))
	var enemy: Dictionary = game.enemies[-1]
	enemy["pos"] = game.player_pos + Vector2(200, 0)
	enemy["stun"] = 0.0
	enemy["hp"] = 100000.0
	enemy["max_hp"] = 100000.0
	var effect := {"kind": "eletrica", "life": 3.0, "max": 3.0, "a": game.player_pos, "b": game.player_pos + Vector2(400, 0), "tick": 0.0}
	game._update_tp_electric(effect, 0.01)
	_check(float(enemy.get("stun", 0.0)) >= game.TP_ELECTRIC_STUN - 0.001, "corrente da Eletrica nao deu choque (stun=%.2f)" % float(enemy.get("stun", 0.0)))
	_check(float(enemy.get("stun", 0.0)) <= 0.2, "choque longo demais")
	_check(float(enemy["hp"]) < 100000.0, "corrente parou de dar dano")


# ------------------------------------------------------------------ item 6
func _check_boss_entry_immunity() -> void:
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss1_time_wave.clear()
	game.boss1_rewind_sequence.clear()
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	game.boss_entry_timer = 1.0
	game._damage_boss(100.0, "eletrica")
	_check(is_equal_approx(float(game.boss_hp), 1000.0), "chefe tomou dano durante a entrada")
	game.boss_entry_timer = 0.0
	game._damage_boss(100.0, "eletrica")
	_check(float(game.boss_hp) < 1000.0, "chefe nao tomou dano depois da entrada")
	for pair in [[RTSertaoController.PHASE, game.boss8_controller], [RTCriptaController.PHASE, game.boss9_controller], [RTBaileController.PHASE, game.boss10_controller]]:
		game.current_phase = int(pair[0])
		pair[1].mode = "entry"
		_check(game._boss_in_entry_animation(), "fase %d: modo entry nao conta como entrada" % int(pair[0]))
		pair[1].mode = "walk"
		_check(not game._boss_in_entry_animation(), "fase %d: fora da entrada ainda imune" % int(pair[0]))
	game.boss_active = false
