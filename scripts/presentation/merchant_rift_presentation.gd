class_name RTMerchantRiftPresentation
extends RefCounted

## Desenho da Fenda do Mercador: abertura (rachadura que se rasga), estado
## aberto com vortice, cartas orbitando e aro brilhante, fase instavel com
## tremor e faiscas, colapso por implosao e a explosao de entrada.

const MistGuide = preload("res://scripts/presentation/mist_guide_presentation.gd")
const RiftController = preload("res://scripts/systems/shop/merchant_rift_controller.gd")

const HALF_WIDTH := 42.0
const HALF_HEIGHT := 96.0
const VOID_COLOR := Color(0.04, 0.0, 0.1, 0.96)
const RIM_COLOR := Color(1.0, 0.9, 0.66)
const GLOW_COLOR := Color(0.74, 0.34, 1.0)
const HOT_COLOR := Color(1.0, 0.36, 0.42)
const CARD_COLOR := Color(0.16, 0.06, 0.26, 0.95)
const ENTER_FLASH_MS := 650.0
const EDGE_POINTS := 30
const EDGE_POINTS_LOW := 18


static func draw_world(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var controller = game.shop_rift_controller
	if controller == null or not controller.active():
		return
	var rift: Dictionary = controller.rift()
	var world_pos: Vector2 = Vector2(rift.get("pos", Vector2.ZERO))
	var noise_seed: float = float(rift.get("seed", 0.0))
	var state: String = String(rift.get("state", ""))
	var low: bool = game._runtime_visual_budget_active() or bool(game.gfx_low_resource)
	var unstable: bool = controller.unstable()
	# Sem trilha no chao: a direcao da fenda fica so com a seta de borda (HUD).
	var center: Vector2 = world_pos - camera
	var cull := Rect2(Vector2(-280.0, -280.0), viewport + Vector2(560.0, 560.0))
	if not cull.has_point(center):
		return
	var t: float = float(game.time_alive)
	var state_age: float = float(rift.get("state_age", 0.0))
	var width_k: float = 1.0
	var height_k: float = 1.0
	var instability: float = 0.0
	var alpha: float = 1.0
	if state == RiftController.STATE_OPENING:
		var open_u: float = clampf(state_age / RiftController.OPEN_TIME, 0.0, 1.0)
		height_k = _ease_out_cubic(clampf(open_u / 0.32, 0.0, 1.0))
		width_k = _ease_out_back(clampf((open_u - 0.24) / 0.76, 0.0, 1.0))
		_draw_opening_burst(game, center, open_u)
	elif state == RiftController.STATE_OPEN:
		if unstable:
			instability = 1.0 - controller.remaining() / RiftController.UNSTABLE_TIME
	elif state == RiftController.STATE_COLLAPSING:
		var collapse_u: float = clampf(state_age / RiftController.COLLAPSE_TIME, 0.0, 1.0)
		instability = 1.0
		width_k = pow(1.0 - collapse_u, 1.6)
		height_k = 1.0 - collapse_u * collapse_u * 0.85
		alpha = 1.0 - smoothstep(0.75, 1.0, collapse_u)
		_draw_collapse_implosion(game, center, collapse_u, low)
	elif state == RiftController.STATE_ENTERED:
		var enter_u: float = clampf(float(Time.get_ticks_msec() - int(rift.get("entered_msec", 0))) / ENTER_FLASH_MS, 0.0, 1.0)
		width_k = 1.0 + enter_u * 0.9
		height_k = 1.0 + enter_u * 0.35
		alpha = 1.0 - enter_u
		t = float(Time.get_ticks_msec()) * 0.001
		_draw_enter_burst(game, center, enter_u)
	if alpha <= 0.01:
		return
	var near: bool = bool(rift.get("near", false))
	var breathe: float = 1.0 + sin(t * 2.1 + noise_seed) * 0.035 + (0.05 if near else 0.0)
	var shake := Vector2.ZERO
	if instability > 0.0:
		shake = Vector2(sin(t * 47.0), cos(t * 39.0)) * instability * 2.6
	var hw: float = HALF_WIDTH * width_k * breathe
	var hh: float = HALF_HEIGHT * height_k * breathe
	var c: Vector2 = center + shake
	var glow: Color = GLOW_COLOR.lerp(HOT_COLOR, instability * 0.8)
	var rim: Color = RIM_COLOR.lerp(Color(1.0, 0.62, 0.42), instability)
	_draw_ground(game, c, hw, hh, glow, alpha)
	_draw_spiral_arms(game, c, hw, hh, glow, t, alpha, low, noise_seed)
	var halo_w: float = maxf(hw, 6.0)
	MistGuide.draw_blob(game, c, Vector2(halo_w * 7.5, hh * 3.2), Color(0.01, 0.0, 0.04, 0.45 * alpha))
	MistGuide.draw_blob(game, c, Vector2(halo_w * 5.6, hh * 2.8), Color(glow.lightened(0.2), 0.6 * alpha))
	MistGuide.draw_blob(game, c, Vector2(halo_w * 3.2, hh * 2.1), Color(glow.lightened(0.55), 0.55 * alpha))
	if hw >= 4.0 and hh >= 6.0:
		var edge: PackedVector2Array = _tear_outline(c, hw, hh, t, instability, low, noise_seed)
		game.draw_colored_polygon(edge, Color(VOID_COLOR, VOID_COLOR.a * alpha))
		_draw_inner_vortex(game, c, hw, hh, glow, rim, t, alpha, low)
		var closed: PackedVector2Array = edge.duplicate()
		closed.append(edge[0])
		var flicker: float = 1.0
		if instability > 0.0:
			flicker = 0.62 + 0.38 * absf(sin(t * (18.0 + instability * 22.0)))
		game.draw_polyline(closed, Color(glow.lightened(0.3), 0.6 * alpha * flicker), 11.0, true)
		game.draw_polyline(closed, Color(rim, alpha * flicker), 3.4, true)
		game.draw_polyline(closed, Color(1.0, 1.0, 1.0, 0.75 * alpha * flicker), 1.2, true)
	else:
		game.draw_line(c + Vector2(0.0, -hh), c + Vector2(0.0, hh), Color(rim, alpha), 2.0, true)
	if state in [RiftController.STATE_OPENING, RiftController.STATE_OPEN]:
		_draw_orbit_cards(game, c, hw, hh, t, alpha * clampf(width_k, 0.0, 1.0), noise_seed)
	if instability > 0.0 and state != RiftController.STATE_ENTERED:
		_draw_sparks(game, c, hw, hh, t, instability, low)
	if state == RiftController.STATE_OPEN or (state == RiftController.STATE_OPENING and state_age >= RiftController.OPEN_TIME * 0.6):
		_draw_labels(game, center, controller, near, unstable, t)


static func _ease_out_cubic(u: float) -> float:
	var inv: float = 1.0 - u
	return 1.0 - inv * inv * inv


static func _ease_out_back(u: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	var v: float = u - 1.0
	return 1.0 + c3 * v * v * v + c1 * v * v


static func _tear_outline(c: Vector2, hw: float, hh: float, t: float, instability: float, low: bool, noise_seed: float) -> PackedVector2Array:
	var count: int = EDGE_POINTS_LOW if low else EDGE_POINTS
	var jag: float = 0.05 + instability * 0.1
	var points := PackedVector2Array()
	points.resize(count)
	for index in range(count):
		var angle: float = float(index) / float(count) * TAU
		var wobble: float = 1.0 + jag * (sin(angle * 7.0 + t * 3.1 + noise_seed) * 0.6 + sin(angle * 13.0 - t * 5.3) * 0.4)
		# Pontas afiadas em cima e embaixo: formato de rasgo, nao de elipse.
		var pinch: float = pow(absf(cos(angle)), 1.35)
		var x: float = cos(angle) * hw * wobble * (0.55 + 0.45 * pinch)
		var y: float = sin(angle) * hh * wobble
		points[index] = c + Vector2(x, y)
	return points


static func _draw_ground(game: Node2D, c: Vector2, hw: float, hh: float, glow: Color, alpha: float) -> void:
	var foot: Vector2 = c + Vector2(0.0, hh * 0.92)
	MistGuide.draw_blob(game, foot, Vector2(hw * 7.0 + 60.0, 46.0), Color(glow.lightened(0.3), 0.5 * alpha))
	MistGuide.draw_blob(game, foot, Vector2(hw * 3.2 + 24.0, 18.0), Color(RIM_COLOR, 0.28 * alpha))
	game.draw_set_transform(foot, 0.0, Vector2(1.0, 0.32))
	game.draw_arc(Vector2.ZERO, hw * 2.6 + 30.0, 0.0, TAU, 40, Color(glow.lightened(0.2), 0.26 * alpha), 3.0, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_spiral_arms(game: Node2D, c: Vector2, hw: float, _hh: float, glow: Color, t: float, alpha: float, low: bool, noise_seed: float) -> void:
	var arms: int = 2 if low else 3
	var steps: int = 6 if low else 11
	var reach: float = maxf(hw * 3.6, 40.0) + 70.0
	for arm in range(arms):
		for step in range(steps):
			var u: float = fposmod(t * 0.55 + float(step) / float(steps) + float(arm) * 0.13, 1.0)
			var radius: float = lerpf(reach, maxf(hw, 8.0) * 0.6, u)
			var angle: float = -t * 1.6 + float(arm) * TAU / float(arms) + u * 3.4 + noise_seed
			var point: Vector2 = c + Vector2(cos(angle) * radius, sin(angle) * radius * 0.58)
			var fade: float = smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(0.85, 1.0, u))
			var size: float = lerpf(56.0, 18.0, u)
			MistGuide.draw_blob(game, point, Vector2(size, size), Color(glow.lerp(RIM_COLOR, u * 0.6), 0.42 * fade * alpha))


static func _draw_inner_vortex(game: Node2D, c: Vector2, hw: float, hh: float, glow: Color, rim: Color, t: float, alpha: float, low: bool) -> void:
	var rings: int = 2 if low else 3
	for ring in range(rings):
		var scale: float = 0.78 - float(ring) * 0.22
		var start_angle: float = t * (1.4 + float(ring) * 0.7) + float(ring) * 1.9
		var points := PackedVector2Array()
		var segments: int = 14
		for segment in range(segments + 1):
			var angle: float = start_angle + float(segment) / float(segments) * PI * 1.25
			points.append(c + Vector2(cos(angle) * hw * scale * 0.72, sin(angle) * hh * scale * 0.9))
		var tint: Color = glow.lerp(rim, float(ring) / float(maxi(1, rings - 1)))
		game.draw_polyline(points, Color(tint, 0.55 * alpha), 2.0, true)
	var specks: int = 4 if low else 8
	for speck in range(specks):
		var u: float = fposmod(t * 0.36 + float(speck) / float(specks), 1.0)
		var angle2: float = t * 2.2 + float(speck) * 2.4
		var point: Vector2 = c + Vector2(cos(angle2) * hw * 0.6 * (1.0 - u), sin(angle2) * hh * 0.78 * (1.0 - u))
		game.draw_circle(point, 1.2 + (1.0 - u) * 1.4, Color(1.0, 0.94, 0.86, 0.85 * alpha * (1.0 - u)))
	MistGuide.draw_blob(game, c, Vector2(hw * 1.1, hh * 0.9), Color(glow.darkened(0.3), 0.55 * alpha))


static func _draw_orbit_cards(game: Node2D, c: Vector2, hw: float, hh: float, t: float, alpha: float, noise_seed: float) -> void:
	if alpha <= 0.02:
		return
	for index in range(3):
		var angle: float = t * 0.9 + float(index) * TAU / 3.0 + noise_seed
		var depth: float = sin(angle)
		var pos: Vector2 = c + Vector2(cos(angle) * (hw + 58.0), depth * 22.0 - hh * 0.25 + sin(t * 1.7 + float(index)) * 6.0)
		var card_scale: float = 0.82 + 0.22 * (depth * 0.5 + 0.5)
		var card_alpha: float = alpha * (0.55 + 0.45 * (depth * 0.5 + 0.5))
		var rotation: float = sin(t * 1.3 + float(index) * 2.0) * 0.35
		game.draw_set_transform(pos, rotation, Vector2(card_scale, card_scale))
		MistGuide.draw_blob(game, Vector2.ZERO, Vector2(40.0, 48.0), Color(GLOW_COLOR, 0.3 * card_alpha))
		var body := Rect2(Vector2(-8.0, -11.0), Vector2(16.0, 22.0))
		game.draw_rect(body, Color(CARD_COLOR, CARD_COLOR.a * card_alpha), true)
		game.draw_rect(body, Color(RIM_COLOR, 0.9 * card_alpha), false, 1.5)
		game.draw_circle(Vector2(0.0, 0.0), 3.0, Color(RIM_COLOR, 0.85 * card_alpha))
		var glint: float = fposmod(t * 0.8 + float(index) * 0.33, 1.0)
		if glint < 0.18:
			var gx: float = lerpf(-8.0, 8.0, glint / 0.18)
			game.draw_line(Vector2(gx - 3.0, -11.0), Vector2(gx + 3.0, 11.0), Color(1.0, 1.0, 1.0, 0.7 * card_alpha), 1.5, true)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_sparks(game: Node2D, c: Vector2, hw: float, hh: float, t: float, instability: float, low: bool) -> void:
	var count: int = 3 if low else 6
	var tick: float = floor(t * 14.0)
	for index in range(count):
		var h: float = MistGuide._hash(tick + float(index) * 9.1)
		if h > 0.35 + instability * 0.55:
			continue
		var angle: float = h * TAU * 3.0
		var from: Vector2 = c + Vector2(cos(angle) * hw * 0.9, sin(angle) * hh * 0.95)
		var out: Vector2 = Vector2(cos(angle), sin(angle) * 0.7).normalized()
		var bend: Vector2 = out.orthogonal() * (MistGuide._hash(h * 31.0) - 0.5) * 18.0
		var mid: Vector2 = from + out * 14.0 + bend
		var to: Vector2 = from + out * (26.0 + instability * 22.0) - bend * 0.5
		var color := Color(1.0, 0.7, 0.5, 0.85)
		game.draw_polyline(PackedVector2Array([from, mid, to]), color, 1.6, true)


static func _draw_opening_burst(game: Node2D, center: Vector2, open_u: float) -> void:
	var crack_u: float = clampf(open_u / 0.3, 0.0, 1.0)
	var crack_alpha: float = 1.0 - smoothstep(0.35, 0.7, open_u)
	if crack_alpha > 0.01:
		var length: float = HALF_HEIGHT * 1.25 * _ease_out_cubic(crack_u)
		var top: Vector2 = center + Vector2(0.0, -length)
		var bottom: Vector2 = center + Vector2(0.0, length)
		var jag := PackedVector2Array([top, center + Vector2(5.0, -length * 0.45), center + Vector2(-4.0, 0.0), center + Vector2(6.0, length * 0.5), bottom])
		game.draw_polyline(jag, Color(GLOW_COLOR, 0.6 * crack_alpha), 9.0, true)
		game.draw_polyline(jag, Color(1.0, 0.96, 0.9, crack_alpha), 2.5, true)
		MistGuide.draw_blob(game, center, Vector2(90.0, length * 2.4 + 20.0), Color(1.0, 0.86, 1.0, 0.35 * crack_alpha))
	var wave_u: float = clampf((open_u - 0.22) / 0.6, 0.0, 1.0)
	if wave_u > 0.0 and wave_u < 1.0:
		var radius: float = lerpf(30.0, 230.0, _ease_out_cubic(wave_u))
		var wave_alpha: float = 1.0 - wave_u
		game.draw_set_transform(center + Vector2(0.0, HALF_HEIGHT * 0.9), 0.0, Vector2(1.0, 0.36))
		game.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(RIM_COLOR, 0.7 * wave_alpha), 4.0, true)
		game.draw_arc(Vector2.ZERO, radius * 0.82, 0.0, TAU, 48, Color(GLOW_COLOR, 0.45 * wave_alpha), 8.0, true)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		MistGuide.draw_blob(game, center, Vector2(radius * 1.4, radius * 1.1), Color(GLOW_COLOR, 0.18 * wave_alpha))


static func _draw_collapse_implosion(game: Node2D, center: Vector2, collapse_u: float, low: bool) -> void:
	var count: int = 6 if low else 12
	for index in range(count):
		var angle: float = float(index) / float(count) * TAU
		var radius: float = lerpf(150.0, 4.0, _ease_out_cubic(collapse_u))
		var point: Vector2 = center + Vector2(cos(angle), sin(angle) * 0.7) * radius
		MistGuide.draw_blob(game, point, Vector2(26.0, 26.0), Color(GLOW_COLOR, 0.5 * (1.0 - collapse_u * 0.6)))
	if collapse_u > 0.78:
		var flash_u: float = (collapse_u - 0.78) / 0.22
		MistGuide.draw_blob(game, center, Vector2(70.0, 70.0) * (1.0 + flash_u), Color(1.0, 0.92, 1.0, 0.8 * (1.0 - flash_u)))
		game.draw_arc(center, 12.0 + flash_u * 70.0, 0.0, TAU, 40, Color(RIM_COLOR, 0.8 * (1.0 - flash_u)), 2.5, true)


static func _draw_enter_burst(game: Node2D, center: Vector2, enter_u: float) -> void:
	var fade: float = 1.0 - enter_u
	MistGuide.draw_blob(game, center, Vector2(260.0, 300.0) * (0.6 + enter_u), Color(1.0, 0.9, 1.0, 0.55 * fade))
	game.draw_arc(center, 40.0 + enter_u * 260.0, 0.0, TAU, 64, Color(RIM_COLOR, 0.85 * fade), 4.0, true)
	game.draw_arc(center, 20.0 + enter_u * 180.0, 0.0, TAU, 48, Color(GLOW_COLOR, 0.6 * fade), 7.0, true)


static func _draw_labels(game: Node2D, center: Vector2, controller, near: bool, unstable: bool, t: float) -> void:
	var title_color := Color(0.94, 0.84, 1.0)
	var title_pos: Vector2 = center + Vector2(0.0, -HALF_HEIGHT - 52.0 + sin(t * 2.0) * 3.0)
	var outline := Color(0.02, 0.0, 0.06, 0.9)
	game._draw_centered_outlined("FENDA DO MERCADOR", title_pos, 18, title_color, outline, 3)
	var status: String = "ENTRE PARA ABRIR A LOJA"
	var status_color := Color(1.0, 0.84, 0.4)
	if unstable:
		status = "INSTAVEL  -%d%% NO LIMITE" % int(round(RiftController.EDGE_BONUS_DISCOUNT * 100.0))
		status_color = Color(1.0, 0.56, 0.38)
	elif near:
		status = "ENTRE!"
	var status_pos: Vector2 = center + Vector2(0.0, HALF_HEIGHT + 44.0)
	game._draw_centered_outlined(status, status_pos, 15, status_color, outline, 3)
	var ring_center: Vector2 = center + Vector2(0.0, HALF_HEIGHT + 70.0)
	var ratio: float = controller.life_ratio()
	game.draw_arc(ring_center, 9.0, 0.0, TAU, 28, Color(0.0, 0.0, 0.0, 0.55), 4.0, true)
	game.draw_arc(ring_center, 9.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 28, Color(status_color, 0.95), 3.0, true)
	var fragments: int = int(game.shop_rift_fragments)
	if fragments > 0:
		game._draw_centered_outlined("+%d FRAGMENTO%s" % [fragments, "S" if fragments > 1 else ""], center + Vector2(0.0, -HALF_HEIGHT - 30.0), 12, Color(1.0, 0.82, 0.36, 0.92), outline, 2)
