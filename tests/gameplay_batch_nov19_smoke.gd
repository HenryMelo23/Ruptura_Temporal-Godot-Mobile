extends SceneTree

## Lote de 2026-11-19: Lagartona (Trenzinho maior/mais rapido e fome de
## fenda), atalhos padrao de teclado, M1 no disparo no cursor, padrao Android
## da primeira instalacao, Jogabilidade sem opcoes de toque no desktop, sem
## baloes de fala, modo de cor, Espreitador, teleporte sem imunidade gratis,
## Curater +50% e reconstituidos do Rebobinador.

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const CONFIG_PATH := "user://hud_config.save"

var game: Node
var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GAMEPLAY_BATCH_NOV19_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fresh_run() -> void:
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0


func _run() -> void:
	await process_frame
	var guard := UserFileGuard.new(CONFIG_PATH)
	_check_keyboard_defaults()
	_check_first_run_defaults()
	_check_gameplay_options()
	_check_color_vision()
	guard.restore()
	game.color_vision_mode = "off"
	game.ColorVisionFilterScript.apply(game)
	_fresh_run()
	_check_stalker()
	_fresh_run()
	_check_teleport_invulnerability()
	_fresh_run()
	_check_curater_and_reconstituted()
	_fresh_run()
	_check_lagartona()
	if failures.is_empty():
		print("GAMEPLAY_BATCH_NOV19_SMOKE_OK")
		quit(0)
	else:
		print("GAMEPLAY_BATCH_NOV19_SMOKE_FAILED %d" % failures.size())
		quit(1)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event


func _mouse(button: int) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


# ------------------------------------------------------------- itens 3 e 4
func _check_keyboard_defaults() -> void:
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_AUTO
	game._reset_keyboard_bindings()
	var expected: Dictionary = {"attack": KEY_SPACE, "skill": KEY_Q, "secondary": KEY_E, "dash": KEY_SHIFT, "lacerante_empower": KEY_J, "dance": KEY_O, "pause": KEY_ESCAPE, "boss": KEY_R, "interact": KEY_F}
	for action: String in expected:
		_check(String(game.keyboard_bindings.get(action, "")) == game._key_input_binding(int(expected[action])), "padrao de %s: %s" % [action, game.keyboard_bindings.get(action, "")])
	_check(not game._event_matches_keyboard_action(_mouse(MOUSE_BUTTON_LEFT), "attack"), "disparo automatico nao deveria atacar no M1")
	# Save antigo nunca personalizado migra para o padrao novo.
	game._load_keyboard_bindings(PackedStringArray(["MOUSE:1", "MOUSE:2", "KEY:81", "KEY:4194325", "KEY:82", "KEY:79", "KEY:4194305", "KEY:80", "KEY:66", "KEY:69"]))
	_check(String(game.keyboard_bindings["attack"]) == "KEY:32", "padrao antigo nao migrou")
	game._load_keyboard_bindings(PackedStringArray(["MOUSE:1", "MOUSE:2", "KEY:81", "KEY:4194325", "KEY:82", "KEY:79", "KEY:4194305", "KEY:80", "KEY:71", "KEY:69"]))
	_check(String(game.keyboard_bindings["boss"]) == "KEY:71", "save personalizado foi sobrescrito")
	# Disparo no cursor: M1 ataca e SPACE continua.
	game._reset_keyboard_bindings()
	game.keyboard_bindings["skill"] = game._mouse_input_binding(MOUSE_BUTTON_LEFT)
	game._cycle_desktop_attack_aim_mode()
	_check(game.desktop_attack_aim_mode == game.DESKTOP_ATTACK_AIM_CURSOR, "nao entrou no disparo no cursor")
	_check(game._event_matches_keyboard_action(_mouse(MOUSE_BUTTON_LEFT), "attack"), "M1 nao ataca no cursor")
	_check(game._event_matches_keyboard_action(_key(KEY_SPACE), "attack"), "SPACE saiu do ataque no cursor")
	_check(String(game.keyboard_bindings["skill"]) == game.INPUT_BIND_NONE, "M1 continuou em outra acao")
	_check(game.KeyboardBindingDefaultsScript.cursor_label("SPACE") == "MOUSE ESQ. + SPACE", "rotulo do ataque no cursor")
	game._cycle_desktop_attack_aim_mode()
	_check(not game._event_matches_keyboard_action(_mouse(MOUSE_BUTTON_LEFT), "attack"), "M1 continuou atacando no automatico")
	game._reset_keyboard_bindings()


# ------------------------------------------------------------------- item 5
func _check_first_run_defaults() -> void:
	var defaults = load("res://scripts/ui/first_run_hud_defaults.gd")
	_check(defaults.anchored(Vector2(1133.2, 573.2), Vector2(1600, 720)).is_equal_approx(Vector2(1453.2, 573.2)), "ataque nao ficou preso a direita")
	_check(defaults.anchored(Vector2(169.4, 459.0), Vector2(1280, 960)).is_equal_approx(Vector2(169.4, 699.0)), "joystick nao ficou preso embaixo")
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
	game.hud_attack_pos = Vector2.ZERO
	game.hud_attack_scale = 1.0
	game.analog_fixed = true
	game.auto_attack_range_opacity = 1.0
	game._load_config()
	_check(is_equal_approx(game.hud_attack_scale, 2.2), "escala do ataque da primeira execucao")
	_check(is_equal_approx(game.hud_secondary_scale, 1.5) and is_equal_approx(game.hud_lacerante_empower_scale, 1.4), "escalas da primeira execucao")
	_check(game.hud_attack_pos != Vector2.ZERO, "posicao do ataque nao aplicada")
	_check(not game.analog_fixed, "analogico dinamico nao virou padrao")
	_check(game.auto_attack_range_color_index == 2 and is_equal_approx(game.auto_attack_range_opacity, 0.7), "anel do alcance padrao")


# ------------------------------------------------------------- itens 6 e 7
func _check_gameplay_options() -> void:
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	var desktop: Array = game._gameplay_preference_keys()
	_check(not desktop.has("analog") and not desktop.has("haptics"), "desktop ainda mostra opcao de toque: %s" % str(desktop))
	_check(not desktop.has("geovana_bark"), "balao de fala ainda nas opcoes")
	_check(desktop.has("color_vision") and desktop.has("desktop_attack_aim"), "opcoes do desktop")
	var rects: Dictionary = game._gameplay_preferences_rects(Vector2(1280, 720))
	game.mode = "gameplay_settings"
	game.settings_buttons = rects
	game._handle_gameplay_settings_touch(Rect2(rects["fps"]).get_center(), Vector2(1280, 720))
	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	var android: Array = game._gameplay_preference_keys()
	_check(android.has("analog") and android.has("haptics") and not android.has("geovana_bark"), "android: %s" % str(android))


# ------------------------------------------------------------------- item 8
func _check_color_vision() -> void:
	game.color_vision_mode = "off"
	game.ColorVisionFilterScript.apply(game)
	_check(game.get_node_or_null("ColorVisionFilter") == null, "filtro existe desligado")
	game.ColorVisionFilterScript.cycle(game)
	_check(game.color_vision_mode == "protanopia", "ciclo do modo de cor")
	_check(game.get_node_or_null("ColorVisionFilter") != null, "filtro nao criado")
	game.color_vision_mode = "tritanopia"
	game._save_config()
	game.color_vision_mode = "off"
	game._load_config()
	_check(game.color_vision_mode == "tritanopia", "modo de cor nao persistiu")
	var layer: CanvasLayer = game.get_node_or_null("ColorVisionFilter") as CanvasLayer
	_check(layer != null and layer.layer > 120, "filtro nao recarregado")
	game.ColorVisionFilterScript.cycle(game, -3)
	_check(game.color_vision_mode == "off" and game.get_node_or_null("ColorVisionFilter") == null, "desligar nao removeu o filtro")


# ------------------------------------------------------------------- item 9
func _check_stalker() -> void:
	_check(game.STALKER_CAMO_REVEAL_DISTANCE < 300.0, "alcance de revelacao nao diminuiu")
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(250, 0))
	var stalker: Dictionary = game.enemies[-1]
	game._update_stalker(stalker, 0.016)
	_check(bool(stalker.get("invisible", false)), "a 250 px ainda deveria estar camuflado")
	var far_mult: float = float(stalker.get("stalker_close_mult", 1.0))
	stalker["pos"] = game.player_pos + Vector2(80, 0)
	game._update_stalker(stalker, 0.016)
	var near_mult: float = float(stalker.get("stalker_close_mult", 1.0))
	_check(near_mult > far_mult and near_mult > 1.3, "espreitador nao acelera perto (%.2f vs %.2f)" % [near_mult, far_mult])
	var before: Vector2 = Vector2(stalker["pos"])
	stalker["speed"] = 100.0
	game._move_enemy(stalker, 0.1)
	_check(Vector2(stalker["pos"]).distance_to(before) > 12.0, "multiplicador de proximidade nao chegou ao movimento")


# ------------------------------------------------------------------ item 10
func _check_teleport_invulnerability() -> void:
	game.manifestation_key = "lacerante"
	game.tp_effects.clear()
	_check(not game._player_invulnerable(), "jogador ja estava invulneravel")
	game.tp_effects.append({"kind": "lacerante", "life": 3.0, "max": 3.0, "targets": []})
	_check(not game._player_invulnerable(), "teleporte da Lacerante sem alvo deu imunidade")
	game.tp_effects[0]["targets"] = [{"kind": "enemy", "uid": 1}]
	_check(game._player_invulnerable(), "execucao do teleporte perdeu a protecao")
	game.tp_effects.clear()
	game.manifestation_key = "eletrica"
	game._execute_teleport(game.player_pos + Vector2(120, 0))
	_check(not game._player_invulnerable(), "Descarga da Eletrica ainda deixa imune")
	game.tp_effects.clear()


# ------------------------------------------------------------ itens 11 e 12
func _check_curater_and_reconstituted() -> void:
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_CURATER, game.player_pos + Vector2(400, 0))
	var curater: Dictionary = game.enemies[-1]
	_check(float(curater["speed"]) >= game.enemy_speed_base * 0.66, "curater nao ficou 50%% mais rapido (%.1f)" % float(curater["speed"]))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(300, 0))
	var common: Dictionary = game.enemies[-1]
	common["rewinder_returned"] = true
	common["reconstitute_immunity"] = 0.0
	common["reconstitute_time"] = 0.0
	common["hp"] = 1000.0
	common["max_hp"] = 1000.0
	game._damage_enemy(common, 100.0, "eletrica")
	var taken: float = 1000.0 - float(common["hp"])
	_check(taken > 0.0, "reconstituido nao levou dano")
	common["rewinder_returned"] = false
	common["hp"] = 1000.0
	game._damage_enemy(common, 100.0, "eletrica")
	var plain: float = 1000.0 - float(common["hp"])
	_check(taken < plain * 0.9, "armadura leve nao reduziu (%.1f vs %.1f)" % [taken, plain])
	common["speed"] = 100.0
	common["pos"] = game.player_pos + Vector2(400, 0)
	var start: Vector2 = Vector2(common["pos"])
	game._move_enemy(common, 0.1)
	var plain_step: float = Vector2(common["pos"]).distance_to(start)
	common["pos"] = start
	common["rewinder_returned"] = true
	game._move_enemy(common, 0.1)
	var fast_step: float = Vector2(common["pos"]).distance_to(start)
	_check(fast_step > plain_step * 1.3, "reconstituido nao ficou +35%% (%.2f vs %.2f)" % [fast_step, plain_step])
	# reconstituted_once sozinho (Suturador/Sineiro: "nao reconstituir") nao da bonus.
	common["rewinder_returned"] = false
	common["reconstituted_once"] = true
	common["pos"] = start
	game._move_enemy(common, 0.1)
	_check(is_equal_approx(Vector2(common["pos"]).distance_to(start), plain_step), "reconstituted_once deu velocidade sem Rebobinador")
	common["hp"] = 1000.0
	game._damage_enemy(common, 100.0, "eletrica")
	_check(is_equal_approx(1000.0 - float(common["hp"]), plain), "reconstituted_once deu armadura sem Rebobinador")
	# O Rebobinador de verdade grava a marca propria.
	_check(game.has_method("_try_reconstitute_enemy"), "_try_reconstitute_enemy sumiu")


# ------------------------------------------------------------- itens 1 e 2
func _check_lagartona() -> void:
	_check(RTBaileLagartona.TREM_SPEED > 520.0 and RTBaileLagartona.TREM_OVERSHOOT > 260.0, "trenzinho nao ficou maior/mais rapido")
	var c: RTBaileController = game.baile_controller
	game._advance_to_phase(10)
	game._story().queue.clear()
	game.mode = "game"
	var home: Vector2 = c.fight_anchor() + Vector2(0, 400)
	game.player_pos = home
	game.enemies.clear()
	c.miniboss_spawned = false
	game.boss_active = false
	game.phase_started_at = game.time_alive - (c.LAGARTONA_SPAWN_TIME + 1.0)
	c.update(1.0 / 30.0)
	_check(c.miniboss_alive(), "lagartona nao apareceu")
	if not c.miniboss_alive():
		return
	var lag: Dictionary = c.miniboss()
	lag["pos"] = home + Vector2(300, 0)
	lag["b10_state"] = "walk"
	c.lagartona.state = "walk"
	var fragments: int = int(game.shop_rift_fragments)
	game.shop_rift_controller.spawn("test", home + Vector2(300, 260))
	var rift_pos: Vector2 = Vector2(game.shop_rift["pos"])
	var start_dist: float = Vector2(lag["pos"]).distance_to(rift_pos)
	var swallowed := false
	for i in range(int(12.0 * 30.0)):
		game.time_alive += 1.0 / 30.0
		game._update_enemies(1.0 / 30.0)
		c.update(1.0 / 30.0)
		game.player_pos = home
		game.player_hp = game.player_hp_max
		if game.shop_rift.is_empty() or String(game.shop_rift.get("state", "")) == "collapsing":
			swallowed = true
			break
	_check(swallowed, "lagartona nao engoliu a fenda (dist inicial %.0f, agora %.0f)" % [start_dist, Vector2(lag["pos"]).distance_to(rift_pos)])
	_check(int(game.shop_rift_fragments) == fragments, "fenda engolida rendeu fragmento")
