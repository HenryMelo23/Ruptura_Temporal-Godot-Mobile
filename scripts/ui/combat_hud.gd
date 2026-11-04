extends RefCounted

const INK := Color("0a121b")
const TEXT := Color("f1f0e5")
const MUTED := Color("a2b8c1")
const CYAN := Color("65d9dd")
const HEAL := Color("6ce5b1")
const HURT := Color("ff625c")
## Estilo do HUD alinhado aos mapas: paineis ameixa, moldura de bronze e diamantes.
const PANEL := Color("1a0f20")
const BRONZE := Color("b07a3c")
const BRONZE_HI := Color("e8b870")
const GOLD := Color("ffd68c")
const CREAM := Color("f6e8ce")
const PLUM_MUTED := Color("c4aa96")
const XP_GOLD := Color("ffc45a")
const RIFT_VIOLET := Color("c68cff")
const THREAT_TIER_NAMES := ["ESTÁVEL", "INQUIETA", "INSTÁVEL", "RUPTURA", "COLAPSO", "SEM FIM"]
const THREAT_COLORS := [Color("6fe0d6"), Color("b6e06f"), Color("ffb24a"), Color("ff7a3c"), Color("ff4a5a"), Color("ff3060")]
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
	host.draw_rect(rect.grow(3.0), Color(0.0, 0.0, 0.0, 0.22 * alpha))
	host.draw_rect(rect, Color(PANEL, 0.88 * alpha))
	host.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 3.0), Vector2(rect.size.x, 3.0)), Color(accent, 0.55 * alpha))
	host.draw_rect(rect, Color(BRONZE, 0.95 * alpha), false, 1.5)
	host.draw_rect(rect.grow(-3.0), Color(BRONZE_HI, 0.22 * alpha), false, 1.0)
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
		stud(host, corner, 4.0, Color(BRONZE_HI, alpha))


func stud(host: Node2D, center: Vector2, radius: float, color: Color, outline: Color = Color(0.35, 0.21, 0.1)) -> void:
	if radius < 1.0 or color.a <= 0.01:
		return
	var diamond := PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius, 0.0), center + Vector2(0.0, radius), center + Vector2(-radius, 0.0)])
	host.draw_colored_polygon(diamond, color)
	diamond.append(diamond[0])
	host.draw_polyline(diamond, Color(outline, color.a), 1.0, true)


func number(host: Node2D, value: String, pos: Vector2, size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	host.draw_string_outline(host.menu_ui_font, pos, value, align, width, size, maxi(2, size / 7), Color(0.04, 0.01, 0.06, color.a * 0.95))
	host.draw_string(host.menu_ui_font, pos, value, align, width, size, color)


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
	var emblem_center := rect.position + Vector2(31.0, rect.size.y * 0.5)
	_level_emblem(host, emblem_center, 22.0, alpha)
	var x: float = rect.position.x + 62.0
	var right: float = rect.end.x - 12.0
	var top: float = rect.position.y
	var name: String = String(host.HENRY_MUTATIONS[host.selected_mutation].get("name", "Incendiário")) if host.active_character_key == host.CHARACTER_HENRY else String(host.MANIFESTATIONS[host.selected_manifestation]["name"])
	var name_width: float = (right - x) - 86.0
	if name_width >= 44.0:
		text(host, name.to_upper(), Vector2(x, top + 20.0), 11, Color(PLUM_MUTED, alpha), name_width)
	number(host, "%d / %d" % [host.player_hp, host.player_hp_max], Vector2(x, top + 21.0), 16, Color(CREAM, alpha), HORIZONTAL_ALIGNMENT_RIGHT, right - x)
	var bar := Rect2(x, top + 28.0, right - x, 20.0)
	health_bar(host, bar, ratio, accent, alpha)
	var status: String = ""
	var status_color: Color = PLUM_MUTED
	if healing > 0.0:
		status = "+%d  RECUPERANDO" % change
		status_color = HEAL
	elif damage > 0.0:
		status = "%d  DANO" % change
		status_color = HURT
	elif ratio < 0.25:
		status = "ESTADO CRÍTICO"
		status_color = HURT
	elif ratio < 0.55:
		status = "VIDA BAIXA"
		status_color = Color("efb66b")
	if status != "":
		text(host, status, Vector2(x, top + 64.0), 11, Color(status_color, alpha), right - x)
	if host.is_multiplayer and host._is_local_run_leader():
		host._draw_leader_crown(rect.position + Vector2(-3, -3), 0.4, Color("ead391"))


## Emblema com o nivel da run e um anel de XP em volta.
func _level_emblem(host: Node2D, center: Vector2, radius: float, alpha: float) -> void:
	var level: int = clampi(int(host.player_run_level), 1, 10)
	var xp: int = maxi(0, int(host.player_run_xp))
	var needed: int = host._player_run_level_controller().xp_to_next()
	var xp_ratio: float = 1.0 if needed <= 0 or level >= 10 else clampf(float(xp) / float(needed), 0.0, 1.0)
	var manifest: Color = host._manifestation_color()
	host.draw_circle(center, radius + 2.0, Color(0.03, 0.01, 0.05, 0.9 * alpha))
	host.draw_circle(center, radius - 4.0, Color(manifest.darkened(0.55), 0.9 * alpha))
	host.draw_arc(center, radius, 0.0, TAU, 40, Color(BRONZE, 0.9 * alpha), 3.0, true)
	host.draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * xp_ratio, 40, Color(XP_GOLD, alpha), 3.0, true)
	host.draw_arc(center, radius - 5.0, 0.0, TAU, 32, Color(manifest, 0.55 * alpha), 1.5, true)
	number(host, str(level), center + Vector2(0.0, 7.0), 19, Color(CREAM, alpha), HORIZONTAL_ALIGNMENT_CENTER, -1.0)
	host.draw_string(host.menu_ui_font, center + Vector2(-radius, -radius * 0.42 + 1.0), "NV", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 8, Color(GOLD, 0.85 * alpha))


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
	heal_reduction_wire(host, rect, alpha)


func heal_reduction_wire(host: Node2D, rect: Rect2, alpha: float) -> void:
	if host.is_dead or host.player_hp <= 0:
		return
	if host.revive_heal_penalty_timer <= 0.0 and not host._is_player_calcified():
		return
	var turns := clampi(int(rect.size.x / 36.0), 4, 7)
	var pitch: float = (rect.size.x - 8.0) / float(turns)
	var barb_size := clampf(rect.size.y * 0.22, 2.0, 4.0)
	var shadow := Color(0.04, 0.025, 0.035, alpha)
	var metal := Color(0.67, 0.69, 0.72, alpha)
	var rust := Color(0.92, 0.32, 0.35, alpha)
	for turn in range(turns):
		var start := Vector2(rect.position.x + 4.0 + pitch * turn, rect.end.y + 1.0)
		var end := start + Vector2(pitch * 0.75, -rect.size.y - 2.0)
		var next := start + Vector2(pitch, 0.0)
		host.draw_line(end, next, shadow, 3.0, true)
		host.draw_line(end, next, Color(0.38, 0.34, 0.39, alpha), 1.0, true)
		host.draw_line(start, end, shadow, 4.0, true)
		host.draw_line(start, end, metal, 1.4, true)
		var knot := start.lerp(end, 0.5)
		var barb := Vector2(barb_size, barb_size)
		host.draw_line(knot - barb, knot + barb, shadow, 3.0, true)
		host.draw_line(knot - barb, knot + barb, metal, 1.0, true)
		host.draw_line(knot + Vector2(-barb_size, 1.0), knot + Vector2(barb_size, -1.0), rust, 1.5, true)


func stats_panel(host: Node2D, rect: Rect2, alpha: float) -> void:
	surface(host, rect, GOLD, alpha)
	var x: float = rect.position.x + 14.0
	var right: float = rect.end.x - 12.0
	var top: float = rect.position.y
	var gem := rect.position + Vector2(24.0, 30.0)
	host.draw_circle(gem, 13.0, Color(CYAN, 0.16 * alpha))
	stud(host, gem, 9.0, Color(CYAN, alpha), Color(0.08, 0.35, 0.36))
	number(host, display_points(host, host.score), Vector2(x + 26.0, top + 40.0), 26, Color(CREAM, alpha))
	text(host, "PONTOS", Vector2(right - 52.0, top + 16.0), 10, Color(PLUM_MUTED, alpha), 52.0)
	var affordable: int = host._affordable_card_count() if not host._is_drop_game_mode() else 0
	if affordable > 0:
		var badge := Rect2(right - 84.0, top + 22.0, 84.0, 22.0)
		var shine: float = 0.82 + 0.18 * sin(clock * 3.0)
		host.draw_rect(badge, Color(XP_GOLD, shine * alpha))
		host.draw_rect(badge, Color(BRONZE, alpha), false, 1.0)
		var label: String = "%d CARTA%s" % [affordable, "S" if affordable > 1 else ""]
		host.draw_string(host.menu_ui_font, badge.position + Vector2(0.0, 16.0), label, HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 12, Color(0.16, 0.07, 0.03, alpha))
	_shop_status_line(host, Rect2(x, top + 54.0, right - x, 16.0), alpha)


## Linha de baixo do painel de pontos: situacao da loja (fenda / drop).
func _shop_status_line(host: Node2D, area: Rect2, alpha: float) -> void:
	if host._is_drop_game_mode():
		text(host, "MODO DROP  ·  CARTAS DOS INIMIGOS", area.position + Vector2(0.0, 11.0), 10, Color(GOLD, alpha), area.size.x)
		return
	var rift = host.shop_rift_controller
	if rift == null or not rift.enabled():
		return
	if rift.active() and rift.state() != "entered":
		var unstable: bool = rift.unstable()
		var color: Color = Color("ff8a5a") if unstable else RIFT_VIOLET
		var label: String = "FENDA %s  ·  %ds" % ["INSTÁVEL" if unstable else "ABERTA", int(ceil(rift.remaining()))]
		var pulse_alpha: float = 0.75 + 0.25 * sin(clock * (9.0 if unstable else 4.0))
		text(host, label, area.position + Vector2(0.0, 11.0), 11, Color(color, alpha * pulse_alpha), area.size.x)
		return
	var progress: float = rift.kill_progress()
	if host.shop_auto_interval > 0.0:
		progress = maxf(progress, clampf(float(host.shop_auto_elapsed) / float(host.shop_auto_interval), 0.0, 1.0))
	text(host, "PRÓXIMA FENDA", area.position + Vector2(0.0, 9.0), 9, Color(PLUM_MUTED, alpha), 96.0)
	var bar := Rect2(area.position + Vector2(98.0, 4.0), Vector2(maxf(10.0, area.size.x - 98.0), 5.0))
	host.draw_rect(bar, Color(0.04, 0.01, 0.06, 0.9 * alpha))
	host.draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color(RIFT_VIOLET, alpha))


## Pontos inteiros (sem decimal) na mesma escala da loja, com separador de milhar.
func display_points(host: Node, amount: Variant) -> String:
	var value: int = int(floor(float(amount) / host._progression().POINT_DISPLAY_DENOMINATION))
	var digits: String = str(absi(value))
	var grouped: String = ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped


## Estagio de ameaca da run (0..5) a partir do tempo; 3+ coincidem com as curvas longas.
func threat_tier(host: Node) -> int:
	var thresholds: Array = [600.0, 1200.0, float(host.LONG_RUN_RUPTURE_TIME), float(host.LONG_RUN_BROKEN_BUILD_TIME), float(host.LONG_RUN_ENDLESS_TIME)]
	var tier: int = 0
	for limit in thresholds:
		if float(host.time_alive) >= float(limit):
			tier += 1
	return tier


func threat_progress(host: Node) -> float:
	var thresholds: Array = [0.0, 600.0, 1200.0, float(host.LONG_RUN_RUPTURE_TIME), float(host.LONG_RUN_BROKEN_BUILD_TIME), float(host.LONG_RUN_ENDLESS_TIME)]
	var tier: int = threat_tier(host)
	if tier >= thresholds.size() - 1:
		return 1.0
	return clampf((float(host.time_alive) - float(thresholds[tier])) / maxf(1.0, float(thresholds[tier + 1]) - float(thresholds[tier])), 0.0, 1.0)


func clock_text(host: Node) -> String:
	var total: int = maxi(0, int(host.time_alive))
	if total >= 3600:
		return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
	return "%02d:%02d" % [total / 60, total % 60]


## Relogio da run + ameaca (estagio e multiplicador de pontos). compact = celular.
func clock_panel(host: Node2D, rect: Rect2, alpha: float, compact: bool = false) -> void:
	var tier: int = threat_tier(host)
	var tier_color: Color = THREAT_COLORS[tier]
	surface(host, rect, tier_color, alpha)
	for side in [-1.0, 1.0]:
		stud(host, Vector2(rect.get_center().x + side * rect.size.x * 0.5, rect.get_center().y), 6.0, Color(BRONZE_HI, alpha))
	var time_size: int = 28 if compact else 32
	var time_y: float = rect.position.y + (30.0 if compact else 37.0)
	number(host, clock_text(host), Vector2(rect.position.x, time_y), time_size, Color(CREAM, alpha), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	var multiplier: float = float(host._progression().long_run_point_multiplier())
	var pip_y: float = rect.end.y - (14.0 if compact else 13.0)
	if not compact:
		var label: String = "AMEAÇA  %s  ·  ×%.1f PTS" % [String(THREAT_TIER_NAMES[tier]), multiplier]
		host.draw_string(host.menu_ui_font, Vector2(rect.position.x, rect.position.y + 55.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color(tier_color, alpha))
	var pip_gap: float = 13.0 if compact else 15.0
	var pip_x0: float = rect.get_center().x - pip_gap * 2.0 - (16.0 if compact else 0.0)
	var progress: float = threat_progress(host)
	for index in range(5):
		var center := Vector2(pip_x0 + pip_gap * float(index), pip_y)
		var lit: bool = index < tier or tier >= 5
		var current: bool = index == tier and tier < 5
		if lit:
			var pulse_amount: float = 0.5 + 0.5 * sin(clock * 6.0) if tier >= 5 else 1.0
			host.draw_circle(center, 7.0, Color(tier_color, 0.22 * alpha * pulse_amount))
			stud(host, center, 5.0, Color(tier_color, alpha))
		elif current:
			stud(host, center, 5.0, Color(0.2, 0.12, 0.16, alpha), Color(0.55, 0.4, 0.3))
			stud(host, center, 5.0 * progress, Color(tier_color, 0.85 * alpha), Color(tier_color.darkened(0.4)))
		else:
			stud(host, center, 5.0, Color(0.2, 0.12, 0.16, 0.85 * alpha), Color(0.48, 0.36, 0.28))
	if compact:
		host.draw_string(host.menu_ui_font, Vector2(pip_x0 + pip_gap * 4.0 + 10.0, pip_y + 4.0), "×%.1f" % multiplier, HORIZONTAL_ALIGNMENT_LEFT, 44.0, 11, Color(tier_color, alpha))


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
