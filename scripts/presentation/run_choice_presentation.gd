class_name RTRunChoicePresentation
extends RefCounted

## Tela da escolha de fim de chefe (pacto ou evolucao). Cartas lado a lado no
## desktop/landscape largo e empilhadas em telas estreitas.

const GOOD := Color(0.46, 1.0, 0.62)
const BAD := Color(1.0, 0.42, 0.38)
const LORE := Color(0.78, 0.8, 0.9)
const PANEL := Color(0.04, 0.035, 0.07, 0.96)


static func draw(game: Node2D, viewport: Vector2) -> void:
	var choice: RTRunChoiceController = game._run_choice()
	choice.age += game.get_process_delta_time()
	var appear: float = clampf(choice.age / 0.35, 0.0, 1.0)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.02, 0.8 * appear), true)
	var is_pact: bool = choice.kind == "pact"
	var accent: Color = Color(1.0, 0.72, 0.32) if is_pact else Color(game._manifestation_color())
	var title: String = "PACTO POS-BATALHA" if is_pact else "EVOLUCAO DA %s" % String(game._form_evolutions().form_label()).to_upper()
	var subtitle: String = "O chefe caiu, mas deixou marcas. Escolha uma: nao da para recusar." if is_pact else "A vitoria sobre a Sentinela despertou algo novo. Escolha uma evolucao."
	var top: float = maxf(26.0, viewport.y * 0.06)
	game._draw_centered_outlined(title, Vector2(viewport.x * 0.5, top + 22.0), 28 if viewport.x > 700.0 else 22, accent, Color(0, 0, 0, 0.9), 4)
	game._draw_centered(subtitle, Vector2(viewport.x * 0.5, top + 50.0), 14 if viewport.x > 700.0 else 12, LORE)
	var n: int = choice.options.size()
	var wide: bool = viewport.x >= 860.0
	var gap := 18.0
	var area_top: float = top + 72.0
	var area_bottom: float = viewport.y - 86.0
	var rects: Array[Rect2] = []
	if wide:
		var w: float = minf(330.0, (viewport.x - 80.0 - gap * float(n - 1)) / float(n))
		var h: float = minf(290.0, area_bottom - area_top)
		var y0: float = area_top + maxf(0.0, (area_bottom - area_top - h) * 0.35)
		var x0: float = viewport.x * 0.5 - (w * float(n) + gap * float(n - 1)) * 0.5
		for i in range(n):
			rects.append(Rect2(Vector2(x0 + float(i) * (w + gap), y0), Vector2(w, h)))
	else:
		var w2: float = minf(560.0, viewport.x - 32.0)
		var h2: float = minf(150.0, (area_bottom - area_top - gap * float(n - 1)) / float(n))
		for i in range(n):
			rects.append(Rect2(Vector2(viewport.x * 0.5 - w2 * 0.5, area_top + float(i) * (h2 + gap)), Vector2(w2, h2)))
	for i in range(n):
		var r: Rect2 = rects[i]
		var slide: float = clampf((choice.age - 0.08 * float(i)) / 0.3, 0.0, 1.0)
		r.position.y += (1.0 - slide) * 40.0
		game.buttons["run_choice_%d" % i] = r
		_draw_card(game, r, Dictionary(choice.options[i]), i == choice.selected, accent, slide, wide, is_pact)
	var btn := Rect2(Vector2(viewport.x * 0.5 - 120.0, viewport.y - 70.0), Vector2(240.0, 50.0))
	game.buttons["run_choice_confirm"] = btn
	var ready: bool = choice.selected >= 0
	game.draw_rect(btn, Color(accent.darkened(0.55), 0.95 if ready else 0.45), true)
	game.draw_rect(btn, Color(accent, 0.95 if ready else 0.35), false, 2.5)
	game._draw_centered("ESCOLHER" if ready else "TOQUE EM UMA OPCAO", btn.get_center() + Vector2(0, 6), 18 if ready else 13, Color(1, 1, 1, 0.95 if ready else 0.6))


static func _draw_card(game: Node2D, r: Rect2, option: Dictionary, focused: bool, accent: Color, alpha: float, wide: bool, is_pact: bool) -> void:
	var color: Color = Color(option.get("color", accent))
	var pulse: float = 0.5 + 0.5 * sin(float(game.time_alive) * 5.0)
	game.draw_rect(r, Color(PANEL, PANEL.a * alpha), true)
	game.draw_rect(Rect2(r.position, Vector2(r.size.x, 4.0)), Color(color, 0.9 * alpha), true)
	game.draw_rect(r, Color(color if focused else color.darkened(0.45), alpha), false, 3.0 + (pulse * 1.5 if focused else 0.0))
	if focused:
		game.draw_rect(r.grow(5.0), Color(color, 0.25 * alpha), false, 2.0)
	var font: Font = game.font
	var pad := 14.0
	var inner_w: float = r.size.x - pad * 2.0
	var y: float = r.position.y + 30.0
	var name_size: int = 21 if wide else 17
	game.draw_string(font, Vector2(r.position.x + pad, y), String(option.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, inner_w, name_size, Color(color.lightened(0.2), alpha))
	y += 14.0
	var body_size: int = 16 if wide else 13
	var line_h: float = float(body_size) + 5.0
	var buff: String = String(option.get("buff", ""))
	var debuff: String = String(option.get("debuff", ""))
	if buff != "":
		y += line_h
		game.draw_string(font, Vector2(r.position.x + pad, y), "+", HORIZONTAL_ALIGNMENT_LEFT, 14.0, body_size + 2, Color(GOOD, alpha))
		var lines_b: int = 3 if wide else 2
		game.draw_multiline_string(font, Vector2(r.position.x + pad + 16.0, y), buff, HORIZONTAL_ALIGNMENT_LEFT, inner_w - 16.0, body_size, lines_b, Color(GOOD, alpha))
		y += line_h * float(_line_count(font, buff, inner_w - 16.0, body_size, lines_b) - 1)
	if debuff != "":
		y += line_h + 4.0
		game.draw_string(font, Vector2(r.position.x + pad, y), "-", HORIZONTAL_ALIGNMENT_LEFT, 14.0, body_size + 2, Color(BAD, alpha))
		game.draw_multiline_string(font, Vector2(r.position.x + pad + 16.0, y), debuff, HORIZONTAL_ALIGNMENT_LEFT, inner_w - 16.0, body_size, 2, Color(BAD, alpha))
		y += line_h * float(_line_count(font, debuff, inner_w - 16.0, body_size, 2) - 1)
	var lore: String = String(option.get("lore_text", option.get("lore", "")))
	if lore != "":
		var lore_size: int = 13 if wide else 11
		var lore_y: float = maxf(y + line_h + 6.0, r.end.y - (float(lore_size) + 4.0) * (5.0 if wide else 2.0) - 8.0)
		if wide:
			game.draw_line(Vector2(r.position.x + pad, lore_y - 16.0), Vector2(r.end.x - pad, lore_y - 16.0), Color(color, 0.25 * alpha), 1.0)
		game.draw_multiline_string(font, Vector2(r.position.x + pad, lore_y), "\"%s\"" % lore, HORIZONTAL_ALIGNMENT_LEFT, inner_w, lore_size, 5 if wide else 2, Color(LORE, 0.85 * alpha))


static func _line_count(font: Font, text: String, width: float, size: int, max_lines: int) -> int:
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return clampi(int(ceil(w / maxf(1.0, width))), 1, max_lines)
