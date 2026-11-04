class_name RTMistGuidePresentation
extends RefCounted

## Nevoa-guia compartilhada: uma corrente de nevoa ancorada no chao que sai do
## jogador e flui ate um alvo (altar, Fenda do Mercador), mais um marcador de
## borda de tela quando o alvo esta fora da camera. Tudo e procedural e sem
## estado: as particulas derivam do tempo, entao nao ha custo de alocacao.

const PALETTE_ALTAR := {
	"haze": Color(0.2, 0.86, 1.0),
	"core": Color(0.78, 1.0, 0.98),
	"mote": Color(1.0, 0.7, 0.26),
	"label": "ALTAR",
}
const PALETTE_RIFT := {
	"haze": Color(0.58, 0.3, 1.0),
	"core": Color(1.0, 0.66, 0.96),
	"mote": Color(1.0, 0.84, 0.38),
	"label": "FENDA",
}
const PALETTE_RIFT_UNSTABLE := {
	"haze": Color(0.92, 0.28, 0.5),
	"core": Color(1.0, 0.72, 0.6),
	"mote": Color(1.0, 0.56, 0.24),
	"label": "FENDA",
}

const FLOW_SPEED := 150.0
const MAX_GUIDE_LENGTH := 1250.0
const START_OFFSET := 36.0
const END_OFFSET := 70.0
const EDGE_MARGIN := 62.0
## Faixas reservadas ao HUD (paineis do topo e barra de habilidades/controles).
const EDGE_MARGIN_TOP := 116.0
const EDGE_MARGIN_BOTTOM := 124.0
const UNITS_PER_METER := 40.0
const BLOB_TEXTURE_SIZE := 128

static var _blob: Texture2D = null


static func blob_texture() -> Texture2D:
	if _blob != null:
		return _blob
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.38, Color(1.0, 1.0, 1.0, 0.55))
	gradient.add_point(0.7, Color(1.0, 1.0, 1.0, 0.14))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = BLOB_TEXTURE_SIZE
	texture.height = BLOB_TEXTURE_SIZE
	_blob = texture
	return _blob


static func palette_for(kind: String, unstable: bool = false) -> Dictionary:
	if kind == "rift":
		return PALETTE_RIFT_UNSTABLE if unstable else PALETTE_RIFT
	return PALETTE_ALTAR


static func _hash(value: float) -> float:
	return fposmod(sin(value * 12.9898 + 78.233) * 43758.5453, 1.0)


static func draw_blob(ci: CanvasItem, center: Vector2, size: Vector2, color: Color) -> void:
	if color.a <= 0.004:
		return
	ci.draw_texture_rect(blob_texture(), Rect2(center - size * 0.5, size), false, color)


## Blob alongado e girado (corrente de nevoa seguindo a tangente do caminho).
static func draw_streak(ci: CanvasItem, center: Vector2, size: Vector2, angle: float, color: Color) -> void:
	if color.a <= 0.004:
		return
	ci.draw_set_transform(center, angle, Vector2.ONE)
	ci.draw_texture_rect(blob_texture(), Rect2(-size * 0.5, size), false, color)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _bezier(a: Vector2, control: Vector2, b: Vector2, u: float) -> Vector2:
	var inv: float = 1.0 - u
	return a * (inv * inv) + control * (2.0 * inv * u) + b * (u * u)


static func _bezier_tangent(a: Vector2, control: Vector2, b: Vector2, u: float) -> Vector2:
	var tangent: Vector2 = (control - a) * (2.0 * (1.0 - u)) + (b - control) * (2.0 * u)
	return tangent.normalized() if tangent.length_squared() > 0.0001 else (b - a).normalized()


## Corrente de nevoa no chao, do jogador ate o alvo. Desenhar na camada de mundo.
static func draw_floor(game: Node2D, camera: Vector2, viewport: Vector2, target_world: Vector2, palette: Dictionary, intensity: float = 1.0, noise_seed: float = 0.0) -> void:
	var origin: Vector2 = Vector2(game.player_pos)
	var to_target: Vector2 = target_world - origin
	var distance: float = to_target.length()
	if distance <= START_OFFSET + END_OFFSET + 24.0 or intensity <= 0.01:
		return
	var direction: Vector2 = to_target / distance
	var normal: Vector2 = direction.orthogonal()
	var reach: float = minf(distance - END_OFFSET, MAX_GUIDE_LENGTH)
	var a: Vector2 = origin + direction * START_OFFSET - camera
	var b: Vector2 = origin + direction * reach - camera
	var t: float = float(game.time_alive)
	var sway: float = sin(t * 0.34 + noise_seed) * minf(150.0, reach * 0.2) + sin(t * 0.81 + noise_seed * 1.7) * 26.0
	var control: Vector2 = a.lerp(b, 0.5) + normal * sway
	var low: bool = game._runtime_visual_budget_active() or bool(game.gfx_low_resource)
	var haze_count: int = 11 if low else 20
	var core_count: int = 8 if low else 16
	var mote_count: int = 5 if low else 12
	var cull_rect := Rect2(Vector2(-160.0, -160.0), viewport + Vector2(320.0, 320.0))
	var length_scale: float = maxf(240.0, reach)
	var haze: Color = palette.get("haze", Color.WHITE)
	var core_color: Color = palette.get("core", Color.WHITE)
	var mote: Color = palette.get("mote", Color.WHITE)
	# Camada 1: veu largo e lento, da volume a nevoa.
	for index in range(haze_count):
		var h: float = _hash(float(index) + noise_seed)
		var u: float = fposmod(t * FLOW_SPEED * 0.55 / length_scale + float(index) / float(haze_count) + h * 0.07, 1.0)
		var point: Vector2 = _bezier(a, control, b, u)
		if not cull_rect.has_point(point):
			continue
		var tangent: Vector2 = _bezier_tangent(a, control, b, u)
		var side: Vector2 = tangent.orthogonal()
		var spread: float = 18.0 + 36.0 * sin(PI * u)
		point += side * sin(t * 0.7 + h * TAU) * spread
		var fade: float = smoothstep(0.0, 0.06, u) * (1.0 - smoothstep(0.72, 1.0, u))
		var size: float = lerpf(96.0, 168.0, h) * (0.78 + 0.32 * sin(PI * u))
		var angle: float = tangent.angle()
		# Sombra suave por baixo: separa a nevoa de chaos claros ou saturados.
		draw_streak(game, point + Vector2(0.0, 8.0), Vector2(size * 2.0, size * 0.75), angle, Color(0.01, 0.0, 0.04, 0.14 * fade * intensity))
		draw_streak(game, point, Vector2(size * 2.1, size * 0.7), angle, Color(haze.lightened(0.3), 0.3 * fade * intensity))
	# Camada 2: fios brilhantes, a corrente que "puxa" o jogador.
	for index in range(core_count):
		var h2: float = _hash(float(index) * 3.17 + noise_seed + 11.0)
		var u2: float = fposmod(t * FLOW_SPEED / length_scale + float(index) / float(core_count) + h2 * 0.05, 1.0)
		var point2: Vector2 = _bezier(a, control, b, u2)
		if not cull_rect.has_point(point2):
			continue
		var tangent2: Vector2 = _bezier_tangent(a, control, b, u2)
		point2 += tangent2.orthogonal() * sin(t * 1.9 + h2 * TAU + u2 * 9.0) * (5.0 + 10.0 * u2)
		var fade2: float = smoothstep(0.0, 0.05, u2) * (1.0 - smoothstep(0.82, 1.0, u2))
		var size2: float = lerpf(34.0, 54.0, h2)
		var angle2: float = tangent2.angle()
		draw_streak(game, point2, Vector2(size2 * 2.6, size2 * 0.62), angle2, Color(core_color, 0.55 * fade2 * intensity))
		draw_streak(game, point2, Vector2(size2 * 1.3, size2 * 0.24), angle2, Color(1.0, 1.0, 1.0, 0.5 * fade2 * intensity))
	# Camada 3: centelhas que piscam ao longo do caminho.
	for index in range(mote_count):
		var h3: float = _hash(float(index) * 7.31 + noise_seed + 23.0)
		var u3: float = fposmod(t * FLOW_SPEED * 1.25 / length_scale + float(index) / float(mote_count) + h3 * 0.11, 1.0)
		var point3: Vector2 = _bezier(a, control, b, u3)
		if not cull_rect.has_point(point3):
			continue
		var side3: Vector2 = _bezier_tangent(a, control, b, u3).orthogonal()
		point3 += side3 * (h3 - 0.5) * 46.0 + Vector2(0.0, -sin(t * 2.2 + h3 * TAU) * 6.0)
		var twinkle: float = 0.55 + 0.45 * sin(t * 6.0 + h3 * 31.0)
		var fade3: float = smoothstep(0.0, 0.12, u3) * (1.0 - smoothstep(0.85, 1.0, u3))
		var alpha3: float = 0.75 * fade3 * twinkle * intensity
		if alpha3 <= 0.02:
			continue
		draw_blob(game, point3, Vector2(22.0, 22.0), Color(mote, alpha3 * 0.8))
		game.draw_circle(point3, 2.0 + h3 * 1.4, Color(mote.lightened(0.5), alpha3))
	# Redemoinho nos pes do jogador: a nevoa "nasce" de quem ela guia.
	var feet: Vector2 = origin - camera + Vector2(0.0, 18.0)
	var feet_count: int = 3 if low else 5
	for index in range(feet_count):
		var feet_angle: float = t * 2.2 + float(index) * TAU / float(feet_count)
		var feet_radius: float = 22.0 + 6.0 * sin(t * 3.0 + float(index))
		draw_blob(game, feet + Vector2(cos(feet_angle) * feet_radius, sin(feet_angle) * feet_radius * 0.4), Vector2(34.0, 16.0), Color(core_color, 0.3 * intensity))
	# Quando o alvo ja esta perto, a nevoa se enrola em espiral em volta dele.
	if distance <= MAX_GUIDE_LENGTH + END_OFFSET:
		draw_vortex(game, target_world - camera, palette, intensity * (1.0 - smoothstep(MAX_GUIDE_LENGTH * 0.7, MAX_GUIDE_LENGTH + END_OFFSET, distance)), noise_seed, low)


## Espiral de nevoa sendo sugada para o alvo.
static func draw_vortex(game: Node2D, center: Vector2, palette: Dictionary, intensity: float, noise_seed: float, low: bool) -> void:
	if intensity <= 0.01:
		return
	var t: float = float(game.time_alive)
	var count: int = 7 if low else 14
	var haze: Color = palette.get("haze", Color.WHITE)
	var core_color: Color = palette.get("core", Color.WHITE)
	for index in range(count):
		var h: float = _hash(float(index) * 5.3 + noise_seed + 41.0)
		var u: float = fposmod(t * 0.42 + float(index) / float(count) + h * 0.1, 1.0)
		var radius: float = lerpf(150.0, 26.0, u)
		var angle: float = t * 1.25 + float(index) * TAU / float(count) + u * 2.4
		var point: Vector2 = center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.46)
		var fade: float = smoothstep(0.0, 0.2, u) * (1.0 - smoothstep(0.8, 1.0, u))
		var size: float = lerpf(70.0, 30.0, u)
		var tint: Color = haze.lerp(core_color, u)
		draw_blob(game, point, Vector2(size * 1.3, size * 0.7), Color(tint, 0.42 * fade * intensity))


## Marcador de borda com a direcao do alvo. Desenhar na camada de HUD.
## ring_ratio < 0 esconde o anel de tempo.
static func draw_edge_marker(game: Node2D, camera: Vector2, viewport: Vector2, target_world: Vector2, palette: Dictionary, ring_ratio: float = -1.0, urgent: bool = false) -> void:
	var screen_target: Vector2 = target_world - camera
	var on_screen := Rect2(Vector2(EDGE_MARGIN, EDGE_MARGIN), viewport - Vector2(EDGE_MARGIN, EDGE_MARGIN) * 2.0)
	if on_screen.has_point(screen_target):
		return
	var safe := Rect2(Vector2(EDGE_MARGIN, EDGE_MARGIN_TOP), viewport - Vector2(EDGE_MARGIN * 2.0, EDGE_MARGIN_TOP + EDGE_MARGIN_BOTTOM))
	var start: Vector2 = Vector2(game.player_pos) - camera
	var to_target: Vector2 = screen_target - start
	if to_target.length_squared() <= 1.0:
		return
	var direction: Vector2 = to_target.normalized()
	var edge: float = _edge_distance(start, direction, safe)
	var t: float = float(Time.get_ticks_msec()) * 0.001
	var pulse_speed: float = 7.5 if urgent else 3.2
	var bob: float = (0.5 + 0.5 * sin(t * pulse_speed)) * 7.0
	var anchor: Vector2 = start + direction * maxf(40.0, edge - bob)
	var haze: Color = palette.get("haze", Color.WHITE)
	var core_color: Color = palette.get("core", Color.WHITE)
	var mote: Color = palette.get("mote", Color.WHITE)
	var glow: float = 0.72 + 0.28 * sin(t * pulse_speed)
	draw_blob(game, anchor, Vector2(150.0, 150.0), Color(haze, 0.5 * glow))
	draw_blob(game, anchor, Vector2(70.0, 70.0), Color(core_color, 0.5 * glow))
	game.draw_circle(anchor, 23.0, Color(0.02, 0.02, 0.06, 0.78))
	game.draw_arc(anchor, 23.0, 0.0, TAU, 40, Color(haze.lightened(0.35), 0.95), 2.5, true)
	if ring_ratio >= 0.0:
		var ring_color: Color = mote if not urgent else Color(1.0, 0.46, 0.3)
		game.draw_arc(anchor, 29.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(ring_ratio, 0.0, 1.0), 48, Color(ring_color, 0.92), 3.0, true)
	var side: Vector2 = direction.orthogonal()
	var tip: Vector2 = anchor + direction * 16.0
	var arrow := PackedVector2Array([tip, anchor - direction * 8.0 + side * 11.0, anchor - direction * 2.0, anchor - direction * 8.0 - side * 11.0])
	game.draw_colored_polygon(arrow, Color(core_color.lightened(0.25), 0.96))
	var world_distance: float = target_world.distance_to(Vector2(game.player_pos))
	var label: String = "%s  %dm" % [String(palette.get("label", "")), int(round(world_distance / UNITS_PER_METER))]
	var label_pos: Vector2 = anchor - direction * 50.0
	label_pos.x = clampf(label_pos.x, 70.0, viewport.x - 70.0)
	label_pos.y = clampf(label_pos.y, safe.position.y, safe.end.y)
	game._draw_centered_outlined(label, label_pos, 14, Color(core_color.lightened(0.3), 0.96), Color(0.02, 0.0, 0.06, 0.9), 3)


static func _edge_distance(start: Vector2, direction: Vector2, safe: Rect2) -> float:
	var limit_x: float = INF
	var limit_y: float = INF
	if direction.x > 0.001:
		limit_x = (safe.end.x - start.x) / direction.x
	elif direction.x < -0.001:
		limit_x = (safe.position.x - start.x) / direction.x
	if direction.y > 0.001:
		limit_y = (safe.end.y - start.y) / direction.y
	elif direction.y < -0.001:
		limit_y = (safe.position.y - start.y) / direction.y
	return maxf(0.0, minf(limit_x, limit_y))


## Marcadores de HUD de todos os alvos guiados (altar descoberto e fenda).
static func draw_overlay(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	if game.mode not in ["game", "boss_call", "pause_countdown"]:
		return
	var rift_target: Dictionary = game.shop_rift_controller.guide_target()
	if not rift_target.is_empty():
		var unstable: bool = bool(rift_target.get("unstable", false))
		draw_edge_marker(game, camera, viewport, Vector2(rift_target["pos"]), palette_for("rift", unstable), float(rift_target.get("life_ratio", 1.0)), unstable)
	if altar_guide_visible(game):
		draw_edge_marker(game, camera, viewport, Vector2(game.experimental_boss_altar_pos), PALETTE_ALTAR)


static func altar_guide_visible(game: Node2D) -> bool:
	if not game.experimental_phase_controller.uses_definitive_world():
		return false
	if not bool(game.experimental_boss_altar_discovered) or bool(game.experimental_boss_altar_used):
		return false
	return not bool(game.boss_active) and float(game.boss_call_timer) < 0.0
