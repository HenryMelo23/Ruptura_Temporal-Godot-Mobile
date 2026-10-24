class_name RTCharacterSelectPresentation
extends RefCounted

const CYAN := Color(0.12, 0.94, 1.0)
const ORANGE := Color(1.0, 0.42, 0.08)
const HENRY_AMBER := Color(1.0, 0.76, 0.22)
const HENRY_BONE := Color(0.95, 0.9, 0.76)
const HENRY_CHOICE_ICON_TEXTURES := {
	"incendiario": preload("res://assets/ui/henry_choices/mutacao_incendiario.png"),
	"barometrico": preload("res://assets/ui/henry_choices/mutacao_barometrico.png"),
	"colosso": preload("res://assets/ui/henry_choices/mutacao_colosso_d37.png"),
	"incandescencia": preload("res://assets/ui/henry_choices/efeito_incandescencia.png"),
	"nimbo": preload("res://assets/ui/henry_choices/efeito_nimbo.png"),
	"lastro": preload("res://assets/ui/henry_choices/efeito_lastro.png"),
}

static var _henry_stage_by_game: Dictionary = {}
static var _henry_stage_change_ms_by_game: Dictionary = {}
static var _henry_choice_by_game: Dictionary = {}
static var _henry_choice_change_ms_by_game: Dictionary = {}


static func draw(game: Node2D, viewport: Vector2) -> void:
	if game.mode == "character_select":
		game._draw_holo_background(viewport, game.textures.get("choice_bg"), CYAN)
		_draw_character_cards(game, viewport)
	else:
		game._draw_holo_background(viewport, null, ORANGE)
		_draw_henry_build_step(game, viewport)


static func _draw_character_cards(game: Node2D, viewport: Vector2) -> void:
	game._draw_glitch_title("ESCOLHA QUEM ATRAVESSA", Vector2(viewport.x * 0.5, 66.0), 34, CYAN)
	game._draw_centered("Escolha o personagem e como as cartas entram na jornada.", Vector2(viewport.x * 0.5, 106.0), 15, Color(0.78, 0.92, 1.0))
	var card_size := Vector2(minf(330.0, viewport.x * 0.36), minf(390.0, viewport.y * 0.54))
	var gap := minf(50.0, viewport.x * 0.04)
	var total := card_size.x * 2.0 + gap
	var left := Rect2(Vector2((viewport.x - total) * 0.5, 138.0), card_size)
	var right := Rect2(Vector2(left.end.x + gap, 138.0), card_size)
	game.buttons["character_geovana"] = left
	game.buttons["character_henry"] = right
	game.buttons["character_back"] = Rect2(30.0, viewport.y - 66.0, 170.0, 42.0)
	_draw_character_card(game, left, "GEOVANA", "Manifestações + Espectros", game._frame_texture("player_idle", 160, "player_fire"), game.character_select_index == 0, true, CYAN)
	var unlocked: bool = game._henry_unlocked()
	_draw_character_card(game, right, "HENRY", "Mutações + Efeitos", game._frame_texture("henry_idle", 165, "player_idle"), game.character_select_index == 1, unlocked, ORANGE)
	var mode_y := minf(left.end.y + 16.0, viewport.y - 116.0)
	var mode_width := minf(520.0, viewport.x * 0.52)
	var mode_gap := 10.0
	var mode_button_width := (mode_width - mode_gap) * 0.5
	var mode_left := viewport.x * 0.5 - mode_width * 0.5
	game.buttons["journey_mode_shop"] = Rect2(mode_left, mode_y, mode_button_width, 40.0)
	game.buttons["journey_mode_drop"] = Rect2(mode_left + mode_button_width + mode_gap, mode_y, mode_button_width, 40.0)
	_draw_mode_button(game, game.buttons["journey_mode_shop"], "LOJA", "compras entre combates", game.selected_run_mode == game.RUN_MODE_SHOP, CYAN)
	_draw_mode_button(game, game.buttons["journey_mode_drop"], "DROP", "cartas dos inimigos", game.selected_run_mode == game.RUN_MODE_DROP, Color(1.0, 0.68, 0.18))
	game._draw_centered("A/D PERSONAGEM  •  W/S MODO  •  ENTER CONFIRMA", Vector2(viewport.x * 0.5, mode_y + 62.0), 11, Color(0.66, 0.78, 0.84))
	_draw_button(game, game.buttons["character_back"], "VOLTAR", false, Color(0.55, 0.72, 0.78))


static func _draw_mode_button(game: Node2D, rect: Rect2, title: String, subtitle: String, selected: bool, accent: Color) -> void:
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.2 if selected else 0.055), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.96 if selected else 0.42), false, 2.5 if selected else 1.2)
	game.draw_string(game.font, rect.position + Vector2(14.0, 17.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.34, 14, Color(0.96, 1.0, 1.0))
	game.draw_string(game.font, rect.position + Vector2(rect.size.x * 0.35, 17.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.6, 11, Color(accent.r, accent.g, accent.b, 0.92))


static func _draw_character_card(game: Node2D, rect: Rect2, title: String, subtitle: String, texture: Texture2D, selected: bool, unlocked: bool, accent: Color) -> void:
	var alpha := 0.94 if unlocked else 0.52
	game.draw_rect(rect, Color(0.012, 0.025, 0.035, 0.92), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, alpha), false, 4.0 if selected else 2.0)
	if selected:
		game.draw_rect(rect.grow(7.0), Color(accent.r, accent.g, accent.b, 0.18), false, 2.0)
	var portrait := Rect2(rect.position + Vector2(30.0, 32.0), Vector2(rect.size.x - 60.0, rect.size.y * 0.55))
	if texture != null:
		game._draw_entity_fit(texture, portrait.get_center(), portrait.size, Color(1.0, 1.0, 1.0, alpha), true)
	game._draw_centered(title, Vector2(rect.get_center().x, rect.end.y - 92.0), 28, Color(0.95, 0.99, 1.0, alpha))
	game._draw_centered(subtitle, Vector2(rect.get_center().x, rect.end.y - 56.0), 15, Color(accent.r, accent.g, accent.b, alpha))
	if not unlocked:
		game.draw_rect(Rect2(rect.position + Vector2(18.0, rect.size.y * 0.44), Vector2(rect.size.x - 36.0, 72.0)), Color(0.02, 0.02, 0.025, 0.88), true)
		game._draw_centered("DERROTE A UMBRA", Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.44 + 28.0), 17, Color(1.0, 0.58, 0.28))
		game._draw_centered("para liberar Henry", Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.44 + 52.0), 13, Color(0.86, 0.88, 0.9))


static func _draw_henry_build_step(game: Node2D, viewport: Vector2) -> void:
	var mutation_step: bool = game.mode == "mutation_select" or game.mode == "mutation_select_mp"
	var items: Array = game.HENRY_MUTATIONS if mutation_step else game.HENRY_EFFECTS
	var selected_index: int = game.selected_mutation if mutation_step else game.selected_effect
	selected_index = clampi(selected_index, 0, items.size() - 1)
	var item: Dictionary = items[selected_index]
	var accent: Color = item.get("accent", ORANGE)
	var compact: bool = viewport.x < 1100.0 or viewport.y < 650.0
	var game_id: int = game.get_instance_id()
	var stage_key := "mutation" if mutation_step else "effect"
	var choice_key := "%s:%d" % [stage_key, selected_index]
	var now_ms: int = Time.get_ticks_msec()
	if String(_henry_stage_by_game.get(game_id, stage_key)) != stage_key:
		_henry_stage_change_ms_by_game[game_id] = now_ms
	_henry_stage_by_game[game_id] = stage_key
	if String(_henry_choice_by_game.get(game_id, choice_key)) != choice_key:
		_henry_choice_change_ms_by_game[game_id] = now_ms
	_henry_choice_by_game[game_id] = choice_key

	_draw_henry_background_marks(game, viewport, accent, mutation_step)
	var title_y := 46.0 if compact else 54.0
	game._draw_glitch_title("PROTOCOLO HENRY", Vector2(viewport.x * 0.28, title_y), 25 if compact else 30, HENRY_BONE)
	game._draw_centered("D37 // CONFIGURAÇÃO BIOMECÂNICA DE CAMPO", Vector2(viewport.x * 0.28, title_y + 30.0), 10 if compact else 12, Color(0.76, 0.79, 0.72, 0.9))
	_draw_henry_stage_indicator(game, viewport, mutation_step, accent, compact)

	var content_top := 96.0 if compact else 112.0
	var content_bottom := viewport.y - (62.0 if compact else 72.0)
	var content_h := maxf(300.0, content_bottom - content_top)
	var outer_margin := 24.0 if compact else 36.0
	var gap := 14.0 if compact else 22.0
	var available_w := viewport.x - outer_margin * 2.0 - gap
	var bank_w := available_w * (0.56 if compact else 0.57)
	var bank_rect := Rect2(outer_margin, content_top, bank_w, content_h)
	var detail_rect := Rect2(bank_rect.end.x + gap, content_top, available_w - bank_w, content_h)
	_draw_henry_choice_bank(game, bank_rect, items, selected_index, mutation_step, accent, compact, now_ms, game_id)
	_draw_henry_detail_panel(game, detail_rect, item, mutation_step, accent, compact)

	var continue_rect := Rect2(viewport.x - (218.0 if compact else 254.0), viewport.y - (52.0 if compact else 58.0), 194.0 if compact else 218.0, 40.0 if compact else 44.0)
	var back_rect := Rect2(outer_margin, continue_rect.position.y, 142.0 if compact else 166.0, continue_rect.size.y)
	game.buttons["henry_continue"] = continue_rect
	game.buttons["henry_back"] = back_rect
	var action_label := "CONTINUAR" if mutation_step else "INICIAR"
	if game.mode.ends_with("_mp") and not mutation_step:
		action_label = "INICIAR" if game._manifest_mp_start_available() else ("CANCELAR PRONTO" if game.mp_local_ready else "PRONTO")
	_draw_button(game, continue_rect, action_label, true, accent)
	_draw_button(game, back_rect, "VOLTAR", false, Color(0.63, 0.65, 0.58))
	game._draw_centered("A / D  OU  ◀ / ▶  ALTERA A ESCOLHA", Vector2(viewport.x * 0.5, continue_rect.get_center().y + 4.0), 9 if compact else 11, Color(0.74, 0.76, 0.69, 0.84))

	var stage_age := float(now_ms - int(_henry_stage_change_ms_by_game.get(game_id, now_ms))) * 0.001
	if stage_age < 0.46:
		_draw_henry_stage_transition(game, viewport, accent, stage_age / 0.46)


static func _draw_henry_background_marks(game: Node2D, viewport: Vector2, accent: Color, mutation_step: bool) -> void:
	var warm := Color(0.92, 0.29, 0.06, 0.16) if mutation_step else Color(0.94, 0.7, 0.18, 0.13)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(warm.r * 0.08, warm.g * 0.08, warm.b * 0.06, 0.22), true)
	for i in range(7):
		var y := 116.0 + float(i) * 78.0
		if y >= viewport.y - 58.0:
			break
		var start_x := 12.0 + float((i * 53) % 96)
		game.draw_line(Vector2(start_x, y), Vector2(minf(viewport.x - 12.0, start_x + 106.0), y - 18.0), Color(warm.r, warm.g, warm.b, 0.24), 1.0)
	for i in range(9):
		var x := 18.0 + float(i) * (viewport.x - 36.0) / 8.0
		game.draw_line(Vector2(x, 91.0), Vector2(x + 14.0, 97.0), Color(accent.r, accent.g, accent.b, 0.18), 1.0)


static func _draw_henry_stage_indicator(game: Node2D, viewport: Vector2, mutation_step: bool, accent: Color, compact: bool) -> void:
	var width := 308.0 if compact else 354.0
	var height := 38.0 if compact else 42.0
	var rect := Rect2(viewport.x - width - (24.0 if compact else 36.0), 30.0, width, height)
	var half := rect.size.x * 0.5
	game.draw_rect(rect, Color(0.018, 0.022, 0.02, 0.92), true)
	game.draw_rect(rect, Color(0.56, 0.52, 0.38, 0.55), false, 1.2)
	var active_rect := Rect2(rect.position + Vector2(2.0 if mutation_step else half, 2.0), Vector2(half - 2.0, height - 4.0))
	game.draw_rect(active_rect, Color(accent.r, accent.g, accent.b, 0.2), true)
	game.draw_rect(active_rect, Color(accent.r, accent.g, accent.b, 0.9), false, 2.0)
	game._draw_centered("01  MUTAÇÃO", Vector2(rect.position.x + half * 0.5, rect.get_center().y + 4.0), 11 if compact else 13, accent if mutation_step else Color(0.52, 0.53, 0.5))
	game._draw_centered("02  EFEITO", Vector2(rect.position.x + half * 1.5, rect.get_center().y + 4.0), 11 if compact else 13, accent if not mutation_step else Color(0.52, 0.53, 0.5))


static func _draw_henry_choice_bank(game: Node2D, rect: Rect2, items: Array, selected_index: int, mutation_step: bool, accent: Color, compact: bool, now_ms: int, game_id: int) -> void:
	game._draw_holo_panel(rect, Color(0.8, 0.35, 0.08) if mutation_step else HENRY_AMBER, true, 0.34)
	game.draw_rect(Rect2(rect.position, Vector2(5.0, rect.size.y)), Color(accent.r, accent.g, accent.b, 0.72), true)
	game.draw_string(game.font, rect.position + Vector2(20.0, 28.0), "BANCO DE %s" % ("MUTAÇÕES" if mutation_step else "EFEITOS"), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40.0, 13 if compact else 16, HENRY_BONE)
	game.draw_string(game.font, rect.position + Vector2(20.0, 48.0), "SELECIONE A ASSINATURA QUE HENRY LEVA PARA A RUPTURA", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40.0, 8 if compact else 10, Color(0.69, 0.72, 0.67, 0.86))

	var count := items.size()
	var card_area := Rect2(rect.position + Vector2(16.0, 62.0 if compact else 70.0), Vector2(rect.size.x - 32.0, rect.size.y - (84.0 if compact else 96.0)))
	var base_card_w := minf(174.0, (card_area.size.x - 22.0) / 2.55)
	var base_card_h := minf(244.0, card_area.size.y - 18.0)
	var spacing := minf(base_card_w * 1.05, card_area.size.x * 0.33)
	var center := card_area.get_center() + Vector2(0.0, -2.0)
	var choice_age := float(now_ms - int(_henry_choice_change_ms_by_game.get(game_id, now_ms))) * 0.001
	for i in range(count):
		var relative := i - selected_index
		var half_count := float(count) * 0.5
		if float(relative) > half_count:
			relative -= count
		elif float(relative) < -half_count:
			relative += count
		var selected := i == selected_index
		var scale := 1.0 if selected else 0.79
		var card_size := Vector2(base_card_w, base_card_h) * scale
		var card_center := center + Vector2(float(relative) * spacing, 0.0)
		var card_rect := Rect2(card_center - card_size * 0.5, card_size)
		var card_item: Dictionary = items[i]
		var card_accent: Color = card_item.get("accent", accent)
		var opacity := 1.0 if selected else 0.58
		game.buttons["henry_choice_%d" % i] = card_rect.grow(5.0)
		game.draw_rect(card_rect, Color(0.018, 0.022, 0.02, 0.96 if selected else 0.84), true)
		game.draw_rect(card_rect, Color(card_accent.r, card_accent.g, card_accent.b, 0.96 if selected else 0.38), false, 3.0 if selected else 1.2)
		if selected:
			var pulse := 0.5 + sin(float(now_ms) * 0.008) * 0.5
			game.draw_rect(card_rect.grow(6.0 + pulse * 2.0), Color(card_accent.r, card_accent.g, card_accent.b, 0.18 + pulse * 0.12), false, 1.6)
			if choice_age < 0.28:
				var scan_y := card_rect.position.y + card_rect.size.y * clampf(choice_age / 0.28, 0.0, 1.0)
				game.draw_line(Vector2(card_rect.position.x + 7.0, scan_y), Vector2(card_rect.end.x - 7.0, scan_y), Color(card_accent.r, card_accent.g, card_accent.b, 0.9), 2.0)
		var icon_center := card_rect.position + Vector2(card_rect.size.x * 0.5, card_rect.size.y * 0.39)
		_draw_henry_choice_icon(game, String(card_item.get("key", "")), icon_center, minf(card_rect.size.x, card_rect.size.y) * (0.25 if selected else 0.23), card_accent, opacity)
		game._draw_centered(String(card_item.get("name", "")).to_upper(), Vector2(card_rect.get_center().x, card_rect.end.y - (48.0 if selected else 39.0)), 13 if compact and selected else (15 if selected else 11), Color(HENRY_BONE.r, HENRY_BONE.g, HENRY_BONE.b, opacity))
		game._draw_centered("SELECIONADO" if selected else "DISPONÍVEL", Vector2(card_rect.get_center().x, card_rect.end.y - (22.0 if selected else 18.0)), 8 if compact else (9 if selected else 8), Color(card_accent.r, card_accent.g, card_accent.b, opacity))
	game._draw_centered("TOQUE EM UMA PLACA OU USE ESQUERDA / DIREITA", Vector2(rect.get_center().x, rect.end.y - 12.0), 8 if compact else 10, Color(0.72, 0.74, 0.68, 0.78))


static func _draw_henry_detail_panel(game: Node2D, rect: Rect2, item: Dictionary, mutation_step: bool, accent: Color, compact: bool) -> void:
	game._draw_holo_panel(rect, accent, true, 0.42)
	game.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color(accent.r, accent.g, accent.b, 0.88), true)
	var portrait: Texture2D = game._frame_texture("henry_idle", 165, "player_idle")
	var portrait_size := Vector2(58.0, 82.0) if compact else Vector2(72.0, 102.0)
	if portrait != null:
		var portrait_pos := Vector2(rect.end.x - portrait_size.x - 12.0, rect.position.y + 13.0)
		game.draw_texture_rect(portrait, Rect2(portrait_pos, portrait_size), false, Color(0.95, 0.86, 0.7, 0.34))
	var pad := 18.0 if compact else 22.0
	var text_w := rect.size.x - pad * 2.0
	game.draw_string(game.font, rect.position + Vector2(pad, 28.0), "DOSSIÊ // %s" % ("MUTAÇÃO" if mutation_step else "EFEITO"), HORIZONTAL_ALIGNMENT_LEFT, text_w - portrait_size.x * 0.5, 9 if compact else 11, Color(accent.r, accent.g, accent.b, 0.9))
	game.draw_string(game.font, rect.position + Vector2(pad, 55.0 if compact else 61.0), String(item.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, text_w - portrait_size.x * 0.55, 20 if compact else 25, HENRY_BONE)
	var desc_y := rect.position.y + (78.0 if compact else 92.0)
	var preview_h := 72.0 if compact else 88.0
	var preview_rect := Rect2(rect.position + Vector2(pad, rect.size.y - preview_h - pad), Vector2(text_w, preview_h))
	var desc_h := 66.0 if compact else 82.0
	game._draw_wrapped_clamped(String(item.get("desc", "")), Rect2(rect.position.x + pad, desc_y, text_w, desc_h), 11 if compact else 13, Color(0.88, 0.9, 0.84, 0.94), 4)
	var line_y := desc_y + desc_h + 2.0
	game.draw_line(Vector2(rect.position.x + pad, line_y), Vector2(rect.end.x - pad, line_y), Color(accent.r, accent.g, accent.b, 0.28), 1.0)
	var details_rect := Rect2(rect.position.x + pad, line_y + 10.0, text_w, maxf(54.0, preview_rect.position.y - line_y - 18.0))
	_draw_henry_detail_lines(game, details_rect, String(item.get("details", "")), accent, compact)
	_draw_henry_preview_reserve(game, preview_rect, mutation_step, accent, compact)


static func _draw_henry_detail_lines(game: Node2D, rect: Rect2, details: String, accent: Color, compact: bool) -> void:
	var lines := details.split("\n", false)
	var line_h := rect.size.y / float(maxi(1, lines.size()))
	for i in range(lines.size()):
		var line := String(lines[i])
		var separator := line.find(":")
		var label := line.substr(0, separator + 1) if separator >= 0 else "LEITURA"
		var body := line.substr(separator + 1).strip_edges() if separator >= 0 else line
		var y := rect.position.y + float(i) * line_h
		game.draw_rect(Rect2(rect.position.x, y + 2.0, 3.0, maxf(12.0, line_h - 7.0)), Color(accent.r, accent.g, accent.b, 0.72), true)
		game.draw_string(game.font, Vector2(rect.position.x + 9.0, y + 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, 52.0 if compact else 62.0, 9 if compact else 10, Color(accent.r, accent.g, accent.b, 0.96))
		var body_x := rect.position.x + (64.0 if compact else 75.0)
		game._draw_wrapped_clamped(body, Rect2(body_x, y + 2.0, rect.end.x - body_x, maxf(16.0, line_h - 5.0)), 9 if compact else 10, Color(0.82, 0.84, 0.78, 0.92), 2)


static func _draw_henry_preview_reserve(game: Node2D, rect: Rect2, mutation_step: bool, accent: Color, compact: bool) -> void:
	game.draw_rect(rect, Color(0.006, 0.008, 0.007, 0.88), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.24), false, 1.0)
	var corner := 12.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner_pos := Vector2(rect.get_center().x + sx * (rect.size.x * 0.5 - 7.0), rect.get_center().y + sy * (rect.size.y * 0.5 - 7.0))
			game.draw_line(corner_pos, corner_pos - Vector2(sx * corner, 0.0), Color(accent.r, accent.g, accent.b, 0.46), 1.4)
			game.draw_line(corner_pos, corner_pos - Vector2(0.0, sy * corner), Color(accent.r, accent.g, accent.b, 0.46), 1.4)
	game.draw_line(Vector2(rect.position.x + 18.0, rect.get_center().y), Vector2(rect.end.x - 18.0, rect.get_center().y), Color(accent.r, accent.g, accent.b, 0.08), 1.0)
	game._draw_centered("ESPAÇO DE PREVIEW // %s" % ("MUTAÇÃO" if mutation_step else "EFEITO"), rect.get_center() + Vector2(0.0, -5.0), 9 if compact else 11, Color(accent.r, accent.g, accent.b, 0.72))
	game._draw_centered("MÓDULO VISUAL RESERVADO PARA UMA ATUALIZAÇÃO FUTURA", rect.get_center() + Vector2(0.0, 13.0), 7 if compact else 8, Color(0.58, 0.6, 0.56, 0.78))


static func _draw_henry_choice_icon(game: Node2D, key: String, center: Vector2, radius: float, accent: Color, opacity: float) -> void:
	var icon_texture: Texture2D = HENRY_CHOICE_ICON_TEXTURES.get(key)
	if icon_texture != null:
		var icon_size := Vector2.ONE * radius * 2.3
		game.draw_texture_rect(icon_texture, Rect2(center - icon_size * 0.5, icon_size), false, Color(1.0, 1.0, 1.0, opacity))
		return

	var bright := Color(accent.r, accent.g, accent.b, opacity)
	var dim := Color(accent.r, accent.g, accent.b, opacity * 0.22)
	game.draw_circle(center, radius, Color(0.01, 0.012, 0.01, 0.92 * opacity))
	game.draw_arc(center, radius, -PI * 0.9, PI * 0.72, 40, bright, 2.2, true)
	game.draw_arc(center, radius * 0.8, PI * 0.16, PI * 1.7, 36, dim, 1.2, true)
	match key:
		"incendiario":
			var flame := PackedVector2Array([center + Vector2(0.0, -radius * 0.62), center + Vector2(radius * 0.34, -radius * 0.08), center + Vector2(radius * 0.22, radius * 0.5), center + Vector2(0.0, radius * 0.68), center + Vector2(-radius * 0.34, radius * 0.28), center + Vector2(-radius * 0.22, -radius * 0.12)])
			game.draw_colored_polygon(flame, Color(accent.r, accent.g * 0.72, accent.b * 0.35, opacity * 0.86))
			game.draw_circle(center + Vector2(radius * 0.02, radius * 0.25), radius * 0.18, Color(1.0, 0.92, 0.5, opacity))
		"barometrico":
			game.draw_arc(center, radius * 0.52, 0.0, TAU, 34, bright, 2.0, true)
			game.draw_circle(center, radius * 0.12, bright)
			for angle in [-2.45, -0.88, 0.7, 2.27]:
				var direction := Vector2.from_angle(angle)
				game.draw_line(center + direction * radius * 0.33, center + direction * radius * 0.76, bright, 3.0, true)
		"colosso":
			var fist := Rect2(center - Vector2(radius * 0.32, radius * 0.02), Vector2(radius * 0.64, radius * 0.58))
			game.draw_rect(fist, Color(accent.r, accent.g, accent.b, opacity * 0.78), true)
			for i in range(3):
				game.draw_rect(Rect2(center + Vector2(-radius * 0.4 + float(i) * radius * 0.28, -radius * 0.46), Vector2(radius * 0.22, radius * 0.4)), bright, true)
			game.draw_line(center + Vector2(-radius * 0.32, radius * 0.25), center + Vector2(radius * 0.32, radius * 0.25), Color(0.08, 0.09, 0.06, opacity), 2.0)
		"incandescencia":
			game.draw_circle(center, radius * 0.24, Color(1.0, 0.68, 0.12, opacity))
			for i in range(8):
				var direction := Vector2.from_angle(float(i) * TAU / 8.0)
				game.draw_line(center + direction * radius * 0.38, center + direction * radius * 0.68, bright, 2.4, true)
			game.draw_arc(center, radius * 0.48, -PI * 0.2, PI * 1.36, 30, bright, 2.0, true)
		"nimbo":
			game.draw_circle(center + Vector2(-radius * 0.25, -radius * 0.08), radius * 0.3, dim)
			game.draw_circle(center + Vector2(0.0, -radius * 0.22), radius * 0.38, Color(accent.r, accent.g, accent.b, opacity * 0.52))
			game.draw_circle(center + Vector2(radius * 0.28, -radius * 0.06), radius * 0.28, dim)
			game.draw_line(center + Vector2(-radius * 0.48, radius * 0.12), center + Vector2(radius * 0.48, radius * 0.12), bright, 3.0, true)
			var bolt := PackedVector2Array([center + Vector2(radius * 0.08, radius * 0.04), center + Vector2(-radius * 0.12, radius * 0.38), center + Vector2(radius * 0.03, radius * 0.35), center + Vector2(-radius * 0.08, radius * 0.66), center + Vector2(radius * 0.28, radius * 0.24), center + Vector2(radius * 0.1, radius * 0.27)])
			game.draw_colored_polygon(bolt, bright)
		"lastro":
			game.draw_line(center + Vector2(0.0, -radius * 0.52), center + Vector2(0.0, radius * 0.4), bright, 4.0, true)
			game.draw_arc(center, radius * 0.22, 0.0, TAU, 24, bright, 2.2, true)
			game.draw_arc(center, radius * 0.56, 0.18, PI - 0.18, 28, bright, 3.0, true)
			game.draw_line(center + Vector2(-radius * 0.56, radius * 0.1), center + Vector2(-radius * 0.28, radius * 0.42), bright, 3.0, true)
			game.draw_line(center + Vector2(radius * 0.56, radius * 0.1), center + Vector2(radius * 0.28, radius * 0.42), bright, 3.0, true)


static func _draw_henry_stage_transition(game: Node2D, viewport: Vector2, accent: Color, progress: float) -> void:
	var eased := smoothstep(0.0, 1.0, clampf(progress, 0.0, 1.0))
	var x := lerpf(-viewport.x * 0.12, viewport.x * 1.12, eased)
	var alpha := sin(clampf(progress, 0.0, 1.0) * PI)
	game.draw_rect(Rect2(x - 62.0, 90.0, 124.0, viewport.y - 146.0), Color(accent.r, accent.g, accent.b, 0.035 * alpha), true)
	game.draw_line(Vector2(x, 88.0), Vector2(x - 38.0, viewport.y - 52.0), Color(accent.r, accent.g, accent.b, 0.92 * alpha), 3.0)
	game.draw_line(Vector2(x + 10.0, 88.0), Vector2(x - 28.0, viewport.y - 52.0), Color(HENRY_BONE.r, HENRY_BONE.g, HENRY_BONE.b, 0.42 * alpha), 1.0)


static func _draw_button(game: Node2D, rect: Rect2, label: String, primary: bool, accent: Color) -> void:
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.23 if primary else 0.08), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.92), false, 2.0)
	game._draw_centered(label, rect.get_center() + Vector2(0.0, 4.0), 17, Color(0.96, 1.0, 1.0))
