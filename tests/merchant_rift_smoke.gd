extends SceneTree

## Fenda do Mercador (solo): gatilhos, entrada, bonus de limite, fragmentos,
## colapso, interrupcao pelo boss e preservacao da contagem legada no online.

const MistGuide = preload("res://scripts/presentation/mist_guide_presentation.gd")

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("MERCHANT_RIFT_FAIL " + message)
	quit(1)


func _prepare_run() -> void:
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game.mode = "game"
	game.is_multiplayer = false
	game.shop_auto_enabled = true
	game.shop_rift_controller.allow_rift = true
	game.shop_auto_elapsed = 0.0
	game.score = int(game.card_cost) * 4


## Em solo a fenda nao abre mais uma tela: ela leva a Geovana para a oficina.
## A loja so abre quando ela encosta no balcao do Mercador.
func _open_counter(dimension) -> void:
	game._dialogue().clear()
	dimension.talked_this_visit = true
	dimension.counter_armed = true
	game.player_pos = RTMerchantDimension.MERCHANT_POS
	dimension.update(0.016)


func _run() -> void:
	_prepare_run()
	var rift_controller = game.shop_rift_controller
	_check(rift_controller.enabled(), "rift is not enabled in a solo automatic run")
	_check(not game.shop_controller.should_trigger_forced(), "legacy countdown still active while the rift owns the cadence")

	# 1) Marco de abates abre a fenda sem tirar o jogador do modo de jogo.
	game.shop_rift_kills = rift_controller.kill_milestone()
	rift_controller.update(0.016)
	_check(rift_controller.active(), "kill milestone did not open the rift")
	_check(game.mode == "game", "rift opening interrupted gameplay")
	_check(String(game.shop_rift.get("reason", "")) == "kills", "rift reason should be kills")
	var rift_pos: Vector2 = Vector2(game.shop_rift["pos"])
	_check(Rect2(Vector2.ZERO, game.WORLD_SIZE).has_point(rift_pos), "rift spawned outside the world")
	_check(rift_pos.distance_to(game.player_pos) >= 200.0, "rift spawned on top of the player")
	_check(not rift_controller.guide_target().is_empty(), "rift exposes no guide target")

	# 2) Abertura -> aberta.
	rift_controller.update(rift_controller.OPEN_TIME + 0.01)
	_check(rift_controller.state() == rift_controller.STATE_OPEN, "rift did not finish opening")

	# 3) Entrar pela fenda leva para a oficina; a loja abre no balcao.
	game.player_pos = rift_pos
	rift_controller.update(0.016)
	var dimension = game._merchant_dimension()
	_check(dimension.active, "walking into the rift did not open the merchant dimension")
	_check(rift_controller.state() == rift_controller.STATE_ENTERED, "rift did not register the entry")
	_open_counter(dimension)
	_check(game.mode == "shop", "shop did not open at the merchant counter")
	_check(game.shop_rerolls == game.SHOP_FREE_REROLLS_PER_VISIT, "plain entry granted unexpected rerolls")
	_check(game.shop_rift_kills == 0, "kill progress was not consumed by the entry")
	game.shop_controller.finish()
	dimension.leave(false)
	_check(not rift_controller.active(), "entered rift survived the shop exit")
	_check(game.shop_rift_next_allowed_time > game.time_alive, "no spacing after closing the rift shop")

	# 4) Ignorar a fenda guarda um fragmento.
	game.mode = "game"
	game.shop_rift_next_allowed_time = 0.0
	game.shop_last_exit_time = -999.0
	rift_controller.spawn("test", game.player_pos + Vector2(500.0, 0.0))
	game.shop_rift["state"] = rift_controller.STATE_OPEN
	game.shop_rift["age"] = rift_controller.LIFETIME
	rift_controller.update(0.016)
	_check(rift_controller.state() == rift_controller.STATE_COLLAPSING, "expired rift did not collapse")
	rift_controller.update(rift_controller.COLLAPSE_TIME + 0.01)
	_check(not rift_controller.active(), "collapsed rift was not cleared")
	_check(game.shop_rift_fragments == 1, "collapsed rift did not store a fragment")
	_check(game.shop_rift_next_allowed_time > game.time_alive, "collapse did not set a retry delay")

	# 5) Entrar no limite com fragmento: desconto extra e reroll extra.
	game.shop_rift_next_allowed_time = 0.0
	game.shop_endurance_discount = 0.0
	game.shop_auto_elapsed = 0.0
	rift_controller.spawn("test", game.player_pos + Vector2(420.0, 0.0))
	game.shop_rift["state"] = rift_controller.STATE_OPEN
	game.shop_rift["age"] = rift_controller.LIFETIME - 2.0
	_check(rift_controller.unstable(), "rift near expiry is not unstable")
	game.player_pos = Vector2(game.shop_rift["pos"])
	rift_controller.update(0.016)
	_check(dimension.active, "edge entry did not open the merchant dimension")
	_open_counter(dimension)
	_check(game.mode == "shop", "edge entry did not reach the counter")
	var expected_discount: float = rift_controller.EDGE_BONUS_DISCOUNT + rift_controller.FRAGMENT_DISCOUNT
	_check(game.shop_endurance_discount >= expected_discount - 0.001, "edge/fragment discount was not applied (%.3f)" % game.shop_endurance_discount)
	_check(game.shop_rerolls == game.SHOP_FREE_REROLLS_PER_VISIT + rift_controller.FRAGMENT_REROLLS, "fragment did not grant an extra reroll")
	_check(game.shop_rift_fragments == 0, "fragments were not consumed")
	game.shop_controller.finish()
	dimension.leave(false)

	# 6) Chamada do boss recolhe a fenda e devolve um fragmento.
	game.mode = "game"
	game.shop_rift_next_allowed_time = 0.0
	rift_controller.spawn("test", game.player_pos + Vector2(500.0, 0.0))
	game.boss_call_timer = 2.0
	rift_controller.update(0.016)
	_check(rift_controller.state() == rift_controller.STATE_COLLAPSING, "boss call did not collapse the rift")
	rift_controller.update(rift_controller.COLLAPSE_TIME + 0.01)
	_check(game.shop_rift_fragments == 1, "boss interruption did not refund a fragment")
	game.boss_call_timer = -1.0
	rift_controller.update(0.016)
	_check(not rift_controller.active(), "rift respawned during the retry delay")

	# 7) Rede de seguranca: o intervalo da loja automatica ainda garante a fenda.
	game.shop_rift_next_allowed_time = 0.0
	game.shop_last_exit_time = -999.0
	game.shop_rift_kills = 0
	game.score = 0
	game.shop_auto_elapsed = game.shop_auto_interval + 0.1
	rift_controller.update(0.016)
	_check(rift_controller.active() and String(game.shop_rift.get("reason", "")) == "interval", "interval fallback did not open the rift")
	rift_controller.clear_active()

	# 8) Online usa uma unica fenda autoritativa e replicas nao iniciam contagem.
	game.is_multiplayer = true
	game.online_room_owner = true
	_check(rift_controller.enabled(), "world authority did not own the multiplayer rift")
	_check(rift_controller.replaces_forced_countdown(), "authority retained the retired multiplayer countdown")
	game.online_room_owner = false
	game.is_host = false
	_check(not rift_controller.enabled(), "world replica attempted to simulate the multiplayer rift")
	_check(rift_controller.replaces_forced_countdown(), "world replica retained an independent shop countdown")
	game.is_multiplayer = false

	# 9) Troca de fase limpa a fenda ativa.
	rift_controller.spawn("test", game.player_pos + Vector2(500.0, 0.0))
	rift_controller.on_phase_changed()
	_check(not rift_controller.active(), "phase change kept the old rift")

	_check(MistGuide.blob_texture() != null, "mist blob texture unavailable")
	if failed:
		return
	print("MERCHANT_RIFT_OK kills=true dimension=true counter=true edge_bonus=true fragment=true collapse=true boss_refund=true interval_fallback=true online_authority=true phase_clear=true")
	quit(0)
