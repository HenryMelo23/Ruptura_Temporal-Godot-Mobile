extends RefCounted

const INK := Color(0.025, 0.038, 0.046)
const PAPER := Color(0.91, 0.95, 0.96)
const MUTED := Color(0.57, 0.69, 0.72)
const CYAN := Color(0.18, 0.88, 0.89)
const GOLD := Color(1.0, 0.78, 0.29)
const BURN_TIME := 0.72
var action := ""
var elapsed := 0.0
var duration := 0.0
var slot := -1
var previous_cards: Array = []
var entrance := 1.0


func reset() -> void:
	action = ""
	previous_cards.clear()
	entrance = 0.0


func begin(kind: String, cards: Array, index: int = -1) -> void:
	action = kind
	previous_cards = cards.duplicate(true)
	slot = index
	elapsed = 0.0
	duration = 0.62 if kind == "reroll" else (BURN_TIME if kind == "burn" else 0.34)


func busy() -> bool:
	return not action.is_empty()


func update(delta: float) -> void:
	entrance = minf(1.0, entrance + delta / 0.4)
	if not busy():
		return
	elapsed += delta
	if elapsed >= duration:
		action = ""
		previous_cards.clear()


func layout(viewport: Vector2) -> Dictionary:
	var margin := 28.0 if viewport.x >= 1000 else 16.0
	var detail_width := clampf(viewport.x * 0.3, 260.0, 380.0)
	var footer_y := viewport.y - 68.0
	var detail := Rect2(viewport.x - margin - detail_width, 132, detail_width, footer_y - 150)
	var rack := Rect2(margin, 148, detail.position.x - margin - 30, footer_y - 168)
	var card_width := minf(220.0, (rack.size.x - 32) / 3.0)
	var card_height := minf(card_width * 1.48, rack.size.y - 26)
	card_width = minf(card_width, card_height / 1.48)
	var cards: Array[Rect2] = []
	for i in range(3):
		var center := rack.position + Vector2(rack.size.x * (float(i) + 0.5) / 3, rack.size.y * 0.48)
		cards.append(Rect2(center - Vector2(card_width, card_height) * 0.5, Vector2(card_width, card_height)))
	return {
		"cards": cards, "detail": detail,
		"buy": Rect2(detail.position.x, footer_y, detail_width, 48),
		"exit": Rect2(margin, footer_y, 190, 48),
		"reroll": Rect2(viewport.x - margin - 240, 28, 112, 48),
		"deck": Rect2(viewport.x - margin - 112, 28, 112, 48),
		"burn": Rect2(detail.position.x, detail.end.y - 48, (detail_width - 12) * 0.5, 44),
		"reserve": Rect2(detail.position.x + (detail_width + 12) * 0.5, detail.end.y - 48, (detail_width - 12) * 0.5, 44)
	}


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


func draw_manual_reopen_warning(g, viewport: Vector2) -> void:
	var portrait: bool = g._is_portrait(viewport)
	var w: float = minf(viewport.x * (0.84 if portrait else 0.52), 680.0)
	var h: float = 76.0 if not portrait else 88.0
	var rect: Rect2 = Rect2(viewport.x * 0.5 - w * 0.5, viewport.y * (0.17 if not portrait else 0.14), w, h)
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	g._draw_holo_panel(rect, Color(1.0, 0.62, 0.16), true, 0.82)
	g.draw_rect(rect.grow(-7.0), Color(0.05, 0.016, 0.006, 0.54 + pulse * 0.12), true)
	g._draw_centered("AVISO DA LOJA", Vector2(rect.get_center().x, rect.position.y + 27.0), 17 if not portrait else 15, Color(1.0, 0.78, 0.26))
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
			return ["+0.3% SORTE"]
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
			return ["10s ARMAR", "ROOT/SLOW"]
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
			return ["12 ABATES", "COPIA CURTA"]
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
			return ["5s PARADO", "+VIDA PERDIDA"]
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
		g._draw_centered(str(g.shop_rerolls), center + Vector2(0, 5), 13, accent if enabled else Color(0.6, 0.6, 0.6))
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
	g._draw_centered("-%d PTS" % g.shop_spend_anim_amount, rect.get_center() + Vector2(0.0, 5.0), g._readable_text_size(14), Color(1.0, 0.58, 0.24, alpha))


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
	var compact: bool = detail.size.y < 290
	var margin: float = areas.exit.position.x
	g.buttons.clear()
	var background: Texture2D = g.textures.get("cards_back")
	if background:
		g.draw_texture_rect(background, Rect2(Vector2.ZERO, viewport), false, Color(0.22, 0.25, 0.26))
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.015, 0.022, 0.028, 0.76))
	g.draw_rect(Rect2(0, 0, viewport.x, 110), Color(0.02, 0.04, 0.048, 0.96))
	text(g, "ARQUIVO TEMPORAL", Rect2(margin, 15, 340, 18), 13, CYAN)
	text(g, "LOJA DE CARTAS", Rect2(margin, 37, viewport.x - 310, 36), 30, PAPER)
	text(g, "%d PONTOS    /    %d CARTAS NO DECK" % [g.score, g._deck_total_cards()], Rect2(margin, 80, 540, 24), 17, GOLD)
	if g.shop_spend_anim_timer > 0.0 and g.shop_spend_anim_amount > 0:
		var spend_progress: float = 1.0 - clampf(g.shop_spend_anim_timer / maxf(0.01, g.SHOP_SPEND_ANIM_TIME), 0.0, 1.0)
		var rise: float = sin(spend_progress * PI) * 16.0
		var alpha: float = 1.0 - smoothstep(0.62, 1.0, spend_progress)
		var spend_rect := Rect2(margin + 430.0, 67.0 - rise, 126.0, 28.0)
		g.draw_rect(spend_rect, Color(0.16, 0.035, 0.02, 0.78 * alpha), true)
		g.draw_line(spend_rect.position + Vector2(8.0, 2.0), spend_rect.position + Vector2(spend_rect.size.x - 8.0, 2.0), Color(1.0, 0.42, 0.16, 0.92 * alpha), 2.0)
		text(g, "-%d PTS" % int(g.shop_spend_anim_amount), spend_rect.grow(-5), 16, Color(1.0, 0.56, 0.22, alpha), true)
	button(g, areas.reroll, "RERROL %d" % g.shop_rerolls, CYAN, g.shop_rerolls > 0 and not busy() and not g._shop_purchase_animating())
	button(g, areas.deck, "MEU DECK", GOLD, g._deck_total_cards() > 0 and not busy() and not g._shop_purchase_animating())
	var team := "ESCOLHA UMA CARTA"
	if g.is_multiplayer:
		team = "EQUIPE  %d/%d PRONTOS    |    SUAS COMPRAS, SEU SALDO" % [g.shop_mp_ready_count, maxi(1, g.shop_mp_expected_count)]
	text(g, team, Rect2(margin, 114, viewport.x - margin * 2, 25), 15, MUTED)
	for i in range(mini(3, g.shop_cards.size())):
		var card: Dictionary = g.shop_cards[i]
		var rect: Rect2 = areas.cards[i]
		var selected: bool = i == g.shop_selected
		var t := clampf(elapsed / maxf(duration, 0.01), 0, 1)
		if action == "reroll" and not g._shop_slot_locked(i):
			var local_t := clampf((t - i * 0.09) / 0.8, 0, 1)
			if local_t < 0.5 and previous_cards.size() > i:
				card = previous_cards[i]
			var flip := maxf(0.035, absf(cos(local_t * PI)))
			rect = Rect2(rect.get_center() - Vector2(rect.size.x * flip, rect.size.y) * 0.5, Vector2(rect.size.x * flip, rect.size.y))
			rect.position.y -= sin(local_t * PI) * 20
		if action == "burn" and slot == i:
			card = previous_cards[i]
		rect.position.y += (1 - smoothstep(0, 1, entrance)) * (24 + i * 12)
		if selected:
			rect.position.y -= 8
			if g.shop_select_pulse_timer > 0:
				rect.position.y -= sin(clampf(1 - g.shop_select_pulse_timer / 0.26, 0, 1) * PI) * 5
		var price_rect: Rect2 = areas.cards[i]
		var purchase: bool = g._shop_purchase_animating() and g.shop_select_pulse_index == i
		if purchase:
			var p: float = 1 - g.shop_purchase_anim_timer / g.SHOP_PURCHASE_ANIM_TIME
			var flight := smoothstep(0.12, 0.88, p)
			var target: Vector2 = areas.deck.get_center()
			var center := rect.get_center().lerp(target, flight) + Vector2(0, -sin(flight * PI) * 65)
			rect.size *= lerpf(1.0, 0.14, flight)
			rect.position = center - rect.size * 0.5
		var accent: Color = g._card_rarity_color(card)
		frame(g, rect, accent if selected else MUTED.darkened(0.3), selected)
		var icon: Texture2D = g._card_texture(card)
		var art := rect.grow(-9)
		if icon:
			if action == "burn" and slot == i:
				_draw_burn(g, icon, art, t)
			elif not g._draw_cinzas_shader_card(card, art, icon, 1.0, true):
				g._draw_texture_contain(icon, art, Color.WHITE)
		if not purchase and not (action == "burn" and slot == i) and rect.size.x > 80:
			var caption := Rect2(rect.position + Vector2(9, rect.size.y * 0.64), Vector2(rect.size.x - 18, rect.size.y * 0.36 - 9))
			g.draw_rect(caption, Color(0.035, 0.045, 0.055, 0.97))
			g.draw_line(caption.position, Vector2(caption.end.x, caption.position.y), accent.darkened(0.2), 2)
			paragraph(g, String(card.get("name", "Vaga vazia")), Rect2(caption.position + Vector2(6, 4), Vector2(caption.size.x - 12, 36)), 16, true)
			text(g, g._card_rarity_label(card), Rect2(caption.position + Vector2(6, 40), Vector2(caption.size.x - 12, 22)), 13, accent, true)
		if g._shop_slot_locked(i):
			var lock_t := smoothstep(0, 1, t) if action == "lock" and slot == i else 1.0
			var strip := Rect2(rect.position.x + 8, rect.get_center().y - 17, rect.size.x - 16, 34)
			strip.position.x += (1 - lock_t) * 40
			g.draw_rect(strip, Color(0.025, 0.14, 0.17, 0.96))
			text(g, "RESERVADA", strip.grow(-4), 15, CYAN, true)
			g.draw_line(strip.position, Vector2(strip.end.x, strip.position.y), CYAN, 2)
		if not purchase:
			text(g, "VAZIA" if g._is_empty_shop_slot(card) else "%d PTS" % g._effective_card_price(card), Rect2(price_rect.position.x, price_rect.end.y + 12, price_rect.size.x, 26), 18, GOLD if selected else MUTED, true)
		g.buttons["shop_card_%d" % i] = areas.cards[i]
	if not g.shop_cards.is_empty():
		var card: Dictionary = g.shop_cards[g.shop_selected]
		if action == "burn" and slot == g.shop_selected:
			card = previous_cards[slot]
		var accent: Color = g._card_rarity_color(card)
		g.draw_line(detail.position + Vector2(-16, 12), Vector2(detail.position.x - 16, detail.end.y), MUTED.darkened(0.65), 1)
		text(g, "%s  /  NO DECK: %d" % [g._card_rarity_label(card), g._card_count(card)], Rect2(detail.position, Vector2(detail.size.x, 26)), 14, accent)
		text(g, String(card.get("name", "Vaga vazia")).to_upper(), Rect2(detail.position + Vector2(0, 32), Vector2(detail.size.x, 34)), 25, PAPER)
		if not compact:
			text(g, String(card.get("nick", "")), Rect2(detail.position + Vector2(0, 70), Vector2(detail.size.x, 24)), 16, CYAN)
		var copy := String(card.get("desc", ""))
		if card.has("cinzas_bonus_summary"):
			copy += "\n\n" + String(card.cinzas_bonus_summary)
		var projections: Array = [] if g._is_empty_shop_slot(card) or action == "burn" else g._card_projection_lines(card)
		if not projections.is_empty() and detail.size.y >= 320:
			copy += "\n\n" + "\n".join(projections)
		var copy_y := 78.0 if compact else 110.0
		paragraph(g, copy, Rect2(detail.position + Vector2(0, copy_y), Vector2(detail.size.x, maxf(48, detail.size.y - copy_y - 64))))
		var enabled: bool = not busy() and not g._shop_purchase_animating()
		button(g, areas.burn, "QUEIMAR", Color(1, 0.38, 0.17), enabled and g._can_burn_shop_card(card))
		button(g, areas.reserve, "SOLTAR" if g._shop_slot_locked(g.shop_selected) else "RESERVAR", CYAN, enabled and g._can_toggle_shop_reserve(g.shop_selected))
		g.buttons["shop_burn_%d" % g.shop_selected] = areas.burn
		g.buttons["shop_reserve_%d" % g.shop_selected] = areas.reserve
		var price: int = g._effective_card_price(card)
		var label := "COMPRAR  %d PTS" % price
		if g._is_empty_shop_slot(card):
			label = "VAGA VAZIA"
		if g._shop_purchase_animating():
			label = "INCORPORANDO AO DECK"
		elif busy():
			label = {"burn": "REDUZINDO A CINZAS", "reroll": "NOVAS POSSIBILIDADES", "lock": "RESERVA FIXADA", "unlock": "RESERVA LIBERADA"}.get(action, "AGUARDE")
		button(g, areas.buy, label, Color(0.38, 0.95, 0.57), enabled and g.score >= price and not g._is_empty_shop_slot(card))
	button(g, areas.exit, "PRONTO" if g.is_multiplayer else "VOLTAR AO CAMPO", CYAN, g._shop_can_exit())
	if g.is_multiplayer:
		text(g, "Retorno quando todos terminarem", Rect2(areas.exit.end + Vector2(18, -48), Vector2(detail.position.x - areas.exit.end.x - 30, 48)), 15, MUTED)
	for key in ["buy", "exit", "deck", "reroll"]:
		g.buttons["shop_" + key] = areas[key]


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
	var shop_rerolls: int = g.shop_rerolls
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
		var header_text = "Pontos %d  |  Custo %d  |  Rerolls %d" % [score, card_cost, shop_rerolls]
		if shop_endurance_discount > 0.0:
			header_text += "  |  Resistencia -%d%%" % int(round(shop_endurance_discount * 100.0))
		if purchase_animating:
			header_text = g._shop_purchase_stage(purchase_progress)
		g._draw_centered(header_text, Vector2(viewport.x * 0.5, 96), g._readable_text_size(16), Color(1.0, 0.85, 0.24))
		g._draw_shop_spend_anim(Vector2(viewport.x * 0.5, 132.0))
		g._draw_shop_tutorial_line(Rect2(header.position + Vector2(20.0, 90.0), Vector2(header.size.x - 40.0, 28.0)), true)
		g._draw_shop_round_button(g._shop_reroll_center(viewport), g._shop_round_button_radius(viewport), "REROLL", Color(0.0, 0.86, 1.0), shop_rerolls > 0 and not purchase_animating, "reroll")
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
			g.draw_rect(price_rect, Color(0.0, 0.0, 0.0, 0.52 * content_alpha), true)
			g.draw_rect(price_rect, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.7 * content_alpha), false, 1)
			var price_label: = "VAZIA" if g._is_empty_shop_slot(card) else "%d pts" % g._effective_card_price(card)
			g._draw_centered(price_label, price_rect.get_center() + Vector2(0, 4), g._readable_text_size(11), Color(1.0, 0.9, 0.35, content_alpha))
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


	var hud_text = "Pontos: %d  |  Custo: %d  |  Rerolls: %d" % [score, card_cost, shop_rerolls]
	if shop_endurance_discount > 0.0:
		hud_text += "  |  Resistencia -%d%%" % int(round(shop_endurance_discount * 100.0))
	g._draw_centered(hud_text, Vector2(viewport.x * 0.5, 73), g._readable_text_size(16), Color(1.0, 0.85, 0.24))
	g._draw_shop_spend_anim(Vector2(viewport.x * 0.5, 116.0))
	g._draw_shop_tutorial_line(Rect2(header.position + Vector2(22.0, 74.0), Vector2(header.size.x - 44.0, 22.0)), false)
	g._draw_shop_round_button(g._shop_reroll_center(viewport), g._shop_round_button_radius(viewport), "REROLL", Color(0.0, 0.86, 1.0), shop_rerolls > 0 and not purchase_animating, "reroll")
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
	# Quantized strips preserve the real card art while an uneven fire front climbs.
	var source_size := texture.get_size()
	var fitted := source_size * minf(rect.size.x / source_size.x, rect.size.y / source_size.y)
	var origin := rect.get_center() - fitted * 0.5
	for i in range(24):
		var width := fitted.x / 24
		var noise := sin(float(i) * 7.13) * 0.07
		var remaining := clampf(1.0 - progress * 1.2 + noise * sin(progress * PI), 0, 1)
		if remaining <= 0:
			continue
		var strip := Rect2(origin + Vector2(i * width, 0), Vector2(width + 0.5, fitted.y * remaining))
		g.draw_texture_rect_region(texture, strip, Rect2(source_size.x * i / 24, 0, source_size.x / 24, source_size.y * remaining))
		var ember := Vector2(strip.position.x, strip.end.y)
		g.draw_rect(Rect2(ember, Vector2(width, 4)), GOLD)
		g.draw_rect(Rect2(ember + Vector2(sin(i * 2.1 + progress * 8) * 12, -progress * 36), Vector2(3, 3)), Color(1, 0.32, 0.09, 1 - progress))


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
