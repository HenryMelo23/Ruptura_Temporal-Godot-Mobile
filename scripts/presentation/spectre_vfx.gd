class_name RTSpectreVfx
extends RefCounted

## VFX dos espectros reformulados (Vanguarda, Sanguinaria, Voraz, Profetica,
## Peregrino, Avarento) e o aviso de recompensa comum a todos.
## So desenha; estado e regras ficam no AuraSystem e no runtime.

const FIRE := Color(1.0, 0.42, 0.06)
const EMBER := Color(1.0, 0.78, 0.3)
const BLOOD := Color(0.95, 0.06, 0.12)
const GOLD := Color(1.0, 0.84, 0.32)
const PILGRIM := Color(0.56, 0.9, 1.0)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var aura: Dictionary = game.aura_state
	var name: String = String(aura.get("name", ""))
	var t: float = float(game.time_alive)
	var player: Vector2 = Vector2(game.player_pos) - camera
	match name:
		"Vanguarda":
			_draw_fire_ring(game, player, aura, t)
		"Sanguinaria":
			_draw_blood_scent(game, camera, t)
		"Voraz":
			_draw_devour_marks(game, camera, t)
		"Profetica":
			_draw_prophecy(game, camera, player, aura, t)
		"Peregrino":
			_draw_pilgrim_path(game, camera, aura, t)
		"Avarento":
			_draw_avarice(game, camera, player, aura, t)
	for enemy in game.enemies:
		if float(enemy.get("aura_burn", 0.0)) > 0.0:
			_draw_burning(game, Vector2(enemy["pos"]) - camera, t, int(enemy.get("uid", 0)))
	for fx in game.spectre_fx:
		_draw_fx(game, camera, fx, t)


# ------------------------------------------------------------ Vanguarda
static func _draw_fire_ring(game: Node2D, center: Vector2, aura: Dictionary, t: float) -> void:
	var ring: float = float(aura.get("vanguard_ring", 0.0))
	if ring <= 0.0:
		return
	var radius: float = game.AuraSystem.vanguard_ring_radius(aura)
	var heat: int = int(aura.get("vanguard_heat", 1))
	var k: float = clampf(ring / 0.6, 0.0, 1.0)
	game.draw_set_transform(center + Vector2(0, 18), 0.0, Vector2(1.0, 0.62))
	game.draw_circle(Vector2.ZERO, radius, Color(1.0, 0.25, 0.02, 0.06 * k))
	game.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(1.0, 0.5, 0.1, 0.55 * k), 3.0, true)
	game.draw_arc(Vector2.ZERO, radius - 7.0, 0.0, TAU, 72, Color(1.0, 0.85, 0.4, 0.3 * k), 1.5, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var count: int = 26 + heat * 4
	for i in range(count):
		var ang: float = float(i) * TAU / float(count)
		var foot: Vector2 = center + Vector2(0, 18) + Vector2(cos(ang) * radius, sin(ang) * radius * 0.62)
		var flick: float = 0.6 + 0.4 * sin(t * (9.0 + float(i % 5)) + float(i) * 1.7)
		var h: float = (24.0 + heat * 5.0) * flick
		var w: float = 8.0 + heat * 0.8
		_draw_flame(game, foot, w, h, k, i)
	# Brasas subindo.
	for i in range(10 + heat * 2):
		var ang: float = fposmod(float(i) * 2.399, TAU)
		var life: float = fposmod(t * 0.9 + float(i) * 0.37, 1.0)
		var p: Vector2 = center + Vector2(0, 18) + Vector2(cos(ang) * radius * (0.6 + 0.4 * fposmod(float(i) * 0.31, 1.0)), sin(ang) * radius * 0.5) + Vector2(sin(t * 3.0 + i) * 4.0, -life * 60.0)
		game.draw_circle(p, 1.6 + (1.0 - life) * 1.4, Color(EMBER.r, EMBER.g, EMBER.b, (1.0 - life) * 0.8 * k))


static func _draw_flame(game: Node2D, foot: Vector2, w: float, h: float, alpha: float, seed: int) -> void:
	var sway: float = sin(float(game.time_alive) * 7.0 + float(seed)) * w * 0.5
	var outer := PackedVector2Array([foot + Vector2(-w, 0), foot + Vector2(-w * 0.55, -h * 0.45), foot + Vector2(sway, -h), foot + Vector2(w * 0.55, -h * 0.5), foot + Vector2(w, 0)])
	game.draw_colored_polygon(outer, Color(1.0, 0.32, 0.04, 0.75 * alpha))
	var inner := PackedVector2Array([foot + Vector2(-w * 0.5, 0), foot + Vector2(sway * 0.6, -h * 0.62), foot + Vector2(w * 0.5, 0)])
	game.draw_colored_polygon(inner, Color(1.0, 0.82, 0.35, 0.85 * alpha))


static func _draw_burning(game: Node2D, p: Vector2, t: float, uid: int) -> void:
	for i in range(3):
		var foot: Vector2 = p + Vector2(-14.0 + i * 14.0, 14.0)
		var h: float = 24.0 + 10.0 * sin(t * 11.0 + float(uid + i))
		_draw_flame(game, foot, 8.0, h, 0.9, uid * 3 + i)


# ------------------------------------------------------------ Sanguinaria
static func _rule_badge(rule: String, quadrant: int) -> String:
	match rule:
		"basic_attack":
			return "ATK"
		"hab1":
			return "HAB1"
		"ultimate":
			return "ULT"
	return "QUAD"


## Faro: gotas de sangue escorrendo ate a presa, coracao batendo nela e o
## botao exato que precisa matar (igual ao botao da tela).
static func _draw_blood_scent(game: Node2D, camera: Vector2, t: float) -> void:
	var hunted: Dictionary = game._sanguinaria_find_hunt_enemy()
	if hunted.is_empty():
		return
	var target: Vector2 = Vector2(hunted.get("pos", game.player_pos)) - camera
	var start: Vector2 = Vector2(game.player_pos) - camera
	var dist: float = start.distance_to(target)
	if dist > 30.0:
		var dir: Vector2 = (target - start) / dist
		var n: Vector2 = dir.orthogonal()
		var steps: int = clampi(int(dist / 34.0), 3, 26)
		var flow: float = fposmod(t * 1.6, 1.0)
		for i in range(steps):
			var u: float = (float(i) + flow) / float(steps)
			var p: Vector2 = start.lerp(target, u) + n * sin(u * 9.0 + t * 2.0) * 9.0
			var size: float = 4.0 + 3.0 * sin(u * PI)
			var a: float = 0.45 + 0.5 * u
			# Gota: circulo + ponta virada para a presa.
			game.draw_circle(p, size, Color(0.55, 0.0, 0.04, a))
			game.draw_colored_polygon(PackedVector2Array([p + n * size, p + dir * size * 2.2, p - n * size]), Color(0.75, 0.02, 0.06, a))
	# Coracao: duas batidas, pausa.
	var beat: float = fposmod(t, 1.0)
	var pulse: float = maxf(exp(-pow((beat - 0.08) * 18.0, 2.0)), exp(-pow((beat - 0.3) * 18.0, 2.0)))
	game.draw_arc(target, 34.0 + pulse * 14.0, 0.0, TAU, 40, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.35 + pulse * 0.5), 3.0 + pulse * 2.0, true)
	game.draw_circle(target, 30.0, Color(0.6, 0.0, 0.04, 0.12 + pulse * 0.12))
	# Botao que precisa dar o golpe final.
	var rule: String = String(game.aura_state.get("blood_hunt_rule", ""))
	var quadrant: int = int(game.aura_state.get("blood_hunt_quadrant", -1))
	var badge: Vector2 = target + Vector2(0.0, -78.0 - pulse * 4.0)
	game.draw_circle(badge, 21.0, Color(0.08, 0.0, 0.02, 0.92))
	game.draw_arc(badge, 21.0, 0.0, TAU, 32, BLOOD, 3.0, true)
	if rule == "quadrant":
		for q in range(4):
			var cell := Rect2(badge + Vector2(-12.0 + (q % 2) * 12.0, -12.0 + (q / 2) * 12.0), Vector2(11, 11))
			game.draw_rect(cell, BLOOD if q == quadrant else Color(0.35, 0.1, 0.12, 0.8), q == quadrant)
	else:
		game._draw_centered(_rule_badge(rule, quadrant), badge + Vector2(0.0, 5.0), 12 if rule != "hab1" else 10, Color(1.0, 0.86, 0.86))
	game._draw_centered("FINALIZE COM", badge + Vector2(0.0, -28.0), 10, Color(1.0, 0.5, 0.52, 0.85))


# ------------------------------------------------------------ Voraz
## Presas abaixo do limite de devorar ganham uma marca de presas (dentes).
static func _draw_devour_marks(game: Node2D, camera: Vector2, t: float) -> void:
	var threshold: float = game.AuraSystem.voracious_devour_threshold(game.aura_state)
	for enemy in game.enemies:
		var ratio: float = float(enemy.get("hp", 1.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0)))
		var limit: float = threshold * (0.6 if bool(enemy.get("elite", false)) else 1.0)
		if ratio > limit or ratio <= 0.0:
			continue
		var pos: Vector2 = Vector2(enemy["pos"])
		if pos.distance_to(game.player_pos) > 560.0:
			continue
		var p: Vector2 = pos - camera + Vector2(0, -50)
		var bob: float = sin(t * 8.0 + pos.x) * 2.0
		game.draw_circle(p + Vector2(0, bob), 20.0, Color(0.6, 0.0, 0.02, 0.35))
		_draw_fangs(game, p + Vector2(0, bob), 14.0, 0.8 + 0.2 * sin(t * 10.0), 0.15 + 0.15 * sin(t * 6.0))


static func _draw_fangs(game: Node2D, c: Vector2, r: float, alpha: float, close: float) -> void:
	var gap: float = r * 0.55 * (1.0 - close)
	for side in [-1.0, 1.0]:
		var jaw := PackedVector2Array()
		for i in range(4):
			var x: float = -r + float(i) * r * 0.66
			jaw.append(c + Vector2(x, side * gap))
			jaw.append(c + Vector2(x + r * 0.33, side * (gap + r * 0.55)))
		jaw.append(c + Vector2(r, side * gap))
		game.draw_polyline(jaw, Color(1.0, 0.95, 0.9, alpha), 2.0, true)
	game.draw_arc(c, r * 1.35, 0.0, TAU, 24, Color(0.9, 0.08, 0.04, alpha * 0.8), 2.0, true)


# ------------------------------------------------------------ Profetica
static func _draw_prophecy(game: Node2D, camera: Vector2, player: Vector2, aura: Dictionary, t: float) -> void:
	var vision: float = float(aura.get("prophecy_vision", 0.0))
	var fate: int = int(aura.get("prophecy_fate", 0))
	# Olhos de destino orbitando: cada um e um critico guardado.
	for i in range(fate):
		var ang: float = t * 2.2 + float(i) * TAU / maxf(1.0, float(fate))
		var p: Vector2 = player + Vector2(0, -34) + Vector2(cos(ang) * 40.0, sin(ang) * 16.0)
		_draw_eye(game, p, 8.0, 1.0)
	if vision <= 0.0:
		return
	var k: float = clampf(vision / 0.4, 0.0, 1.0)
	var look: float = 0.9
	# Borda dourada: a tela inteira "esta no futuro".
	var view: Vector2 = game.get_viewport_rect().size
	for i in range(4):
		var inset: float = 4.0 + float(i) * 7.0
		game.draw_rect(Rect2(Vector2(inset, inset), view - Vector2(inset, inset) * 2.0), Color(GOLD.r, GOLD.g, GOLD.b, (0.32 - i * 0.07) * k), false, 3.0)
	for bullet in game.enemy_bullets:
		var pos: Vector2 = Vector2(bullet.get("pos", Vector2.ZERO))
		var dir: Vector2 = Vector2(bullet.get("dir", Vector2.ZERO))
		if dir.length() < 0.01:
			continue
		var speed: float = 210.0 * float(bullet.get("speed_mult", 1.0)) * game.AuraSystem.world_multiplier(game.aura_state)
		var future: Vector2 = pos + dir.normalized() * speed * look
		var a: Vector2 = pos - camera
		var b: Vector2 = future - camera
		var segs: int = 8
		for s in range(segs):
			if s % 2 == 1:
				continue
			game.draw_line(a.lerp(b, float(s) / segs), a.lerp(b, float(s + 1) / segs), Color(GOLD.r, GOLD.g, GOLD.b, 0.5 * k), 2.0, true)
		game.draw_circle(b, 7.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.22 * k))
		game.draw_arc(b, 9.0, 0.0, TAU, 16, Color(1.0, 0.95, 0.7, 0.75 * k), 1.5, true)
	for enemy in game.enemies:
		var pos: Vector2 = Vector2(enemy["pos"])
		if pos.distance_to(game.player_pos) > 620.0:
			continue
		var to_player: Vector2 = Vector2(game.player_pos) - pos
		var step: float = minf(to_player.length() * 0.6, float(enemy.get("speed", 80.0)) * look)
		var future: Vector2 = pos + to_player.normalized() * step
		var size: Vector2 = game._enemy_draw_size(enemy)
		game._draw_enemy_texture_raw(game._enemy_texture(enemy), future - camera, size, 0.0, Color(1.0, 0.86, 0.35, 0.22 * k), game._enemy_should_flip(enemy))


static func _draw_eye(game: Node2D, c: Vector2, r: float, alpha: float) -> void:
	game.draw_arc(c, r, PI * 0.15, PI * 0.85, 12, Color(GOLD.r, GOLD.g, GOLD.b, alpha), 2.0, true)
	game.draw_arc(c, r, PI * 1.15, PI * 1.85, 12, Color(GOLD.r, GOLD.g, GOLD.b, alpha), 2.0, true)
	game.draw_circle(c, r * 0.35, Color(1.0, 1.0, 1.0, alpha))


# ------------------------------------------------------------ Peregrino
static func _draw_pilgrim_path(game: Node2D, camera: Vector2, aura: Dictionary, t: float) -> void:
	var path: Array = aura.get("peregrino_path", [])
	if path.size() < 2:
		return
	for i in range(1, path.size()):
		var a: Vector2 = Vector2(path[i - 1]["pos"]) - camera
		var b: Vector2 = Vector2(path[i]["pos"]) - camera
		var life: float = clampf(float(path[i].get("life", 0.0)) / maxf(0.01, float(path[i].get("max", 1.0))), 0.0, 1.0)
		var shimmer: float = 0.75 + 0.25 * sin(t * 6.0 - float(i) * 0.6)
		game.draw_line(a, b, Color(PILGRIM.r, PILGRIM.g, PILGRIM.b, 0.16 * life), 16.0, true)
		game.draw_line(a, b, Color(PILGRIM.r, PILGRIM.g, PILGRIM.b, 0.65 * life * shimmer), 4.0, true)
		game.draw_line(a, b, Color(1.0, 1.0, 1.0, 0.55 * life), 1.4, true)
		if i % 3 == 0:
			var n: Vector2 = (b - a).orthogonal().normalized() * (5.0 if (i / 3) % 2 == 0 else -5.0)
			game.draw_circle(b + n, 3.0, Color(1.0, 0.95, 0.75, 0.5 * life))
	# Ponta: onde o laco pode fechar.
	var head: Vector2 = Vector2(path[path.size() - 1]["pos"]) - camera
	game.draw_arc(head, 12.0 + sin(t * 8.0) * 2.0, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.6), 2.0, true)


# ------------------------------------------------------------ Avarento
static func _draw_avarice(game: Node2D, camera: Vector2, player: Vector2, aura: Dictionary, t: float) -> void:
	var lastro: float = float(aura.get("avarento_lastro", 0.0))
	var coins: int = clampi(int(round(lastro * 2.0)), 0, 10)
	var cofre: bool = float(aura.get("avarento_cofre", 0.0)) > 0.0
	var pending: bool = int(aura.get("avarento_pending", 0)) > 0
	# Moedas do lastro: pesadas, giram baixo; com o cofre aberto, sobem.
	for i in range(coins):
		var ang: float = t * (1.2 if not cofre else 3.4) + float(i) * TAU / maxf(1.0, float(coins))
		var height: float = -8.0 if not cofre else -46.0
		var p: Vector2 = player + Vector2(0, height) + Vector2(cos(ang) * 44.0, sin(ang) * 15.0)
		_draw_coin(game, p, 6.0, t * 6.0 + float(i), 0.95)
	if float(aura.get("avarento_shield", 0.0)) > 0.0:
		var pulse: float = 0.5 + 0.5 * sin(t * 5.0)
		game.draw_circle(player + Vector2(0, -36), 52.0, Color(1.0, 0.8, 0.25, 0.08 + pulse * 0.04))
		game.draw_arc(player + Vector2(0, -36), 52.0, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, 0.65), 2.5, true)
		for i in range(6):
			var ang: float = float(i) * TAU / 6.0 + t * 0.6
			game.draw_line(player + Vector2(0, -36) + Vector2.from_angle(ang) * 48.0, player + Vector2(0, -36) + Vector2.from_angle(ang + 0.5) * 48.0, Color(1.0, 0.95, 0.7, 0.5), 2.0, true)
	if pending:
		game._draw_centered("COFRE ARMADO", player + Vector2(0, -98), 12, Color(GOLD.r, GOLD.g, GOLD.b, 0.9))
	for frag in Array(aura.get("avarento_fragments", [])):
		var p: Vector2 = Vector2(frag.get("pos", Vector2.ZERO)) - camera
		_draw_coin(game, p + Vector2(0, sin(t * 4.0 + p.x) * 3.0), 8.0, t * 5.0 + p.x, clampf(float(frag.get("life", 0.0)) / 0.6, 0.0, 1.0))


static func _draw_coin(game: Node2D, c: Vector2, r: float, spin: float, alpha: float) -> void:
	var sx: float = maxf(0.18, absf(cos(spin)))
	game.draw_set_transform(c, 0.0, Vector2(sx, 1.0))
	game.draw_circle(Vector2.ZERO, r, Color(0.75, 0.48, 0.08, alpha))
	game.draw_circle(Vector2.ZERO, r * 0.78, Color(1.0, 0.82, 0.25, alpha))
	game.draw_arc(Vector2.ZERO, r * 0.5, 0.0, TAU, 12, Color(0.85, 0.58, 0.12, alpha), 1.4, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------ efeitos pontuais
static func _draw_fx(game: Node2D, camera: Vector2, fx: Dictionary, t: float) -> void:
	var k: float = clampf(float(fx.get("life", 0.0)) / maxf(0.01, float(fx.get("max", 1.0))), 0.0, 1.0)
	var u: float = 1.0 - k
	var p: Vector2 = Vector2(fx.get("pos", Vector2.ZERO)) - camera
	match String(fx.get("kind", "")):
		"heat_wave":
			var radius: float = lerpf(30.0, float(fx.get("radius", 150.0)) * 1.15, 1.0 - pow(1.0 - u, 3.0))
			var heat: int = int(fx.get("heat", 1))
			game.draw_set_transform(p + Vector2(0, 10), 0.0, Vector2(1.0, 0.7))
			for i in range(4):
				var rr: float = radius - float(i) * 9.0
				var col: Color = Color(1.0, 0.95, 0.75) if i == 0 else Color(1.0, 0.55 - i * 0.1, 0.1)
				game.draw_arc(Vector2.ZERO, maxf(4.0, rr), 0.0, TAU, 64, Color(col.r, col.g, col.b, (0.9 - i * 0.18) * k), 6.0 - i, true)
			game.draw_circle(Vector2.ZERO, radius * 0.9, Color(1.0, 0.35, 0.05, 0.12 * k))
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in range(14 + heat * 3):
				var ang: float = float(i) * 2.399
				var q: Vector2 = p + Vector2(cos(ang), sin(ang) * 0.7) * radius * (0.75 + 0.3 * fposmod(float(i) * 0.43, 1.0))
				game.draw_circle(q, 2.5 * k + 1.0, Color(EMBER.r, EMBER.g, EMBER.b, k))
		"devour":
			var big: bool = bool(fx.get("big", false))
			var r: float = (34.0 if not big else 70.0)
			var close: float = clampf(u / 0.35, 0.0, 1.0)
			_draw_fangs(game, p + Vector2(0, -30), r, k, close)
			if u > 0.3:
				for i in range(12):
					var ang: float = float(i) * TAU / 12.0
					var q: Vector2 = p + Vector2(0, -30) + Vector2.from_angle(ang) * (u - 0.3) * (90.0 if not big else 160.0)
					game.draw_circle(q, 4.0 * k, Color(0.8, 0.02, 0.05, k))
		"blood_kill":
			var to: Vector2 = Vector2(fx.get("to", fx.get("pos", Vector2.ZERO))) - camera
			for i in range(6):
				var lag: float = float(i) * 0.06
				var v: float = clampf((u - lag) / 0.7, 0.0, 1.0)
				var q: Vector2 = p.lerp(to + Vector2(0, -40), v * v) + Vector2(0, -sin(v * PI) * 50.0)
				game.draw_circle(q, 5.0 - i * 0.5, Color(BLOOD.r, BLOOD.g, BLOOD.b, k))
		"reward_ring":
			var col: Color = Color(fx.get("color", GOLD))
			var player: Vector2 = Vector2(game.player_pos) - camera + Vector2(0, -34)
			game.draw_arc(player, lerpf(26.0, 92.0, u), 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.85 * k), 3.0 * k + 1.0, true)
			for i in range(8):
				var ang: float = float(i) * TAU / 8.0 + u * 1.5
				game.draw_line(player + Vector2.from_angle(ang) * lerpf(30.0, 70.0, u), player + Vector2.from_angle(ang) * lerpf(40.0, 100.0, u), Color(1.0, 1.0, 1.0, 0.7 * k), 2.0)
		"prophecy_open":
			var player: Vector2 = Vector2(game.player_pos) - camera + Vector2(0, -40)
			var open: float = sin(u * PI)
			var w: float = 60.0 + 260.0 * u
			game.draw_set_transform(player, 0.0, Vector2(1.0, maxf(0.05, open * 0.45)))
			game.draw_arc(Vector2.ZERO, w, PI * 0.1, PI * 0.9, 32, Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * k), 4.0, true)
			game.draw_arc(Vector2.ZERO, w, PI * 1.1, PI * 1.9, 32, Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * k), 4.0, true)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			game.draw_circle(player, 14.0 * open, Color(1.0, 1.0, 1.0, 0.8 * k))
		"prophecy_crit":
			var player: Vector2 = Vector2(game.player_pos) - camera + Vector2(0, -34)
			_draw_eye(game, player, 18.0 + u * 20.0, k)
		"prophecy_dodge":
			var to: Vector2 = Vector2(fx.get("to", fx.get("pos", Vector2.ZERO))) - camera + Vector2(0, -34)
			var q: Vector2 = p.lerp(to, u * u)
			_draw_eye(game, q, 9.0, k)
			game.draw_line(p, q, Color(GOLD.r, GOLD.g, GOLD.b, 0.5 * k), 2.0, true)
		"territory":
			var poly: PackedVector2Array = fx.get("polygon", PackedVector2Array())
			if poly.size() >= 3:
				var screen := PackedVector2Array()
				for v in poly:
					screen.append(v - camera)
				var fill: float = (1.0 - u) if u > 0.25 else u / 0.25
				game.draw_colored_polygon(screen, Color(PILGRIM.r, PILGRIM.g, PILGRIM.b, 0.45 * fill))
				game.draw_polyline(screen + PackedVector2Array([screen[0]]), Color(PILGRIM.r, PILGRIM.g, PILGRIM.b, 0.35 * k), 14.0, true)
				game.draw_polyline(screen + PackedVector2Array([screen[0]]), Color(1.0, 1.0, 1.0, 0.9 * k), 3.0, true)
				var centroid := Vector2.ZERO
				for v in screen:
					centroid += v
				centroid /= float(screen.size())
				for i in range(screen.size()):
					if i % 2 == 0:
						var q: Vector2 = screen[i].lerp(centroid, u) + Vector2(0, -u * 60.0)
						game.draw_circle(q, 3.0 * k + 1.0, Color(1.0, 1.0, 0.85, k))
		"coin_burst":
			var count: int = int(fx.get("count", 14))
			for i in range(count):
				var ang: float = float(i) * 2.399
				var dist: float = (60.0 + fposmod(float(i) * 37.0, 130.0)) * (1.0 - pow(1.0 - u, 2.0))
				var q: Vector2 = p + Vector2(0, -30) + Vector2.from_angle(ang) * dist + Vector2(0, u * u * 60.0)
				_draw_coin(game, q, 7.0, t * 9.0 + float(i), k)
			game.draw_arc(p + Vector2(0, -30), 190.0 * u, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, 0.7 * k), 3.0, true)


# ------------------------------------------------------------ aviso de recompensa
## Faixa abaixo do HUD dizendo exatamente o que melhorou (ou o que perdeu).
static func draw_toasts(game: Node2D, viewport: Vector2) -> void:
	var y: float = 112.0
	for toast in game.spectre_toasts:
		var life: float = float(toast.get("life", 0.0))
		var max_life: float = float(toast.get("max", 2.4))
		var age: float = max_life - life
		var appear: float = clampf(age / 0.18, 0.0, 1.0)
		var fade: float = clampf(life / 0.35, 0.0, 1.0)
		var a: float = appear * fade
		var color: Color = Color(toast.get("color", GOLD))
		var lines: Array = toast.get("lines", [])
		var w: float = minf(viewport.x - 40.0, 460.0)
		var h: float = 34.0 + 18.0 * float(lines.size())
		var pop: float = 1.0 + (1.0 - appear) * 0.15
		var rect := Rect2(Vector2(viewport.x * 0.5 - w * 0.5 * pop, y), Vector2(w * pop, h))
		game.draw_rect(rect, Color(0.03, 0.02, 0.05, 0.86 * a), true)
		game.draw_rect(Rect2(rect.position, Vector2(6.0, rect.size.y)), Color(color.r, color.g, color.b, a), true)
		game.draw_rect(rect, Color(color.r, color.g, color.b, 0.75 * a), false, 2.0)
		var icon: String = "+" if String(toast.get("kind", "gain")) == "gain" else ("!" if String(toast.get("kind", "")) == "warn" else "-")
		game._draw_centered_outlined("%s %s" % [icon, String(toast.get("title", ""))], Vector2(viewport.x * 0.5, y + 24.0), 18, Color(1.0, 1.0, 1.0, a), Color(0.0, 0.0, 0.0, 0.8 * a), 3)
		for i in range(lines.size()):
			game._draw_centered(String(lines[i]), Vector2(viewport.x * 0.5, y + 44.0 + 18.0 * float(i)), 13, Color(color.lerp(Color.WHITE, 0.55).r, color.lerp(Color.WHITE, 0.55).g, color.lerp(Color.WHITE, 0.55).b, a))
		y += h + 8.0
