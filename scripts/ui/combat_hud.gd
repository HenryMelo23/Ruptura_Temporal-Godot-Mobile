extends RefCounted

const INK := Color("0a121b")
const TEXT := Color("f1f0e5")
const MUTED := Color("a2b8c1")
const CYAN := Color("65d9dd")
const HEAL := Color("6ce5b1")
const HURT := Color("ff625c")
var last_hp: float = -1.0
var last_max: float = -1.0
var fill: float = 1.0
var trail: float = 1.0
var hold: float = 0.0
var damage: float = 0.0
var healing: float = 0.0
var change: int = 0
var clock: float = 0.0
var danger: float = 0.0


func reset(host: Node) -> void:
	last_hp = float(host.player_hp)
	last_max = float(host.player_hp_max)
	fill = clampf(last_hp / maxf(1.0, last_max), 0.0, 1.0)
	trail = fill
	hold = 0.0
	damage = 0.0
	healing = 0.0
	change = 0
	danger = 0.0


func update(host: Node, delta: float) -> void:
	if host.is_dead or host.player_hp <= 0 or host._spectator_controls_locked():
		reset(host)
		return
	if host.mode not in ["game", "boss_call", "shop_countdown", "pause_countdown", "shop_opening"]:
		if host.mode not in ["paused", "settings", "settings_graphics", "settings_audio", "settings_gameplay", "settings_keys", "settings_gamepad", "pause_deck"]:
			reset(host)
		return
	clock += delta
	var hp: float = float(host.player_hp)
	var maximum: float = float(host.player_hp_max)
	if last_hp < 0.0 or not is_equal_approx(last_max, maximum):
		reset(host)
	var ratio: float = clampf(hp / maxf(1.0, maximum), 0.0, 1.0)
	if hp < last_hp:
		trail = maxf(trail, fill)
		fill = ratio
		hold = 0.28
		damage = 1.0
		healing = 0.0
		change = roundi(hp - last_hp)
	elif hp > last_hp:
		healing = 1.0
		damage = 0.0
		change = roundi(hp - last_hp)
	last_hp = hp
	last_max = maximum
	fill = lerpf(fill, ratio, 1.0 - exp(-delta * 9.0))
	hold = maxf(0.0, hold - delta)
	if hold <= 0.0:
		trail = move_toward(trail, ratio, delta * 0.8)
	damage = maxf(0.0, damage - delta * 1.7)
	healing = maxf(0.0, healing - delta * 0.9)
	danger = lerpf(danger, severity(host), 1.0 - exp(-delta * 4.5))


func severity(host: Node) -> float:
	if host.is_dead or host.player_hp <= 0 or host.player_hp_max <= 0 or host._spectator_controls_locked():
		return 0.0
	var ratio: float = float(host.player_hp) / float(host.player_hp_max)
	return clampf((host.gfx_health_warning_start - ratio) / maxf(0.01, host.gfx_health_warning_start), 0.0, 1.0)


func pulse() -> float:
	var phase: float = fposmod(clock * lerpf(0.8, 1.65, danger), 1.0)
	return exp(-pow((phase - 0.13) * 15.0, 2.0)) + 0.48 * exp(-pow((phase - 0.36) * 18.0, 2.0))


func surface(host: Node2D, rect: Rect2, accent: Color, alpha: float = 1.0) -> void:
	host.draw_rect(rect, Color(INK, 0.94 * alpha))
	host.draw_rect(rect, Color(accent, 0.23 * alpha), false, 1.0)
	host.draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), Color(accent, 0.9 * alpha))


func text(host: Node2D, value: String, pos: Vector2, size: int, color: Color, width: float = -1.0) -> void:
	host._draw_ui_text(value, pos, size, color, width)


func health_color(ratio: float) -> Color:
	if ratio < 0.25:
		return HURT
	if ratio < 0.55:
		return Color("efb66b")
	return HEAL


func health_panel(host: Node2D, rect: Rect2, alpha: float) -> void:
	var ratio: float = clampf(float(host.player_hp) / maxf(1.0, float(host.player_hp_max)), 0.0, 1.0)
	var accent: Color = health_color(ratio).lerp(Color.WHITE, damage * 0.5)
	surface(host, rect, accent, alpha)
	var x: float = rect.position.x + 14.0
	var top: float = rect.position.y
	var status: String = "VIDA" if ratio >= 0.55 else ("VIDA BAIXA" if ratio >= 0.25 else "ESTADO CRÍTICO")
	text(host, status, Vector2(x, top + 21), 11, Color(accent, alpha), rect.size.x * 0.48)
	var value: String = "%d / %d" % [host.player_hp, host.player_hp_max]
	var value_width: float = host.menu_ui_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	text(host, value, Vector2(rect.end.x - 14 - value_width, top + 22), 16, Color(TEXT, alpha))
	var bar := Rect2(x, top + 31, rect.size.x - 28, 20)
	health_bar(host, bar, ratio, accent, alpha)
	var footer_y: float = top + 67
	text(host, "%02d:%02d" % [int(host.time_alive) / 60, int(host.time_alive) % 60], Vector2(x, footer_y), 12, Color(MUTED, alpha), 52)
	var footer: String = String(host.MANIFESTATIONS[host.selected_manifestation]["name"])
	var footer_color := MUTED
	if healing > 0.0:
		footer = "+%d  RECUPERANDO" % change
		footer_color = HEAL
	elif damage > 0.0:
		footer = "%d  DANO" % change
		footer_color = HURT
	text(host, footer, Vector2(x + 59, footer_y), 11, Color(footer_color, alpha), rect.size.x - 88)
	if host.is_multiplayer and host._is_local_run_leader():
		host._draw_leader_crown(rect.position + Vector2(-3, -3), 0.4, Color("ead391"))


func health_bar(host: Node2D, rect: Rect2, ratio: float, accent: Color, alpha: float) -> void:
	host.draw_rect(rect, Color("1d2b33") * Color(1, 1, 1, alpha))
	var inner := rect.grow(-2.0)
	var visible_fill: float = fill if last_hp >= 0.0 else ratio
	var visible_trail: float = maxf(visible_fill, trail if last_hp >= 0.0 else ratio)
	host.draw_rect(Rect2(inner.position, Vector2(inner.size.x * visible_trail, inner.size.y)), Color(HURT, 0.64 * alpha))
	var filled := Rect2(inner.position, Vector2(inner.size.x * visible_fill, inner.size.y))
	if filled.size.x > 0.1:
		host.draw_rect(filled, Color(accent, alpha))
		host.draw_rect(Rect2(filled.position, Vector2(filled.size.x, 4)), Color(1, 1, 1, (0.1 + healing * 0.4) * alpha))
		var beat: float = pulse() * clampf((0.35 - ratio) / 0.35, 0.0, 1.0)
		host.draw_rect(filled, Color(1, 0.78, 0.71, beat * 0.35 * alpha))
		if healing > 0.0:
			var sweep_x: float = filled.position.x + filled.size.x * (1.0 - healing)
			host.draw_line(Vector2(sweep_x, filled.position.y), Vector2(sweep_x, filled.end.y), Color(0.9, 1, 0.95, healing * alpha), 2.0)
	for marker in [0.25, 0.5, 0.75]:
		var marker_x: float = inner.position.x + inner.size.x * marker
		host.draw_line(Vector2(marker_x, inner.position.y), Vector2(marker_x, inner.end.y), Color(INK, 0.5 * alpha), 1.0)
	host.draw_rect(rect, Color(accent, (0.25 + damage * 0.6) * alpha), false, 1.0)


func stats_panel(host: Node2D, rect: Rect2, alpha: float) -> void:
	surface(host, rect, CYAN, alpha)
	text(host, "PONTOS", rect.position + Vector2(14, 20), 10, Color(MUTED, alpha))
	text(host, str(host.score), rect.position + Vector2(14, 43), 23, Color(TEXT, alpha), rect.size.x - 28)
	var footer: String = "Pode comprar: %d  ·  Custo: %d" % [host._affordable_card_count(), host.card_cost]
	text(host, footer, rect.position + Vector2(14, 66), 11, Color("ead391") * Color(1, 1, 1, alpha), rect.size.x - 28)


func ability_status(info: Dictionary) -> String:
	if bool(info.get("active", false)):
		return String(info.get("sub", "")) if not String(info.get("sub", "")).is_empty() else "ATIVO"
	if float(info.cd_elapsed) < float(info.cd_max):
		return "%.1fs" % maxf(0.0, float(info.cd_max) - float(info.cd_elapsed))
	return "PRONTO"


func ability(host: Node2D, rect: Rect2, info: Dictionary) -> void:
	var accent: Color = info.color
	var ready: bool = float(info.cd_elapsed) >= float(info.cd_max)
	var active: bool = bool(info.get("active", false))
	surface(host, rect, accent if ready or active else MUTED, 0.95)
	if active:
		host.draw_rect(rect.grow(-3), Color(accent, 0.08 + (0.5 + sin(clock * 4.0) * 0.5) * 0.09))
	text(host, String(info.get("bind", "")), rect.position + Vector2(9, 15), 10, MUTED, rect.size.x - 18)
	var center := rect.position + Vector2(rect.size.x * 0.5, 35)
	var icon_color := accent if ready or active else accent.lerp(MUTED, 0.7)
	match String(info.icon_type):
		"sword": host._draw_icon_sword(center, 20.0, icon_color)
		"star": host._draw_icon_star(center, 20.0, icon_color)
		"trident": host._draw_icon_trident(center, 20.0, icon_color)
		"portal": host._draw_icon_portal(center, 20.0, icon_color)
	text(host, String(info.label), rect.position + Vector2(9, 64), 11, TEXT, rect.size.x - 18)
	var progress: float = clampf(float(info.cd_elapsed) / maxf(0.01, float(info.cd_max)), 0.0, 1.0)
	if active:
		progress = 1.0
	host.draw_rect(Rect2(rect.position + Vector2(8, rect.size.y - 7), Vector2(rect.size.x - 16, 2)), Color(MUTED, 0.2))
	host.draw_rect(Rect2(rect.position + Vector2(8, rect.size.y - 7), Vector2((rect.size.x - 16) * progress, 2)), accent)
	text(host, ability_status(info), rect.position + Vector2(9, 80), 10, accent if active else MUTED, rect.size.x - 18)
	if int(info.get("charges", 0)) > 0:
		text(host, "×%d" % int(info.charges), rect.position + Vector2(rect.size.x - 28, 15), 10, TEXT, 24)


func overlay(host: Node2D, viewport: Vector2) -> void:
	if host.is_dead or host.player_hp <= 0 or host._spectator_controls_locked():
		return
	var strength: float = float(host.gfx_health_warning_strength)
	var hit: float = clampf(host.damage_flash_timer / 0.22, 0.0, 1.0)
	if strength <= 0.0:
		return
	var ratio: float = float(host.player_hp) / maxf(1.0, float(host.player_hp_max))
	var critical: float = clampf((0.25 - ratio) / 0.25, 0.0, 1.0)
	var beat: float = pulse()
	var edge_alpha: float = minf(0.88, ((0.12 + danger * 0.45 + critical * 0.26) * danger + beat * danger * 0.12 + hit * 0.24) * strength)
	if edge_alpha < 0.001:
		return
	var center := viewport * 0.5
	# Vertex gradients form an elliptical clear aperture. No fullscreen texture or
	# shader sampling is required, including on the mobile compatibility renderer.
	var aperture := Vector2(0.74 - danger * 0.15, 0.72 - danger * 0.16)
	for i in range(64):
		var a := Vector2.from_angle(float(i) * TAU / 64.0)
		var b := Vector2.from_angle(float(i + 1) * TAU / 64.0)
		var outer_a: Vector2 = center + a / maxf(absf(a.x), absf(a.y)) * center
		var outer_b: Vector2 = center + b / maxf(absf(b.x), absf(b.y)) * center
		var inner_a: Vector2 = center + a * center * aperture
		var inner_b: Vector2 = center + b * center * aperture
		host.draw_polygon(PackedVector2Array([outer_a, outer_b, inner_b, inner_a]), PackedColorArray([Color(0.36, 0.0, 0.025, edge_alpha), Color(0.36, 0.0, 0.025, edge_alpha), Color(0.72, 0.015, 0.03, 0), Color(0.72, 0.015, 0.03, 0)]))
	if hit > 0.0:
		host.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.9, 0.03, 0.025, hit * 0.065 * minf(strength, 1.0)))
	if danger < 0.15:
		return
	for corner in range(4):
		for branch in range(4):
			_vein(host, viewport, corner, branch, critical, beat, strength)


func _vein(host: Node2D, viewport: Vector2, corner: int, branch: int, critical: float, beat: float, strength: float) -> void:
	var flip := Vector2(-1 if corner % 2 else 1, -1 if corner >= 2 else 1)
	var origin := Vector2(viewport.x if flip.x < 0 else 0.0, viewport.y if flip.y < 0 else 0.0)
	var start := Vector2(0.0, 0.04 + branch * 0.053) if branch % 2 == 0 else Vector2(0.025 + branch * 0.035, 0.0)
	var end := Vector2(0.25 + branch * 0.018, 0.23 + (3 - branch) * 0.035)
	var growth: float = clampf(danger * 1.05 + critical * 0.17, 0.0, 1.0)
	var alpha: float = minf(0.9, danger * (0.44 + critical * 0.44 + beat * 0.14) * strength)
	var points: Array[Vector2] = []
	for segment in range(21):
		var t: float = float(segment) / 20.0 * growth
		var point: Vector2 = start.lerp(end, t)
		var bend: float = sin(t * 14.0 + branch * 2.7 + corner) * sin(t * PI) * 0.018
		point += Vector2(bend, -bend * 0.8)
		point += Vector2(0.0015, -0.002) * sin(clock * 2.0 + t * 4.0) * critical
		points.append(origin + point * viewport * flip)
	for segment in range(1, points.size()):
		var taper: float = 1.0 - float(segment) / float(points.size())
		var width: float = (1.0 + taper * (3.0 + critical * 3.0)) * minf(viewport.x / 1280.0, 1.2)
		host.draw_line(points[segment - 1], points[segment], Color(0.09, 0.0, 0.014, alpha), width + 2.0, true)
		host.draw_line(points[segment - 1], points[segment], Color(0.64 + beat * 0.12, 0.025, 0.055, alpha * taper), width, true)
		if segment in [7, 12, 17]:
			var branch_start := points[segment]
			for twig in range(1, 5):
				var t := float(twig) / 4.0
				var offset := Vector2(0.055 * t, -0.042 * t * t) * viewport * flip * growth * taper
				var tip := points[segment] + offset
				host.draw_line(branch_start, tip, Color(0.39, 0.005, 0.035, alpha * taper * (1.0 - t * 0.65)), maxf(0.65, width * 0.5 * (1.0 - t * 0.7)), true)
				branch_start = tip
