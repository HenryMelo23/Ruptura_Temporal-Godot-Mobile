class_name RTArautoThreatPresentation
extends RefCounted

## Visual das mecanicas novas dos Arautos (RTArautoThreatController).

const CYAN := Color(0.56, 0.92, 1.0)
const PINK := Color(1.0, 0.46, 0.9)
const VIOLET := Color(0.7, 0.4, 1.0)
const VENOM := Color(0.56, 1.0, 0.22)
const INK := Color(0.03, 0.02, 0.08)


static func _beam(game: Node2D, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	game.draw_line(a, b, Color(INK, color.a * 0.6), width + 6.0, true)
	game.draw_line(a, b, Color(color, color.a * 0.35), width + 14.0, true)
	game.draw_line(a, b, color, width, true)
	game.draw_line(a, b, Color(1.0, 1.0, 1.0, color.a), maxf(1.5, width * 0.25), true)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var ctrl: RTArautoThreatController = game.arauto_threat
	if ctrl == null:
		return
	var t: float = float(game.time_alive)
	var ab: Dictionary = ctrl.ability
	var kind: String = String(ab.get("kind", ""))
	var apos: Vector2 = Vector2(game.arauto.get("pos", Vector2.ZERO)) - camera
	match kind:
		"choir":
			_draw_choir(game, ctrl, ab, camera)
		"prism":
			_draw_prism(game, ctrl, ab, apos)
		"hush":
			_draw_hush(game, ab, camera)
		"shell":
			_draw_shell(game, ab, apos, t)
	if not ctrl.inversion.is_empty():
		_draw_inversion(game, ctrl.inversion, camera, t)
	for sting_value in ctrl.stings:
		var sting: Dictionary = sting_value
		var p: Vector2 = Vector2(sting["pos"]) - camera
		var d: Vector2 = Vector2(sting["dir"])
		if float(sting.get("telegraph", 0.0)) > 0.0:
			game.draw_line(p, p + d * 420.0, Color(VENOM, 0.35), 3.0, true)
			game.draw_circle(p, 10.0, Color(VENOM, 0.7))
			continue
		game.Boss1VFX.streak(game, p - d * 46.0, p, Color(VENOM, 0.8), 6.0)
		var side: Vector2 = d.orthogonal() * 7.0
		game.draw_colored_polygon(PackedVector2Array([p + d * 16.0, p - d * 8.0 + side, p - d * 8.0 - side]), Color(INK, 0.9))
		game.draw_colored_polygon(PackedVector2Array([p + d * 13.0, p - d * 6.0 + side * 0.7, p - d * 6.0 - side * 0.7]), VENOM)
	for spike_value in ctrl.spikes:
		var spike: Dictionary = spike_value
		var sp: Vector2 = Vector2(spike["pos"]) - camera
		var sd: Vector2 = Vector2(spike["dir"])
		game.Boss1VFX.streak(game, sp - sd * 30.0, sp, Color(1.0, 0.86, 0.3, 0.85), 5.0)
	if not ctrl.venom_stacks.is_empty():
		var pp: Vector2 = game.player_pos - camera
		var n: int = ctrl.venom_stacks.size()
		var pulse: float = 0.5 + 0.5 * sin(t * 6.0)
		game.draw_arc(pp + Vector2(0, 30), 30.0 + pulse * 3.0, 0.0, TAU, 32, Color(VENOM, 0.35 + 0.08 * n), 3.0, true)
		for i in range(n):
			var drip: Vector2 = pp + Vector2(-float(n - 1) * 7.0 + float(i) * 14.0, -86.0)
			game.draw_circle(drip, 5.0, Color(INK, 0.8))
			game.draw_circle(drip, 4.0, VENOM)


static func _draw_choir(game: Node2D, ctrl: RTArautoThreatController, ab: Dictionary, camera: Vector2) -> void:
	var age: float = float(ab.get("age", 0.0))
	var target: Vector2 = Vector2(ab.get("target", game.player_pos))
	var fired: bool = bool(ab.get("fired", false))
	var p: float = clampf(age / RTArautoThreatController.CHOIR_TELEGRAPH, 0.0, 1.0)
	for src_value in ab.get("sources", []):
		var src: Vector2 = Vector2(src_value)
		var dir: Vector2 = (target - src).normalized()
		var a: Vector2 = src - camera
		var b: Vector2 = src + dir * RTArautoThreatController.CHOIR_BEAM_LENGTH - camera
		if not fired:
			game.draw_line(a, b, Color(INK, 0.4), 6.0, true)
			game.draw_line(a, a.lerp(b, p), Color(CYAN, 0.35 + p * 0.5), 2.0 + p * 2.0, true)
			game.draw_circle(a, 10.0 + p * 8.0, Color(CYAN, 0.25 + p * 0.4))
		else:
			var fade: float = 1.0 - clampf((age - RTArautoThreatController.CHOIR_TELEGRAPH) / 0.35, 0.0, 1.0)
			_beam(game, a, b, Color(CYAN, fade), RTArautoThreatController.CHOIR_BEAM_WIDTH)
	if not fired:
		var tp: Vector2 = target - camera
		game.draw_arc(tp, 26.0, 0.0, TAU, 28, Color(CYAN, 0.5 + p * 0.4), 2.5, true)


static func _draw_prism(game: Node2D, ctrl: RTArautoThreatController, ab: Dictionary, apos: Vector2) -> void:
	var age: float = float(ab.get("age", 0.0))
	var tele: float = RTArautoThreatController.PRISM_TELEGRAPH
	var colors: Array = [PINK, CYAN, VIOLET]
	for i in range(RTArautoThreatController.PRISM_BEAMS):
		var ang: float = ctrl.prism_angle(i)
		var end: Vector2 = apos + Vector2.from_angle(ang) * RTArautoThreatController.PRISM_LENGTH
		var col: Color = colors[i % colors.size()]
		if age < tele:
			var p: float = age / tele
			game.draw_line(apos, end, Color(INK, 0.4), 5.0, true)
			game.draw_line(apos, apos.lerp(end, p), Color(col, 0.4 + p * 0.4), 2.0, true)
		else:
			var out: float = 1.0 - clampf((age - tele - RTArautoThreatController.PRISM_DURATION + 0.25) / 0.25, 0.0, 1.0)
			_beam(game, apos, end, Color(col, 0.9 * out), RTArautoThreatController.PRISM_WIDTH * 0.7)
	game.draw_circle(apos + Vector2(0, -30), 18.0 + sin(age * 14.0) * 3.0, Color(1.0, 1.0, 1.0, 0.7))


static func _draw_hush(game: Node2D, ab: Dictionary, camera: Vector2) -> void:
	var age: float = float(ab.get("age", 0.0))
	var tele: float = RTArautoThreatController.HUSH_TELEGRAPH
	var p: float = clampf(age / tele, 0.0, 1.0)
	var view: Vector2 = game.get_viewport_rect().size
	var fired: bool = bool(ab.get("fired", false))
	# A arena escurece; so os circulos seguros ficam acesos.
	var dark: float = 0.18 + p * 0.32 if not fired else 0.5 * (1.0 - clampf((age - tele) / 0.5, 0.0, 1.0))
	game.draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.02, 0.08, dark), true)
	for safe_value in ab.get("safes", []):
		var c: Vector2 = Vector2(safe_value) - camera
		var r: float = RTArautoThreatController.HUSH_SAFE_RADIUS
		game.draw_circle(c, r, Color(0.86, 0.96, 1.0, 0.16 + p * 0.1))
		game.draw_arc(c, r, 0.0, TAU, 48, Color(INK, 0.7), 7.0, true)
		game.draw_arc(c, r, 0.0, TAU, 48, Color(CYAN, 0.95), 3.0, true)
		game.draw_arc(c, r - 10.0, -PI * 0.5, -PI * 0.5 + TAU * p, 40, Color(1.0, 1.0, 1.0, 0.9), 4.0, true)
		game.draw_line(c + Vector2(0, -r - 34), c + Vector2(0, -r - 8), Color(CYAN, 0.4 + p * 0.5), 6.0 * (1.0 - p) + 2.0, true)
	if not fired:
		var pp: Vector2 = game.player_pos - camera
		game._draw_centered("%.1f" % maxf(0.0, tele - age), pp + Vector2(0, -110), 20, Color(1.0, 1.0, 1.0, 0.9))


static func _draw_shell(game: Node2D, ab: Dictionary, apos: Vector2, t: float) -> void:
	var age: float = float(ab.get("age", 0.0))
	var tele: float = RTArautoThreatController.SHELL_TELEGRAPH
	var facing: float = float(game.arauto.get("facing", 1.0))
	var front_angle: float = 0.0 if facing >= 0.0 else PI
	var c: Vector2 = apos + Vector2(0, -10)
	var closing: float = clampf(age / tele, 0.0, 1.0)
	var span: float = lerpf(0.4, 1.35, closing)
	game.draw_arc(c, 92.0, front_angle - span, front_angle + span, 40, Color(INK, 0.7), 16.0, true)
	game.draw_arc(c, 92.0, front_angle - span, front_angle + span, 40, Color(0.62, 0.92, 0.32, 0.9), 10.0, true)
	for plate in range(7):
		var a: float = front_angle - span + float(plate) * span * 2.0 / 6.0
		game.draw_line(c + Vector2.from_angle(a) * 84.0, c + Vector2.from_angle(a) * 100.0, Color(0.96, 1.0, 0.7, 0.85), 2.0, true)
	if age >= tele:
		# Costas abertas: marca piscando mostrando onde bater.
		var back: Vector2 = c + Vector2.from_angle(front_angle + PI) * 96.0
		var blink: float = 0.5 + 0.5 * sin(t * 10.0)
		game.draw_circle(back, 14.0 + blink * 4.0, Color(1.0, 0.86, 0.3, 0.35 + blink * 0.4))
		game.draw_arc(back, 20.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.3, 0.9), 2.5, true)
		var left: float = RTArautoThreatController.SHELL_DURATION - (age - tele)
		game.draw_arc(c, 108.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(left / RTArautoThreatController.SHELL_DURATION, 0.0, 1.0), 48, Color(0.8, 1.0, 0.5, 0.6), 3.0, true)


static func _draw_inversion(game: Node2D, inv: Dictionary, camera: Vector2, t: float) -> void:
	var mark: Vector2 = Vector2(inv["pos"]) - camera
	var age: float = float(inv["age"])
	var delay: float = RTArautoThreatController.INVERSION_DELAY
	var r: float = RTArautoThreatController.INVERSION_RADIUS
	var pulled: bool = bool(inv.get("pulled", false))
	if not pulled:
		var p: float = clampf(age / delay, 0.0, 1.0)
		game.draw_circle(mark, r * 0.6, Color(VIOLET, 0.12 + p * 0.12))
		game.draw_arc(mark, r * 0.6, 0.0, TAU, 32, Color(INK, 0.7), 6.0, true)
		game.draw_arc(mark, r * 0.6, -PI * 0.5, -PI * 0.5 + TAU * p, 32, Color(VIOLET, 0.95), 3.0, true)
		# Fio do eco ligando o jogador a marca: vai encurtar.
		var pp: Vector2 = game.player_pos - camera
		game.draw_dashed_line(pp, mark, Color(VIOLET, 0.3 + p * 0.5), 2.0, 10.0)
		for i in range(3):
			var a: float = -t * 2.0 + float(i) * TAU / 3.0
			game.draw_arc(mark, r * 0.35, a, a + 1.2, 12, Color(1.0, 0.8, 1.0, 0.8), 2.0, true)
	else:
		var q: float = clampf(float(inv.get("pull_age", 0.0)) / RTArautoThreatController.INVERSION_DETONATE, 0.0, 1.0)
		game.draw_circle(mark, r, Color(PINK, 0.1 + q * 0.2))
		game.draw_arc(mark, r, 0.0, TAU, 40, Color(INK, 0.7), 7.0, true)
		game.draw_arc(mark, r, 0.0, TAU, 40, Color(PINK, 0.9), 3.0, true)
		game.draw_arc(mark, r * q, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.8), 3.0, true)
