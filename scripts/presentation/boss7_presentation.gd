class_name RTBoss7Presentation
extends RefCounted

## Visual da Fenix: corpo com inclinacao/squash, cauda de fogo pelo rastro,
## brasas, sombra no chao, preparo dos ataques, sombra do mergulho, rasante,
## anel de chamas e meteoros.

const PhoenixFire = preload("res://scripts/vfx/phoenix_fire.gd")
const EMBER := Color(1.0, 0.56, 0.16)
const HOT := Color(1.0, 0.9, 0.5)
const DEEP := Color(0.85, 0.14, 0.04)


static func _low(game: Node2D) -> bool:
	return game._phase7_visual_budget_enabled()


## Sombra + cauda + corpo. Substitui o desenho simples do sprite da fase 7.
static func draw_boss(game: Node2D, camera: Vector2, tex: Texture2D, draw_pos: Vector2, size: Vector2, modulate: Color) -> void:
	var motion: RTBoss7MotionController = game._boss7_motion()
	var state: String = String(game.boss7_state)
	var t: float = float(game.time_alive)
	var low: bool = _low(game)
	var alt: float = motion.altitude
	if alt > 0.92 and state != game.BOSS7_STATE_DIVE_PREP:
		return
	var screen: Vector2 = draw_pos - camera
	# Sombra no chao (se afasta e encolhe com a altitude).
	var ground: Vector2 = Vector2(game.boss_pos) - camera + Vector2(0, 150.0)
	game.draw_set_transform(ground, 0.0, Vector2(1.0, 0.32))
	game.draw_circle(Vector2.ZERO, 120.0 * (1.0 - alt * 0.5), Color(0.08, 0.02, 0.0, 0.32 * (1.0 - alt * 0.6)))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_tail(game, camera, low, alt)
	# Pose: inclina para onde voa, estica na batida, sobe/encolhe no mergulho.
	var flap: float = sin(RTBoss7Animator.flap_phase(game) * TAU)
	var scale_k: float = 1.0 - alt * 0.55
	var sy: float = (1.0 + flap * 0.035) * scale_k
	var sx: float = (1.0 - flap * 0.02) * scale_k
	var rot: float = motion.bank * 0.2
	var flip: float = -1.0 if RTBoss7Animator.should_flip(game) else 1.0
	var lift := Vector2(0, -alt * 220.0)
	if state == game.BOSS7_STATE_DIVE or state == RTBoss7MotionController.STATE_SWOOP:
		rot = motion.bank * 0.35
		sx *= 1.08
		sy *= 0.94
	# Fantasmas na velocidade alta.
	if motion.speed() > 420.0 and motion.trail.size() > 6 and tex != null:
		for k in [6, 4, 2]:
			var ghost: Vector2 = motion.trail[k] - camera + (screen - (Vector2(game.boss_pos) - camera))
			_draw_tex(game, tex, ghost + lift, size, rot, Vector2(sx * flip, sy), Color(1.0, 0.45, 0.12, 0.16 + 0.05 * float(6 - k)))
	# Aura de calor atras do corpo.
	var windup: float = windup_glow(game)
	var pulse: float = 0.5 + 0.5 * sin(t * 5.0)
	var aura_c: Vector2 = screen + lift + Vector2(0, -size.y * 0.12)
	var aura_a: float = (0.05 + 0.03 * pulse + 0.12 * windup) * modulate.a
	for ring in range(3):
		game.draw_circle(aura_c, size.x * (0.14 + 0.08 * float(ring)) * scale_k, Color(1.0, 0.4, 0.08, aura_a * (1.0 - 0.28 * float(ring))))
	if tex != null:
		_draw_tex(game, tex, screen + lift, size, rot, Vector2(sx * flip, sy), modulate)
	# Nucleo do peito brilha nos preparos.
	if windup > 0.0:
		var chest: Vector2 = screen + lift + Vector2(0, -size.y * 0.2 * scale_k)
		game.draw_circle(chest, (16.0 + 26.0 * windup) * scale_k, Color(1.0, 0.7, 0.24, 0.35 * windup))
		game.draw_circle(chest, (7.0 + 9.0 * windup) * scale_k, Color(HOT, 0.85 * windup))
	draw_embers(game, screen + lift, size * scale_k, t, low)


static func _draw_tex(game: Node2D, tex: Texture2D, center: Vector2, max_size: Vector2, rot: float, scale: Vector2, color: Color) -> void:
	var tex_size: Vector2 = tex.get_size()
	var fit: float = minf(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size: Vector2 = tex_size * fit
	game.draw_set_transform(center, rot, scale)
	# Ancorado embaixo como o desenho antigo (align_bottom).
	game.draw_texture_rect(tex, Rect2(Vector2(-draw_size.x * 0.5, max_size.y * 0.5 - draw_size.y), draw_size), false, color)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 0..1 do preparo de ataque (peito acende, asas abrem).
static func windup_glow(game: Node2D) -> float:
	match String(game.boss7_state):
		game.BOSS7_STATE_FEATHER:
			return 1.0 - float(game.boss7_state_timer) / maxf(0.01, game.BOSS7_FEATHER_WINDUP)
		game.BOSS7_STATE_WING:
			return 1.0 - float(game.boss7_state_timer) / maxf(0.01, game.BOSS7_WING_WINDUP)
		RTBoss7MotionController.STATE_SWOOP_WARN:
			return 1.0 - float(game.boss7_state_timer) / RTBoss7MotionController.SWOOP_WARN
	return 0.0


## Cauda de fogo seguindo o rastro de posicoes (ribbon em 3 camadas).
static func draw_tail(game: Node2D, camera: Vector2, low: bool, alt: float) -> void:
	var motion: RTBoss7MotionController = game._boss7_motion()
	var pts: Array[Vector2] = motion.trail
	if pts.size() < 3 or alt > 0.6:
		return
	var t: float = float(game.time_alive)
	var n: int = mini(pts.size(), 10 if low else 18)
	var base_off := Vector2(0, -20)
	for layer in range(3):
		var width0: float = [46.0, 28.0, 12.0][layer]
		var col: Color = [DEEP, EMBER, HOT][layer]
		var prev: Vector2 = pts[0] - camera + base_off
		for i in range(1, n):
			var u: float = float(i) / float(n)
			var wob := Vector2(sin(t * 9.0 + float(i) * 0.9), cos(t * 7.0 + float(i))) * (3.0 + u * 8.0)
			var p: Vector2 = pts[i] - camera + base_off + wob
			var w: float = width0 * (1.0 - u) * (1.0 - alt)
			if w > 0.8:
				game.draw_line(prev, p, Color(col, (0.55 - 0.12 * float(layer)) * (1.0 - u)), w, true)
			prev = p


## Brasas soltas do corpo (procedural, sem alocar).
static func draw_embers(game: Node2D, center: Vector2, size: Vector2, t: float, low: bool) -> void:
	var count: int = 8 if low else 18
	for i in range(count):
		var seed_f: float = float(i) * 1.618
		var life: float = fposmod(t * (0.6 + fposmod(seed_f, 0.5)) + seed_f, 1.0)
		var x: float = center.x + (fposmod(seed_f * 7.3, 1.0) - 0.5) * size.x * 0.8 + sin(t * 2.0 + seed_f) * 10.0
		var y: float = center.y - size.y * 0.1 + (0.4 - life) * size.y * 0.9
		var a: float = (1.0 - life) * 0.9
		game.draw_rect(Rect2(Vector2(x, y), Vector2(2.5, 2.5)), Color(EMBER.lerp(HOT, 1.0 - life), a), true)


## Telegrafos no chao: sombra do mergulho, caminho do rasante, meteoros.
static func draw_ground(game: Node2D, camera: Vector2) -> void:
	if game.current_phase != 7:
		return
	var motion: RTBoss7MotionController = game._boss7_motion()
	var state: String = String(game.boss7_state)
	var t: float = float(game.time_alive)
	var low: bool = _low(game)
	if state in [game.BOSS7_STATE_DIVE_WAIT, game.BOSS7_STATE_DIVE_MARK, game.BOSS7_STATE_DIVE_FAKE, game.BOSS7_STATE_DIVE_PREP]:
		var lock: float = 0.0
		if state == game.BOSS7_STATE_DIVE_MARK:
			lock = clampf(1.0 - float(game.boss7_state_timer) / 0.9, 0.0, 1.0)
		var sp: Vector2 = motion.shadow_pos - camera
		_draw_bird_shadow(game, sp, 1.0 + 0.25 * lock, 0.25 + 0.3 * motion.altitude + 0.25 * lock, t)
		if state == game.BOSS7_STATE_DIVE_MARK:
			var r: float = 90.0
			game.draw_arc(sp, r, 0.0, TAU, 48, Color(1.0, 0.36, 0.08, 0.55 + 0.35 * lock), 3.0, true)
			game.draw_arc(sp, r, -PI * 0.5, -PI * 0.5 + TAU * lock, 48, Color(HOT, 0.95), 5.0, true)
			for k in range(4):
				var a: float = float(k) * TAU / 4.0 + t * 1.5
				game.draw_line(sp + Vector2.from_angle(a) * (r + 18.0), sp + Vector2.from_angle(a) * (r - 12.0 - 20.0 * lock), Color(HOT, 0.85), 3.0, true)
			if lock > 0.6:
				# Coluna de calor no ponto do impacto.
				game.draw_line(sp, sp + Vector2(0, -520), Color(1.0, 0.5, 0.1, 0.25 * (lock - 0.6) / 0.4), 40.0 * lock, true)
	if state == RTBoss7MotionController.STATE_SWOOP_WARN and not motion.swoop.is_empty():
		var k: float = 1.0 - float(game.boss7_state_timer) / RTBoss7MotionController.SWOOP_WARN
		var prev: Vector2 = motion.swoop_point(0.0) - camera
		var segs: int = 16
		for i in range(1, segs + 1):
			var u: float = float(i) / float(segs)
			var p: Vector2 = motion.swoop_point(u) - camera
			if i % 2 == 0 or u <= k:
				game.draw_line(prev, p, Color(1.0, 0.42 + 0.3 * float(u <= k), 0.1, 0.35 + 0.45 * float(u <= k)), 8.0 if u <= k else 4.0, true)
			prev = p
		var tip: Vector2 = motion.swoop_point(1.0) - camera
		var d: Vector2 = (tip - (motion.swoop_point(0.94) - camera)).normalized()
		game.draw_colored_polygon(PackedVector2Array([tip + d * 16.0, tip - d * 10.0 + d.orthogonal() * 12.0, tip - d * 10.0 - d.orthogonal() * 12.0]), Color(HOT, 0.8))
	for atk in game.boss_attacks:
		if String(atk.get("kind", "")) == game.BOSS7_ATTACK_SKY_FIREBALLS:
			_draw_meteors(game, camera, atk, t, low)


static func _draw_bird_shadow(game: Node2D, p: Vector2, scale: float, alpha: float, t: float) -> void:
	var flap: float = sin(t * 6.0) * 0.15
	var col := Color(0.06, 0.0, 0.0, alpha)
	game.draw_set_transform(p, 0.0, Vector2(scale, scale * 0.55))
	game.draw_circle(Vector2.ZERO, 34.0, col)
	for s in [-1.0, 1.0]:
		game.draw_colored_polygon(PackedVector2Array([Vector2(s * 20, -8), Vector2(s * 120, -40 + flap * 60), Vector2(s * 150, -6 + flap * 40), Vector2(s * 26, 16)]), col)
	game.draw_colored_polygon(PackedVector2Array([Vector2(-14, 20), Vector2(0, 90), Vector2(14, 20)]), col)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Meteoros: sombra cresce, bola cai em diagonal com cauda, impacto e brasa.
static func _draw_meteors(game: Node2D, camera: Vector2, atk: Dictionary, t: float, low: bool) -> void:
	var age: float = float(atk.get("age", 0.0))
	var warning: float = float(atk.get("warning", 0.85))
	var spots: Array = atk.get("spots", [])
	for i in range(spots.size()):
		var hit_t: float = warning + float(i) * RTBoss7Attacks.METEOR_STAGGER
		var p: Vector2 = Vector2(spots[i]) - camera
		var k: float = clampf(age / hit_t, 0.0, 1.0)
		if age < hit_t:
			game.draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
			game.draw_circle(Vector2.ZERO, RTBoss7Attacks.METEOR_RADIUS * (0.4 + 0.6 * k), Color(0.12, 0.02, 0.0, 0.22 + 0.25 * k))
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			game.draw_arc(p, RTBoss7Attacks.METEOR_RADIUS, 0.0, TAU, 28, Color(1.0, 0.4, 0.08, 0.35 + 0.5 * k), 2.0, true)
			if k > 0.35:
				var fall: float = (k - 0.35) / 0.65
				var sky: Vector2 = p + Vector2(180.0, -520.0) * (1.0 - fall)
				var dir: Vector2 = (p - sky).normalized() if fall < 0.999 else Vector2.DOWN
				game.draw_line(sky, sky - dir * (60.0 + 60.0 * fall), Color(1.0, 0.5, 0.12, 0.45), 10.0, true)
				PhoenixFire.draw_projectile(game, sky, dir, 10.0 + 6.0 * fall, t, float(i), low)
		else:
			var after: float = age - hit_t
			if after < 0.35:
				PhoenixFire.draw_burst(game, p, RTBoss7Attacks.METEOR_RADIUS * (0.8 + after * 2.0), t, 1.0 - after / 0.35, low)
			if after < RTBoss7Attacks.METEOR_BURN_TIME:
				var fade: float = 1.0 - after / RTBoss7Attacks.METEOR_BURN_TIME
				game.draw_set_transform(p, 0.0, Vector2(1.0, 0.5))
				game.draw_circle(Vector2.ZERO, RTBoss7Attacks.METEOR_RADIUS * 0.8, Color(0.18, 0.05, 0.0, 0.45 * fade))
				game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for f in range(2 if low else 4):
					PhoenixFire.draw_flame(game, p + Vector2((float(f) - 1.5) * 16.0, 4.0), 12.0, 22.0 * fade, t, float(i * 7 + f), fade, Vector2.UP, low)


## Anel de chamas (impacto do mergulho): faixa de fogo continua + lambidas +
## chao queimado por dentro.
static func draw_flame_wave(game: Node2D, camera: Vector2, wave: Dictionary) -> void:
	var center: Vector2 = Vector2(wave["pos"]) - camera
	var r: float = float(wave.get("radius", 0.0))
	var max_r: float = maxf(1.0, float(wave.get("max_radius", 250.0)))
	var p: float = clampf(r / max_r, 0.0, 1.0)
	var a: float = 1.0 - p * 0.7
	var t: float = float(game.time_alive)
	var low: bool = _low(game)
	var segs: int = 36 if low else 64
	# Chao chamuscado.
	game.draw_set_transform(center, 0.0, Vector2(1.0, 0.62))
	game.draw_circle(Vector2.ZERO, r * 0.92, Color(0.12, 0.03, 0.0, 0.22 * a))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var inner := r - 22.0
	for i in range(segs):
		var a0: float = float(i) * TAU / float(segs)
		var a1: float = float(i + 1) * TAU / float(segs)
		var d0 := Vector2.from_angle(a0) * Vector2(1.0, 0.62)
		var d1 := Vector2.from_angle(a1) * Vector2(1.0, 0.62)
		var lick0: float = 1.0 + 0.12 * sin(a0 * 9.0 + t * 8.0)
		var lick1: float = 1.0 + 0.12 * sin(a1 * 9.0 + t * 8.0)
		game.draw_polygon(PackedVector2Array([center + d0 * maxf(0.0, inner), center + d1 * maxf(0.0, inner), center + d1 * r * lick1, center + d0 * r * lick0]),
			PackedColorArray([Color(DEEP, 0.0), Color(DEEP, 0.0), Color(EMBER, 0.75 * a), Color(EMBER, 0.75 * a)]))
		game.draw_line(center + d0 * r * lick0, center + d1 * r * lick1, Color(HOT, 0.85 * a), 3.0, true)
	var flames: Array = wave.get("flames", [])
	var step: int = 3 if low else 2
	for fi in range(0, flames.size(), step):
		var f: Dictionary = flames[fi]
		var ang: float = float(f["angle"])
		var pos: Vector2 = center + Vector2.from_angle(ang) * Vector2(1.0, 0.62) * r
		var size: float = float(f.get("size", 10.0)) * (1.2 - p * 0.6)
		PhoenixFire.draw_flame(game, pos, size * 1.6, size * 3.8, t, ang * 5.0, a, Vector2.UP, low)
