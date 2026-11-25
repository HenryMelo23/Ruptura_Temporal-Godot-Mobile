class_name RTDialogueBoxPresentation
extends RefCounted
## Caixa de conversa estilo RPG compartilhada (Mercador, cena da UMBRA...):
## retrato encostado na borda de cima, placa de nome, texto com maquina de
## escrever, seta de "continua" e, quando a fala pede, botoes de escolha.
##
## Retratos: assets/sprites/merchant/portrait_<quem>[_<humor>][_talk_n|_blink].
## Quem ainda nao tem arte recebe um substituto (sprite recortado ou retrato
## tingido) pelo chamador, sem asset novo.

const ART := preload("res://scripts/presentation/merchant_dimension_presentation.gd")
const BRASS := Color(0.85, 0.70, 0.34)
const INK := Color(0.94, 0.95, 1.0)
const BOX_BG := Color(0.04, 0.05, 0.10, 0.96)
const CHOICE_H := 40.0
const CHOICE_GAP := 10.0
## Humor da fala -> sufixo do retrato.
const MOOD_SUFFIX := {
	"triste": "sad", "surpresa": "surprised", "desconfiada": "suspicious",
	"irritada": "annoyed", "decidida": "determined", "preocupada": "worried",
	"animado": "excited", "sorrindo": "happy", "preocupado": "worried",
}


## Retrato animado: boca mexe enquanto o texto corre, pisca de vez em quando.
static func portrait(who: String, mood: String, talking: bool, t: float) -> Texture2D:
	var bases: Array = []
	var suffix: String = String(MOOD_SUFFIX.get(mood, mood if mood in MOOD_SUFFIX.values() else ""))
	if suffix != "":
		bases.append("portrait_%s_%s" % [who, suffix])
	bases.append("portrait_" + who)
	for base in bases:
		if ART.art(base) == null and ART.seq(base + "_talk").is_empty():
			continue
		if talking:
			var mouth: Texture2D = ART.seq_frame(base + "_talk", 9.0, t)
			if mouth != null:
				return mouth
		elif fposmod(t, 3.4) < 0.13 and ART.art(base + "_blink") != null:
			return ART.art(base + "_blink")
		if ART.art(base) != null:
			return ART.art(base)
	return null


## spec:
##  text, done, name, accent, portrait (Texture2D), portrait_region (Rect2,
##  recorte da textura), portrait_tint, portrait_draw (Callable(rect) quando nao
##  ha textura), portrait_flip, side ("left"/"right"), dim, bottom_inset,
##  text_size, shake (Vector2), choices (Array[String]), selected (int),
##  box_h_ratio.
## Retorna {"box": Rect2, "choices": Array[Rect2]} para o teste de toque.
static func draw_box(game: Node2D, viewport: Vector2, spec: Dictionary) -> Dictionary:
	var accent: Color = spec.get("accent", BRASS)
	var right: bool = String(spec.get("side", "left")) == "right"
	var choices: Array = spec.get("choices", [])
	var margin: float = 16.0
	var scale: float = RTDialogueTextScale.scale(game)
	var portrait_size: float = clampf(viewport.y * 0.3, 96.0, 168.0)
	# Texto maior pede caixa maior (ate metade da tela) para a fala caber.
	var box_h: float = minf(clampf(viewport.y * float(spec.get("box_h_ratio", 0.3)), 118.0, 196.0) * lerpf(1.0, scale, 0.5), viewport.y * 0.5)
	var bottom: float = viewport.y - margin - float(spec.get("bottom_inset", 0.0))
	var choice_rows: int = choices.size()
	var choice_h: float = CHOICE_H * lerpf(1.0, scale, 0.6)
	var choices_h: float = 0.0
	if choice_rows > 0:
		choices_h = float(choice_rows) * (choice_h + CHOICE_GAP)
	var box := Rect2(Vector2(margin, bottom - box_h), Vector2(viewport.x - margin * 2.0, box_h))
	box.position += Vector2(spec.get("shake", Vector2.ZERO))
	var dim: float = float(spec.get("dim", 0.45))
	if dim > 0.0:
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.03, dim), true)
	game.draw_rect(box, BOX_BG, true)
	game.draw_rect(box, Color(accent.r, accent.g, accent.b, 0.9), false, 2.5)
	var px: float = box.end.x - 10.0 - portrait_size if right else box.position.x + 10.0
	var portrait_rect := Rect2(Vector2(px, box.position.y - portrait_size * 0.52), Vector2(portrait_size, portrait_size))
	game.draw_rect(portrait_rect, Color(0.02, 0.03, 0.07, 0.95), true)
	var tex: Texture2D = spec.get("portrait", null)
	var tint: Color = spec.get("portrait_tint", Color.WHITE)
	if tex != null:
		if spec.has("portrait_region"):
			_draw_region_fit(game, tex, Rect2(spec["portrait_region"]), portrait_rect.grow(-4.0), bool(spec.get("portrait_flip", false)), tint)
		elif tint != Color.WHITE or bool(spec.get("portrait_flip", false)):
			_draw_region_fit(game, tex, Rect2(Vector2.ZERO, tex.get_size()), portrait_rect, bool(spec.get("portrait_flip", false)), tint)
		else:
			game._draw_entity_fit(tex, portrait_rect.get_center(), portrait_rect.size)
	var extra: Callable = spec.get("portrait_draw", Callable())
	if extra.is_valid():
		extra.call(portrait_rect)
	game.draw_rect(portrait_rect, Color(accent.r, accent.g, accent.b, 0.95), false, 2.0)
	game.draw_string(game.font, portrait_rect.position + Vector2(0.0, portrait_rect.size.y + 18.0 * scale), String(spec.get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, portrait_rect.size.x, int(round(13.0 * scale)), Color(accent.r, accent.g, accent.b, 1.0))
	var text_x: float = box.position.x + 18.0 if right else portrait_rect.end.x + 18.0
	var text_w: float = (portrait_rect.position.x - 16.0 - text_x) if right else (box.end.x - portrait_rect.end.x - 34.0)
	var text_rect := Rect2(Vector2(text_x, box.position.y + 18.0), Vector2(text_w, box.size.y - 44.0))
	var base_size: int = int(spec.get("text_size", 17))
	var full_text: String = String(spec.get("full_text", spec.get("text", "")))
	var size: int = RTDialogueTextScale.fit_size(game, full_text, text_rect, int(round(float(base_size) * scale)), base_size)
	game._draw_wrapped(String(spec.get("text", "")), text_rect, size, INK)
	var done: bool = bool(spec.get("done", false))
	var rects: Array = []
	if done and choice_rows > 0:
		rects = _draw_choices(game, viewport, box, choices, int(spec.get("selected", 0)), accent, choices_h, choice_h, scale)
	elif done:
		var ax: float = box.end.x - 26.0 if not right else box.position.x + 26.0
		var arrow := Vector2(ax, box.end.y - 18.0 + sin(float(game.time_alive) * 5.0) * 2.5)
		game.draw_colored_polygon(PackedVector2Array([arrow + Vector2(-7, -5), arrow + Vector2(7, -5), arrow + Vector2(0, 5)]), Color(accent.r, accent.g, accent.b, 0.95))
	return {"box": box, "choices": rects}


## Botoes empilhados logo acima da caixa, no lado oposto ao retrato: dedo
## grande no celular, setas/enter no teclado e no controle.
static func _draw_choices(game: Node2D, viewport: Vector2, box: Rect2, choices: Array, selected: int, accent: Color, choices_h: float, choice_h: float = CHOICE_H, scale: float = 1.0) -> Array:
	var rects: Array = []
	var w: float = clampf(viewport.x * 0.42 * lerpf(1.0, scale, 0.5), 260.0, minf(viewport.x - 40.0, 460.0 * scale))
	var x: float = box.end.x - w - 12.0
	var y: float = box.position.y - choices_h - 4.0
	for i in range(choices.size()):
		var r := Rect2(Vector2(x, y + float(i) * (choice_h + CHOICE_GAP)), Vector2(w, choice_h))
		var on: bool = i == selected
		var pulse: float = 0.5 + 0.5 * sin(float(game.time_alive) * 5.0)
		game.draw_rect(r, Color(0.06, 0.07, 0.13, 0.97) if not on else Color(accent.r * 0.32, accent.g * 0.32, accent.b * 0.32, 0.98), true)
		game.draw_rect(r, Color(accent.r, accent.g, accent.b, 0.55 + (0.45 * pulse if on else 0.0)), false, 2.5 if on else 1.5)
		if on:
			var a := Vector2(r.position.x + 16.0, r.get_center().y)
			game.draw_colored_polygon(PackedVector2Array([a + Vector2(-5, -7), a + Vector2(-5, 7), a + Vector2(6, 0)]), accent)
		game._draw_centered(String(choices[i]), r.get_center(), int(round(16.0 * lerpf(1.0, scale, 0.75))), INK if on else Color(0.82, 0.84, 0.9))
		rects.append(r)
	return rects


static func _draw_region_fit(game: Node2D, tex: Texture2D, src: Rect2, dest: Rect2, flip: bool, tint: Color) -> void:
	var scale: float = minf(dest.size.x / maxf(1.0, src.size.x), dest.size.y / maxf(1.0, src.size.y))
	var size: Vector2 = src.size * scale
	var at: Vector2 = dest.get_center() - size * 0.5
	if flip:
		game.draw_set_transform(Vector2(at.x + size.x, at.y), 0.0, Vector2(-1.0, 1.0))
		game.draw_texture_rect_region(tex, Rect2(Vector2.ZERO, size), src, tint)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		game.draw_texture_rect_region(tex, Rect2(at, size), src, tint)
