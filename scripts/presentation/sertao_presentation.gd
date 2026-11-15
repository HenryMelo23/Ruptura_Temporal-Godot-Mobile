class_name RTSertaoPresentation
extends RefCounted

## Visual da Dimensao 8 (Sertao das Tartarugas): sprites, projeteis, perigos no chao,
## sombra do gnomon, eclipse e calor de tela.

const DIR := "res://assets/sprites/sertao/"
const ENEMY_FRAMES := {
	"s8_jabuti": 4, "s8_mandacaru": 4, "s8_morteiro": 4, "s8_piao": 4,
	"s8_cangaceiro": 16, "s8_egg": 2,
	"boss8_walk": 4, "boss8_cast": 4, "boss8_retract": 2, "boss8_roll": 2,
	"boss8_eclipse": 4, "boss8_death": 4, "boss8_hurt": 1, "boss8_sun": 1,
}
const KIND_KEY := {
	"jabuti_errante": "s8_jabuti",
	"tartaruga_mandacaru": "s8_mandacaru",
	"jabuti_morteiro": "s8_morteiro",
	"cagado_piao": "s8_piao",
	"cagado_cangaceiro": "s8_cangaceiro",
	"ovo_jabuti": "s8_egg",
}
const DRAW_SIZES := {
	"jabuti_errante": Vector2(96, 96),
	"tartaruga_mandacaru": Vector2(132, 132),
	"jabuti_morteiro": Vector2(122, 122),
	"cagado_piao": Vector2(108, 108),
	"cagado_cangaceiro": Vector2(176, 176),
	"ovo_jabuti": Vector2(64, 64),
}
const OUTLINE := Color(0.14, 0.06, 0.03, 0.85)


static func load_textures(game: Node) -> void:
	for key in ENEMY_FRAMES.keys():
		var frames: Array = []
		for i in range(int(ENEMY_FRAMES[key])):
			var path := "%s%s_%d.png" % [DIR, key, i]
			frames.append(load(path) if ResourceLoader.exists(path) else null)
		game.textures[key] = frames


static func _frame(game: Node, key: String, index: int) -> Texture2D:
	if not game.textures.has(key):
		RTRuntimeAssetController.ensure_key(game, key, "res://assets/sprites/")
	var frames: Array = game.textures.get(key, [])
	if frames.is_empty():
		return null
	var tex = frames[posmod(index, frames.size())]
	return tex if tex is Texture2D else null


# ================================================================ inimigos
static func enemy_draw_size(kind: String) -> Vector2:
	return DRAW_SIZES.get(kind, Vector2(72, 72))


static func enemy_texture(game: Node, enemy: Dictionary) -> Texture2D:
	var kind := String(enemy.get("type", ""))
	var key := String(KIND_KEY.get(kind, ""))
	if key == "":
		return null
	var state := String(enemy.get("s8_state", "walk"))
	var step: int = int(float(enemy.get("phase", 0.0)) * 0.5)
	var fast: int = int(float(enemy.get("phase", 0.0)) * 1.4)
	match kind:
		"jabuti_errante":
			if state in ["windup", "spin"]:
				return _frame(game, key, 2 + fast % 2)
			return _frame(game, key, 0 if state == "dizzy" else step % 2)
		"tartaruga_mandacaru":
			if state in ["root", "fire", "uproot"]:
				return _frame(game, key, 2 + (int(float(enemy.get("s8_t", 0.0)) * 6.0) % 2))
			return _frame(game, key, step % 2)
		"jabuti_morteiro":
			if state == "aim":
				return _frame(game, key, 2)
			if state == "launch":
				return _frame(game, key, 3)
			return _frame(game, key, step % 2)
		"cagado_piao":
			if state in ["spinup", "dash"]:
				return _frame(game, key, 2 + fast % 2)
			return _frame(game, key, 0 if state == "dizzy" else step % 2)
		"cagado_cangaceiro":
			match state:
				"rajada_aim", "rajada", "tocaia_prep", "tocaia":
					var shot: int = 1 + int(float(enemy.get("s8_t", 0.0)) * 9.0) % 3 if float(enemy.get("s8_flash", 0.0)) > 0.0 else 0
					return _frame(game, key, 4 + shot)
				"xaxado":
					return _frame(game, key, 8 + int(float(enemy.get("s8_t", 0.0)) * 10.0) % 4)
				"casco_prep", "casco":
					return _frame(game, key, 12 + fast % 2)
				"dizzy":
					return _frame(game, key, 14)
			return _frame(game, key, int(float(enemy.get("phase", 0.0)) * 0.8) % 4)
		"ovo_jabuti":
			return _frame(game, key, 1 if float(enemy.get("s8_t", 0.0)) > 2.2 else 0)
	return null


# ================================================================ chao
static func draw_ground(game: Node, camera: Vector2) -> void:
	var s8: RTSertaoController = game.sertao_controller
	var b8: RTBoss8Controller = game.boss8_controller
	var now: float = game.time_alive
	# Ovos do morteiro: marca no chao onde vao cair.
	for h in s8.hazards:
		match String(h.get("kind", "")):
			"egg":
				var k: float = clampf(float(h["t"]) / maxf(0.01, float(h["flight"])), 0.0, 1.0)
				var c: Vector2 = Vector2(h["to"]) - camera
				var r: float = RTSertaoController.MORTEIRO_BLAST
				game.draw_circle(c, r, Color(1.0, 0.42, 0.12, 0.08 + 0.16 * k))
				game.draw_arc(c, r, 0.0, TAU, 36, Color(1.0, 0.56, 0.2, 0.55 + 0.4 * k), 2.0)
				game.draw_arc(c, r * (1.0 - k), 0.0, TAU, 28, Color(1.0, 0.86, 0.5, 0.7), 1.6)
			"tocaia":
				if bool(h.get("fired", false)):
					for b in s8.bullets:
						if float(b.get("delay", 0.0)) > 0.0 and bool(b.get("aim", false)) and int(b.get("owner", 0)) == int(h.get("owner", 0)):
							var from: Vector2 = Vector2(b["p"]) - camera
							var to: Vector2 = game.player_pos - camera
							game.draw_line(from, from.lerp(to, 0.35), Color(0.5, 0.95, 1.0, 0.28), 1.2)
	# Raiz da Mandacaru: anel verde sob ela enquanto plantada.
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == RTSertaoController.MANDACARU and String(enemy.get("s8_state", "")) in ["root", "fire"]:
			var ep: Vector2 = Vector2(enemy["pos"]) - camera
			if not game._world_point_in_view(Vector2(enemy["pos"]), camera, 120.0):
				continue
			var pulse: float = 0.5 + 0.5 * sin(now * 10.0)
			game.draw_arc(ep + Vector2(0, 18), 46.0 + pulse * 4.0, 0.0, TAU, 28, Color(0.6, 1.0, 0.3, 0.45), 2.0)
		elif String(enemy.get("type", "")) == RTSertaoController.CANGACEIRO and String(enemy.get("s8_state", "")) == "rajada_aim":
			var cp: Vector2 = Vector2(enemy["pos"]) - camera + Vector2(0, -40)
			var aim: Vector2 = Vector2(enemy.get("s8_aim", Vector2.RIGHT))
			game.draw_line(cp, cp + aim * 420.0, Color(1.0, 0.84, 0.3, 0.35), 2.0)
	if game.current_phase != RTSertaoController.PHASE:
		return
	if b8.death_t >= 0.0:
		_draw_boss_death(game, camera)
	if not game.boss_active:
		return
	# Sombra do gnomon.
	if b8.shadow_on:
		_draw_shadow_wedge(game, camera, Color(0.04, 0.07, 0.16, 0.32), true)
	# Rolagem: faixa de aviso.
	if b8.mode == "roll_prep":
		var from: Vector2 = Vector2(game.boss_pos) - camera + Vector2(0, -30)
		var to: Vector2 = from + b8.roll_dir * RTBoss8Controller.ROLL_DISTANCE
		var pulse2: float = 0.5 + 0.5 * sin(now * 22.0)
		game.draw_line(from, to, Color(1.0, 0.4, 0.12, 0.18 + 0.12 * pulse2), 96.0)
		game.draw_line(from, to, Color(1.0, 0.72, 0.3, 0.6), 2.0)
	# Ampulheta: feixes de luz marcando as brechas.
	if b8.mode == "ampulheta":
		var viewport: Vector2 = game.get_viewport_rect().size
		var width: float = viewport.x + 160.0
		var left: float = game.player_pos.x - width * 0.5 - camera.x
		for g in b8.gap_centers():
			var x: float = left + float(g) * width
			var w: float = width * 0.15
			game.draw_rect(Rect2(Vector2(x - w * 0.5, 0.0), Vector2(w, viewport.y)), Color(0.7, 0.95, 1.0, 0.07))
			game.draw_line(Vector2(x - w * 0.5, 0.0), Vector2(x - w * 0.5, viewport.y), Color(0.7, 0.95, 1.0, 0.18), 1.0)
			game.draw_line(Vector2(x + w * 0.5, 0.0), Vector2(x + w * 0.5, viewport.y), Color(0.7, 0.95, 1.0, 0.18), 1.0)


static func _shadow_polygon(game: Node, camera: Vector2) -> PackedVector2Array:
	var b8: RTBoss8Controller = game.boss8_controller
	var origin: Vector2 = Vector2(game.boss_pos) - camera
	var pts := PackedVector2Array([origin])
	var steps := 10
	for i in range(steps + 1):
		var a: float = b8.shadow_angle - RTBoss8Controller.GNOMON_HALF_WIDTH + 2.0 * RTBoss8Controller.GNOMON_HALF_WIDTH * float(i) / float(steps)
		pts.append(origin + Vector2.from_angle(a) * RTBoss8Controller.GNOMON_LENGTH)
	return pts


static func _draw_shadow_wedge(game: Node, camera: Vector2, color: Color, edges: bool) -> void:
	var pts := _shadow_polygon(game, camera)
	game.draw_colored_polygon(pts, color)
	if edges:
		var b8: RTBoss8Controller = game.boss8_controller
		var origin: Vector2 = pts[0]
		for side in [-1.0, 1.0]:
			var a: float = b8.shadow_angle + RTBoss8Controller.GNOMON_HALF_WIDTH * float(side)
			game.draw_line(origin, origin + Vector2.from_angle(a) * RTBoss8Controller.GNOMON_LENGTH, Color(0.5, 0.7, 1.0, 0.35), 2.0)


static func _draw_boss_death(game: Node, camera: Vector2) -> void:
	var b8: RTBoss8Controller = game.boss8_controller
	var k: float = clampf(b8.death_t / 2.2, 0.0, 1.0)
	var tex: Texture2D = _frame(game, "boss8_death", mini(3, int(k * 4.0)))
	var alpha: float = clampf((3.0 - b8.death_t) / 0.8, 0.0, 1.0)
	var pos: Vector2 = b8.death_pos - camera
	if tex != null:
		game._draw_entity_fit_flipped(tex, pos, RTBoss8Controller.DRAW_SIZE, b8.facing < 0.0, Color(1, 1, 1, alpha), true)
	for i in range(6):
		var a: float = float(i) * TAU / 6.0 + b8.death_t * 0.6
		game.draw_line(pos + RTBoss8Controller.SHELL_TOP, pos + RTBoss8Controller.SHELL_TOP + Vector2.from_angle(a) * (60.0 + 200.0 * k), Color(1.0, 0.86, 0.4, 0.4 * alpha), 6.0 * (1.0 - k) + 1.0)


# ================================================================ projeteis
static func draw_bullets(game: Node, camera: Vector2) -> void:
	var s8: RTSertaoController = game.sertao_controller
	var low: bool = game._runtime_visual_budget_active() or game.gfx_low_resource
	var viewport: Vector2 = game.get_viewport_rect().size
	var view := Rect2(Vector2(-24, -24), viewport + Vector2(48, 48))
	# Ovos do morteiro em voo (arco).
	for h in s8.hazards:
		if String(h.get("kind", "")) != "egg":
			continue
		var k: float = clampf(float(h["t"]) / maxf(0.01, float(h["flight"])), 0.0, 1.0)
		var ground: Vector2 = Vector2(h["from"]).lerp(Vector2(h["to"]), k) - camera
		var pos: Vector2 = ground + Vector2(0, -sin(k * PI) * 170.0)
		game.draw_circle(ground, 9.0, Color(0, 0, 0, 0.22))
		game.draw_circle(pos, 11.0, OUTLINE)
		game.draw_circle(pos, 9.0, Color(1.0, 0.5, 0.16))
		game.draw_circle(pos + Vector2(-2, -3), 4.0, Color(1.0, 0.92, 0.6))
	for b in s8.bullets:
		var p: Vector2 = Vector2(b["p"]) - camera
		if not view.has_point(p):
			continue
		var frozen: bool = float(b.get("delay", 0.0)) > 0.0
		var ci: int = int(b["fc"]) if frozen else int(b["c"])
		var col: Color = RTSertaoController.PALETTE[ci]
		var r: float = 6.0 * float(b.get("size", 1.0))
		var dir: Vector2 = Vector2(b["v"])
		if ci == RTSertaoController.COL_THORN or ci == RTSertaoController.COL_GOLD:
			# Espinho / bala: losango alongado na direcao do movimento.
			var fwd: Vector2 = dir * r * 1.9
			var side: Vector2 = dir.orthogonal() * r * 0.8
			if not low:
				game.draw_circle(p, r * 1.7, Color(col.r, col.g, col.b, 0.16))
			game.draw_colored_polygon(PackedVector2Array([p + fwd * 1.15, p + side * 1.25, p - fwd * 1.15, p - side * 1.25]), OUTLINE)
			game.draw_colored_polygon(PackedVector2Array([p + fwd, p + side, p - fwd, p - side]), col)
			game.draw_circle(p, r * 0.36, Color(1, 1, 1, 0.9))
		else:
			if not low:
				game.draw_circle(p, r * 1.85, Color(col.r, col.g, col.b, 0.17))
			game.draw_circle(p, r + 1.6, OUTLINE)
			game.draw_circle(p, r, col)
			game.draw_circle(p - dir * r * 0.15, r * 0.45, Color(1, 1, 1, 0.92))
		if frozen and not low:
			game.draw_arc(p, r + 4.0, 0.0, TAU, 12, Color(0.6, 1.0, 1.0, 0.55), 1.2)


# ================================================================ chefe
static func boss_texture(game: Node) -> Texture2D:
	var info: Array = game.boss8_controller.frame_info()
	var tex := _frame(game, String(info[0]), int(info[1]))
	if tex == null:
		tex = _frame(game, "boss8_walk", 0)
	return tex


static func draw_boss(game: Node, camera: Vector2, tex: Texture2D, pos: Vector2, size: Vector2, modulate: Color) -> void:
	var b8: RTBoss8Controller = game.boss8_controller
	var sink: float = b8.sink()
	var screen: Vector2 = pos - camera + Vector2(0, sink * size.y * 0.55)
	var tint := modulate
	tint.a *= 1.0 - sink * 0.7
	if b8.mode == "eclipse":
		tint = tint * Color(0.82, 0.86, 1.1, 1.0)
	if tex != null:
		game._draw_entity_fit_flipped(tex, screen, size, b8.facing < 0.0, tint, true)
	if sink > 0.0:
		var now: float = game.time_alive
		for i in range(10):
			var a: float = float(i) * TAU / 10.0 + now
			game.draw_circle(pos - camera + Vector2(cos(a) * 120.0, 30.0 + sin(a) * 30.0), 10.0 + 6.0 * sin(now * 8.0 + float(i)), Color(0.86, 0.72, 0.5, 0.5 * sink))
		return
	var shell: Vector2 = b8.shell_center() - camera
	# Ponteiro dourado durante o Ponteiro das Horas.
	if b8.mode == "ponteiro":
		var hand: Vector2 = Vector2(cos(b8.hand_angle), sin(b8.hand_angle) * RTBoss8Controller.RIM_FLATTEN) * RTBoss8Controller.RIM_RADIUS
		game.draw_line(shell, shell + hand, Color(1.0, 0.86, 0.36, 0.95), 5.0)
		game.draw_circle(shell + hand, 6.0, Color(1.0, 0.95, 0.7))
		if b8.stage >= 2:
			game.draw_line(shell, shell - hand, Color(1.0, 0.86, 0.36, 0.8), 4.0)
	# Badaladas: a hora que acabou de soar brilha.
	if b8.mode == "badaladas":
		for i in range(mini(12, b8.count)):
			var a: float = -PI * 0.5 + TAU * float(i) / 12.0
			var rp: Vector2 = shell + Vector2(cos(a), sin(a) * RTBoss8Controller.RIM_FLATTEN) * RTBoss8Controller.RIM_RADIUS
			game.draw_circle(rp, 7.0 if i == b8.count - 1 else 4.0, Color(1.0, 0.86, 0.36, 0.9 if i == b8.count - 1 else 0.5))
	# Gnomon carregando / sol a pino: clarao na ponta.
	if b8.sun_power > 0.05:
		var tip: Vector2 = shell + Vector2(0, -78)
		game.draw_circle(tip, 14.0 + 18.0 * b8.sun_power, Color(1.0, 0.95, 0.75, 0.25 * b8.sun_power))
		game.draw_circle(tip, 7.0 + 6.0 * b8.sun_power, Color(1.0, 1.0, 0.9, 0.8 * b8.sun_power))
	if b8.mode == "eclipse":
		# O eclipse ja esta desenhado no sprite; aqui so a coroa pulsando por cima.
		var pw: float = b8.eclipse_power()
		var tip2: Vector2 = shell + Vector2(0, -78)
		game.draw_arc(tip2, 52.0 + sin(game.time_alive * 6.0) * 3.0, 0.0, TAU, 40, Color(0.7, 0.95, 1.0, 0.35 * pw), 4.0)


# ================================================================ tela
static func draw_screen(game: Node, viewport: Vector2, camera: Vector2) -> void:
	if game.current_phase != RTSertaoController.PHASE:
		return
	var b8: RTBoss8Controller = game.boss8_controller
	var full := Rect2(Vector2.ZERO, viewport)
	# Calor constante do meio-dia eterno.
	game.draw_rect(full, Color(1.0, 0.76, 0.4, 0.045))
	_draw_hitbox(game, camera)
	if not game.boss_active:
		return
	if b8.sun_power > 0.02:
		game.draw_rect(full, Color(1.0, 0.96, 0.82, 0.24 * b8.sun_power))
		if b8.shadow_on:
			_draw_shadow_wedge(game, camera, Color(0.04, 0.06, 0.16, 0.3 * b8.sun_power), false)
			if not b8.player_in_shadow() and b8.mode == "gnomon" and b8.t >= RTBoss8Controller.GNOMON_CHARGE:
				var p: Vector2 = game.player_pos - camera
				game.draw_arc(p, 30.0 + sin(game.time_alive * 18.0) * 3.0, 0.0, TAU, 24, Color(1.0, 0.4, 0.1, 0.8), 3.0)
	var ep: float = b8.eclipse_power()
	if ep > 0.0:
		game.draw_rect(full, Color(0.03, 0.0, 0.08, 0.42 * ep))


## Bullet hell: quando ha projeteis perto, mostra o ponto real de acerto da Geovana
## (o resto do sprite nao leva dano).
static func _draw_hitbox(game: Node, camera: Vector2) -> void:
	var s8: RTSertaoController = game.sertao_controller
	var near := 0.0
	var player: Vector2 = game.player_pos
	for b in s8.bullets:
		var d2: float = Vector2(b["p"]).distance_squared_to(player)
		if d2 < 160.0 * 160.0:
			near = maxf(near, 1.0 - sqrt(d2) / 160.0)
	if near <= 0.05:
		return
	var p: Vector2 = player - camera
	var a: float = clampf(near * 1.6, 0.0, 1.0)
	game.draw_circle(p, RTSertaoController.PLAYER_HIT_RADIUS + 2.0, Color(0.1, 0.02, 0.05, 0.55 * a))
	game.draw_circle(p, RTSertaoController.PLAYER_HIT_RADIUS - 2.0, Color(1.0, 1.0, 1.0, 0.95 * a))
	game.draw_arc(p, RTSertaoController.PLAYER_HIT_RADIUS + 1.0, 0.0, TAU, 20, Color(1.0, 0.3, 0.4, 0.9 * a), 1.6)
	if s8.hit_lock > 0.0:
		game.draw_arc(p, 22.0, 0.0, TAU * s8.hit_lock / RTSertaoController.HIT_LOCK, 24, Color(1.0, 1.0, 1.0, 0.6), 2.0)
