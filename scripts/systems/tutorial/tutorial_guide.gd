class_name RTTutorialGuide
extends RefCounted

## Tutorial adaptado à configuração do jogador + regras de controle.
##  - Textos de cada passo mudam conforme plataforma (PC/controle/toque), mira do
##    ataque (automática ou cursor), modo do teleporte e teclas configuradas, e
##    lembram que tudo pode ser mudado em Configurações.
##  - Regra de controle: com o ataque em mira automática (sem mouse), o
##    teleporte não pode depender do cursor -> vai para a última direção.
##  - Passos novos: CONTROLES (resumo da config), TP x LINHA DE DANO (o teleporte
##    atravessa a linha sem tomar dano), MISSÃO (ficar forte e chamar o chefe).
##  - Liberação progressiva: só o que já foi ensinado pode ser usado no treino.
##  - Contextuais: Fenda do Mercador ao abrir; Inimigo Extraordinário ao surgir.
##  - Missão na tela durante a run do tutorial até derrotar o primeiro chefe.

const STATE_CONTROLS := "controls"
const STATE_DASH_LINE := "dash_line"
const STATE_MISSION := "mission"
const STATE_EXTRAORDINARY := "extraordinary_context"
const SAVE_PATH := "user://tutorial_guide.cfg"

const LINE_OFFSET := 190.0
const LINE_HALF_HEIGHT := 1600.0
const STRONG_TIME := 150.0
const LINE_WIDTH := 26.0
const GOAL_OFFSET := 360.0

var core
var persist := true
var seen_extraordinary := false
var mission_active := false
var mission_banner := 0.0
var line_x := 0.0
var line_y := 0.0
var line_hits := 0
var line_cleared := false
var _clear_hold := 0.0
var _line_prev_x := 0.0
var _line_tick := 0.0
var _blocked_text_cd := 0.0
var _rift_was_active := false
var _scan_cd := 0.0
var strong_until := 0.0
var _call_prompted := false
var rift_context := false


func configure(runtime_core) -> void:
	core = runtime_core
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		persist = false
	if persist:
		var cfg := ConfigFile.new()
		if cfg.load(SAVE_PATH) == OK:
			seen_extraordinary = bool(cfg.get_value("guide", "seen_extraordinary", false))


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("guide", "seen_extraordinary", seen_extraordinary)
	cfg.save(SAVE_PATH)


func reset_run() -> void:
	mission_active = false
	mission_banner = 0.0
	line_cleared = false
	line_hits = 0
	_clear_hold = 0.0
	_rift_was_active = false
	_call_prompted = false
	rift_context = false


# ---------------------------------------------------------------- controles

func desktop() -> bool:
	return core._uses_desktop_ui() and not core.is_gamepad_active


func attack_auto() -> bool:
	return core._sanitize_desktop_attack_aim_mode(core.desktop_attack_aim_mode) == core.DESKTOP_ATTACK_AIM_AUTO


static func teleport_uses_cursor(mode: String, core_ref) -> bool:
	return mode in [core_ref.DESKTOP_TELEPORT_CURSOR, core_ref.DESKTOP_AIM_HOLD, core_ref.DESKTOP_AIM_CONFIRM]


## Modo real do teleporte no PC: sem mouse no ataque, nada de cursor no TP.
func effective_teleport_mode() -> String:
	var mode: String = core._sanitize_desktop_teleport_mode(core.desktop_teleport_mode)
	if attack_auto() and teleport_uses_cursor(mode, core):
		return core.DESKTOP_TELEPORT_LAST_DIRECTION
	return mode


## Modos que o jogador pode escolher nas configurações agora.
func allowed_teleport_modes() -> Array:
	if attack_auto():
		return [core.DESKTOP_TELEPORT_LAST_DIRECTION, core.DESKTOP_TELEPORT_AUTO]
	return [core.DESKTOP_TELEPORT_CURSOR, core.DESKTOP_AIM_HOLD, core.DESKTOP_AIM_CONFIRM, core.DESKTOP_TELEPORT_AUTO, core.DESKTOP_TELEPORT_LAST_DIRECTION]


func key(action: String) -> String:
	if core.is_gamepad_active:
		var b: int = int(core.gamepad_bindings.get(action, -1))
		var names := {0: "A", 1: "B", 2: "X", 3: "Y", 4: "SELECT", 6: "START", 9: "LB", 10: "RB"}
		return "[%s]" % String(names.get(b, "BOTAO %d" % b))
	if desktop():
		return "[%s]" % core._format_key_binding_name(core.keyboard_bindings.get(action, core.INPUT_BIND_NONE))
	var labels := {"attack": "ATK", "skill": "HAB1", "secondary": "ULT", "dash": "TP", "boss": "BOSS", "shop": "LOJA"}
	return "o botão %s" % String(labels.get(action, action.to_upper()))


func attack_text() -> String:
	if desktop():
		if attack_auto():
			return "Aperte %s: o disparo mira sozinho no inimigo mais próximo dentro do anel. Você só precisa chegar perto." % key("attack")
		return "Aponte o mouse e aperte %s: o disparo vai na direção do cursor." % key("attack")
	if core.is_gamepad_active:
		return "Aperte %s: a mira é automática no inimigo mais próximo. O analógico direito mira na mão." % key("attack")
	return "Toque %s: a mira é automática. Arraste o botão se quiser mirar na mão." % key("attack")


func dash_text() -> String:
	if desktop():
		match effective_teleport_mode():
			core.DESKTOP_TELEPORT_LAST_DIRECTION:
				return "Ande numa direção e aperte %s: Geovana teleporta para a última direção em que você andou." % key("dash")
			core.DESKTOP_TELEPORT_AUTO:
				return "Aperte %s: Geovana teleporta em direção ao inimigo mais próximo." % key("dash")
			core.DESKTOP_AIM_HOLD:
				return "Segure %s, mire com o mouse e solte para teleportar." % key("dash")
			core.DESKTOP_AIM_CONFIRM:
				return "Aperte %s, mire com o mouse e aperte de novo para teleportar." % key("dash")
		return "Aperte %s: Geovana teleporta até onde está o cursor." % key("dash")
	return "Ande numa direção e use %s: Geovana teleporta para onde você está indo." % key("dash")


func settings_hint() -> String:
	return "Mude em CONFIGURAÇÕES > JOGABILIDADE" if desktop() else "Mude em CONFIGURAÇÕES > CONTROLES"


func controls_summary() -> String:
	var aim: String = ("AUTOMÁTICO" if attack_auto() else "CURSOR") if desktop() else "AUTOMÁTICO"
	var tp: String = String(core._desktop_teleport_mode_label()) if desktop() else "DIREÇÃO DO MOVIMENTO"
	var lines: Array = [
		"Disparo: %s  %s" % [aim, key("attack")],
		"Teleporte: %s  %s" % [tp, key("dash")],
		"Habilidades: %s e %s" % [key("skill"), key("secondary")],
	]
	if desktop() and attack_auto():
		lines.append("Com o disparo automático, o teleporte não usa o mouse.")
	return "\n".join(lines)


## Textos de cada passo, montados com a configuração atual.
func step_text(state: String) -> Dictionary:
	match state:
		STATE_CONTROLS:
			return {"title": "SEUS CONTROLES", "body": controls_summary() + "\n\nTudo isso pode ser mudado a qualquer momento nas configurações.", "hint": settings_hint()}
		core.TUTORIAL_STATE_ATTACK:
			return {"title": "DISPARO", "body": attack_text(), "hint": "Derrube o alvo para continuar  ·  " + settings_hint()}
		core.TUTORIAL_STATE_SKILL:
			return {"title": "HABILIDADE 1", "body": "Aperte %s. Cada Manifestação tem uma primeira técnica diferente; sinta o ritmo dela antes do caos." % key("skill"), "hint": "Acerte o alvo com %s" % key("skill")}
		core.TUTORIAL_STATE_SECONDARY:
			return {"title": "HABILIDADE 2", "body": "Aperte %s. A segunda habilidade recarrega devagar e serve para virar momentos perigosos." % key("secondary"), "hint": "Acerte o alvo com %s" % key("secondary")}
		core.TUTORIAL_STATE_DASH:
			return {"title": "TELEPORTE", "body": dash_text(), "hint": "Saia da zona marcada com %s  ·  %s" % [key("dash"), settings_hint()]}
		STATE_DASH_LINE:
			return {"title": "ATRAVESSE A LINHA", "body": "Linhas de dano machucam quem anda por elas, mas o teleporte passa por cima sem tomar dano. " + dash_text(), "hint": "Teleporte para o outro lado da linha"}
		STATE_MISSION:
			return {"title": "SUA MISSÃO", "body": "Geovana ainda está fraca para o guardião desta dimensão. Derrote inimigos para ganhar pontos, compre cartas na Fenda do Mercador e, quando estiver pronta, chame o chefe no altar.", "hint": "A missão fica no canto da tela durante a partida."}
		core.TUTORIAL_STATE_SHOP:
			return {"title": "FENDA DO MERCADOR", "body": "Uma Fenda do Mercador abriu no mapa. É a loja: lá você troca pontos por cartas que mudam a sua build. Siga a seta na borda da tela até a fenda; ela fecha depois de um tempo.", "hint": "Enquanto a loja está aberta, a partida fica pausada."}
		core.TUTORIAL_STATE_BOSS_CALL:
			var where: String = "Vá até o altar (siga a seta na borda da tela) para chamar o chefe." if core.experimental_phase_controller.uses_definitive_world() else "Use %s para chamar o chefe." % key("boss")
			return {"title": "CHAMAR O CHEFE", "body": "Você escolhe quando enfrentar o chefe. " + where + " Ficar mais tempo deixa Geovana mais forte, mas a dimensão também fica mais perigosa.", "hint": "Chamar é decisão sua."}
		STATE_EXTRAORDINARY:
			return {"title": "INIMIGO SUPREMO", "body": "Alguns inimigos são raros e bem mais fortes que a horda: têm mecânicas próprias, um nome sobre a cabeça e uma barra de vida. Derrotá-los rende recompensas maiores, sempre com uma Cinzas da Escolha; ignorá-los também é uma escolha.", "hint": "Fique atenta ao padrão de ataque antes de chegar perto."}
	return Dictionary(core.TUTORIAL_STEP_TEXTS.get(state, {}))


# ------------------------------------------------------------ permissões

## Liberação progressiva no treino: só usa o que já foi ensinado.
func action_allowed(action: String) -> bool:
	var s: String = String(core.tutorial_state)
	var order := {"attack": 0, "skill": 1, "secondary": 2, "dash": 3}
	var stage := -1
	match s:
		STATE_CONTROLS:
			stage = -1
		core.TUTORIAL_STATE_ATTACK:
			stage = 0
		core.TUTORIAL_STATE_SKILL:
			stage = 1
		core.TUTORIAL_STATE_SECONDARY:
			stage = 2
		core.TUTORIAL_STATE_DASH, STATE_DASH_LINE:
			stage = 3
		_:
			return true
	var need: int = int(order.get(action, 0))
	if need <= stage:
		return true
	if _blocked_text_cd <= 0.0:
		_blocked_text_cd = 1.0
		core._add_text("AINDA NÃO: SIGA O PASSO ATUAL", core.player_pos + Vector2(-110, -96), Color(1.0, 0.72, 0.3), 0.8, 16)
	return false


# ------------------------------------------------------- linha de dano

func begin_dash_line() -> void:
	line_x = float(core.player_pos.x) + LINE_OFFSET
	line_y = float(core.player_pos.y)
	_line_prev_x = float(core.player_pos.x)
	line_cleared = false
	line_hits = 0
	_clear_hold = 0.0


func update_dash_line(delta: float) -> void:
	var p: Vector2 = core.player_pos
	_line_tick = maxf(0.0, _line_tick - delta)
	var crossed: bool = _line_prev_x < line_x and p.x >= line_x
	var dashed: bool = float(core.time_alive) - float(core.last_dash_time) < 0.2
	if crossed and not dashed:
		# Andou por dentro: a linha queima e empurra de volta.
		core.player_pos = Vector2(line_x - LINE_WIDTH - 6.0, p.y)
		line_hits += 1
		if _line_tick <= 0.0:
			_line_tick = 0.5
			core._damage_player(maxi(1, int(round(float(core.player_hp_max) * 0.03))), "tutorial_line")
			core._add_text("ANDANDO QUEIMA! USE O TP", Vector2(line_x - 120, p.y - 90), Color(1.0, 0.4, 0.3), 1.0, 18)
		p = core.player_pos
	elif crossed and dashed:
		line_cleared = true
		core._add_text("SEM DANO!", p + Vector2(-48, -96), Color(0.4, 1.0, 0.7), 1.2, 24)
	_line_prev_x = p.x
	if line_cleared:
		_clear_hold += delta
		if _clear_hold >= 0.9:
			core._advance_tutorial(core.TUTORIAL_STATE_MANIFESTATION)


func draw_dash_line(game: Node2D, camera: Vector2, t: float) -> void:
	var a := Vector2(line_x, line_y - LINE_HALF_HEIGHT) - camera
	var b := Vector2(line_x, line_y + LINE_HALF_HEIGHT) - camera
	var pulse: float = 0.5 + 0.5 * sin(t * 9.0)
	game.draw_line(a, b, Color(1.0, 0.1, 0.12, 0.18), LINE_WIDTH * 2.2, true)
	game.draw_line(a, b, Color(1.0, 0.25, 0.2, 0.55 + 0.3 * pulse), LINE_WIDTH * 0.6, true)
	game.draw_line(a, b, Color(1.0, 0.85, 0.7, 0.9), 3.0, true)
	for k in range(10):
		var y: float = fposmod(t * 160.0 + float(k) * 70.0, LINE_HALF_HEIGHT * 2.0)
		var sp: Vector2 = a + Vector2(sin(t * 7.0 + float(k)) * 8.0, y)
		game.draw_circle(sp, 3.0, Color(1.0, 0.6, 0.3, 0.8))
	var goal := Vector2(line_x + GOAL_OFFSET - LINE_OFFSET, line_y) - camera
	game.draw_arc(goal, 54.0, 0.0, TAU, 40, Color(0.2, 1.0, 0.8, 0.8), 3.0, true)
	game.draw_arc(goal, 54.0 + 8.0 * pulse, -t * 2.0, -t * 2.0 + PI, 30, Color(0.2, 1.0, 0.8, 0.5), 2.0, true)
	game._draw_centered("DESTINO", goal + Vector2(0, -66), 13, Color(0.6, 1.0, 0.9))
	var player_s: Vector2 = Vector2(core.player_pos) - camera
	if player_s.x < a.x:
		var from := player_s + Vector2(30, -40)
		var to := Vector2(a.x + 60.0, player_s.y - 40.0)
		game.draw_line(from, to, Color(0.3, 1.0, 0.85, 0.5 + 0.4 * pulse), 3.0, true)
		game.draw_colored_polygon(PackedVector2Array([to + Vector2(12, 0), to + Vector2(-6, -8), to + Vector2(-6, 8)]), Color(0.3, 1.0, 0.85, 0.9))
		game._draw_centered("TP", (from + to) * 0.5 + Vector2(0, -12), 14, Color(0.6, 1.0, 0.9))


# --------------------------------------------------- contextuais + missão

func update(delta: float) -> void:
	_blocked_text_cd = maxf(0.0, _blocked_text_cd - delta)
	mission_banner = maxf(0.0, mission_banner - delta)
	if core.tutorial_state == STATE_DASH_LINE:
		update_dash_line(delta)
	if core.mode != "game" or core._tutorial_active():
		return
	# Fenda do Mercador acabou de abrir: explica o que é (uma vez).
	var rift_active: bool = core.shop_rift_controller != null and core.shop_rift_controller.active()
	if rift_active and not _rift_was_active and not core.shop_tutorial_seen:
		rift_context = core._maybe_start_context_tutorial(core.TUTORIAL_STATE_SHOP)
	# Missão: depois do tempo de "ficar forte", ensina a chamar o chefe.
	if mission_active and not _call_prompted and mission_stage() == "call":
		_call_prompted = true
		if not core.boss_call_tutorial_seen:
			core._maybe_start_context_tutorial(core.TUTORIAL_STATE_BOSS_CALL)
			return
	_rift_was_active = rift_active
	if seen_extraordinary:
		return
	_scan_cd -= delta
	if _scan_cd > 0.0:
		return
	_scan_cd = 0.5
	var cam: Vector2 = core._camera(core.get_viewport_rect().size)
	var found := false
	if core._arauto_active():
		found = true
	else:
		for enemy in core.enemies:
			if not is_extraordinary(enemy):
				continue
			if core._world_point_in_view(Vector2(enemy.get("pos", Vector2.INF)), cam, -40.0):
				found = true
				break
	if found and core._maybe_start_context_tutorial(STATE_EXTRAORDINARY):
		core._add_text("!", core.player_pos + Vector2(0, -110), Color(1.0, 0.8, 0.3), 0.8, 30)
		seen_extraordinary = true
		_save()


func is_extraordinary(enemy: Dictionary) -> bool:
	if core._is_boss_or_mini_boss_or_larapio(enemy):
		return true
	var kind: String = String(enemy.get("type", ""))
	return kind == core.ENEMY_SINEIRO_BOREAL or kind == core.ENEMY_AMBER_SUTURER or bool(enemy.get("elite", false))


func consume_rift_context() -> bool:
	var was: bool = rift_context
	rift_context = false
	return was


func start_mission() -> void:
	mission_active = true
	mission_banner = 4.0
	strong_until = float(core.time_alive) + STRONG_TIME
	_call_prompted = false


func mission_stage() -> String:
	if core.boss_dead:
		return "done"
	if core.boss_active or float(core.boss_call_timer) >= 0.0:
		return "fight"
	if float(core.time_alive) < strong_until:
		return "strong"
	return "call"


func mission_text() -> Array:
	# [titulo, detalhe]
	match mission_stage():
		"fight":
			return ["DERROTE O CHEFE", String(core.boss_name)]
		"done":
			return ["", ""]
		"strong":
			var left: int = maxi(0, int(ceil(strong_until - float(core.time_alive))))
			return ["FIQUE MAIS FORTE", "Derrote inimigos e compre cartas (%d:%02d)" % [left / 60, left % 60]]
	if core.experimental_phase_controller.uses_definitive_world():
		return ["CHAME O CHEFE", "Vá até o altar (siga a seta na borda)"]
	return ["CHAME O CHEFE", "Use %s quando estiver pronta" % key("boss")]


func draw_mission(game: Node2D, viewport: Vector2) -> void:
	if not mission_active or game.mode != "game":
		return
	var info: Array = mission_text()
	if String(info[0]) == "":
		mission_active = false
		return
	var face: Font = game.font
	var w: float = minf(400.0, viewport.x * 0.42)
	var rect := Rect2(Vector2(18.0, 104.0 if viewport.y >= 560.0 else 86.0), Vector2(w, 66.0))
	var pulse: float = 0.5 + 0.5 * sin(float(game.time_alive) * 3.0)
	game.draw_rect(rect, Color(0.02, 0.05, 0.07, 0.82), true)
	game.draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color(1.0, 0.78, 0.3, 0.9), true)
	game.draw_rect(rect, Color(1.0, 0.78, 0.3, 0.35 + 0.25 * pulse), false, 1.5)
	game.draw_string(face, rect.position + Vector2(14, 25), "MISSÃO", HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 13, Color(1.0, 0.78, 0.3, 0.95))
	game.draw_string(face, rect.position + Vector2(84, 25), String(info[0]), HORIZONTAL_ALIGNMENT_LEFT, w - 94.0, 19, Color(1, 1, 1, 0.98))
	game.draw_string(face, rect.position + Vector2(14, 52), String(info[1]), HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, 15, Color(0.86, 0.93, 1.0, 0.95))
	if mission_banner > 0.0:
		var a: float = clampf(mission_banner, 0.0, 1.0)
		game._draw_centered_outlined("GEOVANA PRECISA FICAR MAIS FORTE", Vector2(viewport.x * 0.5, viewport.y * 0.3), 28, Color(1.0, 0.84, 0.36, a), Color(0, 0, 0, 0.9 * a), 5)
		game._draw_centered_outlined("Depois, chame o chefe desta dimensão", Vector2(viewport.x * 0.5, viewport.y * 0.3 + 34.0), 18, Color(1, 1, 1, a), Color(0, 0, 0, 0.9 * a), 4)
