class_name RTBossDnaFusionScreen
extends RefCounted

## Tela da maquina de fusao (modo "dna_fusion"). O mundo fica parado.
## Em cima, os 9 tubos de DNA (cor de cada chefe + nome da dimensao); embaixo,
## as 3 habilidades do chefe escolhido. Fundir cobra a essencia e toca a
## animacao da Geovana entrando na maquina.
##
## Toque/mouse: toque no tubo, na habilidade e em FUNDIR/SAIR.
## Teclado: A/D ou setas = habilidade; W/S, Q/E ou Tab = chefe; Enter/Espaco/F
## = fundir; Esc = sair. Controle: direcional, LB/RB, A fundir, B sair.

const MODE := "dna_fusion"
const ANIM_TIME := 3.4
const ANIM_WALK := 0.9
const ANIM_FLASH := 2.3
const MESSAGE_TIME := 2.2

var core: Node = null
var selected_phase_index := 0
var selected_ability := 0
var opened_at := 0.0
## "" escolhendo; senao a habilidade sendo fundida (animacao).
var fusing_id := ""
var fusing_phase := 0
var fusing_started := 0.0
var message := ""
var message_until := 0.0
var _return_mode := "game"
var rects: Dictionary = {}


func configure(runtime_core: Node) -> void:
	core = runtime_core


func dna() -> RTBossDnaController:
	return core._merchant_dimension().dna


func is_open() -> bool:
	return core != null and String(core.mode) == MODE


func _now() -> float:
	return float(Time.get_ticks_msec()) * 0.001


func open() -> bool:
	if core == null or is_open():
		return false
	_return_mode = String(core.mode)
	core.mode = MODE
	opened_at = _now()
	fusing_id = ""
	message = ""
	selected_ability = 0
	selected_phase_index = 0
	var phases := RTBossDnaCatalog.PHASES
	for i in range(phases.size()):
		if dna().dna_count(phases[i]) > 0:
			selected_phase_index = i
			break
	core._play_sfx("ui_manifest_switch", 0.01, 0.4, 0.8)
	return true


func close() -> void:
	if not is_open():
		return
	core.mode = _return_mode if _return_mode != MODE else "game"
	fusing_id = ""
	rects.clear()
	# Volta ao lado da maquina, sem reabrir em seguida.
	core._merchant_dimension().machine.armed = false


func selected_phase() -> int:
	return RTBossDnaCatalog.PHASES[clampi(selected_phase_index, 0, RTBossDnaCatalog.PHASES.size() - 1)]


func selected_ability_id() -> String:
	var ids := RTBossDnaCatalog.boss_abilities(selected_phase())
	return String(ids[clampi(selected_ability, 0, ids.size() - 1)]) if not ids.is_empty() else ""


func step_boss(direction: int) -> void:
	selected_phase_index = posmod(selected_phase_index + direction, RTBossDnaCatalog.PHASES.size())
	core._play_sfx("ui_manifest_switch", 0.01, 0.24, 1.2)


func step_ability(direction: int) -> void:
	selected_ability = posmod(selected_ability + direction, 3)
	core._play_sfx("ui_manifest_switch", 0.01, 0.2, 1.35)


func confirm() -> bool:
	if fusing_id != "":
		return false
	var phase := selected_phase()
	var id := selected_ability_id()
	var reason := dna().fusion_block_reason(phase, id)
	if reason != "":
		_flash(reason)
		core._vibrate(40, 0.2)
		return false
	if not dna().fuse(phase, id):
		return false
	fusing_id = id
	fusing_phase = phase
	fusing_started = _now()
	core._vibrate(160, 0.5)
	return true


func _flash(text: String) -> void:
	message = text
	message_until = _now() + MESSAGE_TIME


## Avanca a animacao (chamado no desenho: o mundo esta parado neste modo).
func _tick_animation() -> void:
	if fusing_id == "":
		return
	if _now() - fusing_started >= ANIM_TIME:
		var name := String(RTBossDnaCatalog.ability(fusing_id).get("name", ""))
		var level := dna().rank(fusing_id)
		fusing_id = ""
		core.player_pos = RTBossDnaMachine.POS + Vector2(0.0, 70.0)
		_flash("%s · NÍVEL %d" % [name.to_upper(), level])
		core._add_text("FUSÃO: %s" % name.to_upper(), Vector2(core.player_pos) + Vector2(-110.0, -130.0), RTBossDnaCatalog.boss_color(fusing_phase), 2.4, 22)


# ================================================================ entrada
func handle_input(event: InputEvent) -> bool:
	if not is_open():
		return false
	if fusing_id != "":
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				step_ability(-1)
			KEY_RIGHT, KEY_D:
				step_ability(1)
			KEY_UP, KEY_W, KEY_Q:
				step_boss(-1)
			KEY_DOWN, KEY_S, KEY_E, KEY_TAB:
				step_boss(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F:
				confirm()
			KEY_ESCAPE, KEY_BACKSPACE:
				close()
		return true
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				step_ability(-1)
			JOY_BUTTON_DPAD_RIGHT:
				step_ability(1)
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_LEFT_SHOULDER:
				step_boss(-1)
			JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_RIGHT_SHOULDER:
				step_boss(1)
			JOY_BUTTON_A:
				confirm()
			JOY_BUTTON_B, JOY_BUTTON_START:
				close()
		return true
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed and _now() - opened_at > 0.2:
		tap(event.position)
	return true


func tap(pos: Vector2) -> void:
	for key in rects.keys():
		if not Rect2(rects[key]).has_point(pos):
			continue
		var name := String(key)
		if name == "fuse":
			confirm()
		elif name == "exit":
			close()
		elif name.begins_with("boss_"):
			selected_phase_index = int(name.trim_prefix("boss_"))
			selected_ability = clampi(selected_ability, 0, 2)
			core._play_sfx("ui_manifest_switch", 0.01, 0.24, 1.2)
		elif name.begins_with("ability_"):
			selected_ability = int(name.trim_prefix("ability_"))
			core._play_sfx("ui_manifest_switch", 0.01, 0.2, 1.35)
		return


# ================================================================ desenho
func draw(g: Node2D, viewport: Vector2) -> void:
	_tick_animation()
	rects.clear()
	var t := _now()
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.03, 0.07, 0.94), true)
	if fusing_id != "":
		RTBossDnaPresentation.draw_fusion_animation(g, viewport, fusing_phase, fusing_id, clampf((t - fusing_started) / ANIM_TIME, 0.0, 1.0), t)
		return
	var small: bool = viewport.y < 560.0
	var margin: float = maxf(16.0, viewport.x * 0.025)
	var focus := RTBossDnaCatalog.boss_color(selected_phase())
	# Brilho da cor do chefe escolhido atras de tudo.
	g.draw_circle(Vector2(viewport.x * 0.5, viewport.y * 0.62), viewport.x * 0.42, Color(focus.r, focus.g, focus.b, 0.06))
	var header_h: float = 40.0 if small else 52.0
	RTBossDnaPresentation.text(g, "MÁQUINA DE FUSÃO · REDE DO PETRO", Rect2(margin, margin * 0.6, viewport.x * 0.55, header_h), 26 if not small else 20, Color(0.86, 0.96, 1.0))
	var info := "ESSÊNCIA %s   ·   FUSÃO %s" % [core._format_points(int(core.score)), core._format_points(dna().next_cost())]
	RTBossDnaPresentation.text(g, info, Rect2(viewport.x * 0.5, margin * 0.6, viewport.x * 0.5 - margin, header_h), 18 if not small else 15, Color(1.0, 0.84, 0.32), HORIZONTAL_ALIGNMENT_RIGHT)
	var strip_top: float = margin * 0.6 + header_h + 6.0
	var strip_h: float = clampf(viewport.y * 0.25, 96.0, 168.0)
	_draw_strip(g, Rect2(margin, strip_top, viewport.x - margin * 2.0, strip_h), t, small)
	var button_h: float = 46.0 if small else 56.0
	var cards_top: float = strip_top + strip_h + (10.0 if small else 18.0)
	var cards_bottom: float = viewport.y - margin * 0.6 - button_h - (8.0 if small else 14.0)
	_draw_cards(g, Rect2(margin, cards_top, viewport.x - margin * 2.0, cards_bottom - cards_top), t, small)
	_draw_footer(g, Rect2(margin, viewport.y - margin * 0.6 - button_h, viewport.x - margin * 2.0, button_h), focus, t, small)


func _draw_strip(g: Node2D, area: Rect2, t: float, small: bool) -> void:
	var phases := RTBossDnaCatalog.PHASES
	var gap: float = 6.0 if small else 10.0
	var w: float = (area.size.x - gap * float(phases.size() - 1)) / float(phases.size())
	for i in range(phases.size()):
		var phase: int = phases[i]
		var rect := Rect2(area.position.x + float(i) * (w + gap), area.position.y, w, area.size.y)
		rects["boss_%d" % i] = rect
		var owned_count := 0
		for id in RTBossDnaCatalog.boss_abilities(phase):
			if dna().rank(String(id)) > 0:
				owned_count += 1
		RTBossDnaPresentation.draw_dna_tube(g, rect, phase, dna().dna_count(phase), owned_count, i == selected_phase_index, core.phase_flow_controller.phase_region_name(phase), t, small)


func _draw_cards(g: Node2D, area: Rect2, t: float, small: bool) -> void:
	var phase := selected_phase()
	var ids := RTBossDnaCatalog.boss_abilities(phase)
	var gap: float = 10.0 if small else 18.0
	var w: float = (area.size.x - gap * 2.0) / 3.0
	for i in range(ids.size()):
		var rect := Rect2(area.position.x + float(i) * (w + gap), area.position.y, w, area.size.y)
		rects["ability_%d" % i] = rect
		var id := String(ids[i])
		RTBossDnaPresentation.draw_ability_card(g, rect, id, dna().rank(id), i == selected_ability, dna().dna_count(phase) > 0, t, small)


func _draw_footer(g: Node2D, area: Rect2, focus: Color, t: float, small: bool) -> void:
	var exit_rect := Rect2(area.position, Vector2(minf(220.0, area.size.x * 0.24), area.size.y))
	var fuse_rect := Rect2(area.end.x - minf(320.0, area.size.x * 0.32), area.position.y, minf(320.0, area.size.x * 0.32), area.size.y)
	rects["exit"] = exit_rect
	rects["fuse"] = fuse_rect
	var phase := selected_phase()
	var id := selected_ability_id()
	var reason := dna().fusion_block_reason(phase, id)
	var verb := "MELHORAR" if dna().rank(id) > 0 else "FUNDIR"
	RTBossDnaPresentation.draw_button(g, exit_rect, "SAIR", Color(0.62, 0.7, 0.86), true)
	RTBossDnaPresentation.draw_button(g, fuse_rect, "%s · %s" % [verb, core._format_points(dna().next_cost())], focus, reason == "")
	var mid := Rect2(exit_rect.end.x + 12.0, area.position.y, fuse_rect.position.x - exit_rect.end.x - 24.0, area.size.y)
	var line := reason
	var color := Color(1.0, 0.62, 0.42)
	if _now() < message_until and message != "":
		line = message
		color = Color(1.0, 0.92, 0.5)
	elif reason == "":
		line = "Entre na máquina: o Petro costura %s em você." % String(RTBossDnaCatalog.ability(id).get("name", ""))
		color = Color(0.78, 0.92, 1.0)
	RTBossDnaPresentation.text(g, line, mid, 16 if not small else 13, color, HORIZONTAL_ALIGNMENT_CENTER)
