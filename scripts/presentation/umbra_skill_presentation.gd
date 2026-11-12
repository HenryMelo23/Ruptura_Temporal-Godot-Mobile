class_name RTUmbraSkillPresentation
extends RefCounted

## Desenho das habilidades da UMBRA. Usa a arte do Codex quando existe em
## assets/sprites/umbra_skills/<grupo>/<nome>_NN.png; enquanto falta, desenha
## uma versao procedural com a mesma leitura (aviso -> golpe).

const ROOT := "res://assets/sprites/umbra_skills/"
const GREEN := Color(0.36, 1.0, 0.56)
const VOID := Color(0.04, 0.06, 0.19)
const PALE := Color(0.78, 1.0, 0.9)

static var _frames: Dictionary = {}


## Frames `<grupo>/<nome>_01.png`, `_02`... (vazio se a arte ainda nao existe).
static func frames(group: String, name: String) -> Array[Texture2D]:
	var key: String = group + "/" + name
	if _frames.has(key):
		return _frames[key]
	var out: Array[Texture2D] = []
	for i in range(1, 13):
		var path: String = "%s%s/%s_%02d.png" % [ROOT, group, name, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		out.append(tex)
	_frames[key] = out
	return out


static func frame_at(group: String, name: String, t: float, fps: float = 8.0, loop: bool = true) -> Texture2D:
	var list: Array[Texture2D] = frames(group, name)
	if list.is_empty():
		return null
	var idx: int = int(floor(t * fps))
	idx = posmod(idx, list.size()) if loop else mini(idx, list.size() - 1)
	return list[idx]


static func draw_centered(game: Node2D, tex: Texture2D, center: Vector2, size: float, modulate: Color = Color.WHITE, rotation: float = 0.0) -> void:
	var s: Vector2 = tex.get_size()
	var scale: float = size / maxf(1.0, maxf(s.x, s.y))
	game.draw_set_transform(center, rotation, Vector2(scale, scale))
	game.draw_texture(tex, -s * 0.5, modulate)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================ plasma/portal/sifao
## Projetil do ataque basico. Devolve false quando a arte ainda nao existe.
static func draw_plasma(game: Node2D, pos: Vector2, dir: Vector2, t: float) -> bool:
	var tex: Texture2D = frame_at("plasma", "bolt", t, 10.0)
	if tex == null:
		return false
	draw_centered(game, tex, pos, 104.0, Color(1, 1, 1, 0.95), dir.angle())
	return true


## Clarao do cano, impacto e faisca curta do plasma.
static func draw_plasma_burst(game: Node2D, name: String, pos: Vector2, dir: Vector2, size: float, fade: float) -> bool:
	var tex: Texture2D = frame_at("plasma", name, 0.0, 1.0, false)
	if tex == null:
		return false
	draw_centered(game, tex, pos, size, Color(1, 1, 1, fade), dir.angle())
	return true


## Portal do teleporte: `fake` usa a arte rachada da finta.
static func draw_portal(game: Node2D, pos: Vector2, progress: float, fake: bool, t: float) -> bool:
	if fake:
		var fake_tex: Texture2D = frames("teleporte", "fake")[0] if not frames("teleporte", "fake").is_empty() else null
		if fake_tex == null:
			return false
		draw_centered(game, fake_tex, pos, 150.0, Color(1, 1, 1, 0.85), t * 0.6)
		return true
	var list: Array[Texture2D] = frames("teleporte", "portal")
	if list.is_empty():
		return false
	var idx: int = clampi(int(floor(clampf(progress, 0.0, 1.0) * float(list.size()))), 0, list.size() - 1)
	draw_centered(game, list[idx], pos, 86.0 + 72.0 * clampf(progress, 0.0, 1.0), Color(1, 1, 1, 0.92))
	return true


static func draw_portal_arrival(game: Node2D, pos: Vector2, fade: float) -> bool:
	var list: Array[Texture2D] = frames("teleporte", "arrive")
	if list.is_empty():
		return false
	draw_centered(game, list[0], pos, 150.0 + 90.0 * (1.0 - fade), Color(1, 1, 1, fade))
	return true


## Cupula do Sifao e o sigilo no chao.
static func draw_siphon(game: Node2D, pos: Vector2, radius: float, t: float) -> bool:
	var dome: Texture2D = frame_at("sifao", "dome", t, 5.0)
	if dome == null:
		return false
	var sigil: Texture2D = frame_at("sifao", "sigil", t, 1.0, false)
	if sigil != null:
		draw_centered(game, sigil, pos, radius * 1.5, Color(1, 1, 1, 0.5 + 0.12 * sin(t * 4.0)), t * 0.35)
	draw_centered(game, dome, pos, radius * 2.1, Color(1, 1, 1, 0.72))
	return true


# ================================================================ kit base
static func draw_world(game: Node2D, camera: Vector2) -> void:
	if game.current_phase != 5 or not game.has_method("_umbra_base_skills"):
		return
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()
	var t: float = float(game.time_alive)
	for e in skills.ecos:
		_draw_eco(game, e, camera, t)
	for r in skills.rewinds:
		_draw_rewind(game, r, camera, t)


static func _draw_eco(game: Node2D, e: Dictionary, camera: Vector2, t: float) -> void:
	var pos: Vector2 = Vector2(e["pos"]) - camera
	var radius: float = RTUmbraBaseSkills.ECO_RADIUS
	var blast: float = float(e["blast"])
	if blast < 0.0:
		var k: float = 1.0 - clampf(float(e["timer"]) / RTUmbraBaseSkills.ECO_WARNING, 0.0, 1.0)
		var tex: Texture2D = frame_at("eco", "sigil", t, 6.0)
		if tex != null:
			draw_centered(game, tex, pos, radius * 2.3, Color(1, 1, 1, 0.55 + 0.45 * k))
		else:
			game.draw_circle(pos, radius, Color(VOID.r, VOID.g, VOID.b, 0.28 + 0.22 * k))
			for ring in range(3):
				var rr: float = radius * (0.45 + 0.27 * float(ring))
				var spin: float = t * (1.6 + float(ring)) * (1.0 if ring % 2 == 0 else -1.0)
				game.draw_arc(pos, rr, spin, spin + TAU * 0.78, 40, Color(GREEN.r, GREEN.g, GREEN.b, 0.35 + 0.4 * k), 2.0, true)
			for n in range(8):
				var a: float = float(n) * TAU / 8.0 + t * 0.7
				var p0: Vector2 = pos + Vector2.from_angle(a) * radius * 0.86
				game.draw_line(p0, p0 + Vector2.from_angle(a) * 9.0, Color(PALE.r, PALE.g, PALE.b, 0.6 * k + 0.2), 2.0)
			# Olho: abre conforme o golpe se aproxima.
			var eye_h: float = 4.0 + 14.0 * k
			var eye := PackedVector2Array()
			for s in range(17):
				var u: float = float(s) / 16.0
				var x: float = lerpf(-28.0, 28.0, u)
				var y: float = sin(u * PI) * eye_h
				eye.append(pos + Vector2(x, -y))
			for s in range(15, 0, -1):
				var u2: float = float(s) / 16.0
				eye.append(pos + Vector2(lerpf(-28.0, 28.0, u2), sin(u2 * PI) * eye_h))
			game.draw_colored_polygon(eye, Color(0.02, 0.06, 0.04, 0.85))
			game.draw_polyline(eye, Color(GREEN.r, GREEN.g, GREEN.b, 0.9), 2.0, true)
			game.draw_circle(pos, 3.0 + 4.0 * k, Color(PALE.r, PALE.g, PALE.b, 0.95))
		# Anel de contagem: fecha ate o golpe.
		game.draw_arc(pos, radius + 6.0, -PI * 0.5, -PI * 0.5 + TAU * k, 48, Color(PALE.r, PALE.g, PALE.b, 0.85), 3.0, true)
		return
	var b: float = clampf(blast / RTUmbraBaseSkills.ECO_BLAST_TIME, 0.0, 1.0)
	var btex: Texture2D = frame_at("eco", "blast", blast, 3.0 / RTUmbraBaseSkills.ECO_BLAST_TIME, false)
	if btex != null:
		draw_centered(game, btex, pos, radius * 2.8, Color(1, 1, 1, 1.0 - b * 0.6))
		return
	game.draw_circle(pos, radius * (0.6 + 0.6 * b), Color(VOID.r, VOID.g, VOID.b, 0.75 * (1.0 - b)))
	game.draw_circle(pos, radius * 0.55 * (1.0 - b), Color(PALE.r, PALE.g, PALE.b, 0.9 * (1.0 - b)))
	game.draw_arc(pos, radius * (0.8 + 0.7 * b), 0.0, TAU, 48, Color(GREEN.r, GREEN.g, GREEN.b, 1.0 - b), 4.0 * (1.0 - b) + 1.0, true)


static func _draw_rewind(game: Node2D, r: Dictionary, camera: Vector2, t: float) -> void:
	var anchor: Vector2 = Vector2(r["anchor"]) - camera
	var player: Vector2 = Vector2(game.player_pos) - camera
	var k: float = 1.0 - clampf(float(r["timer"]) / RTUmbraBaseSkills.REWIND_DELAY, 0.0, 1.0)
	var pulling: bool = float(r.get("pull", -1.0)) >= 0.0
	# Relogio no ponto de retorno.
	var clock: Texture2D = frame_at("rebobinar", "clock", t)
	if clock != null:
		draw_centered(game, clock, anchor, 150.0, Color(1, 1, 1, 0.8))
	else:
		game.draw_circle(anchor, 62.0, Color(VOID.r, VOID.g, VOID.b, 0.35))
		game.draw_arc(anchor, 62.0, 0.0, TAU, 48, Color(GREEN.r, GREEN.g, GREEN.b, 0.7), 2.5, true)
		for n in range(12):
			var a: float = float(n) * TAU / 12.0
			var inner: float = 50.0 if n % 3 == 0 else 55.0
			game.draw_line(anchor + Vector2.from_angle(a) * inner, anchor + Vector2.from_angle(a) * 60.0, Color(PALE.r, PALE.g, PALE.b, 0.8), 2.0)
		# Ponteiros girando ao contrario (rebobinando).
		game.draw_line(anchor, anchor + Vector2.from_angle(-t * 5.0 - PI * 0.5) * 44.0, Color(PALE.r, PALE.g, PALE.b, 0.95), 3.0)
		game.draw_line(anchor, anchor + Vector2.from_angle(-t * 0.8 - PI * 0.5) * 30.0, Color(GREEN.r, GREEN.g, GREEN.b, 0.95), 4.0)
		game.draw_arc(anchor, 66.0, -PI * 0.5, -PI * 0.5 - TAU * k, 48, Color(PALE.r, PALE.g, PALE.b, 0.9), 3.0, true)
	# Rastro temporal pelo caminho percorrido desde a marca.
	var path: Array = r.get("path", [])
	if path.size() >= 2:
		var pts := PackedVector2Array()
		for p in path:
			pts.append(Vector2(p) - camera)
		pts.append(player)
		game.draw_polyline(pts, Color(GREEN.r, GREEN.g, GREEN.b, 0.18 + 0.3 * k), 6.0, true)
		game.draw_polyline(pts, Color(PALE.r, PALE.g, PALE.b, 0.25 + 0.4 * k), 2.0, true)
	# Corrente ate o jogador: fica tensa conforme o tempo acaba.
	var chain_col := Color(GREEN.r, GREEN.g, GREEN.b, 0.35 + 0.55 * k)
	var seg: int = 14
	var prev: Vector2 = anchor
	for s in range(1, seg + 1):
		var u: float = float(s) / float(seg)
		var sag: float = sin(u * PI) * 26.0 * (1.0 - k)
		var p2: Vector2 = anchor.lerp(player, u) + Vector2(0, sag)
		if s % 2 == 1:
			game.draw_line(prev, p2, chain_col, 3.0, true)
		prev = p2
	if pulling:
		return
	# Ampulheta sobre o jogador.
	var head: Vector2 = player + Vector2(0, -86.0 + sin(t * 4.0) * 3.0)
	var glass: Texture2D = frame_at("rebobinar", "hourglass", t, 5.0)
	if glass != null:
		draw_centered(game, glass, head, 54.0)
		return
	var w: float = 14.0
	var h: float = 20.0
	var top := PackedVector2Array([head + Vector2(-w, -h), head + Vector2(w, -h), head])
	var bottom := PackedVector2Array([head, head + Vector2(w, h), head + Vector2(-w, h)])
	game.draw_colored_polygon(top, Color(VOID.r, VOID.g, VOID.b, 0.85 * (1.0 - k) + 0.15))
	game.draw_colored_polygon(bottom, Color(VOID.r, VOID.g, VOID.b, 0.2 + 0.7 * k))
	game.draw_polyline(PackedVector2Array([head + Vector2(-w, -h), head + Vector2(w, -h), head + Vector2(-w, h), head + Vector2(w, h), head + Vector2(-w, -h)]), Color(GREEN.r, GREEN.g, GREEN.b, 0.95), 2.0, true)
	game.draw_line(head + Vector2(-w - 3, -h), head + Vector2(w + 3, -h), PALE, 3.0)
	game.draw_line(head + Vector2(-w - 3, h), head + Vector2(w + 3, h), PALE, 3.0)
