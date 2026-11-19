class_name RTLarapioPresentation
extends RefCounted

## Leitura do Larapio no mapa grande: rastro de moedas no chao por onde ele passa,
## aviso do bote de roubo e seta na borda da tela quando ele sai da vista.
## So apresentacao: o rastro e derivado da posicao (que ja e replicada).

const TRAIL_LIFE := 7.0
const TRAIL_SPACING := 44.0
const TRAIL_MAX := 180
const GOLD := Color(1.0, 0.8, 0.24)
const GOLD_DARK := Color(0.45, 0.26, 0.04)
const PURPLE := Color(0.78, 0.24, 1.0)

## uid -> Array de {pos, t, side}
static var trails: Dictionary = {}


static func _larapios(game: Node2D) -> Array:
	var result: Array = []
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == game.ENEMY_LARAPIO and float(enemy.get("hp", 0.0)) > 0.0:
			result.append(enemy)
	return result


static func _update_trails(game: Node2D, larapios: Array) -> void:
	var now: float = float(game.time_alive)
	var alive: Dictionary = {}
	for enemy in larapios:
		var uid: int = int(enemy.get("uid", -1))
		alive[uid] = true
		var trail: Array = trails.get(uid, [])
		var pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		if trail.is_empty() or Vector2(Dictionary(trail[-1])["pos"]).distance_to(pos) >= TRAIL_SPACING:
			var side: float = -1.0 if trail.size() % 2 == 0 else 1.0
			trail.append({"pos": pos + Vector2(0.0, 22.0), "t": now, "side": side})
			if trail.size() > TRAIL_MAX:
				trail.pop_front()
		while not trail.is_empty() and now - float(Dictionary(trail[0])["t"]) > TRAIL_LIFE:
			trail.pop_front()
		trails[uid] = trail
	for uid in trails.keys():
		if not alive.has(uid):
			var stale: Array = trails[uid]
			while not stale.is_empty() and now - float(Dictionary(stale[0])["t"]) > TRAIL_LIFE:
				stale.pop_front()
			if stale.is_empty():
				trails.erase(uid)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var larapios := _larapios(game)
	if larapios.is_empty() and trails.is_empty():
		return
	_update_trails(game, larapios)
	var now: float = float(game.time_alive)
	var view: Vector2 = game.get_viewport_rect().size
	for uid in trails:
		var trail: Array = trails[uid]
		for i in range(trail.size()):
			var mark: Dictionary = trail[i]
			var p: Vector2 = Vector2(mark["pos"]) - camera
			if p.x < -30.0 or p.y < -30.0 or p.x > view.x + 30.0 or p.y > view.y + 30.0:
				continue
			var age: float = now - float(mark["t"])
			var fade: float = 1.0 - clampf(age / TRAIL_LIFE, 0.0, 1.0)
			var c: Vector2 = p + Vector2(float(mark["side"]) * 7.0, 0.0)
			# Moeda deitada no chao (elipse) com borda escura e brilho piscando.
			game.draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
			game.draw_circle(Vector2.ZERO, 6.5, Color(GOLD_DARK, 0.75 * fade))
			game.draw_circle(Vector2.ZERO, 5.0, Color(GOLD, 0.9 * fade))
			game.draw_circle(Vector2(-1.5, -1.5), 2.0, Color(1.0, 0.96, 0.7, 0.9 * fade))
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var glint: float = sin(now * 5.0 + float(i) * 1.7)
			if glint > 0.82 and fade > 0.25:
				var g: float = (glint - 0.82) / 0.18
				game.draw_line(c + Vector2(-6, 0) * g, c + Vector2(6, 0) * g, Color(1.0, 1.0, 0.86, 0.9 * fade), 1.4, true)
				game.draw_line(c + Vector2(0, -6) * g, c + Vector2(0, 6) * g, Color(1.0, 1.0, 0.86, 0.9 * fade), 1.4, true)
	for enemy in larapios:
		_draw_lunge(game, enemy, camera)


static func _draw_lunge(game: Node2D, enemy: Dictionary, camera: Vector2) -> void:
	var state: String = game.larapio_lunge_state(enemy)
	if state == "":
		return
	var pos: Vector2 = Vector2(enemy["pos"]) - camera
	var dir: Vector2 = Vector2(enemy.get("larapio_lunge_dir", Vector2.RIGHT)).normalized()
	var side: Vector2 = dir.orthogonal()
	if state == "windup":
		var p: float = 1.0 - clampf(float(enemy.get("larapio_lunge_windup", 0.0)) / game.LARAPIO_LUNGE_WINDUP, 0.0, 1.0)
		var length: float = game.LARAPIO_LUNGE_RANGE * 0.9
		var tip: Vector2 = pos + dir * length
		game.draw_colored_polygon(PackedVector2Array([pos + side * 22.0, tip + side * 30.0, tip - side * 30.0, pos - side * 22.0]), Color(GOLD, 0.08 + p * 0.14))
		game.draw_line(pos, pos.lerp(tip, p), Color(GOLD, 0.9), 4.0, true)
		game.draw_polyline(PackedVector2Array([tip - dir * 24.0 + side * 22.0, tip, tip - dir * 24.0 - side * 22.0]), Color(1.0, 0.94, 0.6, 0.6 + p * 0.4), 4.0, true)
		# "!" de aviso acima da cabeca.
		var head: Vector2 = pos + Vector2(0, -72)
		game.draw_circle(head, 12.0, Color(GOLD_DARK, 0.85))
		game.draw_circle(head, 10.0, Color(GOLD, 0.95))
		game.draw_line(head + Vector2(0, -6), head + Vector2(0, 2), Color(0.2, 0.08, 0.0), 3.0)
		game.draw_circle(head + Vector2(0, 6), 1.8, Color(0.2, 0.08, 0.0))
	else:
		for i in range(6):
			var lane: float = (float(i) / 5.0) * 2.0 - 1.0
			var start: Vector2 = pos - dir * 18.0 + side * lane * 20.0
			game.Boss1VFX.streak(game, start - dir * (70.0 + absf(lane) * -20.0), start, Color(GOLD, 0.7 - absf(lane) * 0.3), 4.0)


## Seta na borda da tela apontando para Larapio / Sineiro quando estao fora da vista.
static func draw_indicator(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	for enemy in _larapios(game):
		var loot: bool = int(enemy.get("stolen", 0)) > 0
		var meters: int = int(round(Vector2(enemy["pos"]).distance_to(game.player_pos) / 40.0))
		edge_marker(game, Vector2(enemy["pos"]), camera, viewport, (("LADRAO %dm" % meters) if loot else ("LARAPIO %dm" % meters)), Color(1.0, 0.36, 0.3) if loot else GOLD, "coin")
	for enemy in game.enemies:
		if String(enemy.get("type", "")) != "sineiro_boreal" or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var meters2: int = int(round(Vector2(enemy["pos"]).distance_to(game.player_pos) / 40.0))
		edge_marker(game, Vector2(enemy["pos"]), camera, viewport, "SINEIRO %dm" % meters2, Color(0.36, 1.0, 0.78), "bell")


static func edge_marker(game: Node2D, world_pos: Vector2, camera: Vector2, viewport: Vector2, label: String, tint: Color, icon: String) -> void:
	var p: Vector2 = world_pos - camera
	var margin := 54.0
	if p.x >= 0.0 and p.y >= 0.0 and p.x <= viewport.x and p.y <= viewport.y:
		return
	var center: Vector2 = viewport * 0.5
	var to: Vector2 = p - center
	if to.length() <= 1.0:
		return
	var dir: Vector2 = to.normalized()
	var half: Vector2 = viewport * 0.5 - Vector2(margin, margin)
	var scale_x: float = half.x / absf(dir.x) if absf(dir.x) > 0.001 else INF
	var scale_y: float = half.y / absf(dir.y) if absf(dir.y) > 0.001 else INF
	var at: Vector2 = center + dir * minf(scale_x, scale_y)
	var pulse: float = 0.5 + 0.5 * sin(float(game.time_alive) * 6.0)
	var tip: Vector2 = at + dir * 26.0
	game.draw_colored_polygon(PackedVector2Array([tip, at + dir.orthogonal() * 12.0 + dir * 6.0, at - dir.orthogonal() * 12.0 + dir * 6.0]), Color(tint, 0.95))
	game.draw_circle(at, 21.0 + pulse * 2.0, Color(0.06, 0.02, 0.1, 0.82))
	game.draw_arc(at, 21.0 + pulse * 2.0, 0.0, TAU, 32, Color(tint, 0.95), 2.5, true)
	if icon == "bell":
		game.draw_colored_polygon(PackedVector2Array([at + Vector2(-5, -8), at + Vector2(5, -8), at + Vector2(9, 6), at + Vector2(-9, 6)]), Color(0.86, 0.98, 1.0))
		game.draw_circle(at + Vector2(0, 9), 2.5, Color(0.72, 0.42, 1.0))
	else:
		game.draw_circle(at, 9.0, Color(GOLD_DARK))
		game.draw_circle(at, 7.5, Color(GOLD))
		game.draw_circle(at + Vector2(-2, -2), 2.5, Color(1.0, 0.96, 0.72))
	game._draw_centered(label, at + Vector2(0, 38), 12, Color(tint, 0.95))
