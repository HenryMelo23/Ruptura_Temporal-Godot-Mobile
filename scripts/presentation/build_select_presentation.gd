class_name RTBuildSelectPresentation
extends RefCounted

## Tela unica de escolha de build (solo). Geovana: Manifestacao -> Espectro (tema
## cientista). Henry: Mutacao -> Efeito (tema elegante). Mesmo layout, mesmas
## animacoes; so o tema muda. O chamador monta o `model` e cuida do input.
##
## model = {
##   theme: "geovana" | "henry", step: 0 | 1,
##   items: [{index, key, name, color, texture, unlocked, unread}] em ordem de slot,
##   selected_slot: int, target_scroll: float (slots, continuo durante arrasto),
##   dossier: Dictionary (RTBuildChoiceDossier), locked_text: String,
##   summary: String, primary_label, primary_enabled, preview_enabled, hint,
##   keys: {primary, back, preview, pick_prefix, prev, next}
## }

const THEMES := {
	"geovana": {
		"title": "LABORATÓRIO DA RUPTURA",
		"subtitle": "GEOVANA // REGISTRO DE CAMPO",
		"steps": ["MANIFESTAÇÃO", "ESPECTRO"],
		"bank": ["BANCO DE MANIFESTAÇÕES", "BANCO DE ESPECTROS"],
		"bank_hint": ["A FORMA COMO A RUPTURA AGE EM GEOVANA", "O ESTADO ESPECTRAL QUE ACOMPANHA A FORMA"],
		"dossier": ["RELATÓRIO // MANIFESTAÇÃO", "RELATÓRIO // ESPECTRO"],
		"ink": Color(0.88, 0.97, 1.0),
		"frame": Color(0.18, 0.86, 1.0),
		"paper": Color(0.008, 0.03, 0.045),
		"muted": Color(0.55, 0.74, 0.82),
		"bg_accent": Color(0.0, 1.0, 0.82),
	},
	"henry": {
		"title": "PROTOCOLO HENRY",
		"subtitle": "D37 // CONFIGURAÇÃO BIOMECÂNICA DE CAMPO",
		"steps": ["MUTAÇÃO", "EFEITO"],
		"bank": ["BANCO DE MUTAÇÕES", "BANCO DE EFEITOS"],
		"bank_hint": ["A ASSINATURA QUE HENRY LEVA PARA A RUPTURA", "O EFEITO QUE ACOMPANHA A MUTAÇÃO"],
		"dossier": ["DOSSIÊ // MUTAÇÃO", "DOSSIÊ // EFEITO"],
		"ink": Color(0.95, 0.9, 0.76),
		"frame": Color(0.86, 0.66, 0.3),
		"paper": Color(0.02, 0.016, 0.01),
		"muted": Color(0.72, 0.7, 0.62),
		"bg_accent": Color(1.0, 0.42, 0.08),
	},
}

const SCROLL_RATE := 16.0
const STEP_ANIM := 0.42
const CHOICE_ANIM := 0.26
const OPEN_ANIM := 0.38
const ROW_STAGGER := 0.045

static var _state: Dictionary = {}
## Escala do retrato: o jogo estica a largura para 1280, entao desenhamos num
## viewport virtual de ~720 de largura e escalamos (inclusive os botoes).
static var _k: float = 1.0


static func _set_button(game: Node2D, key: String, rect: Rect2) -> void:
	game.buttons[key] = Rect2(rect.position * _k, rect.size * _k)


static func draw(game: Node2D, viewport: Vector2, model: Dictionary) -> void:
	var theme: Dictionary = THEMES.get(String(model.get("theme", "geovana")), THEMES["geovana"])
	var st := _frame_state(game, model)
	var items: Array = model.get("items", [])
	var selected_slot: int = clampi(int(model.get("selected_slot", 0)), 0, maxi(0, items.size() - 1))
	var item: Dictionary = items[selected_slot] if not items.is_empty() else {}
	var accent: Color = item.get("color", theme["frame"]) if bool(item.get("unlocked", true)) else Color(0.46, 0.5, 0.66)
	game._draw_holo_background(viewport, null, theme["bg_accent"])
	_k = maxf(1.0, viewport.x / 720.0) if viewport.y > viewport.x else 1.0
	if _k > 1.0:
		viewport /= _k
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_k, _k))
	var portrait: bool = viewport.y > viewport.x
	var compact: bool = viewport.x < 1100.0 or viewport.y < 650.0
	var now: float = float(st["now"])
	var open_p: float = _ease(clampf((now - float(st["open_at"])) / OPEN_ANIM, 0.0, 1.0))
	var step_p: float = _ease(clampf((now - float(st["step_at"])) / STEP_ANIM, 0.0, 1.0))
	var choice_age: float = now - float(st["choice_at"])
	_clear_pick_buttons(game, model)
	_draw_theme_marks(game, viewport, theme, String(model.get("theme", "")), accent, now)
	var header_h: float = 124.0 if portrait else (78.0 if compact else 92.0)
	_draw_header(game, viewport, theme, model, accent, compact, portrait, step_p, header_h)

	var margin: float = 16.0 if portrait else (24.0 if compact else 36.0)
	var footer_h: float = 64.0 if portrait else (58.0 if compact else 66.0)
	var gap: float = 12.0 if (portrait or compact) else 20.0
	var top: float = header_h + 6.0
	var bottom: float = viewport.y - footer_h
	var bank_rect: Rect2
	var dossier_rect: Rect2
	if portrait:
		var bank_h: float = clampf((bottom - top) * 0.36, 250.0, 340.0)
		bank_rect = Rect2(margin, top, viewport.x - margin * 2.0, bank_h)
		dossier_rect = Rect2(margin, bank_rect.end.y + gap, viewport.x - margin * 2.0, bottom - bank_rect.end.y - gap * 2.0)
	else:
		var avail: float = viewport.x - margin * 2.0 - gap
		var bank_w: float = avail * 0.5
		bank_rect = Rect2(margin, top, bank_w, bottom - top - 8.0)
		dossier_rect = Rect2(bank_rect.end.x + gap, top, avail - bank_w, bank_rect.size.y)
	# Entrada: paineis deslizam e aparecem.
	var slide: float = (1.0 - open_p) * 26.0 + (1.0 - step_p) * 18.0
	_draw_bank(game, Rect2(bank_rect.position - Vector2(slide, 0.0), bank_rect.size), theme, model, items, selected_slot, accent, compact, now, choice_age, st)
	_draw_dossier(game, Rect2(dossier_rect.position + Vector2(slide, 0.0), dossier_rect.size), theme, model, item, accent, compact, choice_age)
	var fade: float = maxf(1.0 - open_p, (1.0 - step_p) * 0.85)
	if fade > 0.01:
		game.draw_rect(Rect2(bank_rect.position - Vector2(slide, 0.0), bank_rect.size).grow(2.0), Color(theme["paper"], fade), true)
		game.draw_rect(Rect2(dossier_rect.position + Vector2(slide, 0.0), dossier_rect.size).grow(2.0), Color(theme["paper"], fade), true)
	_draw_footer(game, viewport, theme, model, accent, compact, portrait, margin, footer_h)
	if step_p < 1.0:
		_draw_step_wipe(game, viewport, accent, step_p)
	if _k > 1.0:
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- estado por jogo (scroll suave, tempos de troca) ---------------------------

static func _frame_state(game: Node2D, model: Dictionary) -> Dictionary:
	var id: int = game.get_instance_id()
	var now: float = float(Time.get_ticks_msec()) * 0.001
	var items: Array = model.get("items", [])
	var count: int = maxi(1, items.size())
	var step_key: String = "%s:%d" % [String(model.get("theme", "")), int(model.get("step", 0))]
	var st: Dictionary = _state.get(id, {})
	var fresh: bool = st.is_empty() or now - float(st.get("now", 0.0)) > 0.75
	if fresh:
		st = {"now": now, "open_at": now, "step_at": now - STEP_ANIM, "choice_at": now - CHOICE_ANIM, "step_key": step_key, "choice": -1, "scroll": float(model.get("target_scroll", 0.0))}
	var dt: float = clampf(now - float(st["now"]), 0.0, 0.1)
	st["now"] = now
	if String(st["step_key"]) != step_key:
		st["step_key"] = step_key
		st["step_at"] = now
		st["scroll"] = float(model.get("target_scroll", 0.0))
	var choice: int = int(model.get("selected_slot", 0))
	if int(st["choice"]) != choice:
		if int(st["choice"]) >= 0:
			st["choice_at"] = now
		st["choice"] = choice
	var target: float = float(model.get("target_scroll", 0.0))
	var current: float = float(st["scroll"])
	var diff: float = _wrap_diff(target - current, count)
	current += diff * (1.0 - exp(-SCROLL_RATE * dt))
	if absf(_wrap_diff(target - current, count)) < 0.002:
		current = target
	st["scroll"] = fposmod(current, float(count))
	_state[id] = st
	return st


static func _wrap_diff(value: float, count: int) -> float:
	var n: float = float(maxi(1, count))
	var half: float = n * 0.5
	var d: float = fposmod(value + half, n) - half
	return d


static func _ease(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


static func _clear_pick_buttons(game: Node2D, model: Dictionary) -> void:
	var keys: Dictionary = model.get("keys", {})
	var prefix: String = String(keys.get("pick_prefix", "build_pick_"))
	for key in game.buttons.keys():
		if String(key).begins_with(prefix):
			game.buttons.erase(key)
	for k in ["prev", "next", "preview", "primary", "back"]:
		if keys.has(k):
			game.buttons.erase(String(keys[k]))


# --- cabecalho ---------------------------------------------------------------

static func _draw_header(game: Node2D, viewport: Vector2, theme: Dictionary, model: Dictionary, accent: Color, compact: bool, portrait: bool, step_p: float, header_h: float) -> void:
	var title_x: float = viewport.x * 0.5 if portrait else viewport.x * 0.27
	var title_y: float = 34.0 if portrait else header_h * 0.5 - 2.0
	game._draw_glitch_title(String(theme["title"]), Vector2(title_x, title_y), 22 if (compact or portrait) else 28, theme["ink"])
	game._draw_centered(String(theme["subtitle"]), Vector2(title_x, title_y + 26.0), 9 if compact else 11, Color(theme["muted"], 0.92))
	var w: float = minf(viewport.x - 32.0, 300.0 if compact else 352.0)
	var h: float = 34.0 if compact else 40.0
	var rect := Rect2(viewport.x * 0.5 - w * 0.5, title_y + 40.0, w, h) if portrait else Rect2(viewport.x - w - (24.0 if compact else 36.0), header_h * 0.5 - h * 0.5, w, h)
	var step: int = int(model.get("step", 0))
	var half: float = rect.size.x * 0.5
	game.draw_rect(rect, Color(theme["paper"], 0.92), true)
	game.draw_rect(rect, Color(theme["frame"], 0.45), false, 1.2)
	# O destaque desliza entre as etapas.
	var from_x: float = 0.0 if step == 1 else half
	var to_x: float = 0.0 if step == 0 else half
	var x: float = lerpf(from_x, to_x, step_p)
	var active := Rect2(rect.position + Vector2(x + 2.0, 2.0), Vector2(half - 4.0, rect.size.y - 4.0))
	game.draw_rect(active, Color(accent, 0.2), true)
	game.draw_rect(active, Color(accent, 0.92), false, 2.0)
	var steps: Array = theme["steps"]
	for i in range(2):
		var on: bool = i == step
		var label := "%02d  %s" % [i + 1, String(steps[i])]
		game._draw_centered(label, Vector2(rect.position.x + half * (0.5 + float(i)), rect.get_center().y + 4.0), 10 if compact else 12, accent if on else Color(theme["muted"], 0.6))


# --- banco (carrossel) ---------------------------------------------------------

static func _draw_bank(game: Node2D, rect: Rect2, theme: Dictionary, model: Dictionary, items: Array, selected_slot: int, accent: Color, compact: bool, now: float, choice_age: float, st: Dictionary) -> void:
	var henry: bool = String(model.get("theme", "")) == "henry"
	var step: int = int(model.get("step", 0))
	_draw_frame(game, rect, theme, henry, Color(theme["frame"], 0.6), 0.5)
	game.draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), Color(accent, 0.75), true)
	var pad: float = 16.0 if compact else 20.0
	game.draw_string(game.font, rect.position + Vector2(pad, 26.0), String(theme["bank"][step]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 12 if compact else 15, theme["ink"])
	game.draw_string(game.font, rect.position + Vector2(pad, 44.0), String(theme["bank_hint"][step]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, 8 if compact else 10, Color(theme["muted"], 0.86))
	var summary: String = String(model.get("summary", ""))
	if summary != "":
		var chip_w: float = minf(rect.size.x * 0.46, game.font.get_string_size(summary, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 22.0)
		var chip := Rect2(rect.end.x - chip_w - pad, rect.position.y + 12.0, chip_w, 22.0)
		game.draw_rect(chip, Color(theme["paper"], 0.9), true)
		game.draw_rect(chip, Color(theme["frame"], 0.5), false, 1.0)
		game._draw_centered(summary, chip.get_center() + Vector2(0, 4.0), 9 if compact else 10, theme["ink"])

	var count: int = items.size()
	if count == 0:
		return
	var info_h: float = 74.0 if compact else 86.0
	var area := Rect2(rect.position + Vector2(pad, 56.0), Vector2(rect.size.x - pad * 2.0, rect.size.y - 56.0 - info_h - 26.0))
	var card_h: float = minf(area.size.y - 8.0, 236.0)
	var card_w: float = minf(card_h * 0.76, area.size.x * 0.36)
	var spacing: float = card_w * 1.04 if count <= 3 else float(game._manifest_carousel_spacing(game.get_viewport_rect().size)) / _k
	var center: Vector2 = area.get_center()
	var scroll: float = float(st["scroll"])
	var order: Array = []
	for slot in range(count):
		var d: float = _wrap_diff(float(slot) - scroll, count)
		if absf(d) <= 2.3:
			order.append([absf(d), slot, d])
	order.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	var keys: Dictionary = model.get("keys", {})
	var prefix: String = String(keys.get("pick_prefix", "build_pick_"))
	for entry in order:
		var dist: float = float(entry[0])
		var slot: int = int(entry[1])
		var d: float = float(entry[2])
		var card_item: Dictionary = items[slot]
		var scale: float = lerpf(1.0, 0.74, clampf(dist, 0.0, 1.0)) if dist <= 1.0 else lerpf(0.74, 0.6, clampf(dist - 1.0, 0.0, 1.0))
		var alpha: float = lerpf(1.0, 0.52, clampf(dist, 0.0, 1.0)) if dist <= 1.0 else lerpf(0.52, 0.0, clampf(dist - 1.0, 0.0, 1.3))
		if alpha <= 0.02:
			continue
		var size := Vector2(card_w, card_h) * scale
		var c := center + Vector2(d * spacing, (1.0 - scale) * 18.0)
		var card := Rect2(c - size * 0.5, size)
		if card.position.x < rect.position.x + 6.0 or card.end.x > rect.end.x - 6.0:
			alpha *= 0.55
		_set_button(game, prefix + str(int(card_item.get("index", slot))), card.grow(4.0))
		_draw_card(game, card, theme, henry, card_item, slot == selected_slot and dist < 0.5, alpha, now, choice_age)

	# Contador e setas (so quando ha mais do que cabe).
	var counter_y: float = area.end.y + 12.0
	if count > 3:
		var bar_w: float = minf(area.size.x * 0.5, 220.0)
		var bar := Rect2(center.x - bar_w * 0.5, counter_y, bar_w, 4.0)
		game.draw_rect(bar, Color(theme["muted"], 0.2), true)
		var seg: float = bar_w / float(count)
		game.draw_rect(Rect2(bar.position.x + seg * scroll, bar.position.y, seg, 4.0), Color(accent, 0.95), true)
		game._draw_centered("%02d / %02d" % [selected_slot + 1, count], Vector2(center.x, counter_y + 20.0), 10, Color(theme["muted"], 0.9))
		var arrow_w: float = 40.0
		var prev_rect := Rect2(area.position.x - 4.0, center.y - 30.0, arrow_w, 60.0)
		var next_rect := Rect2(area.end.x - arrow_w + 4.0, center.y - 30.0, arrow_w, 60.0)
		if keys.has("prev"):
			_set_button(game, String(keys["prev"]), prev_rect)
			_set_button(game, String(keys["next"]), next_rect)
		for pair in [[prev_rect, -1.0], [next_rect, 1.0]]:
			var r: Rect2 = pair[0]
			var dir: float = float(pair[1])
			game.draw_rect(r, Color(theme["paper"], 0.78), true)
			game.draw_rect(r, Color(accent, 0.55), false, 1.2)
			var tip: Vector2 = r.get_center() + Vector2(dir * 7.0, 0.0)
			game.draw_polyline(PackedVector2Array([tip - Vector2(dir * 12.0, -12.0), tip, tip - Vector2(dir * 12.0, 12.0)]), accent, 3.0, true)
	else:
		for slot in range(count):
			var dot := Vector2(center.x + (float(slot) - float(count - 1) * 0.5) * 16.0, counter_y + 6.0)
			game.draw_circle(dot, 5.0 if slot == selected_slot else 3.0, accent if slot == selected_slot else Color(theme["muted"], 0.35))

	# Nome e leitura rapida do selecionado.
	var item: Dictionary = items[selected_slot]
	var info := Rect2(rect.position.x + pad, rect.end.y - info_h - 6.0, rect.size.x - pad * 2.0, info_h)
	var reveal: float = _ease(clampf(choice_age / CHOICE_ANIM, 0.0, 1.0))
	var unlocked: bool = bool(item.get("unlocked", true))
	var name: String = String(item.get("name", "")).to_upper() if unlocked else "???"
	game._draw_centered(name, Vector2(info.get_center().x, info.position.y + 24.0 + (1.0 - reveal) * 8.0), 20 if compact else 24, Color(accent, reveal))
	var dossier: Dictionary = model.get("dossier", {})
	var style: String = String(dossier.get("style", "")) if unlocked else "REGISTRO BLOQUEADO"
	if style != "":
		game._draw_centered(style.to_upper(), Vector2(info.get_center().x, info.position.y + 46.0), 9 if compact else 11, Color(theme["muted"], reveal * 0.95))
	var difficulty: int = int(dossier.get("difficulty", 0)) if unlocked else 0
	if difficulty > 0:
		for i in range(3):
			var p := Vector2(info.get_center().x + (float(i) - 1.0) * 18.0, info.position.y + 62.0)
			var on: bool = i < difficulty
			_draw_diamond(game, p, 5.5, Color(accent, reveal) if on else Color(theme["muted"], 0.3 * reveal), on)


static func _draw_card(game: Node2D, card: Rect2, theme: Dictionary, henry: bool, item: Dictionary, selected: bool, alpha: float, now: float, choice_age: float) -> void:
	var color: Color = item.get("color", theme["frame"])
	var unlocked: bool = bool(item.get("unlocked", true))
	if not unlocked:
		color = Color(0.46, 0.5, 0.66)
	game.draw_rect(card, Color(theme["paper"], 0.94 * alpha), true)
	if selected:
		var pulse: float = 0.5 + sin(now * 4.6) * 0.5
		game.draw_rect(card.grow(5.0 + pulse * 2.0), Color(color, (0.16 + pulse * 0.12) * alpha), false, 1.6)
		game.draw_rect(Rect2(card.position, Vector2(card.size.x, card.size.y * 0.55)), Color(color, 0.06 * alpha), true)
	_draw_frame(game, card, theme, henry, Color(color, (0.95 if selected else 0.4) * alpha), 0.0, 2.6 if selected else 1.2)
	var icon_rect := Rect2(card.position + Vector2(card.size.x * 0.14, card.size.y * 0.1), Vector2(card.size.x * 0.72, card.size.y * 0.56))
	var tex: Texture2D = item.get("texture", null)
	if not unlocked:
		game._draw_catalog_locked_card_icon(icon_rect.grow(-6.0), false)
	elif tex != null:
		game._draw_texture_contain(tex, icon_rect, Color(1, 1, 1, alpha))
	var name: String = String(item.get("name", "")).to_upper() if unlocked else "???"
	game._draw_centered(name, Vector2(card.get_center().x, card.end.y - card.size.y * 0.16), 14 if selected else 11, Color(theme["ink"], alpha))
	game._draw_centered("SELECIONADO" if selected else ("BLOQUEADO" if not unlocked else "DISPONÍVEL"), Vector2(card.get_center().x, card.end.y - 10.0), 8, Color(color, alpha * 0.9))
	if selected and choice_age < CHOICE_ANIM:
		var scan_y: float = card.position.y + card.size.y * (choice_age / CHOICE_ANIM)
		game.draw_line(Vector2(card.position.x + 6.0, scan_y), Vector2(card.end.x - 6.0, scan_y), Color(color, 0.9), 2.0)
	if bool(item.get("unread", false)) and unlocked:
		var badge := Rect2(card.end - Vector2(40.0, card.size.y - 6.0), Vector2(34.0, 16.0))
		game.draw_rect(badge, Color(0.48, 0.02, 0.07, 0.96 * alpha), true)
		game._draw_centered("NOVO", badge.get_center() + Vector2(0, 4.0), 8, Color(1, 1, 1, alpha))


# --- dossie ---------------------------------------------------------------------

static func _draw_dossier(game: Node2D, rect: Rect2, theme: Dictionary, model: Dictionary, item: Dictionary, accent: Color, compact: bool, choice_age: float) -> void:
	var henry: bool = String(model.get("theme", "")) == "henry"
	var step: int = int(model.get("step", 0))
	_draw_frame(game, rect, theme, henry, Color(accent, 0.85), 0.62)
	game.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), Color(accent, 0.85), true)
	var pad: float = 16.0 if compact else 22.0
	var width: float = rect.size.x - pad * 2.0
	var reveal: float = _ease(clampf(choice_age / CHOICE_ANIM, 0.0, 1.0))
	var shift: float = (1.0 - reveal) * 14.0
	var x: float = rect.position.x + pad + shift
	var y: float = rect.position.y + 24.0
	game.draw_string(game.font, Vector2(x, y), String(theme["dossier"][step]), HORIZONTAL_ALIGNMENT_LEFT, width, 9 if compact else 11, Color(accent, 0.9 * reveal))
	var unlocked: bool = bool(item.get("unlocked", true))
	y += 30.0 if compact else 36.0
	game.draw_string(game.font, Vector2(x, y), String(item.get("name", "")).to_upper() if unlocked else "REGISTRO BLOQUEADO", HORIZONTAL_ALIGNMENT_LEFT, width, 20 if compact else 25, Color(theme["ink"], reveal))
	var preview_h: float = 0.0 if not model.has("preview_enabled") else (40.0 if compact else 46.0)
	var bottom: float = rect.end.y - pad - (preview_h + 8.0 if preview_h > 0.0 else 0.0)
	if not unlocked:
		var lock_rect := Rect2(Vector2(rect.position.x + pad, y + 18.0), Vector2(minf(130.0, width * 0.3), minf(130.0, width * 0.3)))
		game._draw_catalog_locked_card_icon(lock_rect, true)
		var text := "COMO LIBERAR\n" + String(model.get("locked_text", ""))
		_draw_text_block(game, text, Vector2(lock_rect.end.x + 16.0, y + 30.0), rect.end.x - pad - lock_rect.end.x - 16.0, game._readable_text_size(12), Color(theme["ink"], 0.92 * reveal))
	else:
		var dossier: Dictionary = model.get("dossier", {})
		var tagline: String = String(dossier.get("tagline", ""))
		y += 10.0
		if tagline != "":
			y = _draw_text_block(game, tagline, Vector2(x, y), width, game._readable_text_size(12 if compact else 13), Color(theme["ink"], 0.9 * reveal)) + 6.0
		game.draw_line(Vector2(rect.position.x + pad, y), Vector2(rect.end.x - pad, y), Color(accent, 0.28), 1.0)
		y += 10.0
		var rows: Array = dossier.get("rows", [])
		var note: String = String(dossier.get("note", ""))
		var font_size: int = _fit_rows(game, rows, note, width, bottom - y, game._readable_text_size(11 if compact else 12))
		for i in range(rows.size()):
			var row_age: float = choice_age - float(i) * ROW_STAGGER
			var row_p: float = _ease(clampf(row_age / CHOICE_ANIM, 0.0, 1.0))
			y = _draw_row(game, rows[i], Vector2(rect.position.x + pad + (1.0 - row_p) * 18.0, y), width, font_size, accent, theme, row_p)
		if note != "":
			_draw_text_block(game, note, Vector2(rect.position.x + pad, y + 2.0), width, maxi(8, font_size - 1), Color(theme["muted"], 0.86 * reveal))
	if preview_h > 0.0:
		_draw_preview_slot(game, Rect2(rect.position.x + pad, rect.end.y - pad - preview_h, width, preview_h), theme, model, accent, compact)


static func _row_height(game: Node2D, row: Dictionary, width: float, font_size: int) -> float:
	var text_h: float = game.font.get_multiline_string_size(String(row.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, width - 10.0, font_size).y
	return float(font_size) + 10.0 + text_h + 9.0


static func _fit_rows(game: Node2D, rows: Array, note: String, width: float, available: float, start_size: int) -> int:
	var size: int = start_size
	while size > 8:
		var total: float = 0.0
		for row in rows:
			total += _row_height(game, row, width, size)
		if note != "":
			total += game.font.get_multiline_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, width, size - 1).y + 4.0
		if total <= available:
			return size
		size -= 1
	return 8


static func _draw_row(game: Node2D, row: Dictionary, pos: Vector2, width: float, font_size: int, accent: Color, theme: Dictionary, alpha: float) -> float:
	var label: String = String(row.get("label", ""))
	var title: String = String(row.get("title", ""))
	var chip_w: float = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x + 14.0
	var chip := Rect2(pos, Vector2(chip_w, float(font_size) + 7.0))
	game.draw_rect(chip, Color(accent, 0.2 * alpha), true)
	game.draw_rect(chip, Color(accent, 0.75 * alpha), false, 1.0)
	game.draw_string(game.font, chip.position + Vector2(7.0, float(font_size) + 1.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color(accent, alpha))
	game.draw_string(game.font, Vector2(chip.end.x + 8.0, chip.position.y + float(font_size) + 1.0), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, width - chip_w - 8.0, font_size, Color(theme["ink"], alpha))
	var y: float = chip.end.y + 4.0
	game.draw_rect(Rect2(pos.x, y, 2.0, 1.0), Color(accent, 0.0), true)
	var end_y: float = _draw_text_block(game, String(row.get("text", "")), Vector2(pos.x + 10.0, y), width - 10.0, font_size, Color(theme["ink"].lerp(theme["muted"], 0.35), 0.95 * alpha))
	game.draw_line(Vector2(pos.x + 3.0, y), Vector2(pos.x + 3.0, end_y - 2.0), Color(accent, 0.45 * alpha), 2.0)
	return end_y + 9.0


static func _draw_text_block(game: Node2D, text: String, pos: Vector2, width: float, font_size: int, color: Color) -> float:
	if text == "" or width <= 8.0:
		return pos.y
	var size: Vector2 = game.font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
	game.draw_multiline_string(game.font, pos + Vector2(0.0, game.font.get_ascent(font_size)), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, -1, color)
	return pos.y + size.y


static func _draw_preview_slot(game: Node2D, rect: Rect2, theme: Dictionary, model: Dictionary, accent: Color, compact: bool) -> void:
	var enabled: bool = bool(model.get("preview_enabled", false))
	game.draw_rect(rect, Color(theme["paper"], 0.9), true)
	game.draw_rect(rect, Color(accent, 0.55 if enabled else 0.22), false, 1.2)
	var corner: float = 10.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var p := Vector2(rect.get_center().x + sx * (rect.size.x * 0.5 - 5.0), rect.get_center().y + sy * (rect.size.y * 0.5 - 5.0))
			game.draw_line(p, p - Vector2(sx * corner, 0.0), Color(accent, 0.5), 1.4)
			game.draw_line(p, p - Vector2(0.0, sy * corner), Color(accent, 0.5), 1.4)
	if enabled:
		var keys: Dictionary = model.get("keys", {})
		if keys.has("preview"):
			_set_button(game, String(keys["preview"]), rect)
		var tri: Vector2 = rect.get_center() + Vector2(-58.0, 0.0)
		game.draw_colored_polygon(PackedVector2Array([tri + Vector2(-5, -7), tri + Vector2(7, 0), tri + Vector2(-5, 7)]), accent)
		game._draw_centered("VER PREVIEW", rect.get_center() + Vector2(8.0, 5.0), 11 if compact else 13, accent)
	else:
		game._draw_centered("PREVIEW // EM BREVE", rect.get_center() + Vector2(0.0, 4.0), 9 if compact else 11, Color(accent, 0.6))


# --- rodape ----------------------------------------------------------------------

static func _draw_footer(game: Node2D, viewport: Vector2, theme: Dictionary, model: Dictionary, accent: Color, compact: bool, portrait: bool, margin: float, footer_h: float) -> void:
	var h: float = 46.0 if portrait else (40.0 if compact else 44.0)
	var y: float = viewport.y - footer_h * 0.5 - h * 0.5
	var primary_w: float = (viewport.x - margin * 2.0) * 0.56 if portrait else (200.0 if compact else 230.0)
	var back_w: float = (viewport.x - margin * 2.0) * 0.4 if portrait else (150.0 if compact else 170.0)
	var back := Rect2(margin, y, back_w, h)
	var primary := Rect2(viewport.x - margin - primary_w, y, primary_w, h)
	var keys: Dictionary = model.get("keys", {})
	var henry: bool = String(model.get("theme", "")) == "henry"
	_set_button(game, String(keys.get("back", "build_back")), back)
	_set_button(game, String(keys.get("primary", "build_primary")), primary)
	var enabled: bool = bool(model.get("primary_enabled", true))
	_draw_button(game, back, "VOLTAR", false, Color(theme["muted"], 1.0), theme, henry)
	_draw_button(game, primary, String(model.get("primary_label", "CONTINUAR")), true, accent if enabled else Color(0.46, 0.5, 0.6), theme, henry)
	if not portrait:
		game._draw_centered(String(model.get("hint", "")), Vector2(viewport.x * 0.5, y + h * 0.5 + 4.0), 9 if compact else 11, Color(theme["muted"], 0.8))


static func _draw_button(game: Node2D, rect: Rect2, label: String, primary: bool, color: Color, theme: Dictionary, henry: bool) -> void:
	game.draw_rect(rect, Color(color, 0.22 if primary else 0.07), true)
	game.draw_rect(rect, Color(color, 0.92), false, 2.0)
	if henry:
		game.draw_rect(rect.grow(-4.0), Color(color, 0.32), false, 1.0)
	else:
		game.draw_line(rect.position + Vector2(0, rect.size.y), rect.position + Vector2(14.0, rect.size.y), Color(color, 1.0), 3.0)
	game._draw_centered(label, rect.get_center() + Vector2(0.0, 5.0), 15 if label.length() < 14 else 13, theme["ink"])


# --- molduras e marcas de tema -------------------------------------------------

static func _draw_frame(game: Node2D, rect: Rect2, theme: Dictionary, henry: bool, color: Color, fill_alpha: float, width: float = 1.4) -> void:
	if fill_alpha > 0.0:
		game.draw_rect(rect, Color(theme["paper"], fill_alpha), true)
	game.draw_rect(rect, color, false, width)
	if henry:
		# Art deco: filete interno e losangos nos cantos.
		game.draw_rect(rect.grow(-5.0), Color(color, color.a * 0.35), false, 1.0)
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
			_draw_diamond(game, corner, 4.0, color, true)
	else:
		# Laboratorio: colchetes de medicao nos cantos.
		var arm: float = minf(18.0, rect.size.x * 0.1)
		var inner: Color = Color(color, minf(1.0, color.a + 0.25))
		for sx in [0, 1]:
			for sy in [0, 1]:
				var p := Vector2(rect.position.x if sx == 0 else rect.end.x, rect.position.y if sy == 0 else rect.end.y)
				var dx: float = arm if sx == 0 else -arm
				var dy: float = arm if sy == 0 else -arm
				game.draw_line(p, p + Vector2(dx, 0.0), inner, width + 1.0)
				game.draw_line(p, p + Vector2(0.0, dy), inner, width + 1.0)


static func _draw_diamond(game: Node2D, center: Vector2, r: float, color: Color, filled: bool) -> void:
	var pts := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)])
	if filled:
		game.draw_colored_polygon(pts, color)
	else:
		pts.append(pts[0])
		game.draw_polyline(pts, color, 1.2)


static func _draw_theme_marks(game: Node2D, viewport: Vector2, theme: Dictionary, theme_key: String, accent: Color, now: float) -> void:
	if theme_key == "henry":
		for i in range(7):
			var y: float = 116.0 + float(i) * 78.0
			if y >= viewport.y - 58.0:
				break
			var sx: float = 12.0 + float((i * 53) % 96)
			game.draw_line(Vector2(sx, y), Vector2(minf(viewport.x - 12.0, sx + 106.0), y - 18.0), Color(theme["frame"], 0.12), 1.0)
	else:
		# Linha de varredura lenta, como um scanner de bancada.
		var scan_y: float = fposmod(now * 60.0, viewport.y)
		game.draw_line(Vector2(0.0, scan_y), Vector2(viewport.x, scan_y), Color(accent, 0.05), 2.0)


static func _draw_step_wipe(game: Node2D, viewport: Vector2, accent: Color, p: float) -> void:
	var x: float = viewport.x * p
	game.draw_line(Vector2(x, 0.0), Vector2(x - 60.0, viewport.y), Color(accent, 0.55 * (1.0 - p)), 3.0)
	game.draw_line(Vector2(x - 18.0, 0.0), Vector2(x - 78.0, viewport.y), Color(accent, 0.25 * (1.0 - p)), 1.5)
