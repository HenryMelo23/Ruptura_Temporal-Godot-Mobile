class_name RTMerchantWorkshopPhysics
extends RefCounted

## Fisica leve da oficina do Mercador (so dentro da dimensao).
##
## - Moveis pesados (maquinas da parede, estantes, cofre, poltrona, balcao e o
##   teleportador) sao solidos: a Geovana desliza pela borda deles.
## - Miudezas (caixas, barril, livros, caixa de ferramentas, cabos, bobina,
##   planta, luminaria, placa, sucata, carrinho, balanca e o bichinho) sao
##   corpos soltos: ela as chuta ao encostar, disparos as empurram, elas
##   deslizam com atrito, quicam nas paredes, batem umas nas outras e balancam.
## - O Mercador e um corpo solido que cambaleia quando leva um esbarrao.
##
## Tudo e local (cosmetico + colisao do jogador local): nao vai para a rede.

const WALL_MARGIN := 70.0
## Atrito exponencial (fracao da velocidade que sobra por segundo).
const FRICTION_PER_SECOND := 0.06
const MAX_SPEED := 620.0
const PLAYER_RADIUS := 22.0
const KICK_IMPULSE := 260.0
const BULLET_IMPULSE := 150.0
const BULLET_RADIUS := 10.0
const RESTITUTION := 0.55
const MERCHANT_RADIUS := 34.0
## Mercador: o corpo dele fica um pouco acima do pe (sprite em pe).
const MERCHANT_BODY_OFFSET := Vector2(0.0, -16.0)
const MERCHANT_WOBBLE_DAMP := 7.0
const MERCHANT_COMPLAIN_COOLDOWN := 6.0

## Miudezas que se mexem: nome da arte -> [raio, massa].
const MOVABLE: Dictionary = {
	"crates": [30.0, 2.2],
	"crate_fallen": [28.0, 2.0],
	"barrel": [26.0, 1.8],
	"books": [18.0, 0.6],
	"toolbox": [18.0, 0.8],
	"cables": [18.0, 0.7],
	"coil": [22.0, 1.4],
	"plant": [18.0, 0.9],
	"lamp_floor": [16.0, 1.0],
	"sign": [20.0, 1.1],
	"scrap": [24.0, 1.3],
	"wheelbarrow": [28.0, 1.6],
	"scales": [20.0, 1.0],
	"pet": [16.0, 0.5],
}
## Pecas que nao saem do lugar mas bloqueiam (raio relativo a altura).
const STATIC_RADIUS_SCALE := 0.36
## A luminaria pendurada nao tem pe no chao: nao colide.
const GHOSTS: Array[String] = ["lamp_hanging"]

var bodies: Array[Dictionary] = []
var world_size := Vector2(1500.0, 1050.0)
var merchant_pos := Vector2.ZERO
var merchant_lean := 0.0
var merchant_lean_vel := 0.0
var _complain_cd := 0.0
var _complain_requested := false


## Monta os corpos a partir do cenario fixo (chamado ao entrar na oficina).
func setup(props: Array, extra_statics: Array, world: Vector2, merchant: Vector2) -> void:
	bodies.clear()
	world_size = world
	merchant_pos = merchant
	merchant_lean = 0.0
	merchant_lean_vel = 0.0
	_complain_cd = 0.0
	_complain_requested = false
	for entry in props:
		var name := String(entry[0])
		var height := float(entry[2])
		var movable: bool = MOVABLE.has(name)
		var radius: float = float(MOVABLE[name][0]) if movable else height * STATIC_RADIUS_SCALE
		bodies.append({
			"name": name,
			"pos": Vector2(entry[1]),
			"home": Vector2(entry[1]),
			"vel": Vector2.ZERO,
			"radius": radius,
			"mass": float(MOVABLE[name][1]) if movable else 0.0,
			"movable": movable,
			"ghost": GHOSTS.has(name),
			"height": height,
			"flip": bool(entry[3]),
			"tilt": float(entry[4]),
			"base_tilt": float(entry[4]),
			"tilt_vel": 0.0,
			"shade": float(entry[5]),
		})
	for extra in extra_statics:
		bodies.append({
			"name": String(extra[0]), "pos": Vector2(extra[1]), "home": Vector2(extra[1]), "vel": Vector2.ZERO,
			"radius": float(extra[2]), "mass": 0.0, "movable": false, "ghost": false, "hidden": true,
			"height": 0.0, "flip": false, "tilt": 0.0, "base_tilt": 0.0, "tilt_vel": 0.0, "shade": 1.0,
		})


func is_ready() -> bool:
	return not bodies.is_empty()


## Corpo visivel por nome+posicao inicial (a apresentacao desenha daqui).
func drawable_bodies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for body in bodies:
		if not bool(body.get("hidden", false)):
			out.append(body)
	return out


## Empurra o jogador para fora dos solidos e chuta as miudezas que ele toca.
func push_player(pos: Vector2, previous: Vector2) -> Vector2:
	var moved: Vector2 = pos - previous
	var out := pos
	for body in bodies:
		if bool(body["ghost"]):
			continue
		var center: Vector2 = body["pos"]
		var min_dist: float = float(body["radius"]) + PLAYER_RADIUS
		var delta: Vector2 = out - center
		var dist: float = delta.length()
		if dist >= min_dist:
			continue
		var normal: Vector2 = delta / dist if dist > 0.01 else Vector2.UP
		if bool(body["movable"]):
			# Chute: a miudeza leva o impulso e a Geovana so perde um pouco.
			var push_dir: Vector2 = -normal
			var speed_hint: float = clampf(moved.length() * 60.0, 60.0, 420.0)
			var impulse: float = (KICK_IMPULSE + speed_hint * 0.5) / maxf(0.3, float(body["mass"]))
			body["vel"] = (Vector2(body["vel"]) + push_dir * impulse).limit_length(MAX_SPEED)
			body["pos"] = center + push_dir * (min_dist - dist) * 0.8
			body["tilt_vel"] = float(body["tilt_vel"]) + (18.0 if push_dir.x >= 0.0 else -18.0) / maxf(0.4, float(body["mass"]))
			out = center + normal * maxf(dist, min_dist * 0.82)
		else:
			out = center + normal * min_dist
	# Mercador: solido e cambaleia com o esbarrao.
	var m_center: Vector2 = merchant_pos + MERCHANT_BODY_OFFSET
	var m_delta: Vector2 = out - m_center
	var m_dist: float = m_delta.length()
	var m_min: float = MERCHANT_RADIUS + PLAYER_RADIUS
	if m_dist < m_min:
		var m_normal: Vector2 = m_delta / m_dist if m_dist > 0.01 else Vector2.DOWN
		out = m_center + m_normal * m_min
		bump_merchant(-m_normal, clampf(moved.length() * 60.0, 80.0, 360.0))
	return out


## Esbarrao no Mercador: ele inclina para o lado do empurrao.
func bump_merchant(direction: Vector2, strength: float) -> void:
	merchant_lean_vel += signf(direction.x if absf(direction.x) > 0.05 else 1.0) * strength * 0.012
	if _complain_cd <= 0.0 and strength >= 120.0:
		_complain_requested = true
		_complain_cd = MERCHANT_COMPLAIN_COOLDOWN


## Retorna true uma vez quando ele merece reclamar do esbarrao.
func consume_complaint() -> bool:
	var asked := _complain_requested
	_complain_requested = false
	return asked


## Disparos empurram as miudezas (o disparo segue: e so fisica de cenario).
func apply_bullets(bullets: Array) -> void:
	for bullet in bullets:
		var bpos: Vector2 = Vector2(bullet.get("pos", Vector2.INF))
		if not bpos.is_finite():
			continue
		var bdir: Vector2 = Vector2(bullet.get("dir", Vector2.ZERO))
		for body in bodies:
			if not bool(body["movable"]):
				continue
			var reach: float = float(body["radius"]) + BULLET_RADIUS
			if bpos.distance_squared_to(Vector2(body["pos"])) > reach * reach:
				continue
			var hit_key: String = "ws_%d" % bodies.find(body)
			var hits: Dictionary = bullet.get("workshop_hits", {})
			if hits.has(hit_key):
				continue
			hits[hit_key] = true
			bullet["workshop_hits"] = hits
			var dir: Vector2 = bdir.normalized() if bdir.length() > 0.01 else (Vector2(body["pos"]) - bpos).normalized()
			body["vel"] = (Vector2(body["vel"]) + dir * BULLET_IMPULSE / maxf(0.3, float(body["mass"]))).limit_length(MAX_SPEED)
			body["tilt_vel"] = float(body["tilt_vel"]) + (10.0 if dir.x >= 0.0 else -10.0)


func update(delta: float) -> void:
	if delta <= 0.0 or bodies.is_empty():
		return
	_complain_cd = maxf(0.0, _complain_cd - delta)
	var keep: float = pow(FRICTION_PER_SECOND, delta)
	var lo := Vector2(WALL_MARGIN, WALL_MARGIN * 2.4)
	var hi := world_size - Vector2(WALL_MARGIN, WALL_MARGIN)
	for body in bodies:
		# Balanco: mola amortecida de volta para a inclinacao original.
		var tilt: float = float(body["tilt"])
		var tilt_vel: float = float(body["tilt_vel"])
		tilt_vel += (float(body["base_tilt"]) - tilt) * 60.0 * delta
		tilt_vel *= pow(0.02, delta)
		body["tilt_vel"] = tilt_vel
		body["tilt"] = clampf(tilt + tilt_vel * delta, -28.0, 28.0)
		if not bool(body["movable"]):
			continue
		var vel: Vector2 = Vector2(body["vel"]) * keep
		var pos: Vector2 = Vector2(body["pos"]) + vel * delta
		var r: float = float(body["radius"])
		if pos.x < lo.x + r:
			pos.x = lo.x + r
			vel.x = absf(vel.x) * RESTITUTION
		elif pos.x > hi.x - r:
			pos.x = hi.x - r
			vel.x = -absf(vel.x) * RESTITUTION
		if pos.y < lo.y + r:
			pos.y = lo.y + r
			vel.y = absf(vel.y) * RESTITUTION
		elif pos.y > hi.y - r:
			pos.y = hi.y - r
			vel.y = -absf(vel.y) * RESTITUTION
		if vel.length() < 4.0:
			vel = Vector2.ZERO
		body["vel"] = vel
		body["pos"] = pos
	_resolve_body_contacts()
	# O Mercador volta a ficar de pe.
	merchant_lean_vel += -merchant_lean * 40.0 * delta
	merchant_lean_vel *= exp(-MERCHANT_WOBBLE_DAMP * delta)
	merchant_lean = clampf(merchant_lean + merchant_lean_vel * delta, -0.35, 0.35)


## Contatos entre corpos (n pequeno: ~30 corpos, O(n^2) barato).
func _resolve_body_contacts() -> void:
	var count: int = bodies.size()
	var m_center: Vector2 = merchant_pos + MERCHANT_BODY_OFFSET
	for i in range(count):
		var a: Dictionary = bodies[i]
		if not bool(a["movable"]):
			continue
		for j in range(count):
			if i == j:
				continue
			var b: Dictionary = bodies[j]
			if bool(b["ghost"]):
				continue
			if bool(b["movable"]) and j < i:
				continue
			var delta: Vector2 = Vector2(a["pos"]) - Vector2(b["pos"])
			var min_dist: float = float(a["radius"]) + float(b["radius"])
			var dist: float = delta.length()
			if dist >= min_dist:
				continue
			var normal: Vector2 = delta / dist if dist > 0.01 else Vector2.RIGHT
			var overlap: float = min_dist - dist
			if bool(b["movable"]):
				var ma: float = float(a["mass"])
				var mb: float = float(b["mass"])
				var total: float = maxf(0.01, ma + mb)
				a["pos"] = Vector2(a["pos"]) + normal * overlap * (mb / total)
				b["pos"] = Vector2(b["pos"]) - normal * overlap * (ma / total)
				var rel: float = (Vector2(a["vel"]) - Vector2(b["vel"])).dot(normal)
				if rel < 0.0:
					var impulse: float = -(1.0 + RESTITUTION) * rel / (1.0 / maxf(0.1, ma) + 1.0 / maxf(0.1, mb))
					a["vel"] = Vector2(a["vel"]) + normal * impulse / maxf(0.1, ma)
					b["vel"] = Vector2(b["vel"]) - normal * impulse / maxf(0.1, mb)
					b["tilt_vel"] = float(b["tilt_vel"]) - impulse * 0.05
			else:
				a["pos"] = Vector2(a["pos"]) + normal * overlap
				var rel_static: float = Vector2(a["vel"]).dot(normal)
				if rel_static < 0.0:
					a["vel"] = Vector2(a["vel"]) - normal * rel_static * (1.0 + RESTITUTION)
		# Miudeza contra o Mercador: ela quica e ele cambaleia.
		var to_m: Vector2 = Vector2(a["pos"]) - m_center
		var m_min: float = float(a["radius"]) + MERCHANT_RADIUS
		var m_dist: float = to_m.length()
		if m_dist < m_min:
			var m_normal: Vector2 = to_m / m_dist if m_dist > 0.01 else Vector2.RIGHT
			a["pos"] = m_center + m_normal * m_min
			var rel_m: float = Vector2(a["vel"]).dot(m_normal)
			if rel_m < 0.0:
				bump_merchant(-m_normal, -rel_m * float(a["mass"]))
				a["vel"] = Vector2(a["vel"]) - m_normal * rel_m * (1.0 + RESTITUTION)


func any_moving() -> bool:
	for body in bodies:
		if bool(body["movable"]) and Vector2(body["vel"]).length_squared() > 1.0:
			return true
	return false
