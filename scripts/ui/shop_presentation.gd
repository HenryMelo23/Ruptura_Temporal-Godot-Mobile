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
