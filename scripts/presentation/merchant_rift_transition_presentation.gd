class_name MerchantRiftTransitionPresentation
extends RefCounted

## Desenha a Geovana entrando e saindo da Fenda do Mercador (ver
## RTMerchantRiftTransition). So le o estado do controlador; nao muda nada.
##
## Funciona hoje com o sprite atual do personagem animado por transformacao
## (posicao, giro, escala). Quando existirem quadros dedicados em
##   res://assets/sprites/player/rift/<humor>_<fase>_<n>.png
## (ex.: scared_land_0.png, scared_land_1.png...) eles substituem o sprite
## base naquela fase, e a presentation deixa de girar o corpo (a pose vem da
## arte). Humores: scared, resigned, stylish, ejected. Fases: dive, land,
## exit_dive, emerge.

const Transition := preload("res://scripts/systems/shop/merchant_rift_transition.gd")
const SPRITE_DIR := "res://assets/sprites/player/rift/"
const MAX_FRAMES := 12
const FX_DIR := "res://assets/sprites/rift_fx/"
## Caixa dos quadros dedicados (tools/rift_slice.py), em unidades da altura
## da Geovana em pe: o png tem FRAME_BOX_H alturas e os pes ficam a
## FRAME_FOOT_PAD da base.
const FRAME_BOX_H := 1.34
const FRAME_FOOT_PAD := 0.08
## Quantos quadros de cada fase acontecem no ar (antes de tocar o chao). 0 =
## a fase nao tem quadro de queda: reaproveita o ultimo do mergulho.
const AIRBORNE_FRAMES := {
	"scared_land": 0, "resigned_land": 1, "stylish_land": 0,
	"scared_emerge": 1, "resigned_emerge": 1, "stylish_emerge": 2, "ejected_emerge": 1,
}

const RIFT_GLOW := Color(0.86, 0.6, 1.0)
const RIFT_CYAN := Color(0.4, 0.95, 1.0)
const GOLD := Color(1.0, 0.84, 0.36)

static var _frame_cache: Dictionary = {}


## Retorna true quando a cena desenhou o jogador (o desenho normal e pulado).
static func draw_player(game: Node2D, camera: Vector2) -> bool:
	var tr = game.rift_transition
	if tr == null:
		return false
	# Onda do empurrao continua visivel mesmo depois que ela some na fenda.
	if not tr.pushes.is_empty():
		_draw_shockwave(game, Vector2(tr.target) - camera, clampf(tr.push_t / Transition.PUSH_TIME, 0.0, 1.0))
	if not tr.busy():
		return false
	var tex: Texture2D = game._player_texture()
	if tex == null:
		return false
	var profile: Dictionary = game._player_draw_profile()
	var height: float = float(profile.get("height", 0.0)) if bool(profile.get("preserve_height", false)) else Vector2(profile.get("size", Vector2(66.0, 92.0))).y
	height = maxf(48.0, height)
	var foot: Vector2 = Vector2(game.player_pos) - camera + Vector2(profile.get("offset", Vector2.ZERO)) + Vector2(0.0, float(game.PLAYER_DRAW_BOX_SIZE.y) * 0.5)
	var flip: bool = game._should_flip_player_sprite()
	var pose: Dictionary = _pose(tr, game, height)
	var custom: Array = _frames(String(tr.mood), String(tr.phase)) if game.active_character_key == game.CHARACTER_GEOVANA else []
	var phase: String = String(tr.phase)
	var p: float = tr.progress()
	var ip: float = tr.impact_time()
	var now: float = float(game.time_alive)
	var body_h: float = height
	var foot_pad: float = 0.0
	if not custom.is_empty():
		# Quadro dedicado: a pose (giro, deitada, agachada) vem da arte. O
		# codigo so mantem o voo (altura), o encolher no portal e a cor.
		var idx: int = _custom_index(String(tr.mood), phase, custom.size(), p, ip)
		var keep_rot: bool = false
		if idx < 0:
			# Queda sem quadro proprio: segue com o ultimo quadro do mergulho,
			# girando, como se ainda viesse caindo pelo tunel.
			var dive_frames: Array = _frames(String(tr.mood), Transition.PHASE_DIVE)
			tex = dive_frames.back() if not dive_frames.is_empty() else custom[0]
			keep_rot = true
		else:
			tex = custom[idx]
		if not keep_rot:
			pose["rot"] = 0.0
		var off: Vector2 = Vector2(pose.get("offset", Vector2.ZERO))
		pose["offset"] = Vector2(off.x, minf(off.y, 0.0))
		var sc: Vector2 = Vector2(pose.get("scale", Vector2.ONE))
		pose["scale"] = Vector2.ONE * minf(1.0, minf(sc.x, sc.y))
		body_h = height * FRAME_BOX_H
		foot_pad = height * FRAME_FOOT_PAD
	# Tunel entre as duas pontas da fenda: fim do mergulho / inicio da queda.
	_draw_tunnel(game, phase, p, now)
	# Sem buraco proprio na entrada/saida: a fenda do mundo e o portal de
	# saida da oficina ja estao desenhados ali (ficava um portal em cima do
	# outro). _draw_floor_hole fica para cenas sem portal no local.
	# Rasgo no ceu/ar de onde ela cai ou sai.
	var tear_k: float = float(pose.get("tear", 0.0))
	if tear_k > 0.01:
		var open_k: float = clampf(p / 0.1, 0.0, 1.0) if (phase == Transition.PHASE_LAND or phase == Transition.PHASE_EMERGE) else 1.0
		_draw_tear(game, foot + Vector2(pose.get("tear_offset", Vector2(0.0, -380.0))), tear_k, now, open_k, height)
	var offset: Vector2 = Vector2(pose.get("offset", Vector2.ZERO))
	var scale: Vector2 = Vector2(pose.get("scale", Vector2.ONE))
	var alpha: float = float(pose.get("alpha", 1.0))
	var airborne: float = clampf(-offset.y / 260.0, 0.0, 1.0)
	_draw_shadow(game, foot, (1.0 - airborne * 0.7) * alpha * minf(scale.x, 1.0), 1.0 - airborne * 0.5)
	if float(pose.get("dust", 0.0)) > 0.01:
		_draw_dust(game, foot, float(pose["dust"]), height)
	if float(pose.get("ring", 0.0)) > 0.01:
		_draw_hero_ring(game, foot, float(pose["ring"]), height, now)
	var center: Vector2 = foot + offset + Vector2(0.0, (foot_pad - body_h * 0.5) * scale.y)
	var mid: Vector2 = foot + offset + Vector2(0.0, -height * 0.5 * scale.y)
	var falling: bool = (phase == Transition.PHASE_LAND) and p < ip and String(tr.mood) != Transition.MOOD_RESIGNED
	if falling:
		_draw_speed(game, mid, height, now, alpha)
	_draw_body(game, tex, center, body_h, float(pose.get("rot", 0.0)), scale, alpha, flip, Color(pose.get("tint", Color.WHITE)))
	if (phase == Transition.PHASE_LAND or phase == Transition.PHASE_EMERGE) and p >= ip:
		_draw_impact_flash(game, foot, height, (p - ip) / maxf(0.01, 1.0 - ip))
	var head: Vector2 = foot + offset + Vector2(0.0, -height * 0.92 * scale.y)
	if float(pose.get("stars", 0.0)) > 0.01:
		_draw_dizzy_stars(game, head, float(pose["stars"]), now, height)
	if float(pose.get("sweat", 0.0)) > 0.01:
		_draw_sweat(game, head, float(pose["sweat"]), now, flip, height)
	if float(pose.get("sigh", 0.0)) > 0.01:
		_draw_sigh(game, head, float(pose["sigh"]), flip, height)
	if float(pose.get("glint", 0.0)) > 0.01:
		_draw_glints(game, mid, height, float(pose["glint"]), now)
	return true


## Qual quadro dedicado mostrar. Nas fases com impacto os quadros "no ar"
## cobrem o trecho antes de tocar o chao e o resto cobre o depois, para o
## quadro de queda nunca aparecer com ela ja no chao (e vice-versa).
static func _custom_index(mood: String, phase: String, n: int, p: float, ip: float) -> int:
	var key: String = mood + "_" + phase
	if not AIRBORNE_FRAMES.has(key) or ip <= 0.0 or ip >= 1.0:
		return clampi(int(floor(p * float(n))), 0, n - 1)
	var a: int = mini(int(AIRBORNE_FRAMES[key]), n - 1)
	if p < ip:
		if a == 0:
			return -1
		return clampi(int(floor(p / ip * float(a))), 0, a - 1)
	var w: float = (p - ip) / maxf(0.001, 1.0 - ip)
	return clampi(a + int(floor(w * float(n - a))), a, n - 1)


# ------------------------------------------------------------------ coreografia
static func _pose(tr, game: Node2D, height: float) -> Dictionary:
	var p: float = tr.progress()
	var now: float = float(game.time_alive)
	match String(tr.phase):
		Transition.PHASE_DIVE:
			return _pose_dive(String(tr.mood), p, now)
		Transition.PHASE_LAND:
			return _pose_land(String(tr.mood), p, tr.impact_time(), now, height)
		Transition.PHASE_EXIT_DIVE:
			return _pose_exit(String(tr.mood), p, now)
		Transition.PHASE_EMERGE:
			return _pose_emerge(String(tr.mood), p, tr.impact_time(), now, height)
	return {}


static func _pose_dive(mood: String, p: float, now: float) -> Dictionary:
	match mood:
		Transition.MOOD_SCARED:
			if p < 0.4:
				# Arrastada, tentando resistir: inclinada para tras, tremendo.
				return {"offset": Vector2(sin(now * 60.0) * 3.0, 0.0), "rot": -0.26 + sin(now * 30.0) * 0.05, "sweat": 1.0}
			if p < 0.8:
				var u: float = (p - 0.4) / 0.4
				return {"offset": Vector2(0.0, -u * 60.0), "rot": -0.26 + u * u * TAU * 1.5, "scale": Vector2.ONE * (1.0 - u * 0.35), "sweat": 1.0 - u}
			var v: float = (p - 0.8) / 0.2
			var s: float = 0.65 * (1.0 - v)
			return {"offset": Vector2(0.0, -60.0 + v * 40.0), "rot": -0.26 + TAU * 1.5 + v * PI, "scale": Vector2(s * 0.6, s * 1.35), "alpha": 1.0 - v * 0.4, "tint": RIFT_GLOW.lerp(Color.WHITE, 1.0 - v)}
		Transition.MOOD_RESIGNED:
			if p < 0.55:
				return {"offset": Vector2(0.0, -absf(sin(now * 12.0)) * 3.0), "rot": sin(now * 12.0) * 0.05}
			if p < 0.72:
				var u: float = (p - 0.55) / 0.17
				return {"scale": Vector2(1.0 + sin(u * PI) * 0.04, 1.0 - sin(u * PI) * 0.09), "sigh": sin(u * PI)}
			var v: float = (p - 0.72) / 0.28
			# Se deixa cair reto no buraco, de pe, sem drama.
			return {"offset": Vector2(0.0, v * v * 46.0), "scale": Vector2(1.0 - v * 0.55, 1.0 - v * 0.9), "alpha": 1.0 - v, "tint": RIFT_GLOW.lerp(Color.WHITE, 1.0 - v)}
		Transition.MOOD_STYLISH:
			if p < 0.3:
				return {"offset": Vector2(0.0, -absf(sin(now * 16.0)) * 4.0), "rot": 0.16}
			if p < 0.7:
				var u: float = (p - 0.3) / 0.4
				return {"offset": Vector2(0.0, -sin(u * PI) * 95.0), "rot": u * TAU, "glint": 0.6}
			var v: float = (p - 0.7) / 0.3
			var s: float = 1.0 - v * 0.6
			# Mergulho de cabeca, esticada como agulha.
			return {"offset": Vector2(0.0, lerpf(-24.0, 34.0, v)), "rot": PI, "scale": Vector2(s * 0.8, s * 1.25), "alpha": 1.0 - v * 0.5, "glint": 1.0 - v}
	return {}


static func _pose_land(mood: String, p: float, ip: float, now: float, height: float) -> Dictionary:
	var tear: float = 1.0 - smoothstep(ip, ip + 0.18, p)
	var tear_offset := Vector2(0.0, -300.0)
	if p < ip:
		var u: float = p / ip
		var fall: float = 1.0 - u * u
		match mood:
			Transition.MOOD_SCARED:
				return {"offset": Vector2(sin(u * 9.0) * 14.0, -280.0 * fall), "rot": u * TAU * 2.25, "sweat": 1.0, "tear": tear, "tear_offset": tear_offset}
			Transition.MOOD_RESIGNED:
				return {"offset": Vector2(0.0, -240.0 * fall), "rot": sin(u * 8.0) * 0.08, "scale": Vector2(1.0, 1.0 + u * 0.1), "tear": tear, "tear_offset": tear_offset}
			Transition.MOOD_STYLISH:
				return {"offset": Vector2(0.0, -270.0 * fall), "rot": u * TAU * 2.0, "glint": 0.7, "tear": tear, "tear_offset": tear_offset}
	var w: float = (p - ip) / maxf(0.01, 1.0 - ip)
	match mood:
		Transition.MOOD_SCARED:
			# Cai de cara, fica estirada vendo estrelas e levanta tonta.
			if w < 0.55:
				return {"offset": Vector2(0.0, height * 0.3), "rot": PI * 0.5, "stars": 1.0, "dust": 1.0 - w * 1.6, "tear": tear, "tear_offset": tear_offset}
			var k: float = smoothstep(0.55, 1.0, w)
			return {"offset": Vector2(sin(now * 38.0) * 2.0 * (1.0 - k), height * 0.3 * (1.0 - k)), "rot": PI * 0.5 * (1.0 - k), "stars": 1.0 - k, "sweat": k}
		Transition.MOOD_RESIGNED:
			# Senta no chao, levanta e bate a poeira.
			if w < 0.5:
				return {"scale": Vector2(1.08, 0.78), "dust": 1.0 - w * 1.8, "tear": tear, "tear_offset": tear_offset}
			if w < 0.75:
				var k: float = (w - 0.5) / 0.25
				return {"scale": Vector2(lerpf(1.08, 1.0, k), lerpf(0.78, 1.0, k)), "sigh": sin(k * PI)}
			return {"rot": sin(now * 40.0) * 0.06, "dust": 0.25}
		Transition.MOOD_STYLISH:
			# Aterrissagem de heroi: agachada, onda dourada, levanta com mola.
			if w < 0.6:
				return {"scale": Vector2(1.12, 0.74), "ring": w / 0.6, "glint": 1.0, "dust": 0.8 - w, "tear": tear, "tear_offset": tear_offset}
			var k: float = (w - 0.6) / 0.4
			return {"scale": Vector2(lerpf(1.12, 1.0, k), lerpf(0.74, 1.0, _ease_out_back(k))), "glint": 1.0 - k}
	return {}


static func _pose_exit(mood: String, p: float, now: float) -> Dictionary:
	match mood:
		Transition.MOOD_SCARED:
			if p < 0.3:
				return {"offset": Vector2(sin(now * 50.0) * 2.5, 0.0), "rot": -0.12, "sweat": 1.0}
			var u: float = (p - 0.3) / 0.7
			return {"offset": Vector2(0.0, -sin(u * PI) * 52.0), "rot": u * PI * 1.2, "scale": Vector2.ONE * (1.0 - u * 0.8), "alpha": 1.0 - u * 0.6, "sweat": 1.0 - u, "tint": RIFT_CYAN.lerp(Color.WHITE, 1.0 - u)}
		Transition.MOOD_STYLISH:
			if p < 0.45:
				return {"offset": Vector2(0.0, -absf(sin(now * 16.0)) * 4.0), "rot": 0.16}
			var u: float = (p - 0.45) / 0.55
			return {"offset": Vector2(0.0, -sin(u * PI) * 82.0), "rot": -u * TAU, "scale": Vector2.ONE * (1.0 - smoothstep(0.6, 1.0, u) * 0.85), "glint": 1.0, "alpha": 1.0 - smoothstep(0.7, 1.0, u)}
	if p < 0.7:
		return {"offset": Vector2(0.0, -absf(sin(now * 12.0)) * 3.0), "rot": sin(now * 12.0) * 0.05}
	var v: float = (p - 0.7) / 0.3
	return {"scale": Vector2.ONE * (1.0 - v * 0.85), "alpha": 1.0 - v, "tint": RIFT_CYAN.lerp(Color.WHITE, 1.0 - v)}


static func _pose_emerge(mood: String, p: float, ip: float, now: float, height: float) -> Dictionary:
	var tear: float = 1.0 - smoothstep(ip, ip + 0.25, p)
	match mood:
		Transition.MOOD_EJECTED, Transition.MOOD_SCARED:
			var tear_offset := Vector2(-80.0, -96.0)
			if p < ip:
				var u: float = p / ip
				# Cuspida pela fenda: sai rodando num arco e cai sentada.
				return {"offset": Vector2(-80.0 * (1.0 - u), -96.0 * (1.0 - u) - sin(u * PI) * 64.0), "rot": u * TAU * 1.5, "scale": Vector2.ONE * (0.3 + 0.7 * u), "sweat": 1.0, "tear": tear, "tear_offset": tear_offset}
			var w: float = (p - ip) / maxf(0.01, 1.0 - ip)
			var stars: float = 1.0 if mood == Transition.MOOD_EJECTED else 0.6
			if w < 0.5:
				return {"scale": Vector2(1.08, 0.78), "stars": stars, "dust": 1.0 - w * 1.8, "tear": tear, "tear_offset": tear_offset}
			var k: float = (w - 0.5) / 0.5
			return {"scale": Vector2(lerpf(1.08, 1.0, k), lerpf(0.78, 1.0, k)), "rot": sin(now * 25.0) * 0.08 * (1.0 - k), "stars": stars * (1.0 - k), "sweat": 1.0 - k}
		Transition.MOOD_RESIGNED:
			var tear_offset := Vector2(0.0, -height * 0.55)
			if p < ip:
				var u: float = p / ip
				# Atravessa o rasgo andando, como quem sai de um elevador.
				return {"offset": Vector2(0.0, -14.0 * (1.0 - u)), "scale": Vector2.ONE * (0.25 + 0.75 * u), "alpha": u, "tear": tear, "tear_offset": tear_offset, "tint": RIFT_GLOW.lerp(Color.WHITE, u)}
			var w: float = (p - ip) / maxf(0.01, 1.0 - ip)
			if w < 0.45:
				return {"sigh": sin(w / 0.45 * PI), "tear": tear, "tear_offset": tear_offset}
			return {"rot": sin(now * 40.0) * 0.05 * (1.0 - w), "dust": 0.3 * (1.0 - w)}
		Transition.MOOD_STYLISH:
			var tear_offset := Vector2(0.0, -height * 0.6)
			if p < ip:
				var u: float = p / ip
				return {"offset": Vector2(0.0, lerpf(-height * 0.6, 0.0, u) - sin(u * PI) * 96.0), "rot": u * TAU * 2.0, "scale": Vector2.ONE * (0.4 + 0.6 * u), "glint": 1.0, "tear": tear, "tear_offset": tear_offset}
			var w: float = (p - ip) / maxf(0.01, 1.0 - ip)
			if w < 0.75:
				# A POSE: inclinada, peito estufado, brilho dourado.
				var hold: float = smoothstep(0.0, 0.18, w)
				var pulse: float = 1.0 + sin(w * PI * 2.0) * 0.02
				return {"rot": -0.2 * hold, "scale": Vector2(1.04 * pulse, 1.07 * pulse), "ring": minf(1.0, w / 0.4), "glint": 1.0, "tear": tear, "tear_offset": tear_offset, "tint": Color.WHITE.lerp(GOLD, 0.18 * sin(w / 0.75 * PI))}
			var k: float = (w - 0.75) / 0.25
			return {"rot": -0.2 * (1.0 - k), "scale": Vector2(lerpf(1.04, 1.0, k), lerpf(1.07, 1.0, k)), "glint": 1.0 - k}
	return {}


# ------------------------------------------------------------------ desenho
static func _draw_body(game: Node2D, tex: Texture2D, center: Vector2, height: float, rot: float, scale: Vector2, alpha: float, flip: bool, tint: Color) -> void:
	var tex_size: Vector2 = tex.get_size()
	if tex_size.y <= 0.0 or alpha <= 0.01 or scale.x <= 0.01 or scale.y <= 0.01:
		return
	var size: Vector2 = tex_size * (height / tex_size.y)
	game.draw_set_transform(center, rot, Vector2(scale.x * (-1.0 if flip else 1.0), scale.y))
	game.draw_texture_rect(tex, Rect2(-size * 0.5, size), false, Color(tint.r, tint.g, tint.b, alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_shadow(game: Node2D, foot: Vector2, alpha: float, size_k: float) -> void:
	if alpha <= 0.01:
		return
	game.draw_set_transform(foot + Vector2(0.0, -2.0), 0.0, Vector2(1.35, 0.32))
	game.draw_circle(Vector2.ZERO, 30.0 * size_k, Color(0.0, 0.0, 0.0, 0.34 * alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_tear(game: Node2D, center: Vector2, k: float, now: float, open_k: float, height: float) -> void:
	var frames: Array = _fx("tear")
	if frames.size() < 11:
		_draw_tear_procedural(game, center, k, now)
		return
	var idx: int
	if open_k < 1.0:
		idx = clampi(int(open_k * 4.0), 0, 3)
	elif k > 0.97:
		idx = 4 + int(now * 10.0) % 4
	else:
		idx = 8 + clampi(int((1.0 - k) * 3.0), 0, 2)
	_draw_tex_h(game, frames[idx], center, height * 1.8, clampf(k * 3.0, 0.0, 1.0))


static func _draw_tear_procedural(game: Node2D, center: Vector2, k: float, now: float) -> void:
	var hw: float = 22.0 * k
	var hh: float = 58.0 * k
	var pts := PackedVector2Array()
	for i in range(18):
		var a: float = float(i) / 18.0 * TAU
		var jag: float = 1.0 + sin(a * 5.0 + now * 9.0) * 0.12
		pts.append(center + Vector2(cos(a) * hw * jag, sin(a) * hh))
	game.draw_colored_polygon(pts, Color(0.06, 0.02, 0.12, 0.9 * k))
	game.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(RIFT_GLOW.r, RIFT_GLOW.g, RIFT_GLOW.b, 0.9 * k), 3.0)
	game.draw_arc(center, hh * 0.9, -PI * 0.5 - 0.6, -PI * 0.5 + 0.6, 10, Color(RIFT_CYAN.r, RIFT_CYAN.g, RIFT_CYAN.b, 0.5 * k), 2.0)


static func _draw_shockwave(game: Node2D, center: Vector2, k: float) -> void:
	var eased: float = 1.0 - pow(1.0 - k, 3.0)
	var radius: float = lerpf(30.0, Transition.PUSH_RADIUS, eased)
	var a: float = (1.0 - k) * 0.75
	var frames: Array = _fx("shock")
	# Estouro com arte so perto dela (a arte esticada ate o raio do empurrao
	# fica borrada); a onda grande continua sendo o anel desenhado.
	if not frames.is_empty() and k < 0.5:
		var kk: float = k / 0.5
		var tex: Texture2D = frames[clampi(int(kk * float(frames.size())), 0, frames.size() - 1)]
		var w: float = lerpf(110.0, 300.0, 1.0 - pow(1.0 - kk, 2.0))
		var sz := Vector2(w, w * 0.6)
		game.draw_texture_rect(tex, Rect2(center - sz * 0.5, sz), false, Color(1.0, 1.0, 1.0, 1.0 - kk * 0.8))
	game.draw_set_transform(center, 0.0, Vector2(1.0, 0.55))
	game.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(RIFT_GLOW.r, RIFT_GLOW.g, RIFT_GLOW.b, a), 6.0)
	game.draw_arc(Vector2.ZERO, radius * 0.92, 0.0, TAU, 48, Color(RIFT_CYAN.r, RIFT_CYAN.g, RIFT_CYAN.b, a * 0.5), 2.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_dust(game: Node2D, foot: Vector2, k: float, height: float = 92.0) -> void:
	k = clampf(k, 0.0, 1.0)
	var frames: Array = _fx("dust")
	if not frames.is_empty():
		var tex: Texture2D = frames[clampi(int((1.0 - k) * float(frames.size())), 0, frames.size() - 1)]
		var w: float = height * 1.7
		var sz: Vector2 = tex.get_size() * (w / maxf(1.0, tex.get_size().x))
		game.draw_texture_rect(tex, Rect2(foot + Vector2(-sz.x * 0.5, -sz.y + 6.0), sz), false, Color(1.0, 1.0, 1.0, clampf(k * 2.5, 0.0, 1.0)))
		return
	for i in range(6):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var spread: float = (1.0 - k) * 34.0 + 10.0
		var pos: Vector2 = foot + Vector2(side * (spread + float(i) * 5.0), -6.0 - float(i % 3) * 5.0 * (1.0 - k))
		game.draw_circle(pos, 6.0 + float(i % 3) * 2.0, Color(0.78, 0.72, 0.66, 0.42 * k))


static func _draw_hero_ring(game: Node2D, foot: Vector2, k: float, height: float = 92.0, now: float = 0.0) -> void:
	var radius: float = lerpf(18.0, 96.0, 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 2.0))
	var a: float = (1.0 - clampf(k, 0.0, 1.0)) * 0.85
	var frames: Array = _fx("ring")
	if not frames.is_empty():
		var tex: Texture2D = frames[int(now * 10.0) % frames.size()]
		var w: float = lerpf(height * 0.6, height * 2.0, 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 2.0))
		var sz := Vector2(w, w * 0.42)
		game.draw_texture_rect(tex, Rect2(foot - sz * 0.5, sz), false, Color(1.0, 1.0, 1.0, minf(1.0, a * 1.15)))
		return
	game.draw_set_transform(foot, 0.0, Vector2(1.0, 0.3))
	game.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(GOLD.r, GOLD.g, GOLD.b, a), 5.0)
	for i in range(8):
		var ang: float = float(i) / 8.0 * TAU
		game.draw_line(Vector2.from_angle(ang) * radius * 0.35, Vector2.from_angle(ang) * radius * 0.8, Color(0.2, 0.14, 0.08, a * 0.7), 2.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_dizzy_stars(game: Node2D, head: Vector2, k: float, now: float, height: float = 92.0) -> void:
	var art: Array = _fx("stars")
	if not art.is_empty():
		_draw_tex_w(game, art[0], head + Vector2(0.0, -height * 0.12 + sin(now * 6.0) * 2.0), height * 0.7, k, sin(now * 5.0) * 0.18)
		return
	for i in range(3):
		var ang: float = now * 5.0 + float(i) * TAU / 3.0
		var pos: Vector2 = head + Vector2(cos(ang) * 22.0, sin(ang) * 7.0 - 10.0)
		_draw_star(game, pos, 5.0, Color(1.0, 0.92, 0.4, k))


static func _draw_sweat(game: Node2D, head: Vector2, k: float, now: float, flip: bool, height: float = 92.0) -> void:
	var side: float = -1.0 if flip else 1.0
	var drip: float = fmod(now * 2.2, 1.0)
	var art: Array = _fx("sweat")
	if not art.is_empty():
		_draw_tex_w(game, art[0], head + Vector2(side * height * 0.24, height * 0.02 + drip * height * 0.12), height * 0.11, 0.9 * k * (1.0 - drip * 0.6))
		return
	var pos: Vector2 = head + Vector2(side * 16.0, -4.0 + drip * 10.0)
	game.draw_circle(pos, 3.2, Color(0.55, 0.85, 1.0, 0.85 * k * (1.0 - drip * 0.6)))
	game.draw_line(pos + Vector2(0.0, -3.0), pos + Vector2(0.0, -7.0), Color(0.55, 0.85, 1.0, 0.7 * k), 2.0)


static func _draw_sigh(game: Node2D, head: Vector2, k: float, flip: bool, height: float = 92.0) -> void:
	var side: float = -1.0 if flip else 1.0
	var art: Array = _fx("sigh")
	if not art.is_empty():
		var pos: Vector2 = head + Vector2(side * (height * 0.3 + (1.0 - k) * 12.0), height * 0.18 - (1.0 - k) * 14.0)
		_draw_tex_w(game, art[0], pos, height * (0.3 + (1.0 - k) * 0.12), 0.85 * k, 0.0, flip)
		return
	var pos: Vector2 = head + Vector2(side * (14.0 + (1.0 - k) * 10.0), 6.0 - (1.0 - k) * 8.0)
	game.draw_circle(pos, 4.0 + (1.0 - k) * 4.0, Color(1.0, 1.0, 1.0, 0.55 * k))
	game.draw_circle(pos + Vector2(side * 7.0, -3.0), 2.5 + (1.0 - k) * 3.0, Color(1.0, 1.0, 1.0, 0.4 * k))


static func _draw_glints(game: Node2D, center: Vector2, height: float, k: float, now: float) -> void:
	for i in range(3):
		var phase: float = fmod(now * 1.6 + float(i) * 0.33, 1.0)
		var a: float = sin(phase * PI) * k
		var ang: float = float(i) * 2.1 + 0.6
		var pos: Vector2 = center + Vector2(cos(ang) * height * 0.38, sin(ang) * height * 0.42)
		_draw_star(game, pos, 4.0 + a * 4.0, Color(GOLD.r, GOLD.g, GOLD.b, a))


static func _draw_star(game: Node2D, pos: Vector2, r: float, color: Color) -> void:
	if color.a <= 0.01:
		return
	game.draw_line(pos + Vector2(-r, 0.0), pos + Vector2(r, 0.0), color, 2.0)
	game.draw_line(pos + Vector2(0.0, -r), pos + Vector2(0.0, r), color, 2.0)
	game.draw_line(pos + Vector2(-r, -r) * 0.5, pos + Vector2(r, r) * 0.5, color, 1.2)
	game.draw_line(pos + Vector2(-r, r) * 0.5, pos + Vector2(r, -r) * 0.5, color, 1.2)


static func _ease_out_back(x: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


## Buraco no chao: abre quando ela vai sumir (mergulho e saida da oficina),
## gira enquanto ela afunda e fecha no fim.
static func _draw_floor_hole(game: Node2D, foot: Vector2, phase: String, p: float, height: float, now: float) -> void:
	if phase != Transition.PHASE_DIVE and phase != Transition.PHASE_EXIT_DIVE:
		return
	var frames: Array = _fx("floor_hole")
	if frames.size() < 5:
		return
	var start: float = 0.35
	if p < start:
		return
	var u: float = (p - start) / (1.0 - start)
	var idx: int
	var a: float = 1.0
	if u < 0.3:
		idx = clampi(int(u / 0.3 * 3.0), 0, 2)
	elif u < 0.9:
		idx = 3 if int(now * 8.0) % 3 != 0 else 2
	else:
		idx = 4
		a = 1.0 - (u - 0.9) / 0.1
	var tex: Texture2D = frames[idx]
	var w: float = height * 1.7
	var sz: Vector2 = Vector2(w, w * 0.5)
	game.draw_texture_rect(tex, Rect2(foot + Vector2(-sz.x * 0.5, -sz.y * 0.55), sz), false, Color(1.0, 1.0, 1.0, a))


## Tunel em tela cheia entre a entrada e a saida: escurece o fim do
## mergulho e o comeco da queda, para ler como "passei por dentro".
static func _draw_tunnel(game: Node2D, phase: String, p: float, now: float) -> void:
	var a: float = 0.0
	var zoom: float = 1.0
	var leaving: bool = phase == Transition.PHASE_EXIT_DIVE or phase == Transition.PHASE_EMERGE
	if phase == Transition.PHASE_DIVE or phase == Transition.PHASE_EXIT_DIVE:
		a = smoothstep(0.7, 0.95, p)
		zoom = lerpf(0.8, 1.25, smoothstep(0.7, 1.0, p))
	elif phase == Transition.PHASE_LAND or phase == Transition.PHASE_EMERGE:
		a = 1.0 - smoothstep(0.0, 0.18, p)
		zoom = lerpf(1.25, 2.2, smoothstep(0.0, 0.18, p))
	if a <= 0.01:
		return
	var frames: Array = _fx("tunnel")
	var view: Vector2 = game.get_viewport_rect().size
	game.draw_rect(Rect2(Vector2(-64.0, -64.0), view + Vector2(128.0, 128.0)), Color(0.03, 0.01, 0.07, a * 0.92))
	if frames.size() < 4:
		return
	var cycle: Array = [1, 2, 3] if leaving else [0, 1, 2]
	var tex: Texture2D = frames[int(cycle[int(now * 12.0) % cycle.size()])]
	var w: float = view.length() * 1.05 * zoom
	var sz: Vector2 = tex.get_size() * (w / maxf(1.0, tex.get_size().x))
	game.draw_set_transform(view * 0.5, now * (1.8 if leaving else -1.8), Vector2.ONE)
	game.draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, Color(1.0, 1.0, 1.0, a))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Riscos de velocidade acima dela durante a queda.
static func _draw_speed(game: Node2D, mid: Vector2, height: float, now: float, alpha: float) -> void:
	var frames: Array = _fx("speed")
	if frames.is_empty():
		return
	_draw_tex_h(game, frames[int(now * 14.0) % frames.size()], mid + Vector2(0.0, -height * 0.75), height * 1.4, 0.85 * alpha)


## Clarao no instante do impacto (w = 0..1 do trecho depois de tocar o chao).
static func _draw_impact_flash(game: Node2D, foot: Vector2, height: float, w: float) -> void:
	if w >= 0.25:
		return
	var frames: Array = _fx("flash")
	if frames.is_empty():
		return
	var k: float = w / 0.25
	var tex: Texture2D = frames[clampi(int(k * float(frames.size())), 0, frames.size() - 1)]
	_draw_tex_w(game, tex, foot + Vector2(0.0, -height * 0.3), height * 1.3, 1.0 - k * 0.6)


static func _draw_tex_w(game: Node2D, tex: Texture2D, pos: Vector2, width: float, alpha: float, rot: float = 0.0, flip: bool = false) -> void:
	if alpha <= 0.01 or tex == null:
		return
	var sz: Vector2 = tex.get_size() * (width / maxf(1.0, tex.get_size().x))
	game.draw_set_transform(pos, rot, Vector2(-1.0 if flip else 1.0, 1.0))
	game.draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_tex_h(game: Node2D, tex: Texture2D, pos: Vector2, h: float, alpha: float) -> void:
	if tex == null:
		return
	_draw_tex_w(game, tex, pos, tex.get_size().x * (h / maxf(1.0, tex.get_size().y)), alpha)


## Efeitos com arte (tools/rift_slice.py): <nome>_<n>.png ou <nome>.png.
static func _fx(name: String) -> Array:
	var key: String = "fx:" + name
	if _frame_cache.has(key):
		return _frame_cache[key]
	var frames: Array = []
	var single: String = "%s%s.png" % [FX_DIR, name]
	if ResourceLoader.exists(single):
		var t = load(single)
		if t is Texture2D:
			frames.append(t)
	else:
		for i in range(16):
			var path: String = "%s%s_%d.png" % [FX_DIR, name, i]
			if not ResourceLoader.exists(path):
				break
			var tex = load(path)
			if tex is Texture2D:
				frames.append(tex)
	_frame_cache[key] = frames
	return frames


## Quadros dedicados opcionais (ver cabecalho). Cacheados por humor/fase.
static func _frames(mood: String, phase: String) -> Array:
	var key: String = mood + "_" + phase
	if _frame_cache.has(key):
		return _frame_cache[key]
	var frames: Array = []
	for i in range(MAX_FRAMES):
		var path: String = "%s%s_%d.png" % [SPRITE_DIR, key, i]
		if not ResourceLoader.exists(path):
			break
		var tex = load(path)
		if tex is Texture2D:
			frames.append(tex)
	_frame_cache[key] = frames
	return frames
