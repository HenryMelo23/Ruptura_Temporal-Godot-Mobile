extends RefCounted

const INK := Color(0.025, 0.038, 0.046)
const PAPER := Color(0.91, 0.95, 0.96)
const MUTED := Color(0.57, 0.69, 0.72)
const CYAN := Color(0.18, 0.88, 0.89)
const GOLD := Color(1.0, 0.78, 0.29)
const BURN_TIME := 0.95
var action := ""
var elapsed := 0.0
var duration := 0.0
var slot := -1
var previous_cards: Array = []
var entrance := 2.0


func reset() -> void:
	action = ""
	previous_cards.clear()
	entrance = 0.0


func begin(kind: String, cards: Array, index: int = -1) -> void:
	action = kind
	previous_cards = cards.duplicate(true)
	slot = index
	elapsed = 0.0
	duration = 0.72 if kind == "reroll" else (BURN_TIME if kind == "burn" else 0.5)


func busy() -> bool:
	return not action.is_empty()


func update(delta: float) -> void:
	# 0..1 = visor abrindo; 1..2 = cartas materializando.
	entrance = minf(2.0, entrance + delta / 0.4)
	if not busy():
		return
	elapsed += delta
	if elapsed >= duration:
		action = ""
		previous_cards.clear()


func layout(viewport: Vector2) -> Dictionary:
	# Visor holografico projetado pelo bracelete (embaixo, no centro).
	var small: bool = viewport.y < 560.0
	var margin := 22.0 if viewport.x >= 1000 else 12.0
	var bracelet_h := 62.0 if small else 92.0
	var visor := Rect2(margin, 12.0 if small else 18.0, viewport.x - margin * 2.0, viewport.y - bracelet_h - (12.0 if small else 18.0))
	var pad := 14.0 if small else 22.0
	var header_h := 54.0 if small else 70.0
	var footer_h := 52.0 if small else 62.0
	var detail_width := clampf(visor.size.x * 0.32, 240.0, 370.0)
	var content_top := visor.position.y + header_h + (6.0 if small else 12.0)
	var footer_y := visor.end.y - footer_h
	var detail := Rect2(visor.end.x - pad - detail_width, content_top, detail_width, footer_y - content_top - 8.0)
	var rack := Rect2(visor.position.x + pad, content_top, detail.position.x - visor.position.x - pad * 2.0, footer_y - content_top - (30.0 if small else 38.0))
	var card_width := minf(212.0, (rack.size.x - 30) / 3.0)
	var card_height := minf(card_width * 1.48, rack.size.y - 8)
	card_width = minf(card_width, card_height / 1.48)
	var cards: Array[Rect2] = []
	for i in range(3):
		var center := rack.position + Vector2(rack.size.x * (float(i) + 0.5) / 3, rack.size.y * 0.5)
		cards.append(Rect2(center - Vector2(card_width, card_height) * 0.5, Vector2(card_width, card_height)))
	var button_h := 40.0 if small else 48.0
	var deck_w := 150.0 if not small else 128.0
	var reroll_w := 196.0 if not small else 168.0
	var header_y := visor.position.y + (header_h - button_h) * 0.5 + 2.0
	var action_h := 38.0 if small else 44.0
	return {
		"visor": visor, "header_h": header_h, "pad": pad, "small": small,
		"bracelet": Vector2(viewport.x * 0.5, viewport.y - bracelet_h * 0.46),
		"points": Rect2(visor.position.x + pad, visor.position.y + 6.0, 300.0, header_h - 8.0),
		"cards": cards, "detail": detail,
		"buy": Rect2(detail.position.x, footer_y + (footer_h - button_h) * 0.5, detail_width, button_h),
		"exit": Rect2(visor.position.x + pad, footer_y + (footer_h - button_h) * 0.5, 190 if not small else 160, button_h),
		"deck": Rect2(visor.end.x - pad - deck_w, header_y, deck_w, button_h),
		"reroll": Rect2(visor.end.x - pad - deck_w - 12.0 - reroll_w, header_y, reroll_w, button_h),
		"burn": Rect2(detail.position.x, detail.end.y - action_h, (detail_width - 12) * 0.5, action_h),
		"reserve": Rect2(detail.position.x + (detail_width + 12) * 0.5, detail.end.y - action_h, (detail_width - 12) * 0.5, action_h)
	}


## Queimar so aparece com Cinzas no deck; reservar so com Escolha Adiada (ou
## para soltar uma vaga ja reservada).
func burn_visible(g) -> bool:
	return g._support_card_count(g.CARD_CINZAS_ID) > 0


func reserve_visible(g) -> bool:
	return g._new_common_card_count(g.CARD_ESCOLHA_ADIADA_ID) > 0 or g._shop_slot_locked(g.shop_selected)


func text(g, value: String, rect: Rect2, size: int, color: Color, centered: bool = false) -> void:
	var face: Font = g.menu_ui_font
	var fitted := size
	while fitted > 12 and face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > rect.size.x:
		fitted -= 1
	var baseline := rect.position.y + (rect.size.y + face.get_ascent(fitted) - face.get_descent(fitted)) * 0.5
	g.draw_string(face, Vector2(rect.position.x, baseline), value, HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, fitted, color)


func paragraph(g, value: String, rect: Rect2, size: int = 17, centered: bool = false) -> void:
	var buffer := TextParagraph.new()
	buffer.alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	buffer.width = rect.size.x
	buffer.add_string(value, g.menu_ui_font, size)
	var actual := size
	while buffer.get_size().y > rect.size.y and actual > 10:
		actual -= 1
		buffer.clear()
		buffer.add_string(value, g.menu_ui_font, actual)
	buffer.draw(g.get_canvas_item(), rect.position, PAPER)


func frame(g, rect: Rect2, accent: Color, selected: bool = false) -> void:
	g.draw_style_box(_style(INK, accent.darkened(0.5), 2), rect)
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in range(4):
		var direction := Vector2(1 if i in [0, 3] else -1, 1 if i < 2 else -1)
		var point: Vector2 = corners[i] + direction * 5
		g.draw_line(point, point + Vector2(direction.x * 14, 0), accent, 3)
		g.draw_line(point, point + Vector2(0, direction.y * 12), accent, 3)
	if selected:
		g.draw_line(rect.position + Vector2(18, 0), Vector2(rect.end.x - 18, rect.position.y), accent, 3)


func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func button(g, rect: Rect2, label: String, accent: Color, enabled: bool = true) -> void:
	var hovered: bool = enabled and rect.has_point(g.get_local_mouse_position())
	g.draw_style_box(_style(accent.darkened(0.8 if hovered else 0.91), accent if enabled else MUTED.darkened(0.55), 4), rect)
	text(g, label, rect.grow(-8), 17, PAPER if enabled else MUTED.darkened(0.2), true)


func bargain_discount_rate(card: Dictionary) -> float:
	return clampf(float(card.get("bargain_discount_rate", 0.0)), 0.0, 0.75)


func bargain_base_price(g, card: Dictionary) -> int:
	var stored: int = int(card.get("bargain_base_price", 0))
	if stored > 0:
		return stored
	if g.has_method("_bargain_base_card_price"):
		return g._bargain_base_card_price(card)
	return g._effective_card_price(card)


func draw_bargain_price_tag(g, card: Dictionary, rect: Rect2, selected: bool, alpha: float = 1.0) -> void:
	var rate: float = bargain_discount_rate(card)
	if rate <= 0.0 or g._is_empty_shop_slot(card):
		text(g, "VAZIA" if g._is_empty_shop_slot(card) else "%s PTS" % g._format_points(g._effective_card_price(card)), rect, 18, GOLD if selected else MUTED, true)
		return
	var price: int = g._effective_card_price(card)
	var base_price: int = bargain_base_price(g, card)
	var inner := rect.grow(-2.0)
	g.draw_rect(rect, Color(0.18, 0.11, 0.0, 0.82 * alpha), true)
	g.draw_rect(rect, Color(1.0, 0.78, 0.22, 0.82 * alpha), false, 1.0)
	var left := Rect2(inner.position, Vector2(inner.size.x * 0.44, inner.size.y))
	var right := Rect2(Vector2(inner.position.x + inner.size.x * 0.42, inner.position.y), Vector2(inner.size.x * 0.58, inner.size.y))
	text(g, "%d" % base_price, left, 12, Color(1.0, 0.74, 0.38, 0.66 * alpha), true)
	g.draw_line(left.position + Vector2(7.0, left.size.y * 0.52), Vector2(left.end.x - 7.0, left.position.y + left.size.y * 0.52), Color(1.0, 0.34, 0.16, 0.84 * alpha), 1.4)
	text(g, "%s PTS" % g._format_points(price), right, 15, Color(1.0, 0.94, 0.42, alpha), true)


func draw_bargain_banner(g, card: Dictionary, rect: Rect2, alpha: float = 1.0) -> void:
	var rate: float = bargain_discount_rate(card)
	if rate <= 0.0 or g._is_empty_shop_slot(card):
		return
	var banner := Rect2(rect.position + Vector2(8.0, 8.0), Vector2(minf(128.0, rect.size.x - 16.0), 24.0))
	g.draw_rect(banner, Color(0.2, 0.12, 0.0, 0.88 * alpha), true)
	g.draw_rect(banner, Color(1.0, 0.78, 0.18, 0.9 * alpha), false, 1.0)
	text(g, "DESCONTAO -%d%%" % int(round(rate * 100.0)), banner.grow(-4.0), 10, Color(1.0, 0.96, 0.62, alpha), true)


func draw_cinzas_bonus_callout(g, card: Dictionary, rect: Rect2, alpha: float = 1.0) -> void:
	var summary: String = String(card.get("cinzas_bonus_summary", ""))
	if summary.is_empty() or g._is_empty_shop_slot(card):
		return
	var flicker: float = 0.78 + sin(float(Time.get_ticks_msec()) * 0.012) * 0.16
	g.draw_rect(rect, Color(0.20, 0.045, 0.012, 0.94 * alpha), true)
	g.draw_rect(rect, Color(1.0, 0.30 + flicker * 0.16, 0.08, 0.92 * alpha), false, 1.5)
	var ember_y: float = rect.position.y + 6.0
	for ember_index in range(5):
		var x: float = rect.position.x + 12.0 + float(ember_index) * (rect.size.x - 24.0) / 4.0
		var height: float = 3.0 + fposmod(float(ember_index) * 4.0 + float(Time.get_ticks_msec()) * 0.006, 6.0)
		g.draw_line(Vector2(x, ember_y + height), Vector2(x + 2.0, ember_y), Color(1.0, 0.72, 0.18, 0.72 * alpha), 1.4)
	var title_rect := Rect2(rect.position + Vector2(8.0, 2.0), Vector2(rect.size.x - 16.0, 18.0))
	text(g, "CINZAS DESPERTAS", Rect2(title_rect.position + Vector2(1.0, 1.0), title_rect.size), 12, Color(0.45, 0.04, 0.0, alpha), true)
	text(g, "CINZAS DESPERTAS", title_rect, 12, Color(1.0, 0.84, 0.30, alpha), true)
	paragraph(g, summary, Rect2(rect.position + Vector2(8.0, 20.0), Vector2(rect.size.x - 16.0, rect.size.y - 23.0)), 12, true)


func bargain_exit_confirmation_layout(viewport: Vector2) -> Dictionary:
	var panel_width: float = minf(620.0, viewport.x - 48.0)
	var panel_height: float = 196.0
	var panel := Rect2(viewport * 0.5 - Vector2(panel_width, panel_height) * 0.5, Vector2(panel_width, panel_height))
	var button_width: float = minf(210.0, (panel_width - 60.0) * 0.5)
	var button_y: float = panel.end.y - 62.0
	return {
		"panel": panel,
		"cancel": Rect2(panel.get_center().x - button_width - 8.0, button_y, button_width, 42.0),
		"confirm": Rect2(panel.get_center().x + 8.0, button_y, button_width, 42.0)
	}


func draw_bargain_exit_confirmation(g, viewport: Vector2) -> void:
	var layout_data: Dictionary = bargain_exit_confirmation_layout(viewport)
	var panel: Rect2 = layout_data.panel
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.01, 0.02, 0.025, 0.76), true)
	g.draw_rect(panel, Color(0.055, 0.045, 0.025, 0.98), true)
	g.draw_rect(panel, Color(1.0, 0.78, 0.2, 0.92), false, 2.0)
	text(g, "ENCERRAR DESCONTAO?", Rect2(panel.position + Vector2(24.0, 24.0), Vector2(panel.size.x - 48.0, 30.0)), 22, GOLD, true)
	text(g, "Ao sair, você perderá o Descontão desta visita", Rect2(panel.position + Vector2(24.0, 67.0), Vector2(panel.size.x - 48.0, 36.0)), 17, PAPER, true)
	button(g, Rect2(layout_data.cancel), "CANCELAR", CYAN, true)
	button(g, Rect2(layout_data.confirm), "CONFIRMAR SAIDA", Color(1.0, 0.42, 0.18), true)


func reroll_visual_state(g) -> Dictionary:
	var free_left: int = maxi(0, int(g.shop_rerolls))
	var card_cost: int = maxi(1, int(g.card_cost))
	var enabled: bool = g.shop_controller.can_reroll()
	if free_left > 0:
		return {
			"free": true,
			"cost": 0,
			"ratio": 0.0,
			"accent": Color(0.24, 1.0, 0.46),
			"title": "REROLL",
			"detail": "GRATUITO · %d restantes" % free_left,
			"short": "GRATIS %d" % free_left,
			"enabled": enabled
		}
	var cost: int = maxi(0, int(g.shop_controller.next_paid_reroll_cost()))
	var ratio: float = float(cost) / float(card_cost)
	var accent: Color
	if ratio >= 1.0:
		accent = Color(1.0, 0.18, 0.14)
	elif ratio >= 0.72:
		accent = Color(1.0, 0.43, 0.12).lerp(Color(1.0, 0.18, 0.14), clampf((ratio - 0.72) / 0.28, 0.0, 1.0))
	elif ratio >= 0.42:
		accent = Color(1.0, 0.84, 0.22).lerp(Color(1.0, 0.43, 0.12), clampf((ratio - 0.42) / 0.3, 0.0, 1.0))
	else:
		accent = Color(0.24, 1.0, 0.46).lerp(Color(1.0, 0.84, 0.22), clampf(ratio / 0.42, 0.0, 1.0))
	var detail: String = "%s pts" % g._format_points(cost)
	if not enabled:
		detail = "saldo insuficiente - %d pts" % cost
	return {
		"free": false,
		"cost": cost,
		"ratio": ratio,
		"accent": accent,
		"title": "REROLL PAGO",
		"detail": detail,
		"short": "%s PTS" % g._format_points(cost),
		"enabled": enabled
	}


func reroll_status_line(g) -> String:
	var state: Dictionary = reroll_visual_state(g)
	if bool(state.get("free", false)):
		return "Reroll GRATUITO: %d restantes" % int(g.shop_rerolls)
	return "Reroll PAGO: %d pts" % int(state.get("cost", 0))


func draw_reroll_button(g, rect: Rect2) -> void:
	var state: Dictionary = reroll_visual_state(g)
	var accent: Color = Color(state.get("accent", CYAN))
	var enabled: bool = bool(state.get("enabled", false))
	var alpha: float = 1.0 if enabled else 0.48
	var hovered: bool = enabled and rect.has_point(g.get_local_mouse_position())
	var fill: Color = Color(0.018, 0.032, 0.035, 0.94 * alpha).lerp(accent, 0.12 if hovered else 0.07)
	g.draw_style_box(_style(fill, Color(accent.r, accent.g, accent.b, (0.95 if enabled else 0.42)), 5), rect)
	var stripe: Rect2 = Rect2(rect.position.x + 7.0, rect.position.y + 7.0, 5.0, rect.size.y - 14.0)
	g.draw_rect(stripe, Color(accent.r, accent.g, accent.b, 0.86 * alpha), true)
	var compact_btn: bool = rect.size.y < 46.0
	var title_rect: Rect2 = Rect2(rect.position.x + 20.0, rect.position.y + (3.0 if compact_btn else 6.0), rect.size.x - 28.0, 18.0 if compact_btn else 22.0)
	var detail_rect: Rect2 = Rect2(rect.position.x + 20.0, rect.end.y - (17.0 if compact_btn else 19.0), rect.size.x - 28.0, 14.0 if compact_btn else 18.0)
	text(g, String(state.get("title", "REROLL")), title_rect, 15, PAPER if enabled else MUTED, false)
	text(g, String(state.get("detail", "")), detail_rect, 12, Color(accent.r, accent.g, accent.b, 0.96 * alpha), false)
	if bool(state.get("free", false)) and not compact_btn:
		var pill: Rect2 = Rect2(rect.end.x - 72.0, rect.position.y + 8.0, 58.0, 20.0)
		g.draw_rect(pill, Color(0.04, 0.22, 0.08, 0.84 * alpha), true)
		g.draw_rect(pill, Color(accent.r, accent.g, accent.b, 0.72 * alpha), false, 1)
		text(g, "GRATUITO", pill.grow(-4.0), 10, Color(0.9, 1.0, 0.9, alpha), true)


func draw_manual_reopen_warning(g, viewport: Vector2) -> void:
	var portrait: bool = g._is_portrait(viewport)
	var w: float = minf(viewport.x * (0.84 if portrait else 0.52), 680.0)
	var h: float = 76.0 if not portrait else 88.0
	var rect: Rect2 = Rect2(viewport.x * 0.5 - w * 0.5, viewport.y * (0.17 if not portrait else 0.14), w, h)
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	g._draw_holo_panel(rect, Color(1.0, 0.62, 0.16), true, 0.82)
	g.draw_rect(rect.grow(-7.0), Color(0.05, 0.016, 0.006, 0.54 + pulse * 0.12), true)
	var title: String = "REABERTURA GRATIS" if g._manual_shop_grace_active() else "LOJA MANUAL"
	g._draw_centered(title, Vector2(rect.get_center().x, rect.position.y + 27.0), 17 if not portrait else 15, Color(1.0, 0.78, 0.26))
	g._draw_wrapped_clamped(g.shop_manual_reopen_warning_text, Rect2(rect.position.x + 22.0, rect.position.y + 42.0, rect.size.x - 44.0, rect.size.y - 48.0), 13 if not portrait else 11, Color(0.96, 0.98, 1.0, 0.95), 2)


func draw_tutorial_line(g, rect: Rect2, portrait: bool) -> void:
	g.draw_rect(rect, Color(0.0, 0.0, 0.0, 0.22), true)
	g.draw_line(Vector2(rect.position.x + 8.0, rect.end.y), Vector2(rect.end.x - 8.0, rect.end.y), Color(0.0, 1.0, 0.82, 0.34), 1.0)
	var gap: float = 14.0 if not portrait else 8.0
	var inner: Rect2 = rect.grow(-4.0)
	var half_w: float = (inner.size.x - gap) * 0.5
	var left: Rect2 = Rect2(inner.position, Vector2(half_w, inner.size.y))
	var right: Rect2 = Rect2(Vector2(inner.position.x + half_w + gap, inner.position.y), Vector2(half_w, inner.size.y))
	var text_size: int = 13 if not portrait else 11
	g._draw_wrapped_clamped("REROLL: troca ofertas.", left, text_size, Color(0.78, 0.94, 1.0, 0.94), 1)
	g._draw_wrapped_clamped("COMPRAR: entra no deck; custo sobe.", right, text_size, Color(0.98, 0.88, 0.28, 0.94), 1)


func card_stat_chips(card_name: String) -> Array:
	match card_name:
		"Speed Boost":
			return ["+6.5% VEL"]
		"Porcao":
			return ["+45% CURA", "+HP MAX"]
		"Disparo crescente":
			return ["+15% DANO"]
		"Tempestade":
			return ["+5 DANO", "+2% CRIT"]
		"Trembo":
			return ["+1 REVIVER"]
		"Roubo de Vida":
			return ["+0.1% ROUBO"]
		"Speed Atack":
			return ["-0.026s ATK"]
		"Teleporte":
			return ["-0.30s TP"]
		"Petro":
			return ["+PETRO", "+2 DANO"]
		"Defesa":
			return ["+3.5 DEF"]
		"Sorte":
			return ["ANOMALIA OCULTA"]
		"Poison":
			return ["+0.9% VENENO"]
		"Coletora":
			return ["+0.8% EXEC"]
		"Mercenaria":
			return ["+40 CONTRATO"]
		"Devorador de Destinos":
			return ["20s MARCA", "RAIZ/LOG"]
		"Escolha Adiada":
			return ["RESERVA 1"]
		"TrÃ©gua Regenerativa":
			return ["6s SEM DANO", "+REGEN"]
		"Cinzas da Escolha":
			return ["QUEIMAR", "+PESO FUTURO"]
		"Reserva de Pulso":
			return ["OVERHEAL", "<35% LIBERA"]
		"Casulo Reativo":
			return ["3 HITS/2.2s", "-DANO"]
		"Passagem IntangÃ­vel":
			return ["POS-TP", "SEM CONTATO"]
		"Ã‚ncora Vital":
			return ["POS-DANO", "CURA EM AREA"]
		"Inercia Cronal":
			return ["-8% CONTROLE", "-18% EMPURRO"]
		"Leitura do Instante":
			return ["+7% AVISO"]
		"Margem Segura":
			return ["+35px SPAWN"]
		"Moeda Estavel":
			return ["-6 CUSTO+"]
		"Orbita Coletora":
			return ["+22% COLETA"]
		"Pacto das Possibilidades":
			return ["-4% COMUM"]
		"Solo Consolidado":
			return ["-8% ZONA"]
		"Fratura Cronal":
			return ["7s ARMAR", "+4/12% FRAG"]
		"Pulso Desestabilizador":
			return ["8s ARMAR", "40/100% DANO"]
		"Pressao de Cerco":
			return ["+5/15% CERCO"]
		"Choque de Fontes":
			return ["2 FONTES", "4s/ALVO"]
		"Ferrolho de Ruptura":
			return ["8s ARMAR", "ROOT/SLOW+"]
		"Limiar de Colapso":
			return ["70/40/15%", "SEM LOOP"]
		"Desvio de Probabilidade":
			return ["QUASE HIT", "+CARGA"]
		"Ponto Cego":
			return ["CONE TRAS", "+DANO"]
		"Mandamento da Ruptura":
			return ["3 Q/E", "+RUPTURA"]
		"Carta Zero":
			return ["+6% COMUNS", "RETROATIVA"]
		"Necrocronismo":
			return ["12 ABATES", "ECO + IMPLOSAO"]
		"CoraÃ§Ã£o de AntimatÃ©ria":
			return ["CARGA DANO", "IMPLOSAO"]
		"Cofre do Excesso":
			return ["OVERKILL", "ELITE/BOSS"]
		"Intervalo Fraturado":
			return ["-HAB1 CD", "-ULT CD"]
		"Nucleo Revigorante":
			return ["+ORBE CURA"]
		"Limiar de Ruina":
			return [">90% VIDA", "+DANO"]
		"Estase Reparadora":
			return ["5s PARADO", "CURA ALIADOS", "+RAIO"]
		"Manto de Impulso":
			return ["Q/E/TP", "+ESCUDO"]
		"Recusa do Dano":
			return ["ROLL/DANO", "BLOQUEIO"]
		"Carrasco de Colossos":
			return ["+18%/COPIA", "SO CHEFE"]
		"Sutura Gradual":
			return ["POS-DANO", "CURA 3.2s"]
		"Egide Hemofaga":
			return ["OVERHEAL", "+ESCUDO"]
	return ["MELHORIA"]


func draw_card_stat_chips(g, chips: Array, origin: Vector2, max_width: float, accent: Color, size: = 13) -> float:
	var x: float = origin.x
	var y: float = origin.y
	var chip_h: float = max(22.0, float(size) + 10.0)
	for chip in chips:
		var chip_text: String = String(chip)
		var chip_w: float = clamp(g.font.get_string_size(chip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 22.0, 58.0, max_width)
		if x + chip_w > origin.x + max_width:
			x = origin.x
			y += chip_h + 6.0
		var chip_rect: Rect2 = Rect2(x, y, chip_w, chip_h)
		g.draw_rect(chip_rect, Color(accent.r, accent.g, accent.b, 0.18), true)
		g.draw_rect(chip_rect, Color(accent.r, accent.g, accent.b, 0.82), false, 1)
		g._draw_centered(chip_text, chip_rect.get_center() + Vector2(0, float(size) * 0.16), size, Color.WHITE)
		x += chip_w + 8.0
	return y + chip_h + 2.0 - origin.y


func round_button_radius(g, viewport: Vector2) -> float:
	return 32.0 if not g._is_portrait(viewport) else 28.0


func reroll_center(g, viewport: Vector2) -> Vector2:
	if not g._is_portrait(viewport):
		return g.shop_controller.layout(viewport).reroll.get_center()
	return Vector2(viewport.x * (0.09 if not g._is_portrait(viewport) else 0.13), 58.0 if not g._is_portrait(viewport) else 76.0)


func deck_center(g, viewport: Vector2) -> Vector2:
	if not g._is_portrait(viewport):
		return g.shop_controller.layout(viewport).deck.get_center()
	return Vector2(viewport.x * (0.91 if not g._is_portrait(viewport) else 0.87), 58.0 if not g._is_portrait(viewport) else 76.0)


func draw_round_button(g, center: Vector2, radius: float, label: String, accent: Color, enabled: bool, kind: String) -> void:
	var state: Dictionary = {}
	if kind == "reroll":
		state = reroll_visual_state(g)
		accent = Color(state.get("accent", accent))
		enabled = bool(state.get("enabled", enabled))
	var alpha: float = 1.0 if enabled else 0.42
	g.draw_circle(center, radius + 7.0, Color(accent.r, accent.g, accent.b, 0.1 * alpha))
	g.draw_circle(center, radius, Color(0.015, 0.025, 0.04, 0.92 * alpha))
	g.draw_arc(center, radius, 0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.92 * alpha), 2.4)
	if kind == "reroll":
		var rot: float = g.time_alive * 3.2
		for i in range(2):
			var start: float = rot + i * PI
			g.draw_arc(center, radius * 0.48, start, start + PI * 0.74, 24, Color.WHITE, 2.8)
			var tip: Vector2 = center + Vector2.from_angle(start + PI * 0.74) * radius * 0.48
			var side: Vector2 = Vector2.from_angle(start + PI * 0.74 + PI * 0.68)
			var tri: PackedVector2Array = PackedVector2Array([tip, tip - Vector2.from_angle(start + PI * 0.74) * 8.0 + side * 4.0, tip - Vector2.from_angle(start + PI * 0.74) * 8.0 - side * 4.0])
			g.draw_polygon(tri, PackedColorArray([Color.WHITE]))
		g._draw_centered(String(state.get("short", "")), center + Vector2(0, 2), 11, accent if enabled else Color(0.6, 0.6, 0.6))
		g._draw_centered("GRATUITO" if bool(state.get("free", false)) else "CUSTO", center + Vector2(0, 16), 8, Color(0.88, 0.94, 0.96, alpha))
	else:
		var w: float = radius * 0.72
		var h: float = radius * 0.92
		for offset in [-7.0, 0.0, 7.0]:
			var rect: Rect2 = Rect2(center.x - w * 0.5 + offset, center.y - h * 0.5 - abs(offset) * 0.25, w, h)
			g.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.16 * alpha), true)
			g.draw_rect(rect, Color.WHITE, false, 1)
	g._draw_centered(label, center + Vector2(0, radius + 18.0), 10, Color(0.82, 0.92, 0.96, alpha))


func draw_small_rect_button(g, rect: Rect2, label: String, bg: = Color(0.03, 0.1, 0.12), border: = Color(0.0, 1.0, 0.82)) -> void:
	if g.mode.begins_with("settings"):
		g._draw_settings_surface(rect, rect.has_point(g.get_global_mouse_position()))
		g._draw_centered_with_font(g.menu_ui_font, label, rect.get_center(), 16, Color(0.73, 0.85, 0.84))
		return
	g.draw_rect(rect, bg, true)
	g.draw_rect(rect, border, false, 2)
	var font_size: int = int(rect.size.y * 0.4)
	var text_size: Vector2 = g.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > rect.size.x - 12 and font_size > 10:
		font_size -= 1
		text_size = g.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var y_offset: float = text_size.y * 0.16
	g._draw_centered(label, rect.get_center() + Vector2(0, y_offset), font_size, Color.WHITE)


func purchase_stage(progress: float) -> String:
	if progress < 0.2:
		return "CONFIRMANDO COMPRA"
	if progress < 0.78:
		return "TRANSFERINDO PARA O DECK"
	return "DECK ATUALIZADO"


func draw_purchase_transfer_fx(g, origin: Vector2, target: Vector2, progress: float, accent: Color) -> void:
	var burst_progress: float = clampf(progress / 0.22, 0.0, 1.0)
	var burst_alpha: float = 1.0 - burst_progress
	if burst_alpha > 0.0:
		g.draw_circle(origin, lerpf(12.0, 46.0, burst_progress), Color(accent.r, accent.g, accent.b, 0.08 * burst_alpha))
		g.draw_arc(origin, lerpf(16.0, 52.0, burst_progress), -PI * 0.5, TAU - PI * 0.5, 32, Color(accent.r, accent.g, accent.b, 0.78 * burst_alpha), 2.2)
		for shard_index in range(8):
			var shard_angle: float = float(shard_index) * TAU / 8.0 - PI * 0.5
			var shard_from: Vector2 = origin + Vector2.from_angle(shard_angle) * lerpf(10.0, 26.0, burst_progress)
			var shard_to: Vector2 = origin + Vector2.from_angle(shard_angle) * lerpf(24.0, 62.0, burst_progress)
			g.draw_line(shard_from, shard_to, Color(1.0, 0.92, 0.42, 0.72 * burst_alpha), 1.8, true)

	var transfer_progress: float = clampf((progress - 0.14) / 0.72, 0.0, 1.0)
	if transfer_progress <= 0.0:
		return
	transfer_progress = smoothstep(0.0, 1.0, transfer_progress)
	var previous: Vector2 = origin
	for trail_index in range(1, 10):
		var trail_t: float = float(trail_index) / 9.0 * transfer_progress
		var point: Vector2 = origin.lerp(target, trail_t) + Vector2(0.0, -sin(trail_t * PI) * 74.0)
		var trail_alpha: float = 0.52 * (1.0 - float(trail_index) / 12.0)
		g.draw_line(previous, point, Color(accent.r, accent.g, accent.b, trail_alpha), 2.0, true)
		previous = point
	var target_pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.018)
	g.draw_circle(target, 10.0 + target_pulse * 6.0, Color(accent.r, accent.g, accent.b, 0.12 + target_pulse * 0.1))
	g.draw_arc(target, 18.0 + target_pulse * 5.0, -PI * 0.5, TAU - PI * 0.5, 32, Color(0.78, 1.0, 0.86, 0.76), 2.0)
	g._draw_centered("+1", target + Vector2(0.0, 34.0), 11, Color(0.76, 1.0, 0.84, 0.86))


func draw_spend_anim(g, center: Vector2) -> void:
	if g.shop_spend_anim_timer <= 0.0 or g.shop_spend_anim_amount <= 0:
		return
	var progress: float = 1.0 - clampf(g.shop_spend_anim_timer / maxf(0.01, g.SHOP_SPEND_ANIM_TIME), 0.0, 1.0)
	var alpha: float = 1.0 - smoothstep(0.62, 1.0, progress)
	var pos: Vector2 = center + Vector2(0.0, -sin(progress * PI) * 18.0)
	var rect := Rect2(pos - Vector2(64.0, 16.0), Vector2(128.0, 32.0))
	g.draw_rect(rect, Color(0.16, 0.035, 0.02, 0.78 * alpha), true)
	g.draw_rect(rect, Color(1.0, 0.42, 0.16, 0.86 * alpha), false, 2)
	g._draw_centered("-%s PTS" % g._format_points(g.shop_spend_anim_amount), rect.get_center() + Vector2(0.0, 5.0), g._readable_text_size(14), Color(1.0, 0.58, 0.24, alpha))


func draw_countdown_alert(g, viewport: Vector2) -> void:
	var portrait: bool = g._is_portrait(viewport)
	var center := Vector2(viewport.x * 0.5, viewport.y * (0.17 if portrait else 0.18) + 20.0)
	var seconds_left: int = g._shop_countdown_visible_second()
	var slow_phase: bool = g.forced_shop_timer <= g.FORCED_SHOP_SLOW_START
	var danger: float = clamp(1.0 - g.forced_shop_timer / g.FORCED_SHOP_WARNING, 0.0, 1.0)
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * (0.008 if slow_phase else 0.006)) * (0.035 if slow_phase else 0.025)
	var base_size: int = 70 if not portrait else 62
	var number_size: int = int(base_size * pulse)
	var number_color := Color(1.0, lerp(0.68, 0.04, danger), lerp(0.44, 0.02, danger))
	g._draw_centered_outlined(str(seconds_left), center, number_size, number_color, Color(0.0, 0.0, 0.0, 1.0), 6)
	var label_y: float = center.y + (46.0 if portrait else 52.0)
	g._draw_centered_outlined("Afaste-se dos inimigos", Vector2(center.x, label_y), 13 if portrait else 15, Color(1.0, 0.86, 0.8, 0.94), Color(0.0, 0.0, 0.0, 0.9), 2)


func draw(g, viewport: Vector2) -> void:
	var areas := layout(viewport)
	var detail: Rect2 = areas.detail
	var visor: Rect2 = areas.visor
	var small: bool = areas.small
	var compact: bool = detail.size.y < 290
	var now: float = float(Time.get_ticks_msec()) * 0.001
	g.buttons.clear()
	var background: Texture2D = g.textures.get("cards_back")
	if background:
		g.draw_texture_rect(background, Rect2(Vector2.ZERO, viewport), false, Color(0.16, 0.18, 0.2))
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.01, 0.016, 0.022, 0.8))
	# Visor abre a partir do bracelete.
	var open: float = smoothstep(0.0, 1.0, minf(1.0, entrance))
	var pivot: Vector2 = areas.bracelet
	draw_bracelet(g, pivot, open, now, areas)
	draw_beam(g, pivot, visor, open, now)
	var sy: float = lerpf(0.04, 1.0, open)
	var sx: float = lerpf(0.4, 1.0, open)
	_visor_origin = pivot - Vector2(pivot.x * sx, pivot.y * sy)
	_visor_scale = Vector2(sx, sy)
	g.draw_set_transform(_visor_origin, 0.0, _visor_scale)
	draw_visor(g, visor, now, areas.header_h)
	draw_points_counter(g, areas.points, now, small)
	draw_reroll_button(g, areas.reroll)
	draw_deck_button(g, areas.deck, now)
	if g.is_multiplayer:
		text(g, "EQUIPE  %d/%d PRONTOS  |  SUAS COMPRAS, SEU SALDO" % [g.shop_mp_ready_count, maxi(1, g.shop_mp_expected_count)], Rect2(visor.position.x + 330, visor.position.y + 18, maxf(60.0, areas.reroll.position.x - visor.position.x - 350), 24), 13, MUTED)
	var t := clampf(elapsed / maxf(duration, 0.01), 0, 1)
	for i in range(mini(3, g.shop_cards.size())):
		var card: Dictionary = g.shop_cards[i]
		var rect: Rect2 = areas.cards[i]
		var selected: bool = i == g.shop_selected
		var reveal := 1.0
		if action == "reroll" and not g._shop_slot_locked(i):
			var local_t := clampf((t - i * 0.08) / 0.8, 0, 1)
			if local_t < 0.5 and previous_cards.size() > i:
				card = previous_cards[i]
				reveal = 1.0 - smoothstep(0.0, 0.5, local_t)
			else:
				reveal = smoothstep(0.5, 1.0, local_t)
		var materialize: float = clampf((entrance - 0.7 - float(i) * 0.18) / 0.55, 0.0, 1.0)
		reveal = minf(reveal, smoothstep(0.0, 1.0, materialize))
		if action == "burn" and slot == i and previous_cards.size() > i:
			card = previous_cards[i]
		if selected:
			rect.position.y -= 8
			if g.shop_select_pulse_timer > 0:
				rect.position.y -= sin(clampf(1 - g.shop_select_pulse_timer / 0.26, 0, 1) * PI) * 5
		var price_rect: Rect2 = areas.cards[i]
		var purchase: bool = g._shop_purchase_animating() and g.shop_select_pulse_index == i
		var flight := 0.0
		if purchase:
			var p: float = 1 - g.shop_purchase_anim_timer / g.SHOP_PURCHASE_ANIM_TIME
			flight = smoothstep(0.18, 0.92, p)
			# Lift curto, depois mergulha no bracelete (coordenadas do visor).
			var target: Vector2 = pivot
			var center := rect.get_center().lerp(target, flight) + Vector2(0, -sin(flight * PI) * 70 - (1.0 - flight) * smoothstep(0.0, 0.18, p) * 16.0)
			rect.size *= lerpf(1.0, 0.12, flight)
			rect.position = center - rect.size * 0.5
			if flight > 0.05:
				draw_card_trail(g, areas.cards[i].get_center(), center, flight, g._card_rarity_color(card))
		var accent: Color = g._card_rarity_color(card)
		var alpha: float = clampf(reveal * 1.6, 0.0, 1.0)
		frame(g, rect, Color(accent if selected else MUTED.darkened(0.3), alpha), selected)
		var icon: Texture2D = g._card_texture(card)
		var art := rect.grow(-9)
		if icon:
			if action == "burn" and slot == i:
				_draw_burn(g, icon, art, t)
			elif reveal < 0.999:
				draw_art_reveal(g, icon, art, reveal, accent)
			elif not g._draw_cinzas_shader_card(card, art, icon, 1.0, true):
				g._draw_texture_contain(icon, art, Color.WHITE)
			elif not purchase:
				draw_card_flames(g, rect, card, now)
		if not purchase and not (action == "burn" and slot == i) and rect.size.x > 80 and reveal > 0.6:
			var caption := Rect2(rect.position + Vector2(9, rect.size.y * 0.64), Vector2(rect.size.x - 18, rect.size.y * 0.36 - 9))
			g.draw_rect(caption, Color(0.03, 0.05, 0.06, 0.95))
			g.draw_line(caption.position, Vector2(caption.end.x, caption.position.y), accent.darkened(0.2), 2)
			paragraph(g, String(card.get("name", "Vaga vazia")), Rect2(caption.position + Vector2(6, 4), Vector2(caption.size.x - 12, 36)), 16 if not small else 13, true)
			text(g, g._card_rarity_label(card), Rect2(caption.position + Vector2(6, caption.size.y - 24), Vector2(caption.size.x - 12, 20)), 12, accent, true)
			draw_bargain_banner(g, card, rect, 1.0)
		var lock_anim: bool = (action == "lock" or action == "unlock") and slot == i
		if g._shop_slot_locked(i) or lock_anim:
			draw_lock_overlay(g, rect, t if lock_anim else 1.0, action == "unlock" and slot == i, now)
		if not purchase:
			draw_bargain_price_tag(g, card, Rect2(price_rect.position.x, price_rect.end.y + (6 if small else 10), price_rect.size.x, 26), selected, 1.0)
		g.buttons["shop_card_%d" % i] = areas.cards[i]
	if not g.shop_cards.is_empty():
		var card: Dictionary = g.shop_cards[g.shop_selected]
		if action == "burn" and slot == g.shop_selected and previous_cards.size() > slot:
			card = previous_cards[slot]
		var accent: Color = g._card_rarity_color(card)
		g.draw_line(detail.position + Vector2(-12, 4), Vector2(detail.position.x - 12, detail.end.y), Color(CYAN, 0.25), 1)
		text(g, "%s  /  NO DECK: %d" % [g._card_rarity_label(card), g._card_count(card)], Rect2(detail.position, Vector2(detail.size.x, 24)), 13, accent)
		text(g, String(card.get("name", "Vaga vazia")).to_upper(), Rect2(detail.position + Vector2(0, 26), Vector2(detail.size.x, 32)), 23 if not small else 19, PAPER)
		if not compact:
			text(g, String(card.get("nick", "")), Rect2(detail.position + Vector2(0, 62), Vector2(detail.size.x, 22)), 15, CYAN)
		if bargain_discount_rate(card) > 0.0:
			text(g, "CAPSULA DA BARGANHA: %s -> %s PTS" % [g._format_points(bargain_base_price(g, card)), g._format_points(g._effective_card_price(card))], Rect2(detail.position + Vector2(0, 86 if not compact else 62), Vector2(detail.size.x, 22)), 13, GOLD)
		var cinzas_callout_y: float = 110.0 if bargain_discount_rate(card) > 0.0 else (88.0 if not compact else 62.0)
		if card.has("cinzas_bonus_summary"):
			draw_cinzas_bonus_callout(g, card, Rect2(detail.position + Vector2(0, cinzas_callout_y), Vector2(detail.size.x, 58.0)), 1.0)
		var copy := String(card.get("desc", ""))
		var projections: Array = [] if g._is_empty_shop_slot(card) or action == "burn" else g._card_projection_lines(card)
		if not projections.is_empty() and detail.size.y >= 320:
			copy += "\n\n" + "\n".join(projections)
		var copy_y := 62.0 if compact else 98.0
		if card.has("cinzas_bonus_summary"):
			copy_y = cinzas_callout_y + 64.0
		var show_burn: bool = burn_visible(g)
		var show_reserve: bool = reserve_visible(g)
		var actions_h: float = 54.0 if (show_burn or show_reserve) else 0.0
		paragraph(g, copy, Rect2(detail.position + Vector2(0, copy_y), Vector2(detail.size.x, maxf(40, detail.size.y - copy_y - actions_h - 6))), 16 if not small else 13)
		var enabled: bool = not busy() and not g._shop_purchase_animating()
		var burn_rect: Rect2 = areas.burn
		var reserve_rect: Rect2 = areas.reserve
		if show_burn and not show_reserve:
			burn_rect = Rect2(burn_rect.position, Vector2(detail.size.x, burn_rect.size.y))
		elif show_reserve and not show_burn:
			reserve_rect = Rect2(Vector2(detail.position.x, reserve_rect.position.y), Vector2(detail.size.x, reserve_rect.size.y))
		if show_burn:
			draw_fire_button(g, burn_rect, "QUEIMAR", enabled and g._can_burn_shop_card(card), now)
			g.buttons["shop_burn_%d" % g.shop_selected] = burn_rect
		if show_reserve:
			button(g, reserve_rect, "SOLTAR" if g._shop_slot_locked(g.shop_selected) else "RESERVAR", CYAN, enabled and g._can_toggle_shop_reserve(g.shop_selected))
			draw_padlock(g, reserve_rect.position + Vector2(18, reserve_rect.size.y * 0.5), 0.8, Color(CYAN, 0.9 if g._can_toggle_shop_reserve(g.shop_selected) else 0.4), g._shop_slot_locked(g.shop_selected))
			g.buttons["shop_reserve_%d" % g.shop_selected] = reserve_rect
		var price: int = g._effective_card_price(card)
		var label := "COMPRAR  %s PTS" % g._format_points(price)
		if g._is_empty_shop_slot(card):
			label = "VAGA VAZIA"
		if g._shop_purchase_animating():
			label = "ENVIANDO AO BRACELETE"
		elif busy():
			label = {"burn": "REDUZINDO A CINZAS", "reroll": "RECALIBRANDO VISOR", "lock": "RESERVA FIXADA", "unlock": "RESERVA LIBERADA"}.get(action, "AGUARDE")
		button(g, areas.buy, label, Color(0.38, 0.95, 0.57), enabled and g.score >= price and not g._is_empty_shop_slot(card))
	button(g, areas.exit, "PRONTO" if g.is_multiplayer else "VOLTAR AO CAMPO", CYAN, g._shop_can_exit())
	g.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if action == "reroll":
		draw_reroll_scan(g, visor, t)
	for key in ["buy", "exit", "deck", "reroll"]:
		g.buttons["shop_" + key] = areas[key]


## Moldura do visor: vidro escuro, bordas ciano, scanlines e cantos.
func draw_visor(g, visor: Rect2, now: float, header_h: float) -> void:
	var flicker: float = 0.92 + 0.08 * sin(now * 31.0) * sin(now * 7.0)
	var style := _style(Color(0.012, 0.05, 0.06, 0.9), Color(CYAN, 0.85 * flicker), 16)
	style.set_border_width_all(2)
	g.draw_style_box(style, visor)
	g.draw_rect(Rect2(visor.position + Vector2(10, header_h), Vector2(visor.size.x - 20, 1)), Color(CYAN, 0.22), true)
	var y: float = visor.position.y + 6.0
	var scan_y: float = visor.position.y + fposmod(now * 90.0, visor.size.y)
	while y < visor.end.y - 6.0:
		g.draw_line(Vector2(visor.position.x + 6, y), Vector2(visor.end.x - 6, y), Color(CYAN, 0.025), 1.0)
		y += 4.0
	g.draw_rect(Rect2(Vector2(visor.position.x + 6, scan_y), Vector2(visor.size.x - 12, 2)), Color(CYAN, 0.07), true)
	for i in range(4):
		var dir := Vector2(1 if i in [0, 3] else -1, 1 if i < 2 else -1)
		var corner: Vector2 = [visor.position, Vector2(visor.end.x, visor.position.y), visor.end, Vector2(visor.position.x, visor.end.y)][i]
		var p: Vector2 = corner + dir * 8.0
		g.draw_line(p, p + Vector2(dir.x * 30, 0), Color(0.6, 1.0, 1.0, 0.9), 3)
		g.draw_line(p, p + Vector2(0, dir.y * 22), Color(0.6, 1.0, 1.0, 0.9), 3)
	if visor.size.x < 900.0:
		return
	var tab := Rect2(Vector2(visor.get_center().x - 130, visor.position.y - 1), Vector2(260, 20))
	g.draw_rect(tab, Color(0.02, 0.12, 0.14, 0.95), true)
	g.draw_rect(tab, Color(CYAN, 0.6), false, 1.0)
	text(g, "BRACELETE  ·  ARQUIVO TEMPORAL", tab.grow(-3), 11, Color(0.7, 1.0, 1.0), true)


## Bracelete da personagem embaixo da tela; a gema projeta o visor.
func draw_bracelet(g, center: Vector2, open: float, now: float, areas: Dictionary) -> void:
	var small: bool = areas.small
	var w: float = 250.0 if not small else 190.0
	var h: float = 44.0 if not small else 32.0
	var band := Rect2(center - Vector2(w, h) * 0.5, Vector2(w, h))
	var metal := _style(Color(0.09, 0.1, 0.13, 1.0), Color(0.46, 0.52, 0.6, 1.0), int(h * 0.5))
	metal.set_border_width_all(2)
	g.draw_style_box(metal, band)
	g.draw_rect(Rect2(band.position + Vector2(h * 0.4, 4), Vector2(w - h * 0.8, 3)), Color(1, 1, 1, 0.16), true)
	for k in range(6):
		var x: float = band.position.x + 22.0 + float(k) * (w - 44.0) / 5.0
		if absf(x - center.x) < 34.0:
			continue
		g.draw_line(Vector2(x, band.position.y + 9), Vector2(x, band.end.y - 9), Color(CYAN, 0.25 + 0.2 * sin(now * 3.0 + float(k))), 2.0)
	var pulse: float = 0.5 + 0.5 * sin(now * 4.0)
	var gem_r: float = h * 0.42
	var flash: float = _purchase_flash(g)
	g.draw_circle(center, gem_r + 10.0 + pulse * 4.0 + flash * 18.0, Color(CYAN, 0.12 + 0.1 * open + flash * 0.3))
	g.draw_circle(center, gem_r, Color(0.04, 0.3, 0.34))
	g.draw_circle(center, gem_r * 0.72, Color(0.3 + flash * 0.6, 0.95, 1.0, 0.9))
	g.draw_circle(center + Vector2(-gem_r * 0.25, -gem_r * 0.3), gem_r * 0.22, Color(1, 1, 1, 0.8))
	g.draw_arc(center, gem_r + 3.0, 0.0, TAU, 24, Color(0.8, 1.0, 1.0, 0.8), 2.0, true)


func _purchase_flash(g) -> float:
	if not g._shop_purchase_animating():
		return 0.0
	var p: float = 1 - g.shop_purchase_anim_timer / g.SHOP_PURCHASE_ANIM_TIME
	return clampf(1.0 - absf(p - 0.9) / 0.12, 0.0, 1.0)


## Feixe de luz da gema ate a base do visor.
func draw_beam(g, gem: Vector2, visor: Rect2, open: float, now: float) -> void:
	var top_y: float = lerpf(gem.y, visor.end.y - 4.0, 1.0)
	var half_top: float = visor.size.x * 0.32 * open
	var a: float = 0.14 + 0.05 * sin(now * 5.0)
	var pts := PackedVector2Array([gem + Vector2(-10, -6), gem + Vector2(10, -6), Vector2(gem.x + half_top, top_y), Vector2(gem.x - half_top, top_y)])
	var cols := PackedColorArray([Color(CYAN, a * 2.2), Color(CYAN, a * 2.2), Color(CYAN, a * 0.4), Color(CYAN, a * 0.4)])
	g.draw_polygon(pts, cols)


## Contador de pontos grande com moeda.
func draw_points_counter(g, rect: Rect2, now: float, small: bool) -> void:
	var coin := rect.position + Vector2(20, rect.size.y * 0.5 + 2)
	var r: float = 15.0 if not small else 12.0
	var spin: float = absf(cos(now * 1.6))
	g.draw_circle(coin, r + 5.0, Color(GOLD, 0.15))
	g.draw_set_transform(_visor_origin + coin * _visor_scale, 0.0, Vector2(maxf(0.25, spin), 1.0) * _visor_scale)
	g.draw_circle(Vector2.ZERO, r, Color(1.0, 0.76, 0.18))
	g.draw_circle(Vector2.ZERO, r * 0.72, Color(0.8, 0.48, 0.06))
	g.draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 20, Color(1.0, 0.95, 0.6), 1.6, true)
	g.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_restore_visor_transform(g)
	var x: float = coin.x + r + 12.0
	text(g, "PONTOS", Rect2(x, rect.position.y + 2, 160, 14), 11, Color(GOLD, 0.8))
	var value_size: int = 34 if not small else 26
	var bump: float = 0.0
	if g.shop_spend_anim_timer > 0.0 and g.shop_spend_anim_amount > 0:
		bump = sin((1.0 - clampf(g.shop_spend_anim_timer / maxf(0.01, g.SHOP_SPEND_ANIM_TIME), 0.0, 1.0)) * PI)
	var value_rect := Rect2(x - 1, rect.position.y + 14, 240, rect.size.y - 12)
	text(g, g._format_points(g.score), Rect2(value_rect.position + Vector2(2, 2), value_rect.size), value_size, Color(0.25, 0.12, 0.0, 0.9))
	text(g, g._format_points(g.score), value_rect, value_size, Color(1.0, 0.86 - bump * 0.3, 0.34 - bump * 0.2))
	if bump > 0.0:
		var p: float = 1.0 - clampf(g.shop_spend_anim_timer / maxf(0.01, g.SHOP_SPEND_ANIM_TIME), 0.0, 1.0)
		var alpha: float = 1.0 - smoothstep(0.6, 1.0, p)
		var face: Font = g.menu_ui_font
		var w: float = face.get_string_size(g._format_points(g.score), HORIZONTAL_ALIGNMENT_LEFT, -1, value_size).x
		text(g, "-%s" % g._format_points(g.shop_spend_anim_amount), Rect2(x + w + 12, rect.position.y + 14 - p * 18.0, 140, 28), 20, Color(1.0, 0.45, 0.2, alpha))


var _visor_origin := Vector2.ZERO
var _visor_scale := Vector2.ONE


func _restore_visor_transform(g) -> void:
	# draw_set_transform da moeda substitui o do visor; reaplica a abertura.
	g.draw_set_transform(_visor_origin, 0.0, _visor_scale)


## MEU DECK: pilha de cartas + contador grande.
func draw_deck_button(g, rect: Rect2, now: float) -> void:
	var count: int = g._deck_total_cards()
	var enabled: bool = count > 0 and not busy() and not g._shop_purchase_animating()
	var hovered: bool = enabled and rect.has_point(g.get_local_mouse_position())
	g.draw_style_box(_style(GOLD.darkened(0.82 if hovered else 0.9), Color(GOLD, 0.9 if enabled else 0.35), 6), rect)
	var stack := rect.position + Vector2(22, rect.size.y * 0.5)
	for k in range(3):
		var c := Rect2(stack + Vector2(-9 + k * 3, -13 + k * 2), Vector2(16, 22))
		g.draw_rect(c, Color(0.1, 0.14, 0.16), true)
		g.draw_rect(c, Color(GOLD, 0.8 - float(2 - k) * 0.2), false, 1.5)
	text(g, "MEU DECK", Rect2(rect.position + Vector2(42, 4), Vector2(rect.size.x - 50, rect.size.y * 0.45)), 12, Color(PAPER, 0.85 if enabled else 0.5))
	var pulse: float = 0.0
	if g._shop_purchase_animating():
		var p: float = 1 - g.shop_purchase_anim_timer / g.SHOP_PURCHASE_ANIM_TIME
		pulse = clampf(1.0 - absf(p - 0.95) / 0.1, 0.0, 1.0)
	text(g, ("%d CARTA" if count == 1 else "%d CARTAS") % count, Rect2(rect.position + Vector2(42, rect.size.y * 0.42), Vector2(rect.size.x - 50, rect.size.y * 0.5)), 17 + int(pulse * 4.0), Color(1.0, 0.86 + pulse * 0.14, 0.34 + pulse * 0.5))


## Botao de queimar com chamas vivas em cima.
func draw_fire_button(g, rect: Rect2, label: String, enabled: bool, now: float) -> void:
	var alpha: float = 1.0 if enabled else 0.45
	var heat: float = 0.5 + 0.5 * sin(now * 9.0)
	g.draw_style_box(_style(Color(0.22 + heat * 0.06, 0.05, 0.02, 0.96), Color(1.0, 0.42 + heat * 0.2, 0.12, alpha), 4), rect)
	var n: int = maxi(5, int(rect.size.x / 14.0))
	for k in range(n):
		var u: float = (float(k) + 0.5) / float(n)
		var x: float = rect.position.x + u * rect.size.x
		var phase: float = float(k) * 1.7
		var hgt: float = (10.0 + 9.0 * (0.5 + 0.5 * sin(now * 11.0 + phase)) + 5.0 * sin(now * 5.3 + phase * 2.0)) * alpha
		var wob: float = sin(now * 7.0 + phase) * 3.0
		var base := Vector2(x, rect.position.y + 3)
		g.draw_colored_polygon(PackedVector2Array([base + Vector2(-6, 0), base + Vector2(wob, -hgt), base + Vector2(6, 0)]), Color(1.0, 0.34, 0.06, 0.8 * alpha))
		g.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 0), base + Vector2(wob * 0.6, -hgt * 0.62), base + Vector2(3, 0)]), Color(1.0, 0.86, 0.3, 0.9 * alpha))
	for k in range(4):
		var life: float = fposmod(now * 0.9 + float(k) * 0.27, 1.0)
		var sx: float = rect.position.x + rect.size.x * fposmod(float(k) * 0.37 + 0.1, 1.0) + sin(now * 3.0 + float(k)) * 6.0
		g.draw_rect(Rect2(Vector2(sx, rect.position.y - 6.0 - life * 26.0), Vector2(2, 2)), Color(1.0, 0.6, 0.2, (1.0 - life) * alpha), true)
	text(g, label, rect.grow(-8), 17, Color(1.0, 0.94, 0.8, alpha), true)


func draw_padlock(g, center: Vector2, scale: float, color: Color, closed: bool) -> void:
	var w: float = 14.0 * scale
	var h: float = 11.0 * scale
	g.draw_rect(Rect2(center + Vector2(-w * 0.5, -h * 0.2), Vector2(w, h)), color, true)
	var shackle_y: float = center.y - h * 0.2
	var open_off: float = 0.0 if closed else -4.0 * scale
	g.draw_arc(Vector2(center.x, shackle_y + open_off), w * 0.34, PI, TAU, 12, color, 2.4 * scale, true)
	g.draw_circle(center + Vector2(0, h * 0.3), 1.6 * scale, Color(0, 0, 0, 0.7))


## Reserva: dois colchetes holograficos fecham a carta e um cadeado cai.
func draw_lock_overlay(g, rect: Rect2, t: float, releasing: bool, now: float) -> void:
	var k: float = smoothstep(0.0, 1.0, t)
	if releasing:
		k = 1.0 - k
	if k <= 0.01:
		return
	var close: float = smoothstep(0.0, 0.55, k)
	var gap: float = lerpf(rect.size.x * 0.5 + 30.0, 4.0, close)
	var cy: float = rect.get_center().y
	var col := Color(CYAN, 0.9 * k)
	for s in [-1.0, 1.0]:
		var x: float = rect.get_center().x + s * gap
		var x_edge: float = rect.position.x if s < 0.0 else rect.end.x
		var bx: float = lerpf(x, x_edge + s * 4.0, close)
		g.draw_line(Vector2(bx, rect.position.y - 4), Vector2(bx, rect.end.y + 4), col, 3.0)
		g.draw_line(Vector2(bx, rect.position.y - 4), Vector2(bx - s * 14.0, rect.position.y - 4), col, 3.0)
		g.draw_line(Vector2(bx, rect.end.y + 4), Vector2(bx - s * 14.0, rect.end.y + 4), col, 3.0)
	g.draw_rect(rect, Color(0.1, 0.6, 0.7, 0.12 * k), true)
	var drop: float = smoothstep(0.35, 0.85, k)
	var bounce: float = 1.0 + sin(clampf((k - 0.6) / 0.4, 0.0, 1.0) * PI) * 0.35
	var lock_pos := Vector2(rect.get_center().x, lerpf(rect.position.y - 40.0, rect.position.y + 2.0, drop))
	g.draw_circle(lock_pos, 20.0 * bounce, Color(0.02, 0.16, 0.2, 0.92 * drop))
	g.draw_arc(lock_pos, 20.0 * bounce, 0.0, TAU, 24, Color(CYAN, drop), 2.0, true)
	draw_padlock(g, lock_pos + Vector2(0, 2), 1.3 * bounce, Color(0.7, 1.0, 1.0, drop), k > 0.75)
	if k > 0.8:
		var ring: float = clampf((k - 0.8) / 0.2, 0.0, 1.0)
		if not releasing and t < 1.0:
			g.draw_arc(lock_pos, 20.0 + ring * 40.0, 0.0, TAU, 28, Color(CYAN, 0.7 * (1.0 - ring)), 2.0, true)
		var strip := Rect2(rect.position.x + 8, cy - 15, rect.size.x - 16, 30)
		g.draw_rect(strip, Color(0.02, 0.13, 0.16, 0.94 * ring), true)
		g.draw_line(strip.position, Vector2(strip.end.x, strip.position.y), Color(CYAN, ring), 2)
		text(g, "RESERVADA", strip.grow(-4), 14, Color(CYAN, ring), true)


## Arte surgindo/sumindo em linhas de varredura (reroll e entrada do visor).
func draw_art_reveal(g, texture: Texture2D, rect: Rect2, reveal: float, accent: Color) -> void:
	if reveal <= 0.0:
		return
	var source_size := texture.get_size()
	var fitted := source_size * minf(rect.size.x / source_size.x, rect.size.y / source_size.y)
	var origin := rect.get_center() - fitted * 0.5
	var lines := 18
	var shown: float = reveal * float(lines)
	for i in range(lines):
		var a: float = clampf(shown - float(i), 0.0, 1.0)
		if a <= 0.0:
			continue
		var band_h: float = fitted.y / float(lines)
		var jitter: float = (1.0 - a) * sin(float(i) * 9.1 + reveal * 30.0) * 10.0
		var dst := Rect2(origin + Vector2(jitter, band_h * float(i)), Vector2(fitted.x, band_h + 0.5))
		var src := Rect2(0, source_size.y * float(i) / float(lines), source_size.x, source_size.y / float(lines))
		g.draw_texture_rect_region(texture, dst, src, Color(0.6 + 0.4 * a, 1.0, 1.0, a))
	var scan_y: float = origin.y + fitted.y * reveal
	g.draw_rect(Rect2(Vector2(origin.x - 4, scan_y - 2), Vector2(fitted.x + 8, 3)), Color(accent.lightened(0.5), 0.9), true)
	g.draw_rect(Rect2(Vector2(origin.x - 4, scan_y - 8), Vector2(fitted.x + 8, 14)), Color(CYAN, 0.12), true)


## Varredura que atravessa o visor no reroll.
func draw_reroll_scan(g, visor: Rect2, t: float) -> void:
	var x: float = lerpf(visor.position.x, visor.end.x, smoothstep(0.0, 1.0, t))
	var a: float = sin(t * PI)
	g.draw_rect(Rect2(Vector2(x - 2, visor.position.y + 6), Vector2(3, visor.size.y - 12)), Color(0.8, 1.0, 1.0, 0.8 * a), true)
	g.draw_rect(Rect2(Vector2(x - 40, visor.position.y + 6), Vector2(40, visor.size.y - 12)), Color(CYAN, 0.08 * a), true)


func draw_card_trail(g, from: Vector2, to: Vector2, flight: float, accent: Color) -> void:
	var prev := from
	for k in range(1, 9):
		var u: float = float(k) / 8.0 * flight
		var p: Vector2 = from.lerp(to, u) + Vector2(0, -sin(u * PI) * 70)
		g.draw_line(prev, p, Color(accent, 0.5 * (1.0 - float(k) / 10.0)), 3.0, true)
		prev = p
	g.draw_circle(to, 10.0, Color(accent.lightened(0.4), 0.5))


## Chamas na borda de cartas ja queimadas (Cinzas): mais cargas = mais fogo,
## sem nunca apagar o desenho.
func draw_card_flames(g, rect: Rect2, card: Dictionary, now: float) -> void:
	var stacks: int = clampi(int(card.get("cinzas_buff_stacks", 1)), 1, 10)
	var heat: float = float(stacks) / 10.0
	var n: int = 4 + stacks * 2
	for k in range(n):
		var u: float = (float(k) + 0.5) / float(n)
		var phase: float = float(k) * 2.3 + float(stacks)
		var hgt: float = (8.0 + 16.0 * heat) * (0.6 + 0.4 * sin(now * 10.0 + phase))
		var base := Vector2(rect.position.x + u * rect.size.x, rect.end.y - 2.0)
		var wob: float = sin(now * 6.0 + phase) * 4.0
		g.draw_colored_polygon(PackedVector2Array([base + Vector2(-7, 0), base + Vector2(wob, -hgt), base + Vector2(7, 0)]), Color(1.0, 0.32, 0.06, 0.75))
		g.draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 0), base + Vector2(wob * 0.6, -hgt * 0.6), base + Vector2(3, 0)]), Color(1.0, 0.85, 0.3, 0.9))
	if stacks >= 4:
		# Lados pegam fogo a partir da 4a carga.
		var side_n: int = mini(6, stacks - 2)
		for s in [rect.position.x + 2.0, rect.end.x - 2.0]:
			for k in range(side_n):
				var v: float = 1.0 - (float(k) + 0.5) / float(side_n) * (0.35 + heat * 0.4)
				var phase2: float = float(k) * 1.9 + s
				var base2 := Vector2(s, rect.position.y + rect.size.y * v)
				var hh: float = (6.0 + 8.0 * heat) * (0.6 + 0.4 * sin(now * 9.0 + phase2))
				var dir: float = -1.0 if s < rect.get_center().x else 1.0
				g.draw_colored_polygon(PackedVector2Array([base2 + Vector2(0, -5), base2 + Vector2(dir * hh, sin(now * 7.0 + phase2) * 3.0 - 3.0), base2 + Vector2(0, 5)]), Color(1.0, 0.45, 0.1, 0.7))
	for k in range(3 + stacks):
		var life: float = fposmod(now * (0.5 + 0.05 * float(k)) + float(k) * 0.31, 1.0)
		var x: float = rect.position.x + rect.size.x * fposmod(float(k) * 0.29 + 0.07, 1.0) + sin(now * 2.0 + float(k)) * 8.0
		g.draw_rect(Rect2(Vector2(x, rect.end.y - life * rect.size.y * (0.4 + heat * 0.5)), Vector2(2, 2)), Color(1.0, 0.62, 0.2, (1.0 - life) * 0.9), true)


func draw_legacy(g, viewport: Vector2) -> void:
	var buttons: Dictionary = g.buttons
	var textures: Dictionary = g.textures
	var font: Font = g.font
	var is_multiplayer: bool = g.is_multiplayer
	var shop_cards: Array = g.shop_cards
	var shop_selected: int = g.shop_selected
	var shop_select_pulse_index: int = g.shop_select_pulse_index
	var shop_select_pulse_timer: float = g.shop_select_pulse_timer
	var shop_purchase_anim_timer: float = g.shop_purchase_anim_timer
	var SHOP_PURCHASE_ANIM_TIME: float = g.SHOP_PURCHASE_ANIM_TIME
	var shop_endurance_discount: float = g.shop_endurance_discount
	var score: int = g.score
	var card_cost: int = g.card_cost
	var reroll_status: String = reroll_status_line(g)
	var reroll_accent: Color = Color(reroll_visual_state(g).get("accent", CYAN))
	var shop_mp_ready_to_leave: bool = g.shop_mp_ready_to_leave
	for key in buttons.keys():
		if String(key).begins_with("shop_burn_") or String(key).begins_with("shop_reserve_"):
			buttons.erase(key)

	g._draw_holo_background(viewport, textures["cards_back"], Color(0.0, 1.0, 0.82))

	var portrait = g._is_portrait(viewport)
	var purchase_animating = g._shop_purchase_animating()
	var purchase_progress = 0.0
	if purchase_animating:
		purchase_progress = 1.0 - clamp(shop_purchase_anim_timer / SHOP_PURCHASE_ANIM_TIME, 0.0, 1.0)
	var purchase_index = shop_select_pulse_index if purchase_animating else -1
	if shop_cards.is_empty():
		var empty_w: float = min(480.0, viewport.x * 0.86)
		var empty_panel: = Rect2(viewport.x * 0.5 - empty_w * 0.5, viewport.y * 0.5 - 84.0, empty_w, 168.0)
		g._draw_holo_panel(empty_panel, Color(0.0, 1.0, 0.82), true, 0.8)
		g._draw_glitch_title("LOJA SINCRONIZADA", Vector2(empty_panel.get_center().x, empty_panel.position.y + 50.0), 24, Color(0.0, 1.0, 0.82))
		var wait_text: = "AGUARDANDO PARCEIRO"
		if not is_multiplayer:
			wait_text = "SEM CARTAS DISPONIVEIS"
		g._draw_centered(wait_text, empty_panel.get_center() + Vector2(0, 22), g._readable_text_size(17), Color(1.0, 0.88, 0.32))
		return

	if portrait:
		var header = Rect2(viewport.x * 0.06, 24, viewport.x * 0.88, 124)
		g._draw_holo_panel(header, Color(0.0, 1.0, 0.82), true, 0.76)
		g._draw_glitch_title("LOJA DE CARTAS", Vector2(viewport.x * 0.5, 60), 30, Color(0.0, 1.0, 0.82))
		var header_text = "Pontos %s  |  Custo %s  |  %s" % [g._format_points(score), g._format_points(card_cost), reroll_status]
		if shop_endurance_discount > 0.0:
			header_text += "  |  Resistencia -%d%%" % int(round(shop_endurance_discount * 100.0))
		if purchase_animating:
			header_text = g._shop_purchase_stage(purchase_progress)
		g._draw_centered(header_text, Vector2(viewport.x * 0.5, 96), g._readable_text_size(16), Color(1.0, 0.85, 0.24))
		g._draw_shop_spend_anim(Vector2(viewport.x * 0.5, 132.0))
		g._draw_shop_tutorial_line(Rect2(header.position + Vector2(20.0, 90.0), Vector2(header.size.x - 40.0, 28.0)), true)
		g._draw_shop_round_button(g._shop_reroll_center(viewport), g._shop_round_button_radius(viewport), "REROLL", reroll_accent, g.shop_controller.can_reroll(), "reroll")
		g._draw_shop_round_button(g._shop_deck_center(viewport), g._shop_round_button_radius(viewport), "DECK", Color(0.64, 0.88, 1.0), g._deck_total_cards() > 0 and not purchase_animating, "deck")

		var w = viewport.x * 0.74
		var h = min(242.0, viewport.y * 0.19)
		for i in range(shop_cards.size()):
			var card: Dictionary = shop_cards[i]
			var rarity_color: Color = g._card_rarity_color(card)
			var cinzas_buffed: = bool(card.get("cinzas_return_buff", false))
			var x = viewport.x * 0.5 - w * 0.5
			var y = 188.0 + i * (h + 22.0)
			var rect = Rect2(x, y, w, h)
			var card_alpha = 1.0
			var content_alpha: float = card_alpha
			var icon_alpha: float = card_alpha
			if purchase_animating:
				card_alpha = 0.18 if i != purchase_index else 1.0
			if i == shop_selected:
				var select_pulse = 0.0
				if shop_select_pulse_index == i and shop_select_pulse_timer > 0.0:
					select_pulse = sin((1.0 - shop_select_pulse_timer / 0.26) * PI)
				rect = rect.grow(12 + select_pulse * 12.0)
			var purchase_origin: Vector2 = rect.get_center()
			if purchase_animating and i == purchase_index:
				g._draw_shop_purchase_transfer_fx(purchase_origin, g._shop_deck_center(viewport), purchase_progress, rarity_color)
				var transfer_t: float = smoothstep(0.0, 1.0, clampf((purchase_progress - 0.14) / 0.72, 0.0, 1.0))
				var flight_center: Vector2 = purchase_origin.lerp(g._shop_deck_center(viewport), transfer_t)
				var card_scale: float = lerpf(1.0, 0.46, transfer_t)
				rect.size = rect.size * card_scale
				rect.position = flight_center - rect.size * 0.5
				var burst: float = sin(clampf(purchase_progress / 0.28, 0.0, 1.0) * PI)
				rect = rect.grow(10.0 + burst * 16.0)
				card_alpha = lerpf(1.0, 0.34, transfer_t)
				content_alpha = card_alpha * (1.0 - clampf((transfer_t - 0.08) / 0.18, 0.0, 1.0))
				icon_alpha = card_alpha * lerpf(1.0, 0.72, transfer_t)
			var bg_color = Color(0.035, 0.045, 0.06)
			bg_color = bg_color.lerp(card["color"], 0.14 if i == shop_selected else 0.05)
			if cinzas_buffed:
				bg_color = Color(0.03, 0.022, 0.018).lerp(card["color"], 0.05 if i == shop_selected else 0.02)
			bg_color.a = 0.94 * card_alpha
			if cinzas_buffed:
				g._draw_cinzas_burn_glow(rect, card_alpha, i == shop_selected)
			else:
				g.draw_rect(rect, bg_color, true)
			var border_color = rarity_color if i == shop_selected else Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.58)
			if not cinzas_buffed:
				border_color.a = max(0.16, card_alpha)
				g.draw_rect(rect, border_color, false, 5 if i == shop_selected else 2)
			if purchase_animating and i == purchase_index:
				var glow = (0.35 + sin(Time.get_ticks_msec() * 0.01) * 0.15) * (1.0 - purchase_progress * 0.35)
				for glow_index in range(1, 4):
					var glow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, glow / float(glow_index))
					g.draw_rect(rect.grow(glow_index * 7.0), glow_color, false, 2)
			var icon: Texture2D = g._card_texture(card)
			if icon:
				var icon_rect = Rect2(rect.position + Vector2(18, 18), Vector2(94, rect.size.y - 36))
				if not g._draw_cinzas_shader_card(card, icon_rect, icon, icon_alpha, false):
					g._draw_texture_contain(icon, icon_rect, Color(1.0, 1.0, 1.0, icon_alpha))
			g._draw_centered(card["name"], Vector2(rect.position.x + 128 + (rect.size.x - 150) * 0.5, rect.position.y + 48), g._readable_text_size(19), Color(1.0, 1.0, 1.0, content_alpha))
			g._draw_centered(g._card_rarity_label(card), Vector2(rect.end.x - 52.0, rect.position.y + 24.0), g._readable_text_size(10), Color(rarity_color.r, rarity_color.g, rarity_color.b, content_alpha))
			var nick_color = Color(card["color"].r, card["color"].g, card["color"].b, content_alpha)
			g._draw_centered(card["nick"], Vector2(rect.position.x + 128 + (rect.size.x - 150) * 0.5, rect.position.y + 80), g._readable_text_size(15), nick_color)
			g._draw_wrapped(card["desc"], Rect2(rect.position + Vector2(128, 102), Vector2(rect.size.x - 150, rect.size.y - 118)), g._readable_text_size(12), Color(0.84, 0.89, 0.93, max(0.0, content_alpha)))
			var price_rect = Rect2(rect.end.x - 118.0, rect.end.y - 44.0, 94.0, 28.0)
			draw_bargain_price_tag(g, card, price_rect, i == shop_selected, content_alpha)
			draw_bargain_banner(g, card, rect, content_alpha)
			if g._can_toggle_shop_reserve(i):
				var reserve_rect = Rect2(rect.position.x + 18.0, rect.end.y - 44.0, 96.0, 28.0)
				buttons["shop_reserve_%d" % i] = reserve_rect
				var reserve_color: = Color(0.04, 0.14, 0.2, 0.86 * content_alpha)
				if g._shop_slot_locked(i):
					reserve_color = Color(0.12, 0.28, 0.08, 0.9 * content_alpha)
				g.draw_rect(reserve_rect, reserve_color, true)
				g.draw_rect(reserve_rect, Color(0.4, 0.94, 1.0, 0.82 * content_alpha), false, 1)
				g._draw_centered("SOLTAR" if g._shop_slot_locked(i) else "TRAVAR", reserve_rect.get_center() + Vector2(0, 4), g._readable_text_size(10), Color(1.0, 1.0, 1.0, content_alpha))
			if g._can_burn_shop_card(card):
				var burn_rect = Rect2(rect.position.x + 18.0, rect.end.y - 78.0, 96.0, 28.0)
				buttons["shop_burn_%d" % i] = burn_rect
				g.draw_rect(burn_rect, Color(0.2, 0.08, 0.04, 0.88 * content_alpha), true)
				g.draw_rect(burn_rect, Color(1.0, 0.58, 0.28, 0.82 * content_alpha), false, 1)
				g._draw_centered("QUEIMAR", burn_rect.get_center() + Vector2(0, 4), g._readable_text_size(10), Color(1.0, 1.0, 1.0, content_alpha))
			if i == shop_selected:
				g._draw_card_stat_chips(g._card_stat_chips(String(card["name"])), rect.position + Vector2(128, rect.size.y - 76), rect.size.x - 150, Color(card["color"].r, card["color"].g, card["color"].b, content_alpha), g._readable_text_size(11))
				var conf_rect = Rect2(rect.position.x + 128, rect.position.y + rect.size.y - 45, rect.size.x - 140, 35)
				g.draw_rect(conf_rect, Color(0.05, 0.35, 0.15, 0.9 * content_alpha), true)
				g.draw_rect(conf_rect, Color(0.2, 1.0, 0.45, max(0.0, content_alpha)), false, 1)
				var confirm_label = "VAZIA" if g._is_empty_shop_slot(card) else ("CONFIRMADA" if purchase_animating and i == purchase_index else "SELECIONADA")
				g._draw_centered(confirm_label, Vector2(conf_rect.position.x + conf_rect.size.x * 0.5, conf_rect.position.y + 22), g._readable_text_size(16), Color(1.0, 1.0, 1.0, content_alpha))

		var btn_h = 44.0
		var btn_w = viewport.x * 0.4
		var btn_y = viewport.y - btn_h - 24


		var btn_buy_rect = Rect2(viewport.x * 0.25 - btn_w * 0.5, btn_y, btn_w, btn_h)
		var selected_empty_portrait: bool = shop_cards.size() > shop_selected and g._is_empty_shop_slot(shop_cards[shop_selected])
		var selected_price_portrait: int = g._effective_card_price(shop_cards[shop_selected]) if shop_cards.size() > shop_selected and not selected_empty_portrait else card_cost
		var buy_bg_portrait: Color = Color(0.03, 0.12, 0.05) if score >= selected_price_portrait and not selected_empty_portrait else Color(0.08, 0.08, 0.08)
		var buy_border_portrait: Color = Color(0.2, 1.0, 0.45) if score >= selected_price_portrait and not selected_empty_portrait else Color(0.3, 0.3, 0.3)
		if purchase_animating:
			buy_bg_portrait = Color(0.08, 0.08, 0.08, 0.55)
			buy_border_portrait = Color(0.36, 0.36, 0.36, 0.55)
		var buy_label_portrait: String = "VAZIA" if selected_empty_portrait else ("CONFIRMANDO..." if purchase_animating else "COMPRAR %d" % selected_price_portrait)
		g._draw_small_rect_button(btn_buy_rect, buy_label_portrait, buy_bg_portrait, buy_border_portrait)


		var btn_sair_rect = Rect2(viewport.x * 0.75 - btn_w * 0.5, btn_y, btn_w, btn_h)
		var can_exit = g._shop_can_exit()

		if not can_exit:
			g._draw_small_rect_button(btn_sair_rect, "GASTE SEUS PONTOS", Color(0.15, 0.03, 0.05, 0.9), Color(0.5, 0.25, 0.28, 1.0))
		elif shop_mp_ready_to_leave:
			g._draw_small_rect_button(btn_sair_rect, "AGUARDANDO PARCEIRO", Color(0.05, 0.15, 0.05, 0.9), Color(0.2, 1.0, 0.45, 1.0))
		else:
			g._draw_small_rect_button(btn_sair_rect, "AGUARDE" if purchase_animating else "FECHAR LOJA", Color(0.12, 0.03, 0.05, 0.55 if purchase_animating else 1.0), Color(1.0, 0.25, 0.28, 0.55 if purchase_animating else 1.0))
		return



	var header = Rect2(viewport.x * 0.05, 16, viewport.x * 0.9, 98)
	g._draw_holo_panel(header, Color(0.0, 1.0, 0.82), true, 0.76)
	g._draw_glitch_title("LOJA DE CARTAS", Vector2(viewport.x * 0.5, 46), 26, Color(0.0, 1.0, 0.82))


	var hud_text = "Pontos: %s  |  Custo: %s  |  %s" % [g._format_points(score), g._format_points(card_cost), reroll_status]
	if shop_endurance_discount > 0.0:
		hud_text += "  |  Resistencia -%d%%" % int(round(shop_endurance_discount * 100.0))
	g._draw_centered(hud_text, Vector2(viewport.x * 0.5, 73), g._readable_text_size(16), Color(1.0, 0.85, 0.24))
	g._draw_shop_spend_anim(Vector2(viewport.x * 0.5, 116.0))
	g._draw_shop_tutorial_line(Rect2(header.position + Vector2(22.0, 74.0), Vector2(header.size.x - 44.0, 22.0)), false)
	g._draw_shop_round_button(g._shop_reroll_center(viewport), g._shop_round_button_radius(viewport), "REROLL", reroll_accent, g.shop_controller.can_reroll(), "reroll")
	g._draw_shop_round_button(g._shop_deck_center(viewport), g._shop_round_button_radius(viewport), "DECK", Color(0.64, 0.88, 1.0), g._deck_total_cards() > 0 and not purchase_animating, "deck")
	if purchase_animating and shop_cards.size() > purchase_index:
		g._draw_centered(g._shop_purchase_stage(purchase_progress), Vector2(viewport.x * 0.5, 124), g._readable_text_size(14), shop_cards[purchase_index]["color"])
	elif shop_select_pulse_timer > 0.0 and shop_cards.size() > shop_selected:
		g._draw_centered("CARTA SELECIONADA", Vector2(viewport.x * 0.5, 124), g._readable_text_size(14), shop_cards[shop_selected]["color"])


	var w = 150.0
	var h = 200.0
	var y = 158.0


	for i in range(shop_cards.size()):
		var card: Dictionary = shop_cards[i]
		var rarity_color: Color = g._card_rarity_color(card)
		var cinzas_buffed: = bool(card.get("cinzas_return_buff", false))


		var is_sel = (i == shop_selected)
		var scale = 1.15 if is_sel else 0.85
		if is_sel and shop_select_pulse_index == i and shop_select_pulse_timer > 0.0:
			scale += sin((1.0 - shop_select_pulse_timer / 0.26) * PI) * 0.1
		var alpha = 1.0 if is_sel else 0.5
		var content_alpha: float = alpha
		var icon_alpha: float = alpha
		if purchase_animating:
			alpha = 0.18 if i != purchase_index else 1.0
		if purchase_animating and i == purchase_index:
			var burst: float = sin(clampf(purchase_progress / 0.28, 0.0, 1.0) * PI)
			scale += burst * 0.18
			var transfer_t: float = smoothstep(0.0, 1.0, clampf((purchase_progress - 0.14) / 0.72, 0.0, 1.0))
			alpha = lerpf(1.0, 0.34, transfer_t)
		var curr_w = w * scale
		var curr_h = h * scale
		var x = viewport.x * 0.5 + (i - 1) * 200 - curr_w * 0.5
		var curr_y = y - 10 if is_sel else y + 15
		var rect = Rect2(x, curr_y, curr_w, curr_h)
		var purchase_origin: Vector2 = rect.get_center()
		if purchase_animating and i == purchase_index:
			g._draw_shop_purchase_transfer_fx(purchase_origin, g._shop_deck_center(viewport), purchase_progress, rarity_color)
			var transfer_t: float = smoothstep(0.0, 1.0, clampf((purchase_progress - 0.14) / 0.72, 0.0, 1.0))
			var flight_center: Vector2 = purchase_origin.lerp(g._shop_deck_center(viewport), transfer_t)
			var card_scale: float = lerpf(1.0, 0.46, transfer_t)
			rect.size = rect.size * card_scale
			rect.position = flight_center - rect.size * 0.5
			var rect_burst: float = sin(clampf(purchase_progress / 0.28, 0.0, 1.0) * PI)
			rect = rect.grow(10.0 + rect_burst * 16.0)
			content_alpha = alpha * (1.0 - clampf((transfer_t - 0.08) / 0.18, 0.0, 1.0))
			icon_alpha = alpha * lerpf(1.0, 0.72, transfer_t)


		var bg_color = Color(0.04, 0.05, 0.07, 0.85 * alpha)
		bg_color = bg_color.lerp(card["color"], 0.14 if is_sel else 0.05)
		if cinzas_buffed:
			bg_color = Color(0.028, 0.022, 0.018, 0.88 * alpha).lerp(card["color"], 0.045 if is_sel else 0.02)
		if cinzas_buffed:
			g._draw_cinzas_burn_glow(rect, alpha, is_sel)
		else:
			g.draw_rect(rect, bg_color, true)


		if is_sel and not cinzas_buffed:
			var pulsar = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
			for glow_index in range(1, 5):
				var glow_alpha = (1.0 - float(glow_index) / 5.0) * (0.3 + pulsar * 0.15)
				if purchase_animating and i == purchase_index:
					glow_alpha += 0.16
				var glow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, glow_alpha)
				g.draw_rect(rect.grow(glow_index * 3), glow_color, false, 1)


		var border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, alpha if is_sel else 0.55 * alpha)
		if not cinzas_buffed:
			g.draw_rect(rect, border_color, false, 4 if is_sel else 2)
		if is_sel and not cinzas_buffed:
			var scan_y = rect.position.y + 12.0 + fposmod(Time.get_ticks_msec() * 0.065, max(1.0, rect.size.y - 24.0))
			g.draw_line(Vector2(rect.position.x + 10.0, scan_y), Vector2(rect.end.x - 10.0, scan_y), Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.72), 2.0)
			var ribbon = Rect2(rect.position.x + 10.0, rect.position.y + 10.0, rect.size.x - 20.0, 25.0)
			g.draw_rect(ribbon, Color(0.0, 0.0, 0.0, 0.68 * content_alpha), true)
			g.draw_rect(ribbon, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.88 * content_alpha), false, 1)
			g._draw_centered("%s | PRE-SELECIONADA" % g._card_rarity_label(card), ribbon.get_center() + Vector2(0, 5), g._readable_text_size(9), Color(1.0, 1.0, 1.0, content_alpha))


		var icon: Texture2D = g._card_texture(card)
		if icon:
			var icon_rect = Rect2(rect.position + Vector2(6, 6), rect.size - Vector2(12, 12))
			if not g._draw_cinzas_shader_card(card, icon_rect, icon, icon_alpha, true):
				g._draw_texture_contain(icon, icon_rect, Color(1, 1, 1, icon_alpha))


		if not cinzas_buffed:
			var text_color = Color(1.0, 1.0, 1.0, content_alpha)
			g._draw_centered(card["nick"].to_upper(), Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 18), g._readable_text_size(12 if is_sel else 10), text_color)

		if is_sel and purchase_animating and i == purchase_index:
			var overlay_rect = Rect2(rect.position.x, rect.position.y + rect.size.y * 0.5 - 18, rect.size.x, 36)
			g.draw_rect(overlay_rect, Color(0.05, 0.35, 0.15, 0.95 * content_alpha), true)
			g.draw_rect(overlay_rect, Color(0.2, 1.0, 0.45, 0.9 * content_alpha), false, 2)
			g._draw_centered("CONFIRMADA", Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.5 + 5), g._readable_text_size(16), Color(1.0, 1.0, 1.0, content_alpha))


	if shop_cards.size() > shop_selected and shop_selected >= 0:
		var sel_card = shop_cards[shop_selected]
		var sel_rarity_color: Color = g._card_rarity_color(sel_card)
		var panel_w = viewport.x * 0.9
		var panel_h = 180.0
		var panel_x = viewport.x * 0.05
		var panel_y = viewport.y - panel_h - 96.0
		var panel_rect = Rect2(panel_x, panel_y, panel_w, panel_h)


		g.draw_rect(panel_rect, Color(0.03, 0.04, 0.06, 0.92), true)


		var border_p_color = Color(sel_rarity_color.r, sel_rarity_color.g, sel_rarity_color.b, 0.8)
		g.draw_rect(panel_rect, border_p_color, false, 2)


		var sep_x = panel_x + panel_w * 0.5 + 30.0
		g.draw_line(Vector2(sep_x, panel_y + 16), Vector2(sep_x, panel_y + panel_h - 16), Color(0.2, 0.2, 0.25, 0.6), 1)



		var title_pos = Vector2(panel_x + 24, panel_y + 30)
		g.draw_string(font, title_pos, sel_card["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, g._readable_text_size(22), sel_card["color"])


		var nick_pos = Vector2(panel_x + 24, panel_y + 60)
		g.draw_string(font, nick_pos, "\"" + sel_card["nick"].to_upper() + "\"", HORIZONTAL_ALIGNMENT_LEFT, -1, g._readable_text_size(15), Color(1, 1, 1, 0.9))


		var desc_rect = Rect2(panel_x + 24, panel_y + 82, (sep_x - panel_x) - 48, panel_h - 94)
		g._draw_wrapped(sel_card["desc"], desc_rect, g._readable_text_size(13), Color(0.88, 0.92, 0.96))


		var cat_name = g._card_category(sel_card["name"])


		var cat_pos = Vector2(sep_x + 24, panel_y + 30)
		g.draw_string(font, cat_pos, "%s | %s" % [g._card_rarity_label(sel_card), cat_name], HORIZONTAL_ALIGNMENT_LEFT, -1, g._readable_text_size(14), sel_rarity_color)


		g._draw_card_stat_chips(g._card_stat_chips(String(sel_card["name"])), Vector2(sep_x + 24, panel_y + 56), (panel_x + panel_w - sep_x) - 48, Color(sel_card["color"]), g._readable_text_size(13))

		var projection_lines: Array[String] = g._card_projection_lines(sel_card)
		g._draw_wrapped("\n".join(projection_lines), Rect2(sep_x + 24, panel_y + 98, (panel_x + panel_w - sep_x) - 196, 54), g._readable_text_size(11), Color(0.84, 0.92, 0.96))


		var owned_count = g._card_count(sel_card)
		var owned_text = "POSSUIDO NO DECK: %d" % owned_count
		var owned_pos = Vector2(sep_x + 24, panel_y + panel_h - 18)
		g.draw_string(font, owned_pos, owned_text, HORIZONTAL_ALIGNMENT_LEFT, -1, g._readable_text_size(13), sel_card["color"])
		if g._can_toggle_shop_reserve(shop_selected):
			var reserve_rect = Rect2(panel_x + panel_w - 164.0, panel_y + panel_h - 44.0, 138.0, 30.0)
			buttons["shop_reserve_%d" % shop_selected] = reserve_rect
			var reserve_bg: = Color(0.04, 0.14, 0.2, 0.92)
			if g._shop_slot_locked(shop_selected):
				reserve_bg = Color(0.12, 0.28, 0.08, 0.94)
			g.draw_rect(reserve_rect, reserve_bg, true)
			g.draw_rect(reserve_rect, Color(0.4, 0.94, 1.0, 0.92), false, 1)
			g._draw_centered("DESTRAVAR" if g._shop_slot_locked(shop_selected) else "TRAVAR", reserve_rect.get_center() + Vector2(0, 5), g._readable_text_size(12), Color.WHITE)
		if g._can_burn_shop_card(sel_card):
			var burn_rect = Rect2(panel_x + panel_w - 164.0, panel_y + panel_h - 80.0, 138.0, 30.0)
			buttons["shop_burn_%d" % shop_selected] = burn_rect
			g.draw_rect(burn_rect, Color(0.2, 0.08, 0.04, 0.92), true)
			g.draw_rect(burn_rect, Color(1.0, 0.58, 0.28, 0.92), false, 1)
			g._draw_centered("QUEIMAR", burn_rect.get_center() + Vector2(0, 5), g._readable_text_size(12), Color.WHITE)


	var btn_w = 220.0
	var btn_h = 42.0
	var btn_y = viewport.y - btn_h - 24.0


	var btn_buy_rect = Rect2(viewport.x * 0.38 - btn_w * 0.5, btn_y, btn_w, btn_h)
	var selected_empty: bool = shop_cards.size() > shop_selected and g._is_empty_shop_slot(shop_cards[shop_selected])
	var selected_price: int = g._effective_card_price(shop_cards[shop_selected]) if shop_cards.size() > shop_selected and not selected_empty else card_cost
	var buy_enabled: bool = score >= selected_price and not purchase_animating and not selected_empty
	var buy_bg: Color = Color(0.03, 0.16, 0.08, 0.9) if buy_enabled else Color(0.08, 0.08, 0.08, 0.6)
	var buy_border: Color = Color(0.2, 1.0, 0.45) if buy_enabled else Color(0.3, 0.3, 0.3)
	var buy_text_color: Color = Color(1.0, 1.0, 1.0) if buy_enabled else Color(0.5, 0.5, 0.5)
	g.draw_rect(btn_buy_rect, buy_bg, true)
	g.draw_rect(btn_buy_rect, buy_border, false, 2)
	var buy_label: String = "VAZIA" if selected_empty else ("CONFIRMANDO..." if purchase_animating else "COMPRAR (%d pts)" % selected_price)
	g._draw_centered(buy_label, btn_buy_rect.get_center() + Vector2(0, 7), 15, buy_text_color)


	var btn_sair_rect = Rect2(viewport.x * 0.62 - btn_w * 0.5, btn_y, btn_w, btn_h)
	var can_exit = g._shop_can_exit()

	if not can_exit:
		g.draw_rect(btn_sair_rect, Color(0.15, 0.03, 0.05, 0.9), true)
		g.draw_rect(btn_sair_rect, Color(0.5, 0.25, 0.28, 1.0), false, 2)
		g._draw_centered("GASTE SEUS PONTOS", btn_sair_rect.get_center() + Vector2(0, 7), 15, Color(1.0, 0.5, 0.5, 1.0))
	elif shop_mp_ready_to_leave:
		g.draw_rect(btn_sair_rect, Color(0.05, 0.15, 0.05, 0.9), true)
		g.draw_rect(btn_sair_rect, Color(0.2, 1.0, 0.45, 1.0), false, 2)
		g._draw_centered("AGUARDANDO PARCEIRO", btn_sair_rect.get_center() + Vector2(0, 7), 13, Color(0.5, 1.0, 0.7, 1.0))
	else:
		g.draw_rect(btn_sair_rect, Color(0.15, 0.03, 0.05, 0.5 if purchase_animating else 0.9), true)
		g.draw_rect(btn_sair_rect, Color(1.0, 0.25, 0.28, 0.55 if purchase_animating else 1.0), false, 2)
		g._draw_centered("AGUARDE" if purchase_animating else "FECHAR LOJA", btn_sair_rect.get_center() + Vector2(0, 7), 15, Color(1.0, 1.0, 1.0, 0.75 if purchase_animating else 1.0))




func _draw_burn(g, texture: Texture2D, rect: Rect2, progress: float) -> void:
	# Frente de fogo irregular sobe; a arte carboniza perto da frente, chamas
	# lambem a borda e cinzas sobem. Usa a arte real em faixas.
	var source_size := texture.get_size()
	var fitted := source_size * minf(rect.size.x / source_size.x, rect.size.y / source_size.y)
	var origin := rect.get_center() - fitted * 0.5
	var strips := 28
	var now: float = float(Time.get_ticks_msec()) * 0.001
	var width := fitted.x / float(strips)
	var glow: float = sin(clampf(progress, 0.0, 1.0) * PI)
	g.draw_rect(Rect2(origin - Vector2(6, 6), fitted + Vector2(12, 12)), Color(1.0, 0.36, 0.06, 0.16 * glow), true)
	for i in range(strips):
		var noise := sin(float(i) * 7.13) * 0.08 + sin(float(i) * 2.3 + 1.0) * 0.05
		var remaining := clampf(1.0 - progress * 1.15 + noise * sin(progress * PI), 0, 1)
		if remaining <= 0:
			continue
		var strip := Rect2(origin + Vector2(i * width, 0), Vector2(width + 0.5, fitted.y * remaining))
		var src := Rect2(source_size.x * i / strips, 0, source_size.x / strips, source_size.y * remaining)
		g.draw_texture_rect_region(texture, strip, src)
		# Carvao subindo na frente de fogo.
		var char_h: float = minf(strip.size.y, 18.0 + 22.0 * progress)
		g.draw_rect(Rect2(Vector2(strip.position.x, strip.end.y - char_h), Vector2(strip.size.x, char_h)), Color(0.12, 0.03, 0.0, 0.55), true)
		var front := Vector2(strip.position.x + width * 0.5, strip.end.y)
		g.draw_rect(Rect2(Vector2(strip.position.x, strip.end.y - 3), Vector2(strip.size.x, 4)), Color(1.0, 0.7, 0.2), true)
		var hgt: float = (10.0 + 14.0 * (0.5 + 0.5 * sin(now * 13.0 + float(i) * 1.7))) * (0.4 + glow)
		var wob: float = sin(now * 9.0 + float(i)) * 3.0
		g.draw_colored_polygon(PackedVector2Array([front + Vector2(-width * 0.7, 0), front + Vector2(wob, -hgt), front + Vector2(width * 0.7, 0)]), Color(1.0, 0.34, 0.05, 0.85))
		g.draw_colored_polygon(PackedVector2Array([front + Vector2(-width * 0.35, 0), front + Vector2(wob * 0.6, -hgt * 0.55), front + Vector2(width * 0.35, 0)]), Color(1.0, 0.9, 0.4, 0.95))
	for k in range(22):
		var life: float = fposmod(progress * 1.6 + float(k) * 0.137, 1.0)
		var x: float = origin.x + fitted.x * fposmod(float(k) * 0.271 + 0.05, 1.0) + sin(float(k) * 3.0 + progress * 9.0) * 14.0
		var y: float = origin.y + fitted.y * (1.0 - progress * 0.9) - life * 70.0
		var ash := Color(0.3, 0.28, 0.26, (1.0 - life) * 0.9) if k % 3 == 0 else Color(1.0, 0.5 + 0.3 * (1.0 - life), 0.15, (1.0 - life))
		g.draw_rect(Rect2(Vector2(x, y), Vector2(3, 3)), ash, true)


func draw_exit(g, viewport: Vector2) -> void:
	var progress: float = clampf(1 - g.shop_return_visual_timer / g.SHOP_RETURN_VISUAL_TIME, 0, 1)
	var areas := layout(viewport)
	if progress < 1:
		for i in range(mini(3, g.shop_cards.size())):
			var rect: Rect2 = areas.cards[i]
			var p := smoothstep(i * 0.07, 0.82 + i * 0.07, progress)
			rect.position.y += p * viewport.y
			var texture: Texture2D = g._card_texture(g.shop_cards[i])
			if texture:
				g._draw_texture_contain(texture, rect, Color(1, 1, 1, 1 - p))
	text(g, "RETORNO EM %d" % maxi(1, ceili(g.shop_return_timer)), Rect2(viewport.x * 0.5 - 130, 32, 260, 40), 20, PAPER, true)


func draw_waiting(g, viewport: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.012, 0.025, 0.032, 0.94))
	var width := minf(560, viewport.x - 48)
	var center := viewport * 0.5
	text(g, "EQUIPE NO ARQUIVO", Rect2(center - Vector2(width * 0.5, 118), Vector2(width, 28)), 15, CYAN, true)
	text(g, "COMPRAS CONCLUIDAS" if not g.is_dead and not g.online_local_spectator else "EQUIPE NA LOJA", Rect2(center - Vector2(width * 0.5, 72), Vector2(width, 40)), 28, PAPER, true)
	text(g, "%d / %d PRONTOS" % [g.shop_mp_ready_count, maxi(1, g.shop_mp_expected_count)], Rect2(center - Vector2(width * 0.5, 6), Vector2(width, 36)), 22, GOLD, true)
	var count: int = maxi(1, g.shop_mp_expected_count)
	for i in range(mini(count, 3)):
		var rect := Rect2(center.x - 92 + i * 64, center.y + 50, 52, 7)
		g.draw_rect(rect, CYAN if i < g.shop_mp_ready_count else MUTED.darkened(0.65))
	text(g, "A partida continua quando todos terminarem.", Rect2(center + Vector2(-width * 0.5, 85), Vector2(width, 30)), 17, MUTED, true)
