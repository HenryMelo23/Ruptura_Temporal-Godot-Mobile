class_name RTRationalVfx
extends RefCounted

## VFX da Racional (Dilatacao Temporal).
## - Pos-processamento: o mundo perde cor e esfria enquanto a Geovana continua
##   viva no centro; borda com aberracao cromatica; onda de choque ao ativar.
## - Rastro de velocidade: copias dela (poses congeladas) e raios estilo
##   "velocista" que seguem o caminho real, regerados 24x/s.
## - Poeira do tempo parada no ar, projeteis inimigos com rastro de lentidao.
## - Fim da dilatacao: o tempo "volta" num anel que implode; o Rebote mostra um
##   relogio regressivo em volta dela.
## So le estado; quem muda o jogo e o AuraSystem.

const LAYER_NAME := "RationalPostProcess"
const RECT_NAME := "Grade"
const BLUE := Color(0.32, 0.9, 1.0)
const GOLD := Color(1.0, 0.86, 0.3)
const AMBER := Color(1.0, 0.52, 0.12)
const AUDIO_SLOW := 0.9
const AUDIO_REBOUND := 1.05

const SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform float amount = 0.0;
uniform float warm = 0.0;
uniform float pulse = 0.0;
uniform float implode = 0.0;
uniform vec2 focus = vec2(0.5);
uniform float aspect = 1.7778;
uniform float hud_top = 0.12;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - focus;
	d.x *= aspect;
	float dist = length(d);
	vec2 dir = dist > 0.0001 ? d / dist : vec2(0.0);
	dir.x /= aspect;
	float hud = smoothstep(hud_top, hud_top + 0.05, SCREEN_UV.y);
	// Onda ao ativar (sai do jogador) e ao terminar (volta para ele).
	float ring_out = (1.0 - pulse) * 1.5;
	float ring_in = implode * 1.3;
	float rip = pulse * exp(-pow((dist - ring_out) * 16.0, 2.0)) + implode * exp(-pow((dist - ring_in) * 16.0, 2.0));
	rip *= hud;
	uv -= dir * rip * 0.02;
	float edge = smoothstep(0.3, 0.95, dist);
	float ca = (amount * 0.004 + warm * 0.0025) * edge * hud;
	vec3 col;
	col.r = texture(screen_texture, uv + dir * ca).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - dir * ca).b;
	float keep = 1.0 - smoothstep(0.06, 0.2, dist);
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 cool = vec3(lum * 0.78, lum * 0.95, lum * 1.15);
	col = mix(col, cool, amount * 0.78 * (1.0 - keep) * hud);
	float vig = smoothstep(0.42, 1.0, dist) * hud;
	col = mix(col, col * 0.5 + vec3(0.0, 0.1, 0.16), vig * amount * 0.7);
	col = mix(col, col * vec3(1.14, 0.96, 0.78), warm * 0.55 * hud);
	col = mix(col, col * 0.62 + vec3(0.18, 0.07, 0.0), vig * warm * 0.55);
	col += mix(vec3(0.55, 0.9, 1.0), vec3(1.0, 0.7, 0.35), implode) * rip * 0.4;
	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
"""


# ------------------------------------------------------------ pos-processamento
static func _rect(game: Node2D, create: bool) -> ColorRect:
	var layer := game.get_node_or_null(LAYER_NAME) as CanvasLayer
	if layer == null:
		if not create:
			return null
		layer = CanvasLayer.new()
		layer.name = LAYER_NAME
		layer.layer = 110
		game.add_child(layer)
	var grade := layer.get_node_or_null(RECT_NAME) as ColorRect
	if grade != null or not create:
		return grade
	grade = ColorRect.new()
	grade.name = RECT_NAME
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(grade)
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	grade.material = mat
	grade.hide()
	return grade


## Chamado no comeco de todo _draw: some com o efeito e com o som lento. O
## apply() do mesmo quadro religa se ainda estiver valendo.
static func reset_frame(game: Node2D) -> void:
	var grade := _rect(game, false)
	if grade != null:
		grade.hide()
	_set_audio(1.0)


static func _set_audio(scale: float) -> void:
	if AudioServer.get("playback_speed_scale") == null:
		return
	if absf(float(AudioServer.get("playback_speed_scale")) - scale) > 0.001:
		AudioServer.set("playback_speed_scale", scale)


static func _state(game: Node2D) -> Dictionary:
	var aura: Dictionary = game.aura_state
	if aura.is_empty() or String(aura.get("name", "")) != "Racional":
		return {}
	var dilation: float = float(aura.get("rational_dilation", 0.0))
	var rebound: float = float(aura.get("rational_rebound", 0.0))
	return {
		"dilation": dilation,
		"rebound": rebound if dilation <= 0.0 else 0.0,
		"flash": clampf(float(game.rational_dilation_flash) / 0.55, 0.0, 1.0),
		"end": clampf(float(game.rational_end_flash) / 0.5, 0.0, 1.0),
	}


static func apply(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	var st := _state(game)
	if st.is_empty():
		return
	var dil: float = float(st["dilation"])
	var reb: float = float(st["rebound"])
	var end_k: float = float(st["end"])
	# Entra/sai suave: 0.35s nas pontas da dilatacao.
	var amount: float = clampf(dil / 0.35, 0.0, 1.0) if dil > 0.0 else 0.0
	var warm: float = clampf(reb / 0.3, 0.0, 1.0) if reb > 0.0 else 0.0
	var pulse: float = float(st["flash"])
	if amount <= 0.001 and warm <= 0.001 and pulse <= 0.001 and end_k <= 0.001:
		return
	if game.mode == "game":
		_set_audio(lerpf(1.0, AUDIO_SLOW, amount) if amount > 0.0 else lerpf(1.0, AUDIO_REBOUND, warm))
	if bool(game.gfx_low_resource):
		return
	var grade := _rect(game, true)
	grade.show()
	var mat := grade.material as ShaderMaterial
	var focus_screen: Vector2 = Vector2(game.player_pos) - camera + Vector2(0.0, -30.0)
	mat.set_shader_parameter("amount", amount)
	mat.set_shader_parameter("warm", warm)
	mat.set_shader_parameter("pulse", pulse)
	mat.set_shader_parameter("implode", end_k)
	mat.set_shader_parameter("focus", focus_screen / viewport)
	mat.set_shader_parameter("aspect", viewport.x / maxf(1.0, viewport.y))
	mat.set_shader_parameter("hud_top", -1.0)


# ------------------------------------------------------------ mundo
static func draw_world(game: Node2D, camera: Vector2, player_screen: Vector2) -> void:
	var st := _state(game)
	if st.is_empty():
		return
	var viewport: Vector2 = game.get_viewport_rect().size
	var t: float = float(game.time_alive)
	var dil: float = float(st["dilation"])
	var reb: float = float(st["rebound"])
	var low: bool = bool(game.gfx_low_resource)
	if dil > 0.0:
		if low:
			game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.2, 0.42, 0.16), true)
		_draw_time_dust(game, camera, viewport, t, clampf(dil / 0.35, 0.0, 1.0))
		_draw_bullet_lag(game, camera)
	_draw_afterimages(game, camera)
	if dil > 0.0:
		_draw_speed_bolts(game, camera, player_screen, t)
	if float(st["flash"]) > 0.0:
		_draw_activation(game, player_screen, float(st["flash"]))
	if float(st["end"]) > 0.0:
		_draw_snap_back(game, player_screen, float(st["end"]))
	if reb > 0.0:
		if low:
			game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.38, 0.14, 0.02, 0.14), true)
		_draw_rebound_clock(game, player_screen, reb, t)
	elif dil > 0.0:
		_draw_dilation_clock(game, player_screen, dil, t)


## Poeira suspensa: quase parada, em paralaxe com a camera.
static func _draw_time_dust(game: Node2D, camera: Vector2, viewport: Vector2, t: float, k: float) -> void:
	for i in range(42):
		var hx: float = fposmod(float(i) * 0.6180339 * 977.0, 1.0)
		var hy: float = fposmod(float(i) * 0.4142135 * 631.0, 1.0)
		var depth: float = 0.35 + fposmod(float(i) * 0.37, 0.65)
		var x: float = fposmod(hx * (viewport.x + 80.0) - camera.x * depth * 0.25 + t * 3.0 * depth, viewport.x + 80.0) - 40.0
		var y: float = fposmod(hy * (viewport.y + 80.0) - camera.y * depth * 0.25 + sin(t * 0.4 + float(i)) * 6.0, viewport.y + 80.0) - 40.0
		var a: float = (0.18 + 0.22 * depth) * k
		var r: float = 1.0 + depth * 2.2
		game.draw_circle(Vector2(x, y), r * 2.4, Color(BLUE.r, BLUE.g, BLUE.b, a * 0.18))
		game.draw_circle(Vector2(x, y), r, Color(0.85, 0.97, 1.0, a))


## Projeteis inimigos esticados: leem como "quase parados" no ar.
static func _draw_bullet_lag(game: Node2D, camera: Vector2) -> void:
	for bullet in game.enemy_bullets:
		var p: Vector2 = Vector2(bullet.get("pos", Vector2.ZERO)) - camera
		var dir: Vector2 = Vector2(bullet.get("dir", Vector2.ZERO))
		if dir.length() < 0.01:
			continue
		dir = dir.normalized()
		for j in range(3):
			var a: float = 0.22 - float(j) * 0.06
			game.draw_line(p - dir * (8.0 + j * 12.0), p - dir * (20.0 + j * 12.0), Color(0.75, 0.95, 1.0, a), 4.0 - j, true)


## Copias dela nas poses que ja passaram (o "duplicado" leve ao se mover).
static func _draw_afterimages(game: Node2D, camera: Vector2) -> void:
	var points: Array = game.rational_trail_points
	if points.size() < 2:
		return
	var profile: Dictionary = game._player_draw_profile()
	var drawn := 0
	var last_pos: Vector2 = game.player_pos
	for i in range(points.size() - 1, -1, -1):
		var point: Dictionary = points[i]
		var pos: Vector2 = Vector2(point.get("pos", game.player_pos))
		if pos.distance_to(last_pos) < 24.0:
			continue
		var ratio: float = clampf(float(point.get("life", 0.0)) / maxf(0.01, float(point.get("max", 1.0))), 0.0, 1.0)
		var tex: Texture2D = point.get("tex", null)
		if tex == null:
			tex = game._player_texture()
		var k: float = float(drawn) / 4.0
		var tint: Color = BLUE.lerp(Color(0.62, 0.42, 1.0), k)
		tint.a = 0.62 * ratio * (1.0 - k * 0.4)
		var flip: bool = bool(point.get("flip", false))
		_draw_ghost(game, tex, pos - camera + Vector2(3.0, 0.0), profile, Color(1.0, 0.85, 0.3, tint.a * 0.45), flip)
		_draw_ghost(game, tex, pos - camera, profile, tint, flip)
		last_pos = pos
		drawn += 1
		if drawn >= 4:
			break


static func _draw_ghost(game: Node2D, tex: Texture2D, ground: Vector2, profile: Dictionary, tint: Color, flip: bool) -> void:
	if tex == null or tint.a <= 0.01:
		return
	var center: Vector2 = ground + Vector2(profile.get("offset", Vector2.ZERO))
	if bool(profile.get("preserve_height", false)):
		game._draw_entity_by_height_rotated(tex, center, float(profile.get("height", 92.0)), 0.0, tint, flip)
	elif bool(profile.get("fit_aspect", false)):
		game._draw_entity_fit_flipped(tex, center, profile["size"], flip, tint, true)
	else:
		game._draw_entity_stretched_rotated(tex, center, profile["size"], 0.0, tint, flip)


## Raios do velocista: seguem o caminho percorrido, nascem do corpo dela e
## mudam de forma 24 vezes por segundo. Afinam e somem na cauda. So aparecem
## quando ela corre.
static func _draw_speed_bolts(game: Node2D, camera: Vector2, player_screen: Vector2, t: float) -> void:
	var points: Array = game.rational_trail_points
	if points.size() < 3:
		_draw_body_crackle(game, player_screen, t, 0.45)
		return
	var path := PackedVector2Array()
	path.append(Vector2(game.player_pos) - camera)
	var length := 0.0
	for i in range(points.size() - 1, -1, -1):
		var p: Vector2 = Vector2(points[i].get("pos", game.player_pos)) - camera
		if p.distance_to(path[path.size() - 1]) < 6.0:
			continue
		length += p.distance_to(path[path.size() - 1])
		path.append(p)
		if length > 150.0:
			break
	var speed_k: float = clampf(length / 110.0, 0.0, 1.0)
	_draw_body_crackle(game, player_screen, t, 0.45 + speed_k * 0.55)
	if speed_k < 0.2 or path.size() < 3:
		return
	var tick: int = int(t * 24.0)
	var rng := RandomNumberGenerator.new()
	for b in range(2):
		rng.seed = tick * 7919 + b * 104729
		var lift: float = -46.0 + float(b) * 22.0
		var bolt := PackedVector2Array()
		for i in range(path.size()):
			var a: Vector2 = path[i] + Vector2(0.0, lift)
			if i > 0:
				var prev: Vector2 = path[i - 1] + Vector2(0.0, lift)
				var seg: Vector2 = a - prev
				var n: Vector2 = seg.orthogonal().normalized() if seg.length() > 0.5 else Vector2.UP
				var spread: float = 3.0 + 9.0 * float(i) / float(path.size())
				bolt.append(prev.lerp(a, 0.5) + n * rng.randf_range(-spread, spread))
			bolt.append(a)
		var outer: Color = GOLD if b == 0 else Color(0.55, 0.95, 1.0)
		var n_seg: int = bolt.size() - 1
		for i in range(n_seg):
			var k: float = (1.0 - float(i) / float(n_seg)) * speed_k
			var a0: Vector2 = bolt[i]
			var a1: Vector2 = bolt[i + 1]
			game.draw_line(a0, a1, Color(outer.r, outer.g, outer.b, 0.22 * k), 9.0 * k + 2.0, true)
			game.draw_line(a0, a1, Color(outer.r, outer.g, outer.b, 0.9 * k), 3.0 * k + 0.8, true)
			game.draw_line(a0, a1, Color(1.0, 1.0, 0.95, k), 1.2, true)
		# Um galho curto perto do corpo.
		var at: Vector2 = bolt[mini(2, bolt.size() - 1)]
		var ang: float = rng.randf_range(0.0, TAU)
		var mid: Vector2 = at + Vector2.from_angle(ang) * rng.randf_range(8.0, 14.0)
		var tip: Vector2 = mid + Vector2.from_angle(ang + rng.randf_range(-0.9, 0.9)) * rng.randf_range(6.0, 10.0)
		game.draw_polyline(PackedVector2Array([at, mid, tip]), Color(outer.r, outer.g, outer.b, 0.85 * speed_k), 1.6, true)


## Faisca curta pulando pelo corpo (mesmo parada ela "zumbe").
static func _draw_body_crackle(game: Node2D, center: Vector2, t: float, k: float) -> void:
	var tick: int = int(t * 18.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = tick * 31337
	var body: Vector2 = center + Vector2(0.0, -36.0)
	for i in range(2):
		if rng.randf() > 0.75:
			continue
		var a: float = rng.randf_range(0.0, TAU)
		var start: Vector2 = body + Vector2(cos(a) * 20.0, sin(a) * 34.0)
		var pts := PackedVector2Array([start])
		var p: Vector2 = start
		for s in range(3):
			p += Vector2.from_angle(a + rng.randf_range(-1.2, 1.2)) * rng.randf_range(5.0, 9.0)
			pts.append(p)
		var c: Color = GOLD if i == 0 else BLUE
		game.draw_polyline(pts, Color(c.r, c.g, c.b, 0.9 * k), 1.6, true)


## Ao ativar: o tempo "trava" num anel de relogio que se expande.
static func _draw_activation(game: Node2D, center: Vector2, k: float) -> void:
	var u: float = 1.0 - k
	var r: float = lerpf(20.0, 520.0, 1.0 - pow(1.0 - u, 3.0))
	game.draw_circle(center, lerpf(70.0, 10.0, u), Color(1.0, 1.0, 1.0, 0.55 * k * k))
	game.draw_arc(center, r, 0.0, TAU, 96, Color(BLUE.r, BLUE.g, BLUE.b, 0.9 * k), 5.0 * k + 1.0, true)
	game.draw_arc(center, r * 0.86, 0.0, TAU, 96, Color(GOLD.r, GOLD.g, GOLD.b, 0.5 * k), 2.0, true)
	for i in range(12):
		var ang: float = float(i) * TAU / 12.0
		var len: float = 18.0 if i % 3 == 0 else 9.0
		game.draw_line(center + Vector2.from_angle(ang) * (r - len), center + Vector2.from_angle(ang) * (r + 2.0), Color(1.0, 1.0, 1.0, 0.85 * k), 2.5 if i % 3 == 0 else 1.5)
	# Ponteiros girando para tras e parando.
	var hand: float = -PI * 0.5 - u * TAU * 1.5
	game.draw_line(center + Vector2(0, -34), center + Vector2(0, -34) + Vector2.from_angle(hand) * 30.0, Color(1.0, 1.0, 1.0, 0.9 * k), 3.0)
	game.draw_line(center + Vector2(0, -34), center + Vector2(0, -34) + Vector2.from_angle(hand * 0.25) * 20.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.9 * k), 3.0)


## Fim da dilatacao: o mundo inteiro volta e se fecha nela.
static func _draw_snap_back(game: Node2D, center: Vector2, k: float) -> void:
	var r: float = lerpf(18.0, 460.0, k * k)
	game.draw_arc(center, r, 0.0, TAU, 96, Color(AMBER.r, AMBER.g, AMBER.b, 0.85 * k), 4.0, true)
	game.draw_arc(center, r * 1.12, 0.0, TAU, 96, Color(1.0, 0.85, 0.5, 0.35 * k), 2.0, true)
	for i in range(16):
		var ang: float = float(i) * TAU / 16.0
		game.draw_line(center + Vector2.from_angle(ang) * (r + 10.0), center + Vector2.from_angle(ang) * (r + 34.0), Color(1.0, 0.7, 0.3, 0.6 * k), 2.0)


## Durante a dilatacao: relogio discreto sob os pes mostrando quanto falta.
static func _draw_dilation_clock(game: Node2D, center: Vector2, dil: float, t: float) -> void:
	var total: float = float(game.AuraSystem.RATIONAL_DILATION_TIME)
	var frac: float = clampf(dil / maxf(0.01, total), 0.0, 1.0)
	var foot: Vector2 = center + Vector2(0.0, 30.0)
	game.draw_set_transform(foot, 0.0, Vector2(1.0, 0.36))
	game.draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 48, Color(BLUE.r, BLUE.g, BLUE.b, 0.22), 2.0, true)
	game.draw_arc(Vector2.ZERO, 46.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, Color(BLUE.r, BLUE.g, BLUE.b, 0.85), 4.0, true)
	for i in range(12):
		var ang: float = float(i) * TAU / 12.0 + t * 0.3
		game.draw_line(Vector2.from_angle(ang) * 52.0, Vector2.from_angle(ang) * 58.0, Color(0.85, 0.97, 1.0, 0.5), 2.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Rebote: o tempo corre mais rapido. Relogio ambar regressivo + setas.
static func _draw_rebound_clock(game: Node2D, center: Vector2, reb: float, t: float) -> void:
	var total: float = float(game.AuraSystem.RATIONAL_REBOUND_TIME)
	var frac: float = clampf(reb / maxf(0.01, total), 0.0, 1.0)
	var foot: Vector2 = center + Vector2(0.0, 30.0)
	game.draw_set_transform(foot, 0.0, Vector2(1.0, 0.36))
	game.draw_arc(Vector2.ZERO, 50.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, Color(AMBER.r, AMBER.g, AMBER.b, 0.95), 5.0, true)
	for i in range(3):
		var ang: float = -t * 6.0 + float(i) * TAU / 3.0
		var p: Vector2 = Vector2.from_angle(ang) * 62.0
		var d: Vector2 = Vector2.from_angle(ang - PI * 0.5)
		for c in range(2):
			var tip: Vector2 = p + d * (6.0 + c * 7.0)
			game.draw_line(tip - d * 6.0 + d.orthogonal() * 5.0, tip, Color(1.0, 0.75, 0.35, 0.85), 2.5)
			game.draw_line(tip - d * 6.0 - d.orthogonal() * 5.0, tip, Color(1.0, 0.75, 0.35, 0.85), 2.5)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	game._draw_centered_outlined("REBOTE %.1fs" % reb, center + Vector2(0.0, -96.0), 13, Color(1.0, 0.8, 0.45), Color(0.0, 0.0, 0.0, 0.85), 3)
