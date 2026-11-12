class_name RTPhase3RitualPresentation
extends RefCounted

## Ritual da Catedral: circulos com runas de compasso, selo do Oficiante,
## profanacao, pulsos e as poses de dança/reverencia dos devotos.

const C_SAFE := Color(1.0, 0.86, 0.38)
const C_DANGER := Color(0.92, 0.22, 0.5)
const C_RITUAL := Color(0.62, 0.94, 0.3)
const C_SEAL := Color(0.78, 0.4, 1.0)
const C_PROFANE := Color(0.62, 1.0, 0.96)
const C_WAX := Color(0.95, 0.74, 0.22)
const C_SICK := Color(0.48, 1.0, 0.32)
const FRAME_ROOT := "res://assets/sprites/phase3_ritual/"

static var _frames_cache: Dictionary = {}


## Frames terceirizados (Codex) em assets/sprites/phase3_ritual/<pasta>/<anim>_NN.png.
## Vazio enquanto nao existirem: o visual procedural continua valendo.
static func frames(prefix: String) -> Array:
	if _frames_cache.has(prefix):
		return _frames_cache[prefix]
	var out: Array = []
	for i in range(1, 33):
		var path: String = "%s%s_%02d.png" % [FRAME_ROOT, prefix, i]
		if not ResourceLoader.exists(path):
			break
		var tex = load(path)
		if tex is Texture2D:
			out.append(tex)
	_frames_cache[prefix] = out
	return out


static func frame_loop(prefix: String, t: float, fps: float) -> Texture2D:
	var list: Array = frames(prefix)
	return null if list.is_empty() else list[int(t * fps) % list.size()]


static func frame_progress(prefix: String, u: float) -> Texture2D:
	var list: Array = frames(prefix)
	if list.is_empty():
		return null
	return list[clampi(int(u * float(list.size())), 0, list.size() - 1)]


## Textura de ritual para o inimigo (dança, reverencia...) quando os frames existem.
static func pose_texture(game: Node2D, enemy: Dictionary, t: float) -> Texture2D:
	var kind: String = String(enemy.get("phase3_ritual_pose", ""))
	if kind == "":
		return null
	var folder: String = "devoto" if String(enemy.get("phase3_ritual_role", "officiant")) == "officiant" else "fiel"
	var prefix: String = "%s/%s" % [folder, kind]
	if frames(prefix).is_empty():
		return null
	var ctl = _ctl(game)
	if (kind == "dance" or kind == "worship") and ctl != null:
		return frame_progress(prefix, ctl.beat_phase())
	return frame_loop(prefix, t + float(int(enemy.get("uid", 0)) % 7) * 0.13, 12.0 if kind == "fervor" else (8.0 if kind == "kneel" else 10.0))


static func _ctl(game: Node2D):
	return game.phase3_ritual_pulse_controller


# ================================================================ poses
## Pose de animacao de um inimigo no ritual: offset, escala e rotacao do sprite.
static func pose(game: Node2D, enemy: Dictionary, t: float) -> Dictionary:
	var kind: String = String(enemy.get("phase3_ritual_pose", ""))
	if kind == "":
		return {}
	if pose_texture(game, enemy, t) != null:
		# Os frames ja animam o corpo; so um leve balanço de vida.
		return {"offset": Vector2(0.0, -absf(sin(t * 3.0)) * 1.5), "scale": Vector2.ONE, "rot": 0.0}
	var ctl = _ctl(game)
	var b: float = ctl.beat_phase() if ctl != null else fposmod(t, 1.3) / 1.3
	var beat: int = ctl.beat_index() if ctl != null else int(t / 1.3)
	var uid: float = float(int(enemy.get("uid", 0)) % 97)
	var offset := Vector2.ZERO
	var scale := Vector2.ONE
	var rot := 0.0
	match kind:
		"procession":
			# Andar de procissao: balanço lateral e passos curtos.
			var step: float = t * 6.5 + uid
			rot = sin(step) * 0.09
			offset = Vector2(0.0, -absf(sin(step)) * 3.5)
		"dance":
			# Oficiante: salto no compasso, aterrissagem com squash, troca de lado.
			var hop: float = sin(b * PI)
			var land: float = maxf(0.0, 1.0 - b * 5.0)
			var side: float = 1.0 if beat % 2 == 0 else -1.0
			rot = side * (0.26 * sin(b * PI) - 0.06)
			offset = Vector2(side * sin(b * PI) * 7.0, -hop * 13.0)
			scale = Vector2(1.0 + 0.16 * land - 0.05 * hop, 1.0 - 0.18 * land + 0.08 * hop)
		"worship":
			# Fiel: reverencia (curva para o centro) logo no pulso, depois ergue os braços.
			var bow: float = _bow_curve(b)
			var lean: float = 1.0 if Vector2(enemy.get("facing_dir", Vector2.RIGHT)).x >= 0.0 else -1.0
			rot = lean * 0.42 * bow + sin(t * 3.0 + uid) * 0.04 * (1.0 - bow)
			scale = Vector2(1.0 + 0.06 * bow, 1.0 - 0.2 * bow)
			offset = Vector2(lean * 5.0 * bow, 6.0 * bow - (1.0 - bow) * absf(sin(t * 4.0 + uid)) * 3.0)
		"kneel":
			# Selo quebrado / atordoado: ajoelha tremendo.
			rot = sin(t * 38.0 + uid) * 0.03
			scale = Vector2(1.1, 0.72)
			offset = Vector2(sin(t * 41.0 + uid) * 1.6, 10.0)
		"fervor":
			# Circulo consumado: saltos de euforia.
			var jump: float = absf(sin(t * 8.0 + uid))
			rot = sin(t * 8.0 + uid) * 0.16
			offset = Vector2(0.0, -jump * 18.0)
			scale = Vector2(1.0 - 0.06 * jump, 1.0 + 0.1 * jump)
	return {"offset": offset, "scale": scale, "rot": rot}


static func _bow_curve(b: float) -> float:
	# 0..0.4 do compasso: desce e sobe; o resto: em pe.
	return sin(clampf(b / 0.4, 0.0, 1.0) * PI) if b < 0.4 else 0.0


# ================================================================ chao
static func draw(game: Node2D, camera: Vector2) -> void:
	var ctl = _ctl(game)
	if ctl == null:
		return
	var snapshot: Dictionary = ctl.active_snapshot()
	if not bool(snapshot.get("active", false)):
		return
	var low: bool = game._memory_saver_active() or game._runtime_visual_budget_active() or game.gfx_low_resource
	var result: String = String(snapshot.get("result", "active"))
	var result_fade: float = 1.0
	if result != "active":
		result_fade = clampf(float(snapshot.get("result_remaining", 0.0)) / maxf(0.01, ctl.RESULT_DISPLAY_TIME), 0.0, 1.0)
	var b: float = ctl.beat_phase()
	var beat: int = ctl.beat_index()
	var circles: Array = Array(snapshot.get("circles", []))
	for value in circles:
		_draw_circle(game, Dictionary(value), camera, b, beat, low, result, result_fade)
	# Fio de procissao: quem ainda esta indo para o circulo.
	for value in Array(snapshot.get("devotees", [])):
		var devotee: Dictionary = value
		if String(devotee.get("pose", "")) != "procession":
			continue
		var devotee_pos: Vector2 = Vector2(devotee.get("pos", Vector2.ZERO)) - camera
		for circle_value in circles:
			if int(Dictionary(circle_value).get("id", -2)) == int(devotee.get("circle_id", -1)):
				var target_pos: Vector2 = Vector2(Dictionary(circle_value).get("pos", Vector2.ZERO)) - camera
				var col: Color = C_SEAL if String(devotee.get("role", "")) == "officiant" else C_RITUAL
				game.draw_dashed_line(devotee_pos, target_pos, Color(col.r, col.g, col.b, 0.32), 2.0, 14.0, true)
				break
	if result == "active":
		_draw_banner(game, snapshot, circles)


static func _draw_circle(game: Node2D, circle: Dictionary, camera: Vector2, b: float, beat: int, low: bool, result: String, fade: float) -> void:
	var pos: Vector2 = Vector2(circle.get("pos", Vector2.ZERO)) - camera
	var radius: float = float(circle.get("radius", 96.0))
	var progress: float = clampf(float(circle.get("progress", 0.0)), 0.0, 1.0)
	var outcome: String = String(circle.get("outcome", ""))
	var sealed: bool = bool(circle.get("sealed", false))
	var profaned: bool = bool(circle.get("profaned", false))
	var accent: Color = C_RITUAL
	if outcome == "consummated":
		accent = C_DANGER
	elif outcome == "disrupted" or bool(circle.get("disrupted", false)):
		accent = Color(0.5, 0.62, 0.52)
	elif profaned:
		accent = C_SAFE
	elif sealed:
		accent = C_SEAL
	var seg: int = 28 if low else 56
	var now: float = float(_ctl(game).elapsed()) if _ctl(game) != null else game.time_alive
	var decal_name: String = "vfx/circle_consummated" if outcome == "consummated" else ("vfx/circle_dissolved" if (outcome == "disrupted" or bool(circle.get("disrupted", false))) else "vfx/circle_idle")
	var decal: Texture2D = frame_loop(decal_name, game.time_alive, 8.0)
	if decal != null:
		var ds: float = radius * 2.5
		game.draw_texture_rect(decal, Rect2(pos - Vector2(ds, ds) * 0.5, Vector2(ds, ds)), false, Color(1, 1, 1, fade))
	else:
		_draw_macabre_floor(game, pos, radius, circle, outcome, fade, low)
	game.draw_circle(pos, radius, Color(0.06, 0.02, 0.09, 0.2 * fade))
	# Runas do compasso: 4 setores; o seguro acende.
	var active_ritual: bool = outcome == "" and not bool(circle.get("disrupted", false)) and result == "active"
	var wedges: int = RTPhase3RitualPulseController.WEDGES
	var safe: int = int(circle.get("safe_wedge", 0))
	if active_ritual and not profaned:
		for w in range(wedges):
			var a0: float = TAU * float(w) / float(wedges)
			var a1: float = a0 + TAU / float(wedges)
			var is_safe: bool = w == safe
			var col: Color = C_SAFE if is_safe else C_DANGER
			# Setores perigosos avermelham conforme o pulso chega; o seguro brilha.
			var alpha: float = (0.34 + 0.14 * sin(b * TAU)) if is_safe else ((0.1 + 0.36 * b * b) if sealed else 0.05)
			_draw_wedge(game, pos, radius * 0.96, a0 + 0.05, a1 - 0.05, Color(col.r, col.g, col.b, alpha * fade), 8 if low else 14)
			game.draw_line(pos + Vector2.from_angle(a0) * radius * 0.2, pos + Vector2.from_angle(a0) * radius, Color(0.05, 0.02, 0.06, 0.7 * fade), 3.0, true)
			if is_safe:
				game.draw_arc(pos, radius * 0.96, a0 + 0.05, a1 - 0.05, 12, Color(1.0, 0.95, 0.66, 0.95 * fade), 4.0, true)
				var mid: float = (a0 + a1) * 0.5
				var rune_pos: Vector2 = pos + Vector2.from_angle(mid) * radius * 0.55
				var rune_tex: Texture2D = frame_loop("vfx/safe_rune", game.time_alive, 8.0)
				if rune_tex != null:
					game.draw_texture_rect(rune_tex, Rect2(rune_pos - Vector2(26, 26), Vector2(52, 52)), false, Color(1, 1, 1, fade))
				else:
					_draw_rune(game, rune_pos, 16.0 + 3.0 * sin(b * TAU), Color(1.0, 0.95, 0.7, 0.98 * fade))
		# Telegrafo: o anel aperta conforme o pulso se aproxima.
		if sealed:
			var warn_r: float = radius * (1.25 - 0.25 * b)
			game.draw_arc(pos, warn_r, 0.0, TAU, seg, Color(C_DANGER.r, C_DANGER.g, C_DANGER.b, 0.15 + 0.55 * b * b), 2.0 + 2.0 * b, true)
	# Pulso que acabou de sair.
	if int(circle.get("pulse_beat", -1)) == beat and b < 0.35:
		var k: float = b / 0.35
		var pulse_tex: Texture2D = frame_progress("vfx/pulse", k)
		if pulse_tex != null:
			var ps: float = radius * 2.6
			game.draw_texture_rect(pulse_tex, Rect2(pos - Vector2(ps, ps) * 0.5, Vector2(ps, ps)), false)
		else:
			game.draw_arc(pos, radius * (0.25 + 0.85 * k), 0.0, TAU, seg, Color(1.0, 0.3, 0.55, 0.9 * (1.0 - k)), 7.0 * (1.0 - k) + 1.0, true)
			game.draw_arc(pos, radius * (0.2 + 0.7 * k), 0.0, TAU, seg, Color(C_SICK.r, C_SICK.g, C_SICK.b, 0.6 * (1.0 - k)), 3.0, true)
			# Crânios de fumaça sendo arremessados para fora.
			for i in range(3 if low else 6):
				var a: float = float(circle.get("phase", 0.0)) + float(i) * TAU / (3.0 if low else 6.0)
				_draw_ghost_skull(game, pos + Vector2.from_angle(a) * radius * (0.3 + 0.8 * k) + Vector2(0, -10.0 * k), 7.0, 0.75 * (1.0 - k))
	if decal == null:
		game.draw_arc(pos, radius, 0.0, TAU, seg, Color(0.03, 0.02, 0.06, 0.85 * fade), 6.0, true)
	game.draw_arc(pos, radius, 0.0, TAU, seg, Color(accent.r, accent.g, accent.b, (0.55 if decal != null else 0.8) * fade), 2.2, true)
	# Progresso do ritual (rosa) e da profanacao (ciano).
	if progress > 0.0:
		game.draw_arc(pos, radius + 8.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 42 if not low else 24, Color(0.95, 0.42, 0.72, 0.92 * fade), 4.0, true)
	var profane: float = clampf(float(circle.get("profane", 0.0)), 0.0, 1.0)
	if profane > 0.0 and not profaned:
		game.draw_arc(pos, radius - 8.0, -PI * 0.5, -PI * 0.5 + TAU * profane, 42 if not low else 24, Color(C_PROFANE.r, C_PROFANE.g, C_PROFANE.b, 0.95 * fade), 5.0, true)
	var rune_count: int = 0 if decal != null else (6 if low else 12)
	for rune_index in range(rune_count):
		var angle: float = float(circle.get("phase", 0.0)) + float(rune_index) * TAU / float(rune_count) + game.time_alive * (0.1 if rune_index % 2 == 0 else -0.07)
		var outer: Vector2 = pos + Vector2.from_angle(angle) * radius * 0.94
		var inner: Vector2 = pos + Vector2.from_angle(angle + 0.12) * radius * 0.86
		game.draw_line(outer, inner, Color(accent.r, accent.g, accent.b, 0.5 * fade), 2.0, true)
	_draw_candles_and_hands(game, pos, radius, circle, outcome, fade, low)
	_draw_one_shots(game, pos, radius, circle, now)
	# Rotulos curtos e legiveis.
	var label := ""
	var label_col: Color = accent
	if outcome == "consummated":
		label = "CONSUMADO"
	elif outcome == "disrupted" or bool(circle.get("disrupted", false)):
		label = "DISSOLVIDO"
	elif profaned:
		label = "PROFANADO · ATAQUE!"
	elif sealed and bool(circle.get("intruder", false)):
		label = "PISE NA RUNA DOURADA"
		label_col = C_SAFE
	elif sealed:
		label = "SELADO · ENTRE"
	if label != "":
		game._draw_centered_outlined(label, pos + Vector2(0.0, radius + 24.0), 13, Color(label_col.r, label_col.g, label_col.b, fade), Color(0, 0, 0, 0.9 * fade), 3)


static func _draw_wedge(game: Node2D, center: Vector2, radius: float, a0: float, a1: float, color: Color, steps: int) -> void:
	var pts := PackedVector2Array([center])
	for i in range(steps + 1):
		pts.append(center + Vector2.from_angle(lerpf(a0, a1, float(i) / float(steps))) * radius)
	game.draw_colored_polygon(pts, color)


static func _draw_rune(game: Node2D, p: Vector2, size: float, color: Color) -> void:
	# Pegada estilizada: oval + tres pontos (onde pisar).
	game.draw_set_transform(p, 0.0, Vector2(0.7, 1.0))
	game.draw_circle(Vector2.ZERO, size * 0.62, Color(color.r, color.g, color.b, color.a * 0.35))
	game.draw_arc(Vector2.ZERO, size * 0.62, 0.0, TAU, 18, color, 2.0, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(3):
		game.draw_circle(p + Vector2(-size * 0.4 + size * 0.4 * float(i), -size * 0.95), 2.2, color)


static func _draw_banner(game: Node2D, snapshot: Dictionary, circles: Array) -> void:
	var viewport: Vector2 = game.get_viewport_rect().size
	var overall: float = clampf(float(snapshot.get("overall_progress", 0.0)), 0.0, 1.0)
	var remaining: int = ceili(float(snapshot.get("remaining", 0.0)))
	var resolved := 0
	for value in circles:
		if String(Dictionary(value).get("outcome", "")) != "" or bool(Dictionary(value).get("disrupted", false)):
			resolved += 1
	var bar_size := Vector2(minf(300.0, viewport.x * 0.4), 9.0)
	var top: float = 124.0 if viewport.y >= 560.0 else 104.0
	var bar_pos := Vector2(viewport.x * 0.5 - bar_size.x * 0.5, top + 14.0)
	game.draw_rect(Rect2(bar_pos - Vector2(3.0, 3.0), bar_size + Vector2(6.0, 6.0)), Color(0.01, 0.015, 0.025, 0.78), true)
	game.draw_rect(Rect2(bar_pos, bar_size), Color(0.18, 0.08, 0.2, 0.82), true)
	game.draw_rect(Rect2(bar_pos, Vector2(bar_size.x * overall, bar_size.y)), Color(0.88, 0.32, 0.64, 0.92), true)
	game._draw_centered_outlined("RITUAL DA CATEDRAL  %d/%d  ·  %ds" % [resolved, circles.size(), remaining], Vector2(viewport.x * 0.5, top), 16, Color(0.9, 1.0, 0.72), Color(0.01, 0.015, 0.025, 0.96), 3)
	var hint_size: int = game._readable_text_size(12) if game.has_method("_readable_text_size") else 12
	game._draw_centered_outlined("Pise na runa dourada no compasso ou atravesse o pulso com TP", Vector2(viewport.x * 0.5, bar_pos.y + 26.0), hint_size, Color(1.0, 0.9, 0.62), Color(0, 0, 0, 0.9), 3)


# ================================================================ sobre os inimigos
## Braços erguidos/reverencia, cupula do selo e faiscas de fervor.
static func draw_overlay(game: Node2D, camera: Vector2) -> void:
	var ctl = _ctl(game)
	if ctl == null or not ctl.is_active():
		return
	var b: float = ctl.beat_phase()
	var t: float = game.time_alive
	var low: bool = game.gfx_low_resource
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		var kind: String = String(enemy.get("phase3_ritual_pose", ""))
		if kind == "" or kind == "procession":
			continue
		var p: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO)) - camera
		var po: Dictionary = pose(game, enemy, t)
		var body: Vector2 = p + Vector2(po.get("offset", Vector2.ZERO))
		var size: Vector2 = game._enemy_draw_size(enemy)
		var shoulder_y: float = -size.y * 0.18
		if kind == "dance" or kind == "worship" or kind == "fervor":
			var raise: float = 1.0 - (_bow_curve(b) if kind == "worship" else 0.0)
			var wave: float = sin(t * 6.0 + float(int(enemy.get("uid", 0)) % 13))
			for s in [-1.0, 1.0]:
				# Braço com cotovelo: abre para o lado e ergue as maos no compasso.
				var shoulder: Vector2 = body + Vector2(s * size.x * 0.18, shoulder_y)
				var elbow: Vector2 = shoulder + Vector2(s * (9.0 + 2.0 * wave * s), -4.0 - 5.0 * raise)
				var hand: Vector2 = elbow + Vector2(s * (2.0 + 3.0 * wave * s), -(4.0 + 10.0 * raise))
				var arm := PackedVector2Array([shoulder, elbow, hand])
				game.draw_polyline(arm, Color(0.1, 0.05, 0.08, 0.92), 5.0, true)
				game.draw_polyline(arm, Color(0.8, 0.66, 0.52, 0.98), 2.8, true)
				game.draw_circle(hand, 3.6, Color(0.1, 0.05, 0.08, 0.9))
				game.draw_circle(hand, 2.6, Color(1.0, 0.86, 0.5, 0.6 + 0.4 * raise))
		if String(enemy.get("phase3_ritual_role", "")) == "officiant":
			var circle: Dictionary = ctl._circle_for_enemy(enemy)
			var dome: Texture2D = frame_loop("vfx/seal_dome", t, 10.0) if bool(circle.get("sealed", false)) else null
			if dome != null:
				game.draw_texture_rect(dome, Rect2(body + Vector2(-size.x * 0.66, -size.x * 1.12), Vector2(size.x * 1.32, size.x * 1.32)), false, Color(1, 1, 1, 0.55))
			elif bool(circle.get("sealed", false)):
				var r: float = size.x * 0.68 + 4.0 * sin(t * 5.0)
				game.draw_arc(body + Vector2(0, -6), r, PI * 1.05, PI * 1.95, 20 if low else 32, Color(C_SEAL.r, C_SEAL.g, C_SEAL.b, 0.85), 3.0, true)
				game.draw_arc(body + Vector2(0, -6), r + 6.0, PI * 1.15, PI * 1.85, 16, Color(1.0, 0.8, 1.0, 0.35), 1.5, true)
				var hexes: int = 4 if low else 7
				for i in range(hexes):
					var a: float = PI + PI * (float(i) + 0.5) / float(hexes)
					game.draw_circle(body + Vector2(0, -6) + Vector2.from_angle(a) * r, 2.2, Color(1.0, 0.85, 1.0, 0.8))
			elif bool(circle.get("profaned", false)) and kind == "kneel":
				game._draw_centered_outlined("VULNERAVEL", body + Vector2(0, -size.y * 0.75), 12, C_SAFE, Color(0, 0, 0, 0.9), 3)
		if kind == "fervor" and not low:
			for i in range(3):
				var a2: float = t * 4.0 + float(i) * TAU / 3.0
				game.draw_circle(body + Vector2.from_angle(a2) * 20.0 + Vector2(0, -size.y * 0.4), 2.4, Color(0.95, 0.3, 0.6, 0.8))


# ================================================================ macabro
static func _draw_macabre_floor(game: Node2D, pos: Vector2, radius: float, circle: Dictionary, outcome: String, fade: float, low: bool) -> void:
	var seed: float = float(circle.get("phase", 0.0))
	var t: float = game.time_alive
	# Poça de cera de queijo e sangue escuro sob o circulo.
	game.draw_set_transform(pos, 0.0, Vector2(1.0, 0.92))
	game.draw_circle(Vector2.ZERO, radius * 1.18, Color(0.12, 0.06, 0.02, 0.42 * fade))
	game.draw_circle(Vector2.ZERO, radius * 1.05, Color(0.36, 0.22, 0.04, 0.22 * fade))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var wax_col: Color = Color(0.5, 0.06, 0.08) if outcome == "consummated" else C_WAX
	# Anel de cera derretida borbulhando.
	game.draw_arc(pos, radius * 1.08, 0.0, TAU, 48 if not low else 24, Color(wax_col.r, wax_col.g, wax_col.b, 0.55 * fade), 9.0, true)
	for i in range(6 if low else 12):
		var a: float = seed + float(i) * TAU / (6.0 if low else 12.0)
		var bubble: float = absf(sin(t * 2.2 + float(i) * 1.7))
		game.draw_circle(pos + Vector2.from_angle(a) * radius * 1.08, 2.0 + 3.0 * bubble, Color(1.0, 0.86, 0.4, (0.25 + 0.4 * bubble) * fade))
		# Escorridos de cera para fora.
		var drip_a: Vector2 = pos + Vector2.from_angle(a + 0.13) * radius * 1.12
		game.draw_line(drip_a, drip_a + Vector2.from_angle(a + 0.13) * (8.0 + 6.0 * sin(seed + float(i))), Color(wax_col.r, wax_col.g, wax_col.b, 0.5 * fade), 3.0, true)
	# Sigilos de rato riscados (pentagrama torto) e ossos espalhados.
	var points: int = 5
	var star := PackedVector2Array()
	for i in range(points + 1):
		var a2: float = seed + float((i * 2) % points) * TAU / float(points) - PI * 0.5
		star.append(pos + Vector2.from_angle(a2) * radius * 0.78)
	game.draw_polyline(star, Color(0.32, 0.04, 0.06, 0.55 * fade), 2.0, true)
	for i in range(4 if low else 7):
		var a3: float = seed * 1.7 + float(i) * 0.9
		var bone_c: Vector2 = pos + Vector2.from_angle(a3) * radius * (0.82 + 0.18 * sin(float(i) * 2.3))
		var dir: Vector2 = Vector2.from_angle(a3 + 1.1)
		game.draw_line(bone_c - dir * 7.0, bone_c + dir * 7.0, Color(0.88, 0.84, 0.7, 0.85 * fade), 2.4, true)
		game.draw_circle(bone_c - dir * 7.0, 2.2, Color(0.9, 0.86, 0.72, 0.85 * fade))
		game.draw_circle(bone_c + dir * 7.0, 2.2, Color(0.9, 0.86, 0.72, 0.85 * fade))
	if outcome == "consummated":
		# Sangue e miasma encharcando.
		for i in range(5):
			var a4: float = seed + float(i) * 1.3
			game.draw_circle(pos + Vector2.from_angle(a4) * radius * 0.45, 10.0 + 5.0 * sin(float(i)), Color(0.42, 0.02, 0.06, 0.5 * fade))


static func _draw_candles_and_hands(game: Node2D, pos: Vector2, radius: float, circle: Dictionary, outcome: String, fade: float, low: bool) -> void:
	var seed: float = float(circle.get("phase", 0.0))
	var t: float = game.time_alive
	var lit: bool = outcome != "disrupted" and not bool(circle.get("disrupted", false)) and not bool(circle.get("profaned", false))
	var candle_tex: Texture2D = frame_loop("vfx/candle", t, 12.0) if lit else null
	var count: int = 5 if (low or candle_tex != null) else 7
	for i in range(count):
		var a: float = seed + PI * 0.15 + float(i) * TAU / float(count)
		var base: Vector2 = pos + Vector2.from_angle(a) * radius * 1.16
		if candle_tex != null:
			game.draw_texture_rect(candle_tex, Rect2(base - Vector2(10, 38), Vector2(20, 40)), false, Color(1, 1, 1, fade))
			continue
		# Vela de sebo de queijo.
		var h: float = 14.0 + 5.0 * sin(seed * 3.0 + float(i))
		game.draw_rect(Rect2(base - Vector2(3.5, h), Vector2(7.0, h)), Color(0.86, 0.68, 0.24, fade), true)
		game.draw_rect(Rect2(base - Vector2(3.5, h), Vector2(7.0, h)), Color(0.2, 0.12, 0.04, fade), false, 1.2)
		game.draw_line(base + Vector2(2.0, -h), base + Vector2(2.0, -h + 6.0), Color(1.0, 0.9, 0.5, 0.9 * fade), 1.6)
		if lit:
			var flick: float = sin(t * 17.0 + float(i) * 2.1) * 1.6
			var tip: Vector2 = base + Vector2(flick, -h - 11.0)
			game.draw_colored_polygon(PackedVector2Array([base + Vector2(-3.2, -h - 1.0), tip, base + Vector2(3.2, -h - 1.0)]), Color(C_SICK.r, C_SICK.g, C_SICK.b, 0.9 * fade))
			game.draw_circle(base + Vector2(0, -h - 4.0), 2.0, Color(0.92, 1.0, 0.7, fade))
			game.draw_circle(base + Vector2(0, -h - 5.0), 9.0, Color(C_SICK.r, C_SICK.g, C_SICK.b, 0.12 * fade))
		else:
			# Apagada: fio de fumaça.
			var smoke_y: float = fposmod(t * 22.0 + float(i) * 9.0, 26.0)
			game.draw_circle(base + Vector2(sin(t * 3.0 + float(i)) * 3.0, -h - 4.0 - smoke_y), 2.6, Color(0.5, 0.5, 0.5, 0.35 * (1.0 - smoke_y / 26.0) * fade))
	if not lit or low:
		return
	# Mãos espectrais saindo da borda e fumaça com crânios subindo.
	var hands_tex: Texture2D = frame_loop("vfx/hands", t, 10.0)
	for i in range(3):
		var a: float = seed + PI * 0.48 + float(i) * TAU / 3.0
		var base2: Vector2 = pos + Vector2.from_angle(a) * radius * 1.02
		if hands_tex != null:
			game.draw_texture_rect(hands_tex, Rect2(base2 - Vector2(20, 38), Vector2(40, 40)), false, Color(1, 1, 1, 0.85 * fade))
			continue
		var rise: float = 0.5 + 0.5 * sin(t * 2.4 + float(i) * 2.0)
		var wrist: Vector2 = base2 + Vector2(0, -6.0 - 14.0 * rise)
		var col: Color = Color(0.62, 0.95, 0.66, (0.25 + 0.3 * rise) * fade)
		game.draw_line(base2, wrist, col, 4.0, true)
		for f in range(4):
			var fa: float = -PI * 0.5 + (float(f) - 1.5) * 0.35 + sin(t * 6.0 + float(f + i)) * 0.15
			game.draw_line(wrist, wrist + Vector2.from_angle(fa) * (7.0 + 3.0 * rise), col, 2.0, true)
	for i in range(2):
		var cycle: float = fposmod(t * 0.35 + float(i) * 0.5 + seed, 1.0)
		var wisp: Vector2 = pos + Vector2(sin(seed * 4.0 + float(i) * 2.0) * radius * 0.4, -cycle * radius * 1.3)
		_draw_ghost_skull(game, wisp, 6.0 + 3.0 * cycle, 0.35 * sin(cycle * PI) * fade)


static func _draw_ghost_skull(game: Node2D, p: Vector2, size: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var col := Color(0.66, 1.0, 0.7, alpha)
	# Crânio de rato: focinho alongado, orelhas e olhos vazios.
	game.draw_circle(p, size, col)
	game.draw_circle(p + Vector2(size * 0.9, size * 0.25), size * 0.55, col)
	game.draw_circle(p + Vector2(-size * 0.55, -size * 0.85), size * 0.38, col)
	game.draw_circle(p + Vector2(size * 0.35, -size * 0.9), size * 0.34, col)
	game.draw_circle(p + Vector2(-size * 0.2, -size * 0.1), size * 0.26, Color(0.02, 0.05, 0.03, alpha))
	game.draw_circle(p + Vector2(size * 0.4, -size * 0.05), size * 0.24, Color(0.02, 0.05, 0.03, alpha))
	game.draw_line(p + Vector2(size * 0.6, size * 0.55), p + Vector2(size * 1.25, size * 0.55), Color(0.02, 0.05, 0.03, alpha), 1.2)


## Animacoes de uma vez: selo quebrando e consumacao.
static func _draw_one_shots(game: Node2D, pos: Vector2, radius: float, circle: Dictionary, now: float) -> void:
	if circle.has("broken_at"):
		var u: float = (now - float(circle["broken_at"])) / 0.7
		if u >= 0.0 and u < 1.0:
			var tex: Texture2D = frame_progress("vfx/seal_break", u)
			if tex != null:
				game.draw_texture_rect(tex, Rect2(pos - Vector2(96, 140), Vector2(192, 192)), false)
			else:
				for i in range(10):
					var a: float = float(i) * TAU / 10.0
					var shard: Vector2 = pos + Vector2(0, -24) + Vector2.from_angle(a) * (10.0 + 90.0 * u)
					game.draw_line(shard, shard + Vector2.from_angle(a) * 9.0, Color(0.92, 0.88, 0.78, 1.0 - u), 3.0, true)
				game.draw_circle(pos + Vector2(0, -24), 40.0 * (1.0 - u), Color(1.0, 0.86, 0.4, 0.4 * (1.0 - u)))
	if circle.has("outcome_at"):
		var u2: float = (now - float(circle["outcome_at"])) / 1.4
		if u2 >= 0.0 and u2 < 1.0:
			var tex2: Texture2D = frame_progress("vfx/consummate", u2)
			if tex2 != null:
				game.draw_texture_rect(tex2, Rect2(pos - Vector2(144, 270), Vector2(288, 288)), false)
			else:
				var k: float = sin(u2 * PI)
				game.draw_rect(Rect2(pos - Vector2(22.0 * k + 6.0, 260.0 * k), Vector2(44.0 * k + 12.0, 260.0 * k)), Color(C_SICK.r, C_SICK.g, C_SICK.b, 0.35 * k), true)
				_draw_ghost_skull(game, pos + Vector2(0, -60.0 - 120.0 * u2), 18.0 + 10.0 * k, 0.7 * k)
