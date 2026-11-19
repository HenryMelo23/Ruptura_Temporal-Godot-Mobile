class_name RTNecroSpecterPresentation
extends RefCounted

## Visual do Necrocronismo (tudo em codigo): rebobinar ao nascer, fantasma do proprio
## inimigo com separacao cromatica e ecos atrasados, risco das investidas e implosao.

const SPECTRAL := Color(0.52, 1.0, 0.86)
const SPECTRAL_DEEP := Color(0.12, 0.62, 0.58)
const CHRONO := Color(0.78, 0.46, 1.0)
const CORE := Color(0.92, 1.0, 0.97)
const BODY_SIZE := Vector2(74, 74)
const ELITE_SIZE := Vector2(90, 90)


static func draw(game: Node2D, camera: Vector2, t: float) -> void:
	var owner: RTNecrocronismController = game.necrocronism
	for streak in owner.streaks:
		_draw_streak(game, camera, streak)
	for specter in game.active_necro_specters:
		_draw_specter(game, camera, specter, t)


static func _draw_streak(game: Node2D, camera: Vector2, streak: Dictionary) -> void:
	var ratio: float = clampf(float(streak.get("life", 0.0)) / maxf(0.01, float(streak.get("max", 1.0))), 0.0, 1.0)
	var a: Vector2 = Vector2(streak["a"]) - camera
	var b: Vector2 = Vector2(streak["b"]) - camera
	# A cauda some primeiro: o risco "encolhe" ate a ponta.
	var tail: Vector2 = a.lerp(b, 1.0 - ratio)
	var width: float = 22.0 if bool(streak.get("elite", false)) else 18.0
	game.draw_line(tail, b, Color(SPECTRAL_DEEP, 0.42 * ratio), width * 1.7, true)
	game.draw_line(tail, b, Color(SPECTRAL, 0.8 * ratio), width * 0.75, true)
	game.draw_line(tail, b, Color(CORE, ratio), 3.0, true)
	var dir: Vector2 = (b - a).normalized()
	var side: Vector2 = dir.orthogonal()
	for i in range(3):
		var p: Vector2 = tail.lerp(b, 0.25 + float(i) * 0.25)
		game.draw_line(p - side * width * 0.9, p - side * width * 0.4 - dir * 8.0, Color(CHRONO, 0.5 * ratio), 1.6, true)


static func _draw_specter(game: Node2D, camera: Vector2, specter: Dictionary, t: float) -> void:
	var pos: Vector2 = Vector2(specter.get("pos", game.player_pos)) - camera
	var state: String = String(specter.get("state", "seek"))
	var state_time: float = float(specter.get("state_time", 0.0))
	var tex: Texture2D = game._enemy_texture(specter)
	var size: Vector2 = ELITE_SIZE if bool(specter.get("elite", false)) else BODY_SIZE
	var flip: bool = float(specter.get("facing", 1.0)) < 0.0
	var life_ratio: float = clampf(float(specter.get("life", 0.0)) / maxf(0.01, float(specter.get("max", 1.0))), 0.0, 1.0)
	var alpha := 0.95
	var scale := 1.0
	if state == "rise":
		var p: float = clampf(state_time / RTNecrocronismController.RISE_TIME, 0.0, 1.0)
		_draw_rewind(game, pos, p, t)
		alpha = 0.95 * p
		scale = lerpf(0.55, 1.0, ease(p, 0.4))
	elif state == "collapse":
		var c: float = clampf(state_time / RTNecrocronismController.COLLAPSE_TIME, 0.0, 1.0)
		_draw_collapse_charge(game, pos, c, t)
		alpha = 0.95 * (1.0 - c * 0.7)
		scale = lerpf(1.0, 0.45, c * c)
	elif life_ratio < 0.2:
		# Aviso de que o tempo do Eco esta acabando.
		alpha *= 0.55 + 0.45 * absf(sin(t * 16.0))
	var bob: float = sin(t * 5.0 + float(specter.get("phase", 0.0))) * 3.0
	var body_size: Vector2 = size * scale
	game.draw_set_transform(pos + Vector2(0, 8), 0.0, Vector2(1.0, 0.32))
	game.draw_circle(Vector2.ZERO, body_size.x * 0.42, Color(0.0, 0.08, 0.08, 0.22 * alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if tex == null:
		game.draw_circle(pos, body_size.x * 0.35, Color(SPECTRAL, alpha * 0.6))
		return
	if state != "rise":
		var trail: Array = specter.get("trail", [])
		for i in range(1, trail.size()):
			var echo_pos: Vector2 = Vector2(trail[i]) - camera
			var fade: float = alpha * (0.42 - float(i) * 0.1)
			if fade <= 0.0:
				continue
			game._draw_entity_fit_flipped(tex, echo_pos + Vector2(0, bob), body_size, flip, Color(CHRONO if i % 2 == 1 else SPECTRAL, fade), true)
	var body: Vector2 = pos + Vector2(0, bob)
	# Halo espectral atras do corpo para destacar do chao e da horda.
	game.draw_circle(body - Vector2(0, body_size.y * 0.4), body_size.x * 0.5, Color(SPECTRAL, 0.14 * alpha))
	game.draw_circle(body - Vector2(0, body_size.y * 0.4), body_size.x * 0.32, Color(SPECTRAL, 0.12 * alpha))
	var split: float = 2.5 if state == "dash" else 1.6
	game._draw_entity_fit_flipped(tex, body + Vector2(-split, 0), body_size, flip, Color(1.0, 0.5, 1.0, alpha * 0.45), true)
	game._draw_entity_fit_flipped(tex, body + Vector2(split, 0), body_size, flip, Color(0.4, 1.0, 1.0, alpha * 0.45), true)
	game._draw_entity_fit_flipped(tex, body, body_size, flip, Color(1.3, 2.2, 2.0, alpha), true)
	# Nucleo de "relogio" no peito: ponteiro girando ao contrario (tempo rebobinado).
	var chest: Vector2 = body - Vector2(0, body_size.y * 0.42)
	var hand: Vector2 = Vector2.from_angle(-t * 6.0) * 7.0 * scale
	game.draw_circle(chest, 5.5 * scale, Color(SPECTRAL_DEEP, 0.55 * alpha))
	game.draw_line(chest, chest + hand, Color(CORE, 0.9 * alpha), 1.6, true)
	game.draw_arc(chest, 8.5 * scale, -PI * 0.5, -PI * 0.5 - TAU * life_ratio, 18, Color(SPECTRAL, 0.7 * alpha), 1.4, true)


static func _draw_rewind(game: Node2D, pos: Vector2, p: float, t: float) -> void:
	var radius: float = 46.0
	# Mostrador no chao varrendo ao contrario.
	game.draw_set_transform(pos + Vector2(0, 6), 0.0, Vector2(1.0, 0.42))
	game.draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 - TAU * p, 40, Color(SPECTRAL, 0.7 * (1.0 - p * 0.4)), 3.0, true)
	for i in range(12):
		var a: float = float(i) * TAU / 12.0
		var outer: Vector2 = Vector2.from_angle(a) * radius
		game.draw_line(outer, outer * 0.84, Color(CHRONO, 0.55 * (1.0 - p * 0.5)), 2.0, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Particulas voltando para o corpo, em espiral.
	for i in range(9):
		var a2: float = float(i) * TAU / 9.0 - p * 3.4 + t * 0.6
		var r: float = lerpf(70.0, 6.0, ease(p, 0.6))
		var mote: Vector2 = pos + Vector2(0, -28) + Vector2.from_angle(a2) * r
		var mote_alpha: float = 0.85 * (1.0 - p * 0.6)
		game.draw_circle(mote, 3.2, Color(CORE if i % 3 == 0 else SPECTRAL, mote_alpha))
		game.draw_line(mote, mote + Vector2.from_angle(a2 + 1.9) * 9.0, Color(SPECTRAL, mote_alpha * 0.5), 1.4, true)


static func _draw_collapse_charge(game: Node2D, pos: Vector2, c: float, t: float) -> void:
	var radius: float = RTNecrocronismController.COLLAPSE_RADIUS * (1.0 - c * 0.75)
	game.draw_circle(pos + Vector2(0, -24), radius * 0.4, Color(0.02, 0.14, 0.14, 0.32 * c))
	game.draw_arc(pos + Vector2(0, -24), radius, t * 7.0, t * 7.0 + PI * 1.5, 40, Color(SPECTRAL, 0.75), 3.0, true)
	game.draw_arc(pos + Vector2(0, -24), radius * 0.66, -t * 9.0, -t * 9.0 + PI * 1.1, 30, Color(CHRONO, 0.6), 2.0, true)


## Efeito em rare_card_effects (kind "necro_collapse").
static func draw_collapse_effect(game: Node2D, pos: Vector2, ratio: float, radius: float) -> void:
	var grow: float = 1.0 - ratio
	var center: Vector2 = pos + Vector2(0, -24)
	if grow < 0.18:
		game.draw_circle(center, 26.0 * (1.0 - grow / 0.18), Color(CORE, 0.8))
	game.draw_circle(center, radius * (0.3 + grow * 0.7), Color(SPECTRAL_DEEP, 0.16 * ratio))
	game.draw_arc(center, radius * (0.3 + grow * 0.8), 0.0, TAU, 56, Color(SPECTRAL, 0.8 * ratio), 4.0 * ratio + 1.0, true)
	game.draw_arc(center, radius * (0.2 + grow * 0.55), 0.0, TAU, 40, Color(CHRONO, 0.55 * ratio), 2.0, true)
	for i in range(8):
		var a: float = float(i) * TAU / 8.0 + 0.2
		var inner: Vector2 = center + Vector2.from_angle(a) * radius * (0.2 + grow * 0.5)
		var outer: Vector2 = center + Vector2.from_angle(a) * radius * (0.45 + grow * 0.75)
		game.draw_line(inner, outer, Color(CORE, 0.7 * ratio), 2.0, true)
