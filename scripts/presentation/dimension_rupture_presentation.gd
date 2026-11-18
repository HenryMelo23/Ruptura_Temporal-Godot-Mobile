class_name RTDimensionRupturePresentation
extends RefCounted
## Apresentação do Fragmento Instável / Impulso de Ruptura / Colapso.
## Tudo deriva do estado compacto de `RTDimensionRuptureController` (no host e
## na réplica): nenhuma partícula, rachadura ou pulso vem da rede.

const C := preload("res://scripts/systems/phase/dimension_rupture_controller.gd")

const COLOR_PERFECT := Color(0.42, 0.96, 1.0)
const COLOR_STABLE := Color(0.62, 0.86, 1.0)
const COLOR_WEAK := Color(1.0, 0.62, 0.22)
const COLOR_EMERGENCY := Color(1.0, 0.2, 0.26)
const COLOR_LOCKED := Color(0.62, 0.66, 0.74)
const COLOR_MOMENTUM := Color(1.0, 0.86, 0.32)
const COLOR_DISORIENT := Color(0.86, 0.56, 1.0)
const OUTLINE := Color(0.01, 0.02, 0.025, 0.96)
const PANEL_W := 300.0
const PANEL_H := 42.0
const CRACK_CELL := 560.0
const ARROW_MIN_DISTANCE := 520.0


static func band_color(rupture: RTDimensionRuptureController) -> Color:
	if rupture.current_state() == C.STATE_EMERGENCY:
		return COLOR_EMERGENCY
	if String(rupture.state.get("suspend_reason", "")) == C.SUSPEND_PORTAL_LOCKED:
		return COLOR_LOCKED
	match rupture.current_band():
		C.BAND_PERFECT:
			return COLOR_PERFECT
		C.BAND_STABLE:
			return COLOR_STABLE
	return COLOR_WEAK


static func band_label(rupture: RTDimensionRuptureController) -> String:
	var s := rupture.current_state()
	if s == C.STATE_EMERGENCY:
		return "COLAPSO IMINENTE %ds" % int(ceil(rupture.remaining_seconds()))
	if String(rupture.state.get("suspend_reason", "")) == C.SUSPEND_PORTAL_LOCKED:
		return "FRAGMENTO INSTÁVEL — RUPTURA FECHADA"
	var secs := int(ceil(rupture.band_remaining_seconds()))
	match rupture.current_band():
		C.BAND_PERFECT:
			return "TRAVESSIA PERFEITA %ds" % secs
		C.BAND_STABLE:
			return "TRAVESSIA ESTÁVEL %ds" % secs
	return "COLAPSO — FRAGMENTO FRACO %ds" % secs


## 1 = estável; cai até 0 aos 180 s. Na emergência, mostra a janela de fuga.
static func stability_ratio(rupture: RTDimensionRuptureController) -> float:
	if rupture.current_state() == C.STATE_EMERGENCY:
		return clampf(rupture.remaining_seconds() / C.EMERGENCY_ESCAPE_SECONDS, 0.0, 1.0)
	return clampf(1.0 - rupture._effective_elapsed() / C.COLLAPSE_TOTAL_SECONDS, 0.0, 1.0)


static func chips(rupture: RTDimensionRuptureController) -> Array:
	var out: Array = []
	if rupture.momentum() > 0:
		out.append(["IMPULSO " + C.roman(rupture.momentum()), COLOR_MOMENTUM])
	var token := rupture.pending_token()
	if not token.is_empty():
		var perfect := String(token.get("tier", "")) == C.BAND_PERFECT
		out.append(["QUALIDADE +%d" % int(token.get("attempts", 1)), COLOR_PERFECT if perfect else COLOR_STABLE])
	if rupture.disorientation_remaining() > 0.0:
		out.append(["DESORIENTAÇÃO %ds" % int(ceil(rupture.disorientation_remaining())), COLOR_DISORIENT])
	return out


static func draw_hud(game: Node2D, viewport: Vector2) -> void:
	if game.mode != "game" or game.dimension_rupture == null:
		return
	var rupture: RTDimensionRuptureController = game.dimension_rupture
	var active := rupture.is_active()
	var chip_list := chips(rupture)
	_draw_banner(game, viewport, rupture)
	if not active and chip_list.is_empty():
		return
	var t := float(game.time_alive)
	if active:
		_draw_vignette(game, viewport, rupture, t)
	var pos: Vector2 = game._boss_panel_pos(viewport)
	if game.boss_active and float(game.boss_hp) > 0.0:
		pos.y += 52.0
	var width := minf(PANEL_W, viewport.x - 32.0)
	pos.x = clampf(pos.x + (380.0 - width) * 0.5, 16.0, viewport.x - width - 16.0)
	var y := pos.y
	if active:
		var accent := band_color(rupture)
		var rect := Rect2(Vector2(pos.x, y), Vector2(width, PANEL_H))
		var pulse := 0.0
		if rupture.current_state() == C.STATE_EMERGENCY:
			pulse = 0.5 + 0.5 * sin(t * 9.0)
		game._draw_combat_panel(rect, accent, 0.62 + 0.2 * pulse)
		game._draw_centered_outlined(glyph_safe(game, band_label(rupture)), Vector2(rect.get_center().x, rect.position.y + 12.0), 14, accent, OUTLINE, 2)
		var bar := Rect2(rect.position + Vector2(14.0, 25.0), Vector2(width - 28.0, 7.0))
		game.draw_rect(bar, Color(0.0, 0.0, 0.0, 0.55))
		var fill := bar
		fill.size.x = bar.size.x * stability_ratio(rupture)
		game.draw_rect(fill, accent.lerp(Color.WHITE, 0.25 * pulse))
		if rupture.current_state() != C.STATE_EMERGENCY:
			for mark in [C.FAST_WINDOW_SECONDS, C.STANDARD_WINDOW_SECONDS]:
				var x: float = bar.position.x + bar.size.x * (1.0 - float(mark) / C.COLLAPSE_TOTAL_SECONDS)
				game.draw_line(Vector2(x, bar.position.y - 3.0), Vector2(x, bar.end.y + 3.0), Color(1, 1, 1, 0.85), 2.0)
		y = rect.end.y + 6.0
	if chip_list.is_empty():
		return
	var chip_w := (width - 6.0 * float(chip_list.size() - 1)) / float(chip_list.size())
	for i in range(chip_list.size()):
		var chip: Array = chip_list[i]
		var chip_rect := Rect2(Vector2(pos.x + float(i) * (chip_w + 6.0), y), Vector2(chip_w, 22.0))
		game._draw_combat_panel(chip_rect, chip[1], 0.5)
		game._draw_centered_outlined(glyph_safe(game, String(chip[0])), chip_rect.get_center(), 13, chip[1], OUTLINE, 2)


## A fonte de contorno do HUD não tem o travessão; troca por hífen só na tela.
static func glyph_safe(_game: Node2D, text: String) -> String:
	return text.replace("—", "-")


static func _draw_banner(game: Node2D, viewport: Vector2, rupture: RTDimensionRuptureController) -> void:
	if rupture.banner_timer <= 0.0 or rupture.banner_text == "":
		return
	var p := 1.0 - rupture.banner_timer / maxf(0.01, rupture.banner_duration)
	var alpha := clampf((1.0 - p) / 0.2, 0.0, 1.0)
	var accent := band_color(rupture) if rupture.is_active() else COLOR_PERFECT
	if rupture.banner_text == C.MSG_EJECTED:
		accent = COLOR_DISORIENT
	var size := 24 if viewport.x >= 1100.0 else 20
	# Abaixo do painel/chips e acima do título da fase que entra na chegada.
	var pos := Vector2(viewport.x * 0.5, clampf(viewport.y * 0.25, 170.0, 200.0))
	var text := glyph_safe(game, rupture.banner_text)
	var width: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 48.0 if game.font != null else 640.0
	var rect := Rect2(pos - Vector2(width * 0.5, 22.0), Vector2(width, 44.0))
	game.draw_rect(rect, Color(0.01, 0.02, 0.03, 0.62 * alpha))
	game.draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color(accent.r, accent.g, accent.b, 0.9 * alpha), 2.0)
	game.draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color(accent.r, accent.g, accent.b, 0.9 * alpha), 2.0)
	game._draw_centered_outlined(text, pos, size, Color(accent.r, accent.g, accent.b, alpha), Color(OUTLINE.r, OUTLINE.g, OUTLINE.b, alpha), 3)


static func _draw_vignette(game: Node2D, viewport: Vector2, rupture: RTDimensionRuptureController, t: float) -> void:
	var intensity := rupture.collapse_intensity()
	if intensity <= 0.0:
		return
	var emergency := rupture.current_state() == C.STATE_EMERGENCY
	var pulse := 0.5 + 0.5 * sin(t * (7.0 if emergency else 2.4))
	var color := COLOR_EMERGENCY if emergency else COLOR_WEAK
	var depth := minf(viewport.x, viewport.y) * (0.06 + 0.1 * intensity)
	var steps := 5
	var base := (0.07 + 0.13 * intensity) * (0.65 + 0.35 * pulse)
	for i in range(steps):
		var d := depth * float(i + 1) / float(steps)
		var c := Color(color.r, color.g, color.b, base / float(steps) * 1.6)
		game.draw_rect(Rect2(0, 0, viewport.x, d), c)
		game.draw_rect(Rect2(0, viewport.y - d, viewport.x, d), c)
		game.draw_rect(Rect2(0, d, d, viewport.y - 2.0 * d), c)
		game.draw_rect(Rect2(viewport.x - d, d, d, viewport.y - 2.0 * d), c)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	if game.dimension_rupture == null:
		return
	var rupture: RTDimensionRuptureController = game.dimension_rupture
	if not rupture.is_active():
		return
	var t := float(game.time_alive)
	var accent := band_color(rupture)
	var intensity := rupture.collapse_intensity()
	if intensity > 0.0:
		_draw_cracks(game, camera, rupture, intensity, accent)
	var portal := rupture.portal_position()
	if portal == Vector2.INF:
		return
	var center: Vector2 = portal - camera
	var urgency := 2.2 + 4.0 * intensity
	for i in range(3):
		var phase := fmod(t * 0.55 * urgency / 2.2 + float(i) / 3.0, 1.0)
		var radius := 70.0 + 150.0 * phase
		game.draw_arc(center, radius, 0.0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.55 * (1.0 - phase)), 3.0)
	game.draw_line(center + Vector2(0, -36), center + Vector2(0, -260), Color(accent.r, accent.g, accent.b, 0.28 + 0.12 * sin(t * urgency)), 10.0)
	var to_portal: Vector2 = portal - Vector2(game.player_pos)
	if to_portal.length() < ARROW_MIN_DISTANCE:
		return
	var dir := to_portal.normalized()
	var tip: Vector2 = Vector2(game.player_pos) - camera + dir * (104.0 + 6.0 * sin(t * 6.0))
	var side := dir.orthogonal() * 13.0
	game.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 24.0 + side, tip - dir * 24.0 - side]), Color(accent.r, accent.g, accent.b, 0.92))


## Rachaduras ancoradas no mundo por célula, sorteadas por `event_id`: quanto
## maior o colapso, mais células racham. Nada é sincronizado.
static func _draw_cracks(game: Node2D, camera: Vector2, rupture: RTDimensionRuptureController, intensity: float, accent: Color) -> void:
	var view: Vector2 = game.get_viewport_rect().size
	var seed_base := hash(String(rupture.state.get("event_id", "")))
	var first := Vector2i(floori(camera.x / CRACK_CELL), floori(camera.y / CRACK_CELL))
	var last := Vector2i(floori((camera.x + view.x) / CRACK_CELL), floori((camera.y + view.y) / CRACK_CELL))
	var rng := RandomNumberGenerator.new()
	var color := Color(accent.r, accent.g, accent.b, 0.22 + 0.3 * intensity)
	for cx in range(first.x, last.x + 1):
		for cy in range(first.y, last.y + 1):
			rng.seed = seed_base ^ (cx * 73856093) ^ (cy * 19349663)
			if rng.randf() > 0.25 + 0.6 * intensity:
				continue
			var p := Vector2((float(cx) + rng.randf()) * CRACK_CELL, (float(cy) + rng.randf()) * CRACK_CELL) - camera
			var angle := rng.randf() * TAU
			var points := PackedVector2Array([p])
			for _seg in range(4):
				angle += rng.randf_range(-0.9, 0.9)
				p += Vector2.from_angle(angle) * rng.randf_range(26.0, 54.0) * (0.6 + intensity)
				points.append(p)
			game.draw_polyline(points, color, 2.0 + 2.0 * intensity)
