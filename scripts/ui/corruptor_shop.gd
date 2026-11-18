class_name RTCorruptorShop
extends RefCounted

## Mercador Corrompido (chip Corruptor Mercantil).
## Abre na Fenda do Mercador quando ha fichas "?" pendentes. Para cada ficha o
## jogador escolhe QUALQUER carta daquela raridade num carrossel (deslizar,
## setas, A/D). Ordem: comuns, incomuns, raras e lendarias. Depois da ultima
## escolha a loja fecha sozinha. O carrossel volta na ultima carta escolhida
## daquela raridade. Reaproveita o visor da loja, sem pontos, trava ou queima.

const MODE := "corruptor_shop"
const SNAP_SPEED := 12.0
const DRAG_DEADZONE := 14.0

var core: Node = null
var rarity := ""
var pool: Array = []
var index := 0
var scroll := 0.0
var picks_done := 0
var picks_total := 0
var opened_at := 0.0
var flash := 0.0
var _last_ms := 0
var _press_pos := Vector2.INF
var _press_scroll := 0.0
var _dragging := false
var _spacing := 200.0
var _return_mode := "game"


func configure(runtime_core: Node) -> void:
	core = runtime_core


func chips() -> RTQuantumChipController:
	return core._quantum_chips()


func can_open() -> bool:
	return chips().corruptor_active() and chips().token_total() > 0


func open() -> bool:
	if not can_open():
		return false
	picks_done = 0
	picks_total = chips().token_total()
	opened_at = _now()
	_return_mode = "game"
	core.mode = MODE
	core._play_sfx("shop_countdown_tick", 0.0, 0.7, 0.62)
	if not _load_next_rarity():
		close()
		return false
	return true


func _now() -> float:
	return float(Time.get_ticks_msec()) * 0.001


func _load_next_rarity() -> bool:
	while true:
		rarity = chips().next_token_rarity()
		if rarity == "":
			return false
		pool = _pool_for(rarity)
		if not pool.is_empty():
			break
		# Raridade sem cartas disponiveis (tudo no maximo): devolve em pontos.
		chips().consume_token(rarity)
		picks_done += 1
		core._apply_score_delta(int(core._points_for_enemy({"points": 75})) * 4, true, "")
		core._add_text("SEM CARTAS %s: PONTOS" % rarity.to_upper(), core.player_pos + Vector2(-90, -110), Color(1.0, 0.86, 0.3), 1.2, 18)
	index = 0
	var last: String = String(chips().last_pick_id.get(rarity, ""))
	for i in range(pool.size()):
		if core._card_id(pool[i]) == last:
			index = i
			break
	scroll = float(index)
	flash = 1.0
	return true


func _pool_for(r: String) -> Array:
	var out: Array = []
	for value in core.CARDS:
		var card: Dictionary = value
		if core._card_rarity_key(card) != r:
			continue
		if not core._card_unlocked(card) or core._card_at_max(card):
			continue
		out.append(card)
	return out


func current_card() -> Dictionary:
	return Dictionary(pool[clampi(index, 0, pool.size() - 1)]) if not pool.is_empty() else {}


func step(direction: int) -> void:
	if pool.is_empty():
		return
	index = posmod(index + direction, pool.size())
	if absf(scroll - float(index)) > float(pool.size()) * 0.5:
		scroll = float(index) - float(direction)
	core._play_sfx("ui_manifest_switch", 0.01, 0.3, 1.2)


func pick() -> void:
	var card: Dictionary = current_card()
	if card.is_empty():
		return
	core._apply_card(card)
	chips().remember_pick(rarity, core._card_id(card))
	chips().consume_token(rarity)
	picks_done += 1
	core._spawn_radial_particles(core.player_pos, core._card_rarity_color(card), 20)
	core._add_text("CARTA: %s" % String(card.get("nick", card.get("name", ""))), core.player_pos + Vector2(-80, -88), core._card_rarity_color(card), 1.2, 20)
	core._play_sfx("shop_buy", 0.02, 0.6, 1.0)
	if not _load_next_rarity():
		close()


func close() -> void:
	pool.clear()
	rarity = ""
	if core.mode == MODE:
		core.mode = _return_mode
	core.shop_last_exit_time = core.time_alive
	if core.is_multiplayer and core._merchant_dimension().active:
		core._submit_quantum_tokens_redeemed(picks_done)
	else:
		core.shop_rift_controller.clear_active()


# ================================================================ input
func handle_input(event: InputEvent, viewport: Vector2) -> bool:
	if core.mode != MODE:
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				step(-1)
			KEY_RIGHT, KEY_D:
				step(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
				pick()
		return true
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			_press_pos = event.position
			_press_scroll = scroll
			_dragging = false
		else:
			var was_drag: bool = _dragging
			_dragging = false
			if was_drag:
				index = posmod(int(round(scroll)), maxi(1, pool.size()))
				scroll = clampf(scroll, -0.49, float(pool.size()) - 0.51)
			elif _press_pos != Vector2.INF:
				_tap(event.position)
			_press_pos = Vector2.INF
		return true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step(1)
		return true
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _press_pos == Vector2.INF:
			return true
		var dx: float = event.position.x - _press_pos.x
		if absf(dx) > DRAG_DEADZONE:
			_dragging = true
		if _dragging and not pool.is_empty():
			scroll = clampf(_press_scroll - dx / maxf(40.0, _spacing), -0.45, float(pool.size()) - 0.55)
		return true
	return true


func _tap(pos: Vector2) -> void:
	var b: Dictionary = core.buttons
	if b.has("corruptor_pick") and Rect2(b["corruptor_pick"]).has_point(pos):
		pick()
	elif b.has("corruptor_prev") and Rect2(b["corruptor_prev"]).has_point(pos):
		step(-1)
	elif b.has("corruptor_next") and Rect2(b["corruptor_next"]).has_point(pos):
		step(1)
	elif b.has("corruptor_left_card") and Rect2(b["corruptor_left_card"]).has_point(pos):
		step(-1)
	elif b.has("corruptor_right_card") and Rect2(b["corruptor_right_card"]).has_point(pos):
		step(1)


# ================================================================ desenho
func draw(g: Node2D, viewport: Vector2) -> void:
	# Carrega as artes das cartas do carrossel mais rapido que o ritmo normal.
	g.RuntimeAssetController.poll_registered_textures(g, 3, 4)
	var now_ms: int = Time.get_ticks_msec()
	var dt: float = clampf(float(now_ms - _last_ms) * 0.001, 0.0, 0.1) if _last_ms > 0 else 0.016
	_last_ms = now_ms
	if not _dragging:
		scroll = lerpf(scroll, float(index), clampf(dt * SNAP_SPEED, 0.0, 1.0))
	flash = maxf(0.0, flash - dt * 2.0)
	var sp = g.shop_presentation
	var now: float = _now()
	var open_k: float = clampf((now - opened_at) / 0.35, 0.0, 1.0)
	g.buttons.clear()
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.0, 0.04, 0.82), true)
	var small: bool = viewport.y < 560.0
	var visor := Rect2(viewport * 0.5 - Vector2(viewport.x * 0.46, viewport.y * 0.44) * Vector2(1.0, lerpf(0.2, 1.0, open_k)), Vector2(viewport.x * 0.92, viewport.y * 0.88 * lerpf(0.2, 1.0, open_k)))
	var header_h: float = 56.0 if not small else 44.0
	sp.draw_visor(g, visor, now, header_h)
	if open_k < 1.0:
		return
	var corrupt := Color(0.74, 0.4, 1.0)
	var card_now: Dictionary = current_card()
	var accent: Color = g._card_rarity_color(card_now) if not card_now.is_empty() else corrupt
	# Cabecalho: so o resgate. Sem pontos, sem reroll, sem trava/queima.
	sp.text(g, "MERCADOR CORROMPIDO", Rect2(visor.position + Vector2(22, 12), Vector2(visor.size.x * 0.5, 26)), 20 if not small else 16, corrupt)
	var rarity_label: String = g._card_rarity_label(card_now) if not card_now.is_empty() else rarity.to_upper()
	sp.text(g, "ESCOLHA %d DE %d  ·  %s" % [picks_done + 1, picks_total, rarity_label], Rect2(Vector2(visor.get_center().x, visor.position.y + 14), Vector2(visor.size.x * 0.5 - 24, 24)), 15 if not small else 13, accent)
	_draw_token_row(g, Rect2(visor.position + Vector2(22, header_h - 4 + (0 if small else 4)), Vector2(visor.size.x - 44, 18)), small)
	# Carrossel.
	var inner := Rect2(visor.position + Vector2(18, header_h + 18), visor.size - Vector2(36, header_h + 18 + (110 if not small else 84)))
	var card_h: float = minf(inner.size.y * 0.92, 360.0)
	var card_w: float = card_h * 0.72
	_spacing = card_w * 0.82
	var center := Vector2(inner.get_center().x, inner.position.y + card_h * 0.5 + 4.0)
	var order: Array = []
	for i in range(pool.size()):
		var d: float = float(i) - scroll
		if absf(d) <= 3.2:
			order.append([absf(d), i, d])
	order.sort_custom(func(a, b): return a[0] > b[0])
	for entry in order:
		var i: int = entry[1]
		var d: float = entry[2]
		var card: Dictionary = pool[i]
		var k: float = clampf(1.0 - absf(d) * 0.2, 0.4, 1.0)
		var alpha: float = clampf(1.15 - absf(d) * 0.35, 0.0, 1.0)
		var size := Vector2(card_w, card_h) * k
		var pos: Vector2 = center + Vector2(d * _spacing, (1.0 - k) * card_h * 0.18) - size * 0.5
		var rect := Rect2(pos, size)
		if rect.position.x < visor.position.x + 56.0 or rect.end.x > visor.end.x - 56.0:
			continue
		var col: Color = g._card_rarity_color(card)
		var focused: bool = absf(d) < 0.5
		sp.frame(g, rect, Color(col if focused else col.darkened(0.45), alpha), focused)
		g._request_card_drop_texture(card)
		var tex: Texture2D = g._card_texture(card) if g._card_drop_texture_loaded(card) else null
		var art := rect.grow(-8)
		if tex != null:
			g._draw_texture_contain(tex, art, Color(1, 1, 1, alpha))
		else:
			g.draw_rect(art, Color(col.r, col.g, col.b, 0.2 * alpha), true)
			sp.paragraph(g, CardCatalogDefinitions.display_name(card), art.grow(-10), 14, true)
		if focused and flash > 0.0:
			g.draw_rect(rect.grow(6.0 * flash), Color(col.r, col.g, col.b, 0.35 * flash), false, 3.0)
		if int(round(d)) == -1:
			g.buttons["corruptor_left_card"] = rect
		elif int(round(d)) == 1:
			g.buttons["corruptor_right_card"] = rect
	# Setas.
	var arrow_y: float = center.y
	var prev := Rect2(Vector2(inner.position.x, arrow_y - 30), Vector2(46, 60))
	var next := Rect2(Vector2(inner.end.x - 46, arrow_y - 30), Vector2(46, 60))
	for pair in [[prev, "<"], [next, ">"]]:
		sp.button(g, pair[0], pair[1], corrupt, pool.size() > 1)
	g.buttons["corruptor_prev"] = prev
	g.buttons["corruptor_next"] = next
	# Detalhe da carta central + botao escolher.
	var info := Rect2(Vector2(visor.position.x + 28, inner.end.y + 8), Vector2(visor.size.x - 56, (96 if not small else 72)))
	if not card_now.is_empty():
		var max_count: int = g._card_max_count(card_now)
		var deck_label: String = ("NO DECK: %d/%d" % [g._card_count(card_now), max_count]) if max_count < 100 else ("NO DECK: %d" % g._card_count(card_now))
		sp.text(g, "%s   ·   %s   ·   %d/%d" % [CardCatalogDefinitions.display_name(card_now).to_upper(), deck_label, index + 1, pool.size()], Rect2(info.position, Vector2(info.size.x * 0.68, 24)), 17 if not small else 14, accent)
		sp.paragraph(g, String(card_now.get("desc", "")), Rect2(info.position + Vector2(0, 26), Vector2(info.size.x * 0.68, info.size.y - 28)), 14 if not small else 12)
	var pick_rect := Rect2(Vector2(info.end.x - info.size.x * 0.28, info.position.y + 8), Vector2(info.size.x * 0.28, 52 if not small else 42))
	sp.button(g, pick_rect, "ESCOLHER", Color(0.38, 0.95, 0.57), not card_now.is_empty())
	g.buttons["corruptor_pick"] = pick_rect
	if not small:
		g._draw_centered("DESLIZE, USE AS SETAS OU A / D  ·  ENTER ESCOLHE", Vector2(visor.get_center().x, visor.end.y - 12), 11, Color(0.7, 0.6, 0.9, 0.8))


func _draw_token_row(g: Node2D, rect: Rect2, small: bool) -> void:
	var x: float = rect.position.x
	for r in RTQuantumChipController.RARITY_ORDER:
		var n: int = int(chips().tokens.get(r, 0))
		if n <= 0 and r != rarity:
			continue
		var sample: Dictionary = {}
		for value in core.CARDS:
			if core._card_rarity_key(value) == r:
				sample = value
				break
		var col: Color = g._card_rarity_color(sample) if not sample.is_empty() else Color.WHITE
		var label: String = "? x%d" % n
		var w: float = 64.0
		var chip := Rect2(Vector2(x, rect.position.y), Vector2(w, rect.size.y))
		g.draw_rect(chip, Color(col.r, col.g, col.b, 0.22 if r == rarity else 0.1), true)
		g.draw_rect(chip, Color(col.r, col.g, col.b, 0.9 if r == rarity else 0.5), false, 1.5)
		g._draw_centered(label, chip.get_center() + Vector2(0, 5), 12 if not small else 10, col)
		x += w + 8.0
