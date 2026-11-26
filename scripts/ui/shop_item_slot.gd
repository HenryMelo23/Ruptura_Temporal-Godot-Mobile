extends RefCounted
## Uma vaga da vitrine da loja: item no pedestal (ou a carta antiga, sem
## arte), legenda com nome, objeto e numeros, queima e redoma de reserva.
## `view` e a apresentacao da loja (estado da animacao e helpers de texto).

const ItemShowcase := preload("res://scripts/presentation/item_showcase.gd")
const MUTED := Color(0.57, 0.69, 0.72)


static func draw(view, g, card: Dictionary, rect: Rect2, i: int, selected: bool, alpha: float, reveal: float, purchase: bool, t: float, now: float, small: bool) -> void:
	var accent: Color = g._card_rarity_color(card)
	var item: Texture2D = ItemShowcase.texture(card)
	var burning: bool = view.action == "burn" and view.slot == i
	var lock_anim: bool = (view.action == "lock" or view.action == "unlock") and view.slot == i
	if item == null:
		_draw_card_slot_legacy(view, g, card, rect, selected, alpha, reveal, burning, purchase, t, now)
	elif purchase:
		g._draw_texture_contain(item, rect, Color.WHITE)
	else:
		ItemShowcase.draw_slot_back(g, rect, accent, selected, maxf(alpha, 0.35), view.workshop, now)
		ItemShowcase.draw_pedestal(g, rect, accent, view.accent(), maxf(alpha, 0.35), view.workshop, now, selected)
		if burning:
			ItemShowcase.draw_burning(g, item, rect, t, now)
		elif reveal < 0.999:
			view.draw_art_reveal(g, item, ItemShowcase.display_rect(rect), reveal, accent)
		else:
			var stacks: int = clampi(int(card.get("cinzas_buff_stacks", 1)), 1, 10) if bool(card.get("cinzas_return_buff", false)) else 0
			if stacks > 0:
				ItemShowcase.draw_charred_base(g, rect, stacks, 1.0, now)
			var frozen: bool = g._shop_slot_locked(i) and not lock_anim
			ItemShowcase.draw_item(g, item, rect, ItemShowcase.rarity_tier(g, card), accent, 1.0, now, float(i) * 1.3, selected, frozen, stacks)
	if not purchase and not burning and rect.size.x > 80 and reveal > 0.6:
		var caption := Rect2(rect.position + Vector2(9, rect.size.y * 0.64), Vector2(rect.size.x - 18, rect.size.y * 0.36 - 9))
		g.draw_rect(caption, Color(0.03, 0.05, 0.06, 0.95))
		g.draw_line(caption.position, Vector2(caption.end.x, caption.position.y), accent.darkened(0.2), 2)
		view.paragraph(g, CardCatalogDefinitions.display_name(card) if card.has("name") else "Vaga vazia", Rect2(caption.position + Vector2(6, 4), Vector2(caption.size.x - 12, 36)), 16 if not small else 13, true)
		if item != null:
			_draw_item_caption(view, g, card, caption, accent, small)
			ItemShowcase.draw_rarity_pill(g, rect, g._card_rarity_label(card), accent, 1.0)
		else:
			view.text(g, g._card_rarity_label(card), Rect2(caption.position + Vector2(6, caption.size.y - 24), Vector2(caption.size.x - 12, 20)), 12, accent, true)
		if item != null and bool(card.get("cinzas_return_buff", false)):
			ItemShowcase.draw_charred_tag(g, rect, clampi(int(card.get("cinzas_buff_stacks", 1)), 1, 10), now)
		view.draw_bargain_banner(g, card, rect, 1.0)
	if g._shop_slot_locked(i) or lock_anim:
		if item != null and not purchase:
			ItemShowcase.draw_reserve_dome(g, rect, t if lock_anim else 1.0, view.action == "unlock" and view.slot == i, view.accent(), now, "RESERVADO")
		else:
			view.draw_lock_overlay(g, rect, t if lock_anim else 1.0, view.action == "unlock" and view.slot == i, now)


## Embaixo do nome: o objeto (ex.: "Tênis da Última Corrida") e os numeros.
static func _draw_item_caption(view, g, card: Dictionary, caption: Rect2, accent: Color, small: bool) -> void:
	# O nome ocupa 1 ou 2 linhas; embaixo vem o objeto e os numeros, se couber.
	var face: Font = g.menu_ui_font
	var name_size: int = 16 if not small else 13
	var name_lines: int = 1 if face.get_string_size(CardCatalogDefinitions.display_name(card), HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x <= caption.size.x - 12 else 2
	var y: float = caption.position.y + 6.0 + float(name_lines) * (name_size + 4.0)
	var room: float = caption.end.y - 6.0 - y
	var chips: Array = view.card_stat_chips(String(card.get("name", ""))).slice(0, 2)
	var chips_h: float = 24.0 if not chips.is_empty() else 0.0
	var object_name: String = ItemShowcase.item_name(card)
	if ItemShowcase.normalize(object_name) == ItemShowcase.normalize(CardCatalogDefinitions.display_name(card)):
		object_name = ""
	if object_name != "" and room >= 18.0 + chips_h:
		view.text(g, object_name, Rect2(caption.position.x + 6, y, caption.size.x - 12, 16), 12, Color(MUTED, 0.95), true)
		y += 20.0
		room -= 20.0
	if chips.is_empty() or room < 22.0:
		return
	var size: int = 11 if small else 12
	var total: float = 0.0
	for chip in chips:
		total += clampf(g.font.get_string_size(String(chip), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 22.0, 58.0, caption.size.x - 12) + 8.0
	var x: float = caption.get_center().x - maxf(0.0, total - 8.0) * 0.5
	view.draw_card_stat_chips(g, chips, Vector2(maxf(caption.position.x + 4.0, x), y + 2.0), caption.size.x - 8, accent, size)


## Vaga sem arte de item: moldura e arte antigas da carta.
static func _draw_card_slot_legacy(view, g, card: Dictionary, rect: Rect2, selected: bool, alpha: float, reveal: float, burning: bool, purchase: bool, t: float, now: float) -> void:
	var accent: Color = g._card_rarity_color(card)
	view.frame(g, rect, Color(accent if selected else MUTED.darkened(0.3), alpha), selected)
	var icon: Texture2D = g._card_texture(card)
	var art := rect.grow(-9)
	if icon == null:
		return
	if burning:
		view._draw_burn(g, icon, art, t)
	elif reveal < 0.999:
		view.draw_art_reveal(g, icon, art, reveal, accent)
	elif not g._draw_cinzas_shader_card(card, art, icon, 1.0, true):
		g._draw_texture_contain(icon, art, Color.WHITE)
	elif not purchase:
		view.draw_card_flames(g, rect, card, now)
