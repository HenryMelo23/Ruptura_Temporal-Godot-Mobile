extends RefCounted

# Draws through the main CanvasItem; state stays on the host during migration.


static func _draw_tutorial_control_highlight(game: Node2D, t: float) -> void:
	var action_key = ""
	match game.tutorial_state:
		game.TUTORIAL_STATE_ATTACK:
			action_key = "attack"
		game.TUTORIAL_STATE_SKILL:
			action_key = "skill"
		game.TUTORIAL_STATE_SECONDARY:
			action_key = "secondary"
		game.TUTORIAL_STATE_DASH:
			action_key = "dash"
	if action_key == "" or not game.buttons.has(action_key):
		return
	var rect: Rect2 = Rect2(game.buttons[action_key])
	var pulse: float = 0.5 + sin(t * 7.0) * 0.5
	var glow: Rect2 = rect.grow(10.0 + pulse * 7.0)
	game.draw_rect(glow, Color(0.0, 1.0, 0.82, 0.075 + pulse * 0.045), true)
	game.draw_rect(glow, Color(0.0, 1.0, 0.82, 0.86), false, 3.0)
	game.draw_rect(rect.grow(4.0), Color(1.0, 0.18, 0.72, 0.64), false, 2.0)


static func _draw_resonant_meter(game: Node2D, viewport: Vector2) -> void :
	var rect = Rect2(viewport.x * 0.5 - 96.0, viewport.y - 52.0, 192.0, 18.0)
	game.draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.46), true)
	game.draw_rect(rect.grow(4.0), Color(1.0, 0.72, 0.2, 0.36), false, 1.4)
	var is_perfect: bool = game._resonant_is_perfect()
	var pulse: float = (0.5 + sin(Time.get_ticks_msec() * 0.018) * 0.5) if is_perfect else 0.0
	var perfect_zone_w: float = max(9.0, rect.size.x * (game.RESONANT_PERFECT_WINDOW / (game.RESONANT_BEAT_INTERVAL * 4.0)) * 2.0)
	for i in range(5):
		var x: float = rect.position.x + rect.size.x * (float(i) / 4.0)
		var zone = Rect2(x - perfect_zone_w * 0.5, rect.position.y - 3.0, perfect_zone_w, rect.size.y + 6.0)
		game.draw_rect(zone, Color(1.0, 0.66, 0.12, 0.16 + pulse * 0.18), true)
		game.draw_line(Vector2(x, rect.position.y - 6.0), Vector2(x, rect.end.y + 6.0), Color(1.0, 0.86, 0.38, 0.72), 1.6)
	var progress: float = fposmod(game.time_alive, game.RESONANT_BEAT_INTERVAL * 4.0) / (game.RESONANT_BEAT_INTERVAL * 4.0)
	var p = Vector2(rect.position.x + rect.size.x * progress, rect.get_center().y)
	var perfect_alpha: float = 1.0 if is_perfect else 0.42
	if is_perfect:
		game.draw_rect(rect.grow(8.0 + pulse * 5.0), Color(1.0, 0.7, 0.14, 0.16 + pulse * 0.12), false, 2.0)
	game.draw_circle(p, 8.0 + pulse * 4.0, Color(1.0, 0.82, 0.22, perfect_alpha))
	var prompt = "ATIRE AGORA" if is_perfect else "ESPERE A BATIDA"
	var prompt_color = Color(1.0, 0.92, 0.36, 1.0) if is_perfect else Color(0.84, 0.9, 1.0, 0.72)
	game._draw_centered(prompt, rect.get_center() + Vector2(0, -22), 13 if is_perfect else 11, prompt_color)
	game._draw_centered("COMBO %d  x%.2f" % [game.resonant_perfect_streak, game._resonant_combo_multiplier()], rect.get_center() + Vector2(0, 22), 10, Color(1.0, 0.9, 0.62, 0.86))


static func _draw_hud(game: Node2D, viewport: Vector2) -> void :
	if game._spectator_controls_locked():
		game._draw_spectator_hud(viewport)
		return
	if game._uses_desktop_ui():
		game._draw_desktop_hud(viewport)
		return
	var portrait = game._is_portrait(viewport)
	var sm = 1.25 if game.is_gamepad_active and not portrait else 1.0
	var left_w = (236.0 * sm) if not portrait else min(236.0, viewport.x * 0.46)
	var left_h = 76.0 * sm
	var left_rect = Rect2(game._left_panel_pos(viewport), Vector2(left_w, left_h))
	var left_alpha: float = game._hud_rect_player_alpha(left_rect, viewport, 84.0)
	game.hud_feedback.health_panel(game, left_rect, left_alpha)

	var right_w = (220.0 * sm) if not portrait else min(220.0, viewport.x * 0.44)
	var right_rect = Rect2(game._right_panel_pos(viewport), Vector2(right_w, left_h))
	if game.buttons.has("pause") and right_rect.intersects(game.buttons["pause"]):
		right_rect.position.x = maxf(left_rect.end.x + 12.0, Rect2(game.buttons["pause"]).position.x - right_w - 12.0)
	var right_alpha: float = game._hud_rect_player_alpha(right_rect, viewport, 84.0)
	game.hud_feedback.stats_panel(game, right_rect, right_alpha)

	if game.boss_active and game.boss_hp > 0.0 and not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		var boss_rect = Rect2(game._boss_panel_pos(viewport), Vector2(380 * sm, 30 * sm))
		game._draw_combat_panel(boss_rect, Color(1.0, 0.16, 0.3), 0.62)
		game._draw_hud_bar(boss_rect.position + Vector2(14 * sm, 11 * sm), boss_rect.size.x - 28.0 * sm, 8.0 * sm, game.boss_hp / game.boss_hp_max, Color(1.0, 0.16, 0.28))
		if game._boss_execute_threshold() > 0.0:
			game._draw_collector_threshold(boss_rect.position + Vector2(14 * sm, 11 * sm), boss_rect.size.x - 28.0 * sm, game._boss_execute_threshold(), game.boss_hp / game.boss_hp_max, 8.0 * sm)
		if game.current_phase == 1 and game.boss_hp / max(1.0, game.boss_hp_max) < game.BOSS1_REWIND_THRESHOLD and game.boss1_rewind_cooldown > 0.0:
			var chrono_text = "CRONO %.0fs" % ceil(game.boss1_rewind_cooldown)
			game.draw_string(game.font, boss_rect.position + Vector2(boss_rect.size.x - 94.0 * sm, 28.0 * sm), chrono_text, HORIZONTAL_ALIGNMENT_LEFT, 82.0 * sm, int(11 * sm), Color(0.48, 0.94, 1.0, 0.92))
		if game.current_phase == 3:
			var faith_rect = Rect2(boss_rect.position + Vector2(64 * sm, 34 * sm), Vector2(252 * sm, 24 * sm))
			game._draw_combat_panel(faith_rect, Color(0.62, 0.94, 0.18), 0.48)
			game._draw_hud_bar(faith_rect.position + Vector2(54 * sm, 8 * sm), 184.0 * sm, 7.0 * sm, game.boss3_faith / 100.0, Color(0.66, 1.0, 0.22))
			game.draw_string(game.font, faith_rect.position + Vector2(8 * sm, 17 * sm), "FE %d" % int(game.boss3_faith), HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * sm), Color(0.86, 1.0, 0.58))
			if game.boss3_ritual_timer > 0.0:
				game._draw_centered("RITUAL %.1fs  %d/2" % [game.boss3_ritual_timer, game.boss3_ritual_destroyed], Vector2(viewport.x * 0.5, 112 * sm), int(20 * sm), Color(1.0, 0.42, 0.18))
	if game.is_multiplayer and game.online_connected:
		var ping_text = "PING %sms" % (str(game.net_ping_ms) if game.net_ping_ms >= 0 else "--")
		if game.net_remote_ping_ms >= 0:
			ping_text += "  PAR %dms" % game.net_remote_ping_ms
		if game._is_world_replica():
			ping_text += "  JIT %.0fms" % game.net_world_jitter_ms
		game.draw_string(game.font, Vector2(viewport.x * 0.5 - 118.0 * sm, 28.0 * sm), ping_text, HORIZONTAL_ALIGNMENT_CENTER, 236.0 * sm, int(12 * sm), Color(0.72, 0.96, 1.0, 0.86))
	game._draw_card_mechanic_huds(viewport, left_rect)
	game._draw_ancorada_hud(viewport, left_rect)
	game._draw_acorrentada_hud(viewport, left_rect)
	game._draw_bombastica_hud(viewport, left_rect)
	game._draw_necronada_hud(viewport, left_rect)
	game._draw_aura_hud(viewport, left_rect)
	game._draw_revive_heal_penalty_hud(viewport, left_rect)
	game._draw_lacerante_coagulum_hud(viewport)
	game._draw_contractual_order_hud(viewport)
	game._draw_unlock_notifications(viewport)


static func _draw_revive_heal_penalty_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.revive_heal_penalty_timer <= 0.0:
		return
	var width: float = min(318.0, max(220.0, viewport.x * 0.35))
	var rect = Rect2(anchor.position + Vector2(0.0, anchor.size.y + 88.0), Vector2(width, 30.0))
	var accent = Color(1.0, 0.26, 0.36, 0.92)
	game.draw_rect(rect, Color(0.04, 0.02, 0.025, 0.72), true)
	game.draw_rect(rect, accent, false, 1.5)
	game.draw_string(game.font, rect.position + Vector2(10.0, 20.0), "SACRIFICIO: CURAS -50%%  %.0fs" % ceil(game.revive_heal_penalty_timer), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, game._readable_text_size(11), accent)


static func _draw_contractual_order_hud(game: Node2D, viewport: Vector2) -> void :
	if not game.contractual_order.is_empty():
		var age = float(game.contractual_order.get("real_age", game.contractual_order.get("age", 0.0)))
		var goal: int = max(1, int(game.contractual_order.get("goal", 1)))
		var progress: int = clampi(int(game.contractual_order.get("progress", 0)), 0, goal)
		var time_left = float(game.contractual_order.get("time_left", 0.0))
		if age < game.CONTRACT_ORDER_EXECUTION_START_TIME:
			var panel_size = Vector2(min(560.0, viewport.x * 0.74), 246.0)
			var center = viewport * 0.5
			var shrink = 1.0
			if age < game.CONTRACT_ORDER_SLOW_IN_TIME:
				shrink = lerpf(0.78, 1.0, clampf(age / game.CONTRACT_ORDER_SLOW_IN_TIME, 0.0, 1.0))
			elif age >= game.CONTRACT_ORDER_READ_END_TIME:
				shrink = lerpf(1.0, 0.58, clampf((age - game.CONTRACT_ORDER_READ_END_TIME) / game.CONTRACT_ORDER_SLOW_OUT_TIME, 0.0, 1.0))
			var reveal_rect = Rect2(center - panel_size * shrink * 0.5, panel_size * shrink)
			var read_left = maxf(0.0, game.CONTRACT_ORDER_READ_END_TIME - maxf(age, game.CONTRACT_ORDER_SLOW_IN_TIME))
			var phase_label = "DESACELERANDO O MUNDO" if age < game.CONTRACT_ORDER_SLOW_IN_TIME else ("LEITURA %.0fs" % ceil(read_left) if age < game.CONTRACT_ORDER_READ_END_TIME else "PROTOCOLANDO ORDEM")
			game._draw_judicial_order_paper(reveal_rect, String(game.contractual_order.get("label", "")), String(game.contractual_order.get("desc", "")), "%d/%d" % [progress, goal], phase_label, false)
		else:
			var compact_rect = Rect2(18.0, 238.0, min(330.0, viewport.x * 0.36), 104.0)
			game._draw_judicial_order_paper(compact_rect, String(game.contractual_order.get("label", "")), "", "%d/%d" % [progress, goal], "%.0fs" % ceil(time_left), true)
			var ratio = float(progress) / float(goal)
			game._draw_hud_bar(compact_rect.position + Vector2(18, 76), compact_rect.size.x - 36.0, 8.0, ratio, Color(0.54, 0.12, 0.04))
	var y = 334.0
	for key in game.contractual_order_rewards.keys():
		game._draw_contractual_status_line(Vector2(18.0, y), "BENCAO %s %.0fs" % [String(key).to_upper(), ceil(float(game.contractual_order_rewards[key]))], Color(0.38, 1.0, 0.58))
		y += 28.0
	for key in game.contractual_order_penalties.keys():
		game._draw_contractual_status_line(Vector2(18.0, y), "CONFISCO %s %.0fs" % [String(key).to_upper(), ceil(float(game.contractual_order_penalties[key]))], Color(1.0, 0.3, 0.18))
		y += 28.0


static func _draw_spectator_hud(game: Node2D, viewport: Vector2) -> void :
	var sm = 1.25 if game.is_gamepad_active and not game._is_portrait(viewport) else 1.0
	var panel_size = Vector2(minf(440.0 * sm, viewport.x - 48.0), 54.0 * sm)
	var panel = Rect2(Vector2((viewport.x - panel_size.x) * 0.5, 18.0 * sm), panel_size)
	game._draw_combat_panel(panel, Color(0.36, 0.86, 1.0), 0.42)
	game._draw_centered("ESPECTADOR", panel.position + Vector2(panel.size.x * 0.5, 22.0 * sm), int(16 * sm), Color(0.78, 1.0, 1.0))
	var ping_text = "PING %sms" % (str(game.net_ping_ms) if game.net_ping_ms >= 0 else "--")
	if game.net_remote_ping_ms >= 0:
		ping_text += "  PAR %dms" % game.net_remote_ping_ms
	if game._is_world_replica():
		ping_text += "  JIT %.0fms" % game.net_world_jitter_ms
	game.draw_string(game.font, panel.position + Vector2(14.0 * sm, 43.0 * sm), ping_text, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 28.0 * sm, int(12 * sm), Color(0.72, 0.96, 1.0, 0.88))


static func _draw_lacerante_coagulum_hud(game: Node2D, viewport: Vector2) -> void :
	if game.manifestation_key != "lacerante":
		return
	var hud_scale = game.hud_coagulum_scale
	var center_y = viewport.y - (42.0 if not game._is_portrait(viewport) else 58.0)
	var pulse = clamp(game.lacerante_coagulum_pulse, 0.0, 1.0)
	var orb_radius = 13.0 + pulse * 4.0 + sin(game.time_alive * 4.0) * 1.2
	var count_text = "(+%d)" % game.lacerante_coagula
	var count_width = game.font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var group_width = orb_radius * 2.0 + 10.0 + count_width
	var center = game._coagulum_hud_center(viewport, group_width, orb_radius, center_y)
	game.draw_set_transform(center * (1.0 - hud_scale), 0.0, Vector2.ONE * hud_scale)
	game.draw_circle(center, orb_radius + 7.0, Color(0.2, 0.0, 0.03, 0.64))
	game.draw_circle(center, orb_radius + 2.0, Color(0.72, 0.01, 0.1, 0.34 + pulse * 0.24))
	game.draw_circle(center, orb_radius, Color(0.94, 0.04, 0.15, 0.92))
	game.draw_circle(center - Vector2(4.0, 4.0), orb_radius * 0.34, Color(1.0, 0.7, 0.72, 0.82))
	game.draw_arc(center, orb_radius + 3.0, - game.time_alive * 1.8, TAU - game.time_alive * 1.8, 32, Color(1.0, 0.28, 0.36, 0.78), 1.8)
	game.draw_string(game.font, center + Vector2(orb_radius + 10.0, 6.0), count_text, HORIZONTAL_ALIGNMENT_LEFT, count_width, 16, Color(1.0, 0.88, 0.88))
	var label = "COAGULO TEMPORAL"
	var label_width = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	game.draw_string(game.font, Vector2(viewport.x * 0.5 - label_width * 0.5, center.y + 27.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_width, 9, Color(1.0, 0.46, 0.52, 0.78))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_ancorada_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.manifestation_key != "ancorada":
		return
	var width: float = minf(224.0, viewport.x * 0.46)
	var origin: Vector2 = game._cards_panel_pos(viewport, anchor) + Vector2(0.0, 54.0)
	var rect: Rect2 = Rect2(origin, Vector2(width, 52.0))
	var hud_color: Color = Color(0.28, 1.0, 0.36)
	if game.lastro_stacks == 5:
		hud_color = Color(0.85, 1.0, 0.88)
	game._draw_combat_panel(rect, hud_color, 0.58)

	var title_text: String = "LASTRO"
	if game.lastro_stacks == 5:
		title_text = "CONTRAPESO TOTAL"
	game.draw_string(game.font, rect.position + Vector2(10, 17), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, hud_color)
	game.draw_string(game.font, rect.position + Vector2(width - 64, 17), "%d/5" % game.lastro_stacks, HORIZONTAL_ALIGNMENT_RIGHT, 56, 12, Color.WHITE)

	var module_width: float = (width - 24.0 - 16.0) / 5.0
	var start_x: float = rect.position.x + 12.0
	var y_pos: float = rect.position.y + 26.0

	for m in range(5):
		var m_x: float = start_x + float(m) * (module_width + 4.0)
		var m_rect: Rect2 = Rect2(m_x, y_pos, module_width, 18.0)
		var is_stack_active: bool = m < game.lastro_stacks
		var is_current_stack: bool = m == game.lastro_stacks

		game.draw_rect(m_rect, Color(0.04, 0.08, 0.05, 0.85), true)
		game.draw_rect(m_rect, Color(0.12, 0.32, 0.16, 0.7), false, 1.0)

		var sub_w: float = (module_width - 5.0) / 4.0
		for sub in range(4):
			var sub_x: float = m_x + 1.0 + float(sub) * (sub_w + 1.0)
			var sub_rect: Rect2 = Rect2(sub_x, y_pos + 2.0, sub_w, 14.0)
			var point_filled: bool = false
			if is_stack_active:
				point_filled = true
			elif is_current_stack and sub < game.lastro_points:
				point_filled = true

			if point_filled:
				var col: Color
				match m:
					0: col = Color(0.2, 0.65, 0.3, 0.9)
					1: col = Color(0.25, 0.85, 0.35, 0.92)
					2: col = Color(0.3, 0.95, 0.4, 0.95)
					3: col = Color(0.35, 1.0, 0.5, 0.98)
					4: col = Color(0.85, 1.0, 0.88, 1.0)
					_: col = Color(0.3, 0.95, 0.4, 0.95)
				game.draw_rect(sub_rect, col, true)


static func _draw_acorrentada_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.manifestation_key != "acorrentada":
		return
	var width = min(224.0, viewport.x * 0.46)
	var origin = game._cards_panel_pos(viewport, anchor) + Vector2(0.0, 54.0)
	var rect = Rect2(origin, Vector2(width, 48.0))
	game._draw_combat_panel(rect, game._acorrentada_color_hot(), 0.6)
	var ratio = clampf(game.acorrentada_tension / 100.0, 0.0, 1.0)
	game.draw_string(game.font, rect.position + Vector2(10, 17), "TENSAO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, game._acorrentada_color_hot())
	game.draw_string(game.font, rect.position + Vector2(width - 64, 17), "%d%%" % int(round(game.acorrentada_tension)), HORIZONTAL_ALIGNMENT_RIGHT, 56, 12, Color.WHITE)
	game.draw_rect(Rect2(rect.position + Vector2(12, 29), Vector2(width - 24, 7)), Color(0.05, 0.05, 0.06, 0.84), true)
	game.draw_rect(Rect2(rect.position + Vector2(12, 29), Vector2((width - 24) * ratio, 7)), game._acorrentada_color_hot(), true)
	for i in range(3):
		var p = rect.position + Vector2(18 + i * 22, 42)
		var filled: bool = i < game.acorrentada_combo_step
		game.draw_arc(p, 6.0, 0.0, TAU, 16, Color(0.18, 0.86, 1.0, 0.86 if filled else 0.24), 2.0)
	if game.acorrentada_tension >= 100.0:
		game._draw_centered("SOBRETENSAO", rect.get_center() + Vector2(0, -1), 11, Color(1.0, 0.96, 0.88))


static func _draw_bombastica_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.manifestation_key != "bombastica":
		return
	var width = min(224.0, viewport.x * 0.46)
	var origin = game._cards_panel_pos(viewport, anchor) + Vector2(0.0, 54.0)
	var rect = Rect2(origin, Vector2(width, 58.0))
	game._draw_combat_panel(rect, Color(1.0, 0.48, 0.12), 0.58)
	var ready_charges = game._bombastica_ready_charges()
	game.draw_string(game.font, rect.position + Vector2(10, 17), "ESTOPIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.7, 0.28))
	game.draw_string(game.font, rect.position + Vector2(width - 94, 17), "%d/%d Q" % [ready_charges, game.BOMBASTICA_Q_CHARGES], HORIZONTAL_ALIGNMENT_RIGHT, 86, 12, Color.WHITE)
	for i in range(game.BOMBASTICA_Q_CHARGES):
		var p = rect.position + Vector2(17 + i * 24, 34)
		var timer = float(game.bombastica_q_recharges[i])
		var charge_ready = timer <= 0.0
		game.draw_circle(p, 7.0, Color(1.0, 0.54, 0.1, 0.94) if charge_ready else Color(0.12, 0.08, 0.04, 0.84))
		game.draw_arc(p, 9.5, 0, TAU, 18, Color(1.0, 0.86, 0.32, 0.76), 1.4)
		if not charge_ready:
			var ratio = 1.0 - clampf(timer / game.BOMBASTICA_Q_RECHARGE, 0.0, 1.0)
			game.draw_arc(p, 11.5, - PI * 0.5, - PI * 0.5 + TAU * ratio, 18, Color(0.18, 0.88, 1.0, 0.86), 2.0)
	var powder_targets = game.bombastica_powder_marks.size()
	game.draw_string(game.font, rect.position + Vector2(92, 36), "BOMBAS %d" % game.bombastica_bombs.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.88, 0.54))
	game.draw_string(game.font, rect.position + Vector2(92, 51), "POLVORA %d" % powder_targets, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.78, 1.0, 1.0))


static func _draw_necronada_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.manifestation_key != "necronada":
		return
	var width = minf(262.0, viewport.x * 0.48)
	var origin = game._cards_panel_pos(viewport, anchor) + Vector2(0.0, 54.0)
	var rect = Rect2(origin, Vector2(width, 64.0))
	game._draw_combat_panel(rect, game._necronada_color(), 0.58)
	game.draw_string(game.font, rect.position + Vector2(10, 18), "JARDIM OSSUARIO", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, game._readable_text_size(11), game._necronada_accent())
	var start = rect.position + Vector2(18.0, 42.0)
	for i in range(game.NECRONADA_ROSE_MAX):
		var rose_pos = start + Vector2(i * 22.0, 0.0)
		var filled = i < game.necronada_vestiges.size()
		game.draw_circle(rose_pos + Vector2(0, 6), 7.0, Color(0.03, 0.04, 0.08, 0.78))
		if filled:
			game.draw_line(rose_pos + Vector2(0, 6), rose_pos + Vector2(0, -7), Color(0.22, 0.62, 0.32, 0.95), 1.7)
			for p_i in range(5):
				game.draw_circle(rose_pos + Vector2.from_angle(float(p_i) * TAU / 5.0) * 3.4 + Vector2(0, -9), 2.9, Color(0.34, 0.82, 1.0, 0.94))
		else:
			game.draw_arc(rose_pos, 7.0, 0.0, TAU, 18, Color(0.25, 0.32, 0.42, 0.58), 1.0)
	var progress = clampf(float(game.necronada_horde_progress) / float(game.NECRONADA_ULTIMATE_REQUIRED_REVIVES), 0.0, 1.0)
	var bar = Rect2(rect.position + Vector2(136.0, 34.0), Vector2(maxf(52.0, rect.size.x - 150.0), 8.0))
	game.draw_rect(bar, Color(0.04, 0.05, 0.09, 0.82), true)
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color(0.66, 0.34, 1.0, 0.92), true)
	game.draw_rect(bar, game._necronada_accent(), false, 1.0)
	game.draw_string(game.font, rect.position + Vector2(132.0, 58.0), "ONDA %d/%d" % [game.necronada_horde_progress, game.NECRONADA_ULTIMATE_REQUIRED_REVIVES], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 142.0, game._readable_text_size(10), Color(0.92, 0.96, 1.0))


static func _draw_card_mechanic_huds(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	var width = min(224.0, viewport.x * 0.46)
	var origin = game._cards_panel_pos(viewport, anchor)
	game.draw_set_transform(origin * (1.0 - game.hud_cards_panel_scale), 0.0, Vector2.ONE * game.hud_cards_panel_scale)
	var y = origin.y
	if int(game.cards_bought.get("Mercenaria", 0)) > 0:
		var pulse = clamp(game.mercenary_hud_pulse, 0.0, 1.0)
		var rect = Rect2(origin.x, y, width, 46.0)
		game._draw_combat_panel(rect, Color(1.0, 0.58 + pulse * 0.22, 0.1), 0.62)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "CONTRATO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.8, 0.3))
		game.draw_string(game.font, rect.position + Vector2(width - 74, 17), "+%d" % game.mercenary_bonus_points, HORIZONTAL_ALIGNMENT_RIGHT, 64, 13, Color.WHITE)
		var progress = game.combo_kills % 5
		for i in range(5):
			var pip_pos = rect.position + Vector2(16 + i * 24, 32)
			var filled = i < progress
			game.draw_circle(pip_pos, 6.0, Color(1.0, 0.65, 0.12, 0.95) if filled else Color(0.22, 0.16, 0.08, 0.86))
			game.draw_arc(pip_pos, 7.5, 0, TAU, 18, Color(1.0, 0.82, 0.34, 0.72), 1.2)
		game.draw_string(game.font, rect.position + Vector2(138, 37), "%d ABATES" % game.combo_kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.86, 0.72))
		y += 52.0
	if game.execute_threshold > 0.0:
		var pulse = clamp(game.collector_hud_pulse, 0.0, 1.0)
		var rect = Rect2(origin.x, y, width, 42.0)
		game._draw_combat_panel(rect, Color(1.0, 0.05, 0.2), 0.62)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "COLETORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.32 + pulse * 0.28, 0.38))
		game.draw_string(game.font, rect.position + Vector2(10, 34), "COMUM %.1f%%" % (game.execute_threshold * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(116, 34), "BOSS %.1f%%" % (game._boss_execute_threshold() * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.76, 0.4))
		y += 48.0
	if game._support_card_count(game.CARD_TREGUA_ID) > 0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.38, 1.0, 0.72), 0.52)
		var ratio: float = 1.0 if game.tregua_regenerativa_active else clamp(game.tregua_regenerativa_timer / max(0.01, game._tregua_delay()), 0.0, 1.0)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "TREGUA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.52, 1.0, 0.76))
		game.draw_string(game.font, rect.position + Vector2(width - 84, 17), "ATIVA" if game.tregua_regenerativa_active else "%.0f%%" % (ratio * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 76, 11, Color.WHITE)
		game.draw_rect(Rect2(rect.position + Vector2(10, 29), Vector2(width - 20, 5)), Color(0.04, 0.1, 0.08, 0.8), true)
		game.draw_rect(Rect2(rect.position + Vector2(10, 29), Vector2((width - 20) * ratio, 5)), Color(0.38, 1.0, 0.72, 0.9), true)
		y += 44.0
	if game._support_card_count(game.CARD_RESERVA_ID) > 0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.44, 0.92, 1.0), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "RESERVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.58, 0.96, 1.0))
		game.draw_string(game.font, rect.position + Vector2(width - 92, 17), "%.0f HP" % game.reserva_pulso_stored, HORIZONTAL_ALIGNMENT_RIGHT, 84, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "LIBERANDO" if game.reserva_pulso_releasing else "ARMAZENADA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.78, 0.92, 0.96))
		y += 44.0
	if game._support_card_count(game.CARD_ESTASE_ID) > 0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.52, 1.0, 0.86), 0.52)
		var ratio = 1.0 if game.estase_reparadora_active else clampf(game.estase_reparadora_timer / 5.0, 0.0, 1.0)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "ESTASE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.66, 1.0, 0.9))
		game.draw_string(game.font, rect.position + Vector2(width - 84, 17), "ATIVA" if game.estase_reparadora_active else "%.0f%%" % (ratio * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 76, 11, Color.WHITE)
		game.draw_rect(Rect2(rect.position + Vector2(10, 29), Vector2(width - 20, 5)), Color(0.04, 0.1, 0.09, 0.8), true)
		game.draw_rect(Rect2(rect.position + Vector2(10, 29), Vector2((width - 20) * ratio, 5)), Color(0.52, 1.0, 0.86, 0.9), true)
		y += 44.0
	if game._rare_card_count(game.CARD_EGIDE_ID) > 0 and game.egide_hemofaga_shield > 0.0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(1.0, 0.72, 0.22), 0.56)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "EGIDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.82, 0.36))
		game.draw_string(game.font, rect.position + Vector2(width - 84, 17), "%.0f HP" % game.egide_hemofaga_shield, HORIZONTAL_ALIGNMENT_RIGHT, 76, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "INTEGRA" if game.egide_hemofaga_full_timer > 0.0 else "DECAINDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.96, 0.88, 0.7))
		y += 44.0
	if game._support_card_count(game.CARD_CASULO_ID) > 0 and (game.casulo_reativo_timer > 0.0 or game.casulo_reativo_cooldown > 0.0):
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.54, 1.0, 0.86), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "CASULO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.68, 1.0, 0.9))
		var casulo_text = "%.1fs" % game.casulo_reativo_timer if game.casulo_reativo_timer > 0.0 else "CD %.0f" % game.casulo_reativo_cooldown
		game.draw_string(game.font, rect.position + Vector2(width - 86, 17), casulo_text, HORIZONTAL_ALIGNMENT_RIGHT, 78, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "-%.0f%% DANO" % (game._casulo_reduction() * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.96, 0.92))
		y += 44.0
	if game._support_card_count(game.CARD_PASSAGEM_ID) > 0 and game.passagem_intangivel_timer > 0.0:
		var rect = Rect2(origin.x, y, width, 36.0)
		game._draw_combat_panel(rect, Color(0.72, 0.9, 1.0), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "PASSAGEM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.78, 0.94, 1.0))
		game.draw_string(game.font, rect.position + Vector2(width - 72, 17), "%.1fs" % game.passagem_intangivel_timer, HORIZONTAL_ALIGNMENT_RIGHT, 64, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 31), "SEM CONTATO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.92, 0.98))
		y += 42.0
	if not game.ancora_vital_state.is_empty():
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.34, 1.0, 0.66), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "ANCORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.46, 1.0, 0.72))
		game.draw_string(game.font, rect.position + Vector2(width - 82, 17), "%.0f HP" % float(game.ancora_vital_state.get("remaining", 0.0)), HORIZONTAL_ALIGNMENT_RIGHT, 74, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "%.1fs" % float(game.ancora_vital_state.get("life", 0.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.96, 0.86))
		y += 44.0
	if game._mandamento_count() > 0:
		var rect = Rect2(origin.x, y, width, 42.0)
		var pulse = clamp(game.mandamento_break_flash, 0.0, 1.0)
		game._draw_combat_panel(rect, Color(1.0, 0.78 + pulse * 0.12, 0.2), 0.6)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "MANDAMENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.86, 0.34))
		for i in range(3):
			var pip_pos = rect.position + Vector2(width - 58 + i * 17, 16)
			var filled = i < game.mandamento_skill_uses
			game.draw_circle(pip_pos, 5.3, Color(1.0, 0.82, 0.22, 0.96) if filled else Color(0.18, 0.14, 0.05, 0.82))
			game.draw_arc(pip_pos, 6.8, 0, TAU, 16, Color(1.0, 0.92, 0.54, 0.68), 1.0)
		game.draw_string(game.font, rect.position + Vector2(10, 34), "+%.0f%% TERCEIRA" % (game._mandamento_power_bonus() * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		y += 48.0
	if game._new_common_card_count(game.CARD_IMPULSO_ID) > 0 and game.impulso_charges > 0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.42, 0.78, 1.0), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "IMPULSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.9, 1.0))
		game.draw_string(game.font, rect.position + Vector2(width - 76, 17), "x%d" % game.impulso_charges, HORIZONTAL_ALIGNMENT_RIGHT, 68, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "+%.0f%% ATK" % (game.impulso_bonus * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.86, 0.42))
		y += 44.0
	if game._new_common_card_count(game.CARD_ZONA_ID) > 0 and (game.zona_charge > 0.0 or game.zona_cooldown > 0.0):
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.44, 1.0, 0.7), 0.52)
		var label = "%.0f%%" % (game.zona_charge * 100.0) if game.zona_cooldown <= 0.0 else "CD %.1f" % game.zona_cooldown
		game.draw_string(game.font, rect.position + Vector2(10, 17), "ZONA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.58, 1.0, 0.78))
		game.draw_string(game.font, rect.position + Vector2(width - 88, 17), label, HORIZONTAL_ALIGNMENT_RIGHT, 80, 11, Color.WHITE)
		game.draw_rect(Rect2(rect.position + Vector2(10, 29), Vector2((width - 20) * clampf(game.zona_charge, 0.0, 1.0), 5)), Color(0.44, 1.0, 0.7, 0.92), true)
		y += 44.0
	if game._new_common_card_count(game.CARD_FOLEGO_ID) > 0 and game.folego_charge > 0.0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(1.0, 0.56, 0.22), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "FOLEGO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.74, 0.34))
		game.draw_string(game.font, rect.position + Vector2(width - 76, 17), "%.0f%%" % (game.folego_charge * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 68, 11, Color.WHITE)
		y += 44.0
	if game._new_common_card_count(game.CARD_MARGEM_ID) > 0 and (game.margem_window_timer > 0.0 or game.margem_debt > 0.0):
		var rect = Rect2(origin.x, y, width, 42.0)
		game._draw_combat_panel(rect, Color(1.0, 0.36, 0.46), 0.54)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "MARGEM", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.54, 0.62))
		var label = "%.0f HP" % game.margem_debt if game.margem_debt > 0.0 else "%.1fs" % game.margem_window_timer
		game.draw_string(game.font, rect.position + Vector2(width - 92, 17), label, HORIZONTAL_ALIGNMENT_RIGHT, 84, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 34), "DIVIDA" if game.margem_debt > 0.0 else "JANELA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.96, 0.82, 0.86))
		y += 48.0
	if game._new_common_card_count(game.CARD_RESSONANCIA_ID) > 0 and ( not game.ressonancia_symbols.is_empty() or game.ressonancia_ready_timer > 0.0):
		var rect = Rect2(origin.x, y, width, 40.0)
		game._draw_combat_panel(rect, Color(0.58, 1.0, 0.96), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "RESSONANCIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.66, 1.0, 0.98))
		var label = "PRONTA" if game.ressonancia_ready_timer > 0.0 else "%d/4" % game.ressonancia_symbols.size()
		game.draw_string(game.font, rect.position + Vector2(width - 86, 17), label, HORIZONTAL_ALIGNMENT_RIGHT, 78, 11, Color.WHITE)
		y += 46.0
	if game._rare_card_count("carta_zero") > 0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.88, 0.96, 1.0), 0.56)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "CARTA ZERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.98, 1.0))
		game.draw_string(game.font, rect.position + Vector2(width - 84, 17), "x%.2f" % game._carta_zero_multiplier(), HORIZONTAL_ALIGNMENT_RIGHT, 76, 12, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "COMUNS NUMERICAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.76, 0.88, 0.94))
		y += 44.0
	if game._rare_card_count("necrocronismo") > 0:
		var rect = Rect2(origin.x, y, width, 42.0)
		game._draw_combat_panel(rect, Color(0.46, 1.0, 0.94), 0.56)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "NECROCRONISMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.58, 1.0, 0.96))
		game.draw_string(game.font, rect.position + Vector2(width - 86, 17), "%d ATIVOS" % game.active_necro_specters.size(), HORIZONTAL_ALIGNMENT_RIGHT, 80, 11, Color.WHITE)
		var progress: float = clamp(float(game.necro_kill_counter) / float(max(1, game._necro_kills_required())), 0.0, 1.0)
		game.draw_rect(Rect2(rect.position + Vector2(10, 30), Vector2(width - 20, 5)), Color(0.04, 0.1, 0.12, 0.8), true)
		game.draw_rect(Rect2(rect.position + Vector2(10, 30), Vector2((width - 20) * progress, 5)), Color(0.46, 1.0, 0.94, 0.92), true)
		y += 48.0
	if game._rare_card_count("coracao_antimateria") > 0:
		var rect = Rect2(origin.x, y, width, 42.0)
		var pulse: float = clamp(game.antimatter_flash, 0.0, 1.0)
		game._draw_combat_panel(rect, Color(0.82, 0.28 + pulse * 0.18, 1.0), 0.56)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "ANTIMATERIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.52, 1.0))
		game.draw_string(game.font, rect.position + Vector2(width - 74, 17), "ARMADA" if game.antimatter_armed else "%.0f%%" % (100.0 * game.antimatter_charge / max(1.0, game._antimatter_required_charge())), HORIZONTAL_ALIGNMENT_RIGHT, 68, 11, Color.WHITE)
		var progress: float = 1.0 if game.antimatter_armed else clamp(game.antimatter_charge / max(1.0, game._antimatter_required_charge()), 0.0, 1.0)
		game.draw_rect(Rect2(rect.position + Vector2(10, 30), Vector2(width - 20, 5)), Color(0.08, 0.02, 0.14, 0.82), true)
		game.draw_rect(Rect2(rect.position + Vector2(10, 30), Vector2((width - 20) * progress, 5)), Color(0.82, 0.28, 1.0, 0.94), true)
		y += 48.0
	if game._rare_card_count("cofre_excesso") > 0:
		var rect = Rect2(origin.x, y, width, 38.0)
		var pulse = clamp(game.excess_discharge_flash, 0.0, 1.0)
		game._draw_combat_panel(rect, Color(1.0, 0.68 + pulse * 0.2, 0.16), 0.56)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "COFRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.76, 0.28))
		game.draw_string(game.font, rect.position + Vector2(width - 92, 17), "%.0f DANO" % game.stored_excess, HORIZONTAL_ALIGNMENT_RIGHT, 84, 12, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), String(game.excess_discharge_kind).to_upper() if game.excess_discharge_kind != "" else "AGUARDANDO ELITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.94, 0.84, 0.62))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_aura_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.aura_state.is_empty():
		return
	var name = String(game.aura_state.get("name", "Racional"))
	var color = game._aura_color()
	var rect = Rect2(game._aura_panel_pos(viewport, anchor), Vector2(min(224.0, viewport.x * 0.46), 48.0))
	game.draw_set_transform(rect.position * (1.0 - game.hud_aura_panel_scale), 0.0, Vector2.ONE * game.hud_aura_panel_scale)
	game._draw_combat_panel(rect, color, 0.58)
	var ratio = game._aura_hud_ratio()
	var pulse = 0.5 + sin(game.time_alive * 6.0) * 0.5
	match name:
		"Racional":
			for i in range(7):
				var x = rect.position.x + 14.0 + i * 18.0
				game.draw_line(Vector2(x, rect.end.y - 12), Vector2(x + 10, rect.position.y + 12), Color(color.r, color.g, color.b, 0.85 if float(i) / 7.0 <= ratio else 0.18), 2.0)
		"Impulsiva":
			for i in range(5): game.draw_circle(rect.position + Vector2(18 + i * 22, 32), 6.0 + (pulse * 2.0 if i < int(game.aura_state.get("impulsive_kills", 0)) else 0.0), color if i < int(game.aura_state.get("impulsive_kills", 0)) else Color(color.r, color.g, color.b, 0.18))
		"Devota":
			for i in range(3): game._draw_hex(rect.position + Vector2(22 + i * 30, 30), 10.0, color if i < int(game.aura_state.get("devoted_charges", 0)) else Color(color.r, color.g, color.b, 0.18))
		"Vanguarda":
			for i in range(9):
				var h = 7.0 + sin(game.time_alive * 8.0 + i) * 5.0
				game.draw_line(rect.position + Vector2(14 + i * 13, 38), rect.position + Vector2(14 + i * 13, 38 - h), Color(1.0, 0.34 + i * 0.03, 0.08, 0.82), 3.0)
		"Insana":
			for i in range(5):
				var p = rect.position + Vector2(18 + i * 23, 31 + sin(game.time_alive * 5.0 + i) * 3.0)
				game.draw_circle(p, 7.0, Color(0.26, 1.0, 0.45, 0.72) if i < int(game.aura_state.get("insane_echoes", 0)) else Color(color.r, color.g, color.b, 0.2))
		"Voraz":
			game.draw_arc(rect.position + Vector2(28, 27), 16.0, - PI * 0.82, PI * 0.82, 24, color, 5.0)
			game.draw_line(rect.position + Vector2(52, 32), rect.position + Vector2(52 + ratio * 108.0, 32), Color(1.0, 0.18, 0.08), 7.0)
		"Nula":
			game.draw_circle(rect.position + Vector2(28, 27), 16.0, Color(0.0, 0.02, 0.05, 0.94))
			game.draw_arc(rect.position + Vector2(28, 27), 11.0 + ratio * 5.0, game.time_alive, game.time_alive + TAU * ratio, 32, color, 2.0)
		"Abissal":
			for i in range(4): game.draw_arc(rect.position + Vector2(28, 27), 6.0 + i * 5.0, PI * ratio, TAU, 30, Color(color.r, color.g, color.b, 0.85 - i * 0.14), 2.0)
		"Profetica":
			for i in range(7):
				var p = rect.position + Vector2(18 + i * 17, 31 + sin(i * 1.4) * 7.0)
				game.draw_circle(p, 3.0 + (pulse * 2.0 if float(i) / 7.0 <= ratio else 0.0), color if float(i) / 7.0 <= ratio else Color(color.r, color.g, color.b, 0.18))
		"Sanguinaria":
			for i in range(6):
				var x = rect.position.x + 17 + i * 19
				game.draw_line(Vector2(x - 4, rect.position.y + 36), Vector2(x + 7, rect.position.y + 15), Color(color.r, color.g, color.b, 0.9 if float(i) / 6.0 <= ratio else 0.18), 3.0)
	game.draw_string(game.font, rect.position + Vector2(126, 20), name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 88.0, 12, color)
	game.draw_string(game.font, rect.position + Vector2(126, 38), game._aura_status_text(), HORIZONTAL_ALIGNMENT_LEFT, 88.0, 10, Color.WHITE)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_desktop_hud(game: Node2D, viewport: Vector2) -> void:
	var life_rect = Rect2(18.0, 16.0, 276.0, 76.0)
	var life_alpha: float = game._hud_rect_player_alpha(life_rect, viewport, 84.0)
	game.hud_feedback.health_panel(game, life_rect, life_alpha)
	var right_rect = Rect2(viewport.x - 300.0, 16.0, 220.0, 76.0)
	var right_alpha: float = game._hud_rect_player_alpha(right_rect, viewport, 84.0)
	game.hud_feedback.stats_panel(game, right_rect, right_alpha)

	if game.boss_active and game.boss_hp > 0.0 and not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		var boss_rect = Rect2(game._boss_panel_pos(viewport), Vector2(380.0, 30.0))
		game._draw_scifi_frame(boss_rect, Color(1.0, 0.16, 0.3), 6.0, 0.88)
		game._draw_hud_bar(boss_rect.position + Vector2(14.0, 11.0), boss_rect.size.x - 28.0, 8.0, game.boss_hp / game.boss_hp_max, Color(1.0, 0.16, 0.28))
		if game._boss_execute_threshold() > 0.0:
			game._draw_collector_threshold(boss_rect.position + Vector2(14.0, 11.0), boss_rect.size.x - 28.0, game._boss_execute_threshold(), game.boss_hp / game.boss_hp_max, 8.0)
		if game.current_phase == 1 and game.boss_hp / maxf(1.0, game.boss_hp_max) < game.BOSS1_REWIND_THRESHOLD and game.boss1_rewind_cooldown > 0.0:
			var chrono_text = "CRONO %.0fs" % ceil(game.boss1_rewind_cooldown)
			game.draw_string(game.font, boss_rect.position + Vector2(boss_rect.size.x - 94.0, 28.0), chrono_text, HORIZONTAL_ALIGNMENT_LEFT, 82.0, 11, Color(0.48, 0.94, 1.0, 0.92))

	if game.is_multiplayer and game.online_connected:
		var ping_text = "PING %sms" % (str(game.net_ping_ms) if game.net_ping_ms >= 0 else "--")
		if game.net_remote_ping_ms >= 0:
			ping_text += "  PAR %dms" % game.net_remote_ping_ms
		if game._is_world_replica():
			ping_text += "  JIT %.0fms" % game.net_world_jitter_ms
		game.draw_string(game.font, Vector2(viewport.x * 0.5 - 118.0, 28.0), ping_text, HORIZONTAL_ALIGNMENT_CENTER, 236.0, 12, Color(0.72, 0.96, 1.0, 0.86))

	game._draw_card_mechanic_huds(viewport, life_rect)
	game._draw_ancorada_hud(viewport, life_rect)
	game._draw_acorrentada_hud(viewport, life_rect)
	game._draw_bombastica_hud(viewport, life_rect)
	game._draw_necronada_hud(viewport, life_rect)
	game._draw_aura_hud(viewport, life_rect)
	game._draw_revive_heal_penalty_hud(viewport, life_rect)
	game._draw_lacerante_coagulum_hud(viewport)
	game._draw_contractual_order_hud(viewport)
	game._draw_unlock_notifications(viewport)


static func _draw_desktop_combat_hud(game: Node2D, viewport: Vector2) -> void :
	var icons = []

	var active_eletrica_secondary = game._active_eletrica_secondary()
	var toggle_ultimate_active = (game.manifestation_key == "prismatica" and game.time_alive - game.last_secondary_time < game.SECONDARY_PRISMATICA_DURATION) or (game.manifestation_key == "eletrica" and active_eletrica_secondary)
	var tp_visual_active = game.tp_cooldown_pending and not game.tp_effects.is_empty()
	var dash_label = "VOLTAR" if game.manifestation_key == "retornante" and game.retornante_tp_window > 0.0 else ("ATIVO" if tp_visual_active else "TP")

	var q_charges = 0
	if game.manifestation_key == "bombastica":
		q_charges = game.bombastica_bombs.size()

	var tp_charges = 0
	if game.manifestation_key == "lacerante":
		tp_charges = game.lacerante_tp_charges

	var ult_color = Color(1.0, 0.78, 0.2, 0.95)
	var ult_label = "ULT"
	var ult_sub = "ULTIMATE"

	if not active_eletrica_secondary.is_empty():
		var tesla_t = float(active_eletrica_secondary.get("active_time", 0.0))
		ult_label = "CANCELAR"
		if tesla_t >= 15.0:
			ult_sub = "SOBRECARGA"
			ult_color = Color(1.0, 0.0, 0.15, 0.98)
		elif tesla_t >= 13.0:
			ult_sub = "ALERTA!"
			ult_color = Color(1.0, 0.4, 0.0, 0.95)
		elif tesla_t >= 10.0:
			ult_sub = "INSTAVEL"
			ult_color = Color(1.0, 0.85, 0.0, 0.9)
		else:
			ult_sub = "ATIVO"
			ult_color = Color(0.0, 0.8, 1.0, 0.9)
	elif toggle_ultimate_active:
		ult_label = "CANCELAR"
		ult_sub = "CANCELAR"
		ult_color = Color(1.0, 0.02, 0.06, 0.98)

	icons.append({"id": "attack", "label": "ATK", "sub": "Ataque", "charges": 0, "bind": game._compact_key_binding_name("attack") if game._uses_desktop_ui() else "", "color": Color(1.0, 0.24, 0.28), "cd_elapsed": 100.0, "cd_max": 1.0, "icon_type": "sword"})
	icons.append({"id": "skill", "label": "HAB 1", "sub": "Hab 1", "charges": q_charges, "bind": game._compact_key_binding_name("skill") if game._uses_desktop_ui() else game._compact_binding_name("skill"), "color": Color(0.2, 0.75, 1.0), "cd_elapsed": game.time_alive - game.last_skill_time, "cd_max": game._skill_cooldown(), "icon_type": "star"})
	icons.append({"id": "secondary", "label": ult_label, "sub": ult_sub, "active": toggle_ultimate_active, "charges": 0, "bind": game._compact_key_binding_name("secondary") if game._uses_desktop_ui() else "", "color": ult_color, "cd_elapsed": game.time_alive - game.last_secondary_time, "cd_max": game._secondary_skill_cooldown(), "icon_type": "trident"})
	icons.append({"id": "dash", "label": dash_label, "active": dash_label != "TP", "sub": "Teleporte" if dash_label == "TP" else "", "charges": tp_charges, "bind": game._compact_key_binding_name("dash") if game._uses_desktop_ui() else "", "color": Color(0.2, 0.9, 1.0), "cd_elapsed": game.time_alive - game.last_dash_time, "cd_max": game._current_dash_cooldown(), "icon_type": "portal"})

	if game.manifestation_key == "lacerante":
		icons.append({"id": "lacerante_empower", "label": "REFORÇO" if game.lacerante_empowered_ready else "+", "sub": "Reforço", "charges": 0, "bind": game._compact_key_binding_name("lacerante_empower") if game._uses_desktop_ui() else "", "color": Color(0.92, 0.03, 0.12, 0.92 if game.lacerante_empowered_ready else 0.68), "cd_elapsed": game.time_alive - game.last_lacerante_empower_time, "cd_max": game.LACERANTE_EMPOWER_COOLDOWN, "icon_type": "star"})
	if game.manifestation_key == "eclipsada":
		var form_color = game._eclipsada_color()
		icons.append({"id": "lacerante_empower", "label": game._eclipsada_form_label(), "sub": "Forma", "charges": 0, "bind": game._compact_key_binding_name("lacerante_empower") if game._uses_desktop_ui() else "", "color": Color(form_color.r, form_color.g, form_color.b, 0.86), "cd_elapsed": 1.0, "cd_max": 1.0, "icon_type": "star"})
	if game.manifestation_key == "necronada":
		var necr_cd_elapsed = game.NECRONADA_EMPOWER_COOLDOWN if game.necronada_empowered_ready else game.NECRONADA_EMPOWER_COOLDOWN - maxf(0.0, game.necronada_empower_cooldown_until - game.time_alive)
		icons.append({"id": "lacerante_empower", "label": "PO" if game.necronada_empowered_ready else "+", "sub": "Poeira", "charges": 0, "bind": game._compact_key_binding_name("lacerante_empower") if game._uses_desktop_ui() else "", "color": Color(0.52, 0.34, 0.92, 0.94 if game.necronada_empowered_ready else 0.7), "cd_elapsed": necr_cd_elapsed, "cd_max": game.NECRONADA_EMPOWER_COOLDOWN, "icon_type": "star"})
	if game.manifestation_key == "bombastica":
		var det_ready = 1.0 if game.bombastica_bombs.size() > 0 else 0.0
		icons.append({"id": "bombastica_detonator", "label": "DET", "sub": "Detonar", "charges": game.bombastica_bombs.size(), "bind": game._compact_key_binding_name("lacerante_empower") if game._uses_desktop_ui() else "", "color": Color(1.0, 0.48, 0.12, 0.88 if det_ready > 0.0 else 0.44), "cd_elapsed": det_ready, "cd_max": 1.0, "icon_type": "star"})

	var desktop_scale: float = game._sanitize_desktop_hud_scale(game.desktop_hud_scale)
	var card_w = 92.0
	var card_h = 96.0
	var gap = 12.0 * desktop_scale
	var visual_card_w: float = card_w * desktop_scale
	var visual_card_h: float = card_h * desktop_scale
	var total_w = visual_card_w * float(icons.size()) + gap * float(icons.size() - 1)
	var start_x = viewport.x * 0.5 - total_w * 0.5
	var start_y = viewport.y - visual_card_h - 24.0

	for i in range(icons.size()):
		var card_rect = Rect2(start_x + i * (visual_card_w + gap), start_y, card_w, card_h)
		game.draw_set_transform(card_rect.position * (1.0 - desktop_scale), 0.0, Vector2.ONE * desktop_scale)
		game.hud_feedback.ability(game, card_rect, icons[i])
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	game._draw_desktop_fps_hud(viewport)


static func _draw_touch_controls(game: Node2D, viewport: Vector2) -> void :
	if game._uses_desktop_ui():
		game._draw_desktop_combat_hud(viewport)
		game._draw_desktop_session_buttons(viewport)
		if game._ability_cancel_active():
			game._draw_ability_cancel_button(viewport)
		game._draw_player_dance_emote(game._camera(viewport))
		return
	if game.is_gamepad_active:
		game._draw_desktop_combat_hud(viewport)
	if game.is_dead or game.player_hp <= 0.0 or game.online_local_spectator:
		game.buttons.erase("revival_mobile")
		game._draw_player_dance_emote(game._camera(viewport))
		return
	var joy = game._active_joy_center(viewport)
	var joy_r = 76.0 * game._joy_scale()
	var joy_alpha: float = game._hud_rect_player_alpha(Rect2(joy - Vector2(joy_r, joy_r), Vector2(joy_r * 2.0, joy_r * 2.0)), viewport)
	if not game.is_gamepad_active:
		game._draw_virtual_stick(joy, joy_r, joy_alpha)

	var atk_c = game.buttons["attack"].position + game.buttons["attack"].size * 0.5
	var atk_r: float = minf(54.0 * game._attack_scale(), float(game.buttons["attack"].size.x) * 0.5)
	var atk_alpha: float = game._hud_rect_player_alpha(Rect2(atk_c - Vector2(atk_r, atk_r), Vector2(atk_r * 2.0, atk_r * 2.0)), viewport)
	var revival_method: String = game._local_revival_altar_method()
	if not game.is_gamepad_active:
		if revival_method != "":
			var revive_color: Color = Color(1.0, 0.18, 0.26, 0.82 * atk_alpha) if revival_method == game.REVIVE_PAY_LIFE else Color(0.08, 0.62, 1.0, 0.82 * atk_alpha)
			game.buttons["revival_mobile"] = game.buttons["attack"]
			game._draw_button(atk_c, atk_r, "REVIVE", revive_color)
			game._draw_centered("2 TOQUES", atk_c + Vector2(0, atk_r + 18.0), 10, Color(0.94, 1.0, 0.98, atk_alpha))
		else:
			game.buttons.erase("revival_mobile")
			game._draw_button(atk_c, atk_r, "ATK", Color(1.0, 0.24, 0.26, 0.7 * atk_alpha))
	if game.attack_holding and not game.attack_dragging:
		var hold_ratio = clamp(game.attack_hold_timer / game.ATTACK_LOCK_HOLD_TIME, 0.0, 1.0)
		game.draw_arc(atk_c, atk_r + 7.0, - PI * 0.5, - PI * 0.5 + TAU * hold_ratio, 48, Color(1.0, 0.86, 0.24, 0.96), 4.0)
		if game.attack_lock_selecting:
			game._draw_attack_lock_preview(viewport)

	var skill_c = game.buttons["skill"].position + game.buttons["skill"].size * 0.5
	var skill_r: float = minf(46.0 * game._skill_scale(), float(game.buttons["skill"].size.x) * 0.5)
	var skill_alpha: float = game._hud_rect_player_alpha(Rect2(skill_c - Vector2(skill_r, skill_r), Vector2(skill_r * 2.0, skill_r * 2.0)), viewport)
	if not game.is_gamepad_active:
		game._draw_button(skill_c, skill_r, "HAB1", Color(game._manifestation_color().r, game._manifestation_color().g, game._manifestation_color().b, 0.7 * skill_alpha))
	if game.manifestation_key == "bombastica" and game.bombastica_bombs.size() > 0:
		var q_badge_center: Vector2 = skill_c + Vector2(skill_r * 0.66, - skill_r * 0.68)
		game.draw_circle(q_badge_center, 14.0, Color(0.16, 0.0, 0.025, 0.96))
		game.draw_arc(q_badge_center, 14.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.18, 0.98), 2.0)
		game._draw_centered("x%d" % game.bombastica_bombs.size(), q_badge_center + Vector2(0, 1), 12, Color.WHITE)
	var secondary_c = game.buttons["secondary"].position + game.buttons["secondary"].size * 0.5
	var secondary_r: float = minf(43.0 * game._secondary_scale(), float(game.buttons["secondary"].size.x) * 0.5)
	var secondary_alpha: float = game._hud_rect_player_alpha(Rect2(secondary_c - Vector2(secondary_r, secondary_r), Vector2(secondary_r * 2.0, secondary_r * 2.0)), viewport)
	var active_eletrica_secondary = game._active_eletrica_secondary()
	var toggle_ultimate_active = not active_eletrica_secondary.is_empty() or not game._active_prismatica_secondary().is_empty()
	var cancel_danger = not active_eletrica_secondary.is_empty() and float(active_eletrica_secondary.get("active_time", 0.0)) >= game.SECONDARY_ELETRICA_DRAIN_DELAY
	var cancel_pulse = 0.5 + sin(game.time_alive * (10.0 if cancel_danger else 7.0)) * 0.5
	if toggle_ultimate_active:
		var outer_alpha = 0.28 + cancel_pulse * (0.24 if cancel_danger else 0.14)
		game.draw_circle(secondary_c, secondary_r + 9.0 + cancel_pulse * 5.0, Color(1.0, 0.0, 0.05, outer_alpha * secondary_alpha))
		game.draw_circle(secondary_c, secondary_r * 0.96, Color(0.4, 0.0, 0.02, 0.92 * secondary_alpha))
	if not game.is_gamepad_active:
		game._draw_button(secondary_c, secondary_r, "CANCELAR" if toggle_ultimate_active else "ULT", game._with_alpha(Color(1.0, 0.02, 0.06, 0.98) if toggle_ultimate_active else Color(1.0, 0.72, 0.22, 0.72), secondary_alpha))
	if game.manifestation_key == "eletrica" and not toggle_ultimate_active:
		var cd_total: float = game._secondary_skill_cooldown()
		var cd_elapsed: float = clampf(game.time_alive - game.last_secondary_time, 0.0, cd_total)
		if cd_elapsed < cd_total:
			var cd_ratio: float = cd_elapsed / maxf(0.01, cd_total)
			var cd_phase: float = game.time_alive * 7.0
			var cd_col: Color = Color(0.14, 0.72, 1.0, 0.42).lerp(Color(0.9, 0.12, 1.0, 0.76), 1.0 - cd_ratio)
			game.draw_arc(secondary_c, secondary_r + 11.0, -PI * 0.5, -PI * 0.5 + TAU * cd_ratio, 58, cd_col, 4.0, true)
			game.draw_arc(secondary_c, secondary_r + 17.0, cd_phase, cd_phase + PI * 0.8, 26, Color(0.58, 0.96, 1.0, 0.28 + 0.3 * (1.0 - cd_ratio)), 2.0, true)
			for spark in range(3):
				var a: float = cd_phase + float(spark) * TAU / 3.0
				var start: Vector2 = secondary_c + Vector2.from_angle(a) * (secondary_r + 15.0)
				game.draw_line(start, start + Vector2.from_angle(a + 0.8) * 7.0, Color(0.86, 0.98, 1.0, 0.42), 1.4, true)
	if toggle_ultimate_active:
		game.draw_arc(secondary_c, secondary_r + 7.0 + cancel_pulse * 4.0, 0.0, TAU, 54, Color(1.0, 0.1, 0.13, 1.0), 4.0)
	if not active_eletrica_secondary.is_empty():
		var tesla_t = float(active_eletrica_secondary.get("active_time", 0.0))
		var status_text = "ATIVO"
		var status_col = Color(0.34, 0.9, 1.0)
		if tesla_t >= 15.0:
			status_text = "SOBRECARGA"
			status_col = Color(1.0, 0.15, 0.25)
		elif tesla_t >= 13.0:
			status_text = "ALERTA!"
			status_col = Color(1.0, 0.45, 0.1)
		elif tesla_t >= 10.0:
			status_text = "INSTAVEL"
			status_col = Color(1.0, 0.85, 0.15)
		game._draw_centered(status_text, secondary_c + Vector2(0, - secondary_r - 18.0), 10, status_col)
		game._draw_centered("CANCELAR", secondary_c + Vector2(0, secondary_r + 17.0), 11, Color(1.0, 0.92, 0.92))
	elif toggle_ultimate_active:
		if cancel_danger:
			game.draw_arc(secondary_c, secondary_r + 15.0 + cancel_pulse * 5.0, - PI * 0.5, PI * 1.5, 54, Color(0.34, 0.9, 1.0, 0.82), 2.0)
			game._draw_centered("DRENANDO", secondary_c + Vector2(0, - secondary_r - 18.0), 10, Color(1.0, 0.28, 0.32))
		game._draw_centered("CANCELAR", secondary_c + Vector2(0, secondary_r + 17.0), 11, Color(1.0, 0.92, 0.92))

	var dash_c = game.buttons["dash"].position + game.buttons["dash"].size * 0.5
	var dash_r: float = minf(46.0 * game._dash_scale(), float(game.buttons["dash"].size.x) * 0.5)
	var dash_alpha: float = game._hud_rect_player_alpha(Rect2(dash_c - Vector2(dash_r, dash_r), Vector2(dash_r * 2.0, dash_r * 2.0)), viewport)
	var tp_visual_active = game.tp_cooldown_pending and not game.tp_effects.is_empty()
	var dash_label = "VOLTAR" if game.manifestation_key == "retornante" and game.retornante_tp_window > 0.0 else ("ATIVO" if tp_visual_active else "TP")
	if not game.is_gamepad_active:
		game._draw_button(dash_c, dash_r, dash_label, game._with_alpha(Color(0.42, 0.28, 1.0, 0.88) if dash_label == "VOLTAR" else Color(0.2, 0.85, 1.0, 0.72), dash_alpha))
	if game.manifestation_key == "lacerante":
		var charge_center: Vector2 = dash_c + Vector2(dash_r * 0.66, - dash_r * 0.68)
		game.draw_circle(charge_center, 14.0, Color(0.16, 0.0, 0.025, 0.96))
		game.draw_arc(charge_center, 14.0, 0.0, TAU, 24, Color(1.0, 0.16, 0.24, 0.98), 2.0)
		game._draw_centered(str(game.lacerante_tp_charges), charge_center + Vector2(0, 1), 14, Color.WHITE)
		if game.lacerante_tp_chain_timer > 0.0 and game.lacerante_tp_charges > 0:
			var chain_ratio: float = clampf(game.lacerante_tp_chain_timer / game.LACERANTE_TP_CHAIN_WINDOW, 0.0, 1.0)
			game.draw_arc(dash_c, dash_r + 8.0, - PI * 0.5, - PI * 0.5 + TAU * chain_ratio, 42, Color(1.0, 0.12, 0.2, 0.96), 4.0)
	if game.buttons.has("lacerante_empower"):
		var empower_rect: Rect2 = game.buttons["lacerante_empower"]
		var empower_c = empower_rect.get_center()
		var empower_r = empower_rect.size.x * 0.5
		var armed_pulse = 0.5 + sin(game.time_alive * 10.0) * 0.5
		if game.manifestation_key == "eclipsada":
			var form_color = game._eclipsada_color()
			game.draw_circle(empower_c, empower_r + 7.0 + armed_pulse * 4.0, Color(form_color.r, form_color.g, form_color.b, 0.14 + armed_pulse * 0.12))
			if not game.is_gamepad_active:
				game._draw_button(empower_c, empower_r, game._eclipsada_form_label(), Color(form_color.r, form_color.g, form_color.b, 0.78))
				game._draw_centered("FORMA", empower_c + Vector2(0, empower_r + 13.0), 9, Color(1.0, 0.9, 0.72, 0.92))
		elif game.manifestation_key == "necronada":
			if game.necronada_empowered_ready:
				game.draw_circle(empower_c, empower_r + 7.0 + armed_pulse * 4.0, Color(0.52, 0.34, 0.92, 0.18 + armed_pulse * 0.16))
			if not game.is_gamepad_active:
				game._draw_button(empower_c, empower_r, "PO" if game.necronada_empowered_ready else "+", Color(0.52, 0.34, 0.92, 0.92 if game.necronada_empowered_ready else 0.68))
				game._draw_centered("POEIRA", empower_c + Vector2(0, empower_r + 13.0), 9, game._necronada_accent())
			if not game.necronada_empowered_ready:
				game._draw_cooldown_overlay(empower_c, empower_r, game.NECRONADA_EMPOWER_COOLDOWN - maxf(0.0, game.necronada_empower_cooldown_until - game.time_alive), game.NECRONADA_EMPOWER_COOLDOWN)
		else:
			if game.lacerante_empowered_ready:
				game.draw_circle(empower_c, empower_r + 7.0 + armed_pulse * 4.0, Color(1.0, 0.02, 0.1, 0.18 + armed_pulse * 0.18))
			if not game.is_gamepad_active:
				game._draw_button(empower_c, empower_r, "R" if game.lacerante_empowered_ready else "+", Color(0.92, 0.03, 0.12, 0.92 if game.lacerante_empowered_ready else 0.68))
				game._draw_centered("REFORCO", empower_c + Vector2(0, empower_r + 13.0), 9, Color(1.0, 0.72, 0.74, 0.92))
			if not game.lacerante_empowered_ready:
				game._draw_cooldown_overlay(empower_c, empower_r, game.time_alive - game.last_lacerante_empower_time, game.LACERANTE_EMPOWER_COOLDOWN)
	if game.buttons.has("bombastica_detonator"):
		var det_rect: Rect2 = game.buttons["bombastica_detonator"]
		var det_c = det_rect.get_center()
		var det_r = det_rect.size.x * 0.5
		var detonator_ready = game.bombastica_bombs.size() > 0
		var hold_ratio = clampf(game.bombastica_detonator_hold / 0.62, 0.0, 1.0) if game.bombastica_detonator_touch_index != -1 else 0.0
		var pulse = 0.5 + sin(game.time_alive * 11.0) * 0.5
		if detonator_ready:
			game.draw_circle(det_c, det_r + 7.0 + pulse * 4.0, Color(1.0, 0.48, 0.08, 0.16 + pulse * 0.12))
		if not game.is_gamepad_active:
			game._draw_button(det_c, det_r, "DET", Color(1.0, 0.48, 0.12, 0.88 if detonator_ready else 0.42))
			game._draw_centered("DETONAR", det_c + Vector2(0, det_r + 13.0), 9, Color(1.0, 0.78, 0.46, 0.92))
		if hold_ratio > 0.0:
			game.draw_arc(det_c, det_r + 8.0, - PI * 0.5, - PI * 0.5 + TAU * hold_ratio, 42, Color(0.18, 0.88, 1.0, 0.96), 4.0)
			game._draw_centered("TODAS", det_c + Vector2(0, - det_r - 14.0), 9, Color(0.7, 1.0, 1.0))

	game._draw_cooldown_overlay(atk_c, atk_r, game.time_alive - game.last_attack_time, game._current_attack_interval())
	game._draw_cooldown_overlay(skill_c, skill_r, game.time_alive - game.last_skill_time, game._skill_cooldown())
	if not toggle_ultimate_active:
		game._draw_cooldown_overlay(secondary_c, secondary_r, game.time_alive - game.last_secondary_time, game._secondary_skill_cooldown())
	if game.tp_cooldown_pending and game.tp_cooldown_release_time <= 0.0 and not game.tp_effects.is_empty():
		var active_tp: Dictionary = game.tp_effects[0]
		game._draw_cooldown_overlay(dash_c, dash_r, float(active_tp.get("max", 1.0)) - float(active_tp.get("life", 0.0)), float(active_tp.get("max", 1.0)))
	else:
		game._draw_cooldown_overlay(dash_c, dash_r, game.time_alive - game.last_dash_time, game._current_dash_cooldown())
	game._draw_hud_rect_button(game.buttons["pause"], "II", game._with_alpha(Color(0.0, 1.0, 0.82), game._hud_rect_player_alpha(game.buttons["pause"], viewport, 72.0)))
	if game.buttons.has("shop_manual"):
		var shop_rect: Rect2 = game.buttons["shop_manual"]
		var shop_accent = Color(0.0, 1.0, 0.82) if game._affordable_card_count() > 0 and game.mode == "game" else Color(0.38, 0.42, 0.46)
		var shop_alpha: float = game._hud_rect_player_alpha(shop_rect, viewport, 82.0)
		game._draw_centered("LOJA %d" % game.card_cost, shop_rect.get_center() + Vector2(0, -29), 12, Color(shop_accent.r, shop_accent.g, shop_accent.b, 0.92 * shop_alpha))
		game._draw_hud_rect_button(shop_rect, "LOJA", game._with_alpha(shop_accent, shop_alpha))
	if game.boss_ready and not game.boss_active and not game.boss_dead:
		var boss_rect: Rect2 = game.buttons["boss"]
		var boss_alpha: float = game._hud_rect_player_alpha(boss_rect, viewport, 82.0)
		game._draw_centered("BOSS PRONTO", boss_rect.get_center() + Vector2(0, -31), 16, Color(1.0, 0.82, 0.24, boss_alpha))
		game._draw_hud_rect_button(boss_rect, "BOSS", Color(1.0, 0.52, 0.16, boss_alpha))
	if game._ability_cancel_active():
		game._draw_ability_cancel_button(viewport)
	game._draw_dance_wheel(viewport)
	game._draw_player_dance_emote(game._camera(viewport))


static func _draw_edit_layout_safe_guides(game: Node2D, viewport: Vector2) -> void:
	var safe_rect: Rect2 = game._edit_layout_safe_rect(viewport)
	var accent = Color(0.0, 1.0, 0.82, 0.42)
	var warn = Color(1.0, 0.72, 0.22, 0.32)
	game.draw_rect(safe_rect, Color(0.0, 0.8, 0.7, 0.035), false, 1.0)
	var corner_len = 42.0
	var points = [
		safe_rect.position,
		Vector2(safe_rect.end.x, safe_rect.position.y),
		Vector2(safe_rect.position.x, safe_rect.end.y),
		safe_rect.end
	]
	for p in points:
		var sx = 1.0 if p.x <= safe_rect.position.x + 1.0 else -1.0
		var sy = 1.0 if p.y <= safe_rect.position.y + 1.0 else -1.0
		game.draw_line(p, p + Vector2(corner_len * sx, 0.0), accent, 2.0)
		game.draw_line(p, p + Vector2(0.0, corner_len * sy), accent, 2.0)
		game.draw_circle(p, 3.0, warn)
	game._draw_centered("AREA SEGURA DAS QUINAS", Vector2(viewport.x * 0.5, viewport.y - 118.0), 13, Color(0.7, 0.92, 1.0, 0.72))


static func _draw_edit_layout(game: Node2D, viewport: Vector2) -> void :
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.05, 0.05, 0.08, 0.9))
	game._draw_edit_layout_safe_guides(viewport)
	game._draw_centered(game._edit_layout_title(), Vector2(viewport.x * 0.5, 40), 28, Color(0.0, 1.0, 0.82))
	if not game._edit_layout_uses_virtual_controls():
		game._draw_centered("Desktop: mova paineis, loja, boss e avisos. Controles ficam em TECLAS.", Vector2(viewport.x * 0.5, viewport.y - 142.0), 14, Color(0.72, 0.92, 1.0, 0.82))

	if game._edit_layout_uses_virtual_controls():
		var joy = game._joy_center(viewport)
		var joy_r = 76.0 * game._joy_scale()
		game.draw_circle(joy, joy_r, Color(0.8, 0.8, 0.0, 0.4) if game.edit_layout_selected == "joy" else Color(0.0, 0.8, 0.8, 0.4))
		game.draw_arc(joy, joy_r, 0, TAU, 64, Color(1.0, 1.0, 0.0) if game.edit_layout_selected == "joy" else Color(0.0, 1.0, 0.85), 3)
		game._draw_centered("JOY", joy, 20, Color.WHITE)
		if game._edit_layout_scale_controls_visible("joy"):
			var joy_scale_controls = game._circle_scale_control_rects(joy, joy_r, viewport)
			game._draw_small_rect_button(joy_scale_controls[0], "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
			game._draw_small_rect_button(joy_scale_controls[1], "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

		var atk_c = game.buttons["attack"].position + game.buttons["attack"].size * 0.5
		var atk_r = 54.0 * game._attack_scale()
		game.draw_circle(atk_c, atk_r, Color(0.8, 0.8, 0.0, 0.4) if game.edit_layout_selected == "attack" else Color(1.0, 0.16, 0.28, 0.4))
		game.draw_arc(atk_c, atk_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if game.edit_layout_selected == "attack" else Color(1.0, 0.16, 0.28), 3)
		game._draw_centered("ATK", atk_c, 20, Color.WHITE)
		if game._edit_layout_scale_controls_visible("attack"):
			var atk_scale_controls = game._circle_scale_control_rects(atk_c, atk_r, viewport)
			game._draw_small_rect_button(atk_scale_controls[0], "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
			game._draw_small_rect_button(atk_scale_controls[1], "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

		var secondary_c = game.buttons["secondary"].position + game.buttons["secondary"].size * 0.5
		var secondary_r = 43.0 * game._secondary_scale()
		game.draw_circle(secondary_c, secondary_r, Color(0.8, 0.8, 0.0, 0.4) if game.edit_layout_selected == "secondary" else Color(1.0, 0.72, 0.22, 0.4))
		game.draw_arc(secondary_c, secondary_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if game.edit_layout_selected == "secondary" else Color(1.0, 0.72, 0.22), 3)
		game._draw_centered("E", secondary_c + Vector2(0, -6), 20, Color.WHITE)
		game._draw_centered("ULT", secondary_c + Vector2(0, 13), 12, Color.WHITE)
		if game._edit_layout_scale_controls_visible("secondary"):
			var secondary_scale_controls = game._circle_scale_control_rects(secondary_c, secondary_r, viewport)
			game._draw_small_rect_button(secondary_scale_controls[0], "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
			game._draw_small_rect_button(secondary_scale_controls[1], "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

		var dash_c = game.buttons["dash"].position + game.buttons["dash"].size * 0.5
		var dash_r = 46.0 * game._dash_scale()
		game.draw_circle(dash_c, dash_r, Color(0.8, 0.8, 0.0, 0.4) if game.edit_layout_selected == "dash" else Color(0.2, 0.85, 1.0, 0.4))
		game.draw_arc(dash_c, dash_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if game.edit_layout_selected == "dash" else Color(0.2, 0.85, 1.0), 3)
		game._draw_centered("TP", dash_c, 20, Color.WHITE)
		if game._edit_layout_scale_controls_visible("dash"):
			var dash_scale_controls = game._circle_scale_control_rects(dash_c, dash_r, viewport)
			game._draw_small_rect_button(dash_scale_controls[0], "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
			game._draw_small_rect_button(dash_scale_controls[1], "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

		var empower_r = 32.0 * game._lacerante_empower_scale()
		var empower_c = game._lacerante_empower_center(viewport)
		game.buttons["lacerante_empower"] = Rect2(empower_c - Vector2(empower_r, empower_r), Vector2(empower_r * 2.0, empower_r * 2.0))
		var is_empower_selected = (game.edit_layout_selected == "lacerante_empower")
		game.draw_circle(empower_c, empower_r, Color(0.8, 0.8, 0.0, 0.4) if is_empower_selected else Color(0.92, 0.03, 0.12, 0.4))
		game.draw_arc(empower_c, empower_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if is_empower_selected else Color(0.92, 0.03, 0.12), 3)
		game._draw_centered("+", empower_c, 24, Color.WHITE)
		if game._edit_layout_scale_controls_visible("lacerante_empower"):
			var empower_scale_controls = game._circle_scale_control_rects(empower_c, empower_r, viewport)
			game._draw_small_rect_button(empower_scale_controls[0], "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
			game._draw_small_rect_button(empower_scale_controls[1], "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
	else:
		game.buttons.erase("lacerante_empower")

	var portrait = game._is_portrait(viewport)
	var left_w = 236.0 if not portrait else min(236.0, viewport.x * 0.46)
	var left_rect = Rect2(game._left_panel_pos(viewport), Vector2(left_w, 76))
	var c_left = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "left_panel" else Color(0, 1, 0.8, 0.3)
	game.draw_rect(left_rect, c_left, false, 2)
	game._draw_centered("VIDA", left_rect.get_center(), 16, Color.WHITE)

	var right_w = 220.0 if not portrait else min(220.0, viewport.x * 0.44)
	var right_rect = Rect2(game._right_panel_pos(viewport), Vector2(right_w, 76))
	var c_right = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "right_panel" else Color(1, 0.8, 0.2, 0.3)
	game.draw_rect(right_rect, c_right, false, 2)
	game._draw_centered("PONTOS", right_rect.get_center(), 16, Color.WHITE)

	var boss_rect = Rect2(game._boss_panel_pos(viewport), Vector2(380, 30))
	var c_boss = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "boss_panel" else Color(1, 0.16, 0.3, 0.3)
	game.draw_rect(boss_rect, c_boss, false, 2)
	game._draw_centered("BOSS HP", boss_rect.get_center(), 14, Color.WHITE)

	var shop_rect = Rect2(game._manual_shop_pos(viewport), Vector2(104, 42))
	game.buttons["shop_manual"] = shop_rect
	var c_shop = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "shop_manual" else Color(0.0, 1.0, 0.82, 0.3)
	game.draw_rect(shop_rect, c_shop, false, 2)
	game._draw_centered("LOJA", shop_rect.get_center(), 14, Color.WHITE)

	var aura_rect = Rect2(game._aura_panel_pos(viewport, left_rect), Vector2(min(224.0, viewport.x * 0.46), 48.0) * game.hud_aura_panel_scale)
	var c_aura = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "aura_panel" else Color(0.54, 0.82, 1.0, 0.3)
	game.draw_rect(aura_rect, c_aura, false, 2)
	game._draw_centered("AUREA", aura_rect.get_center(), 13, Color.WHITE)
	if game._edit_layout_scale_controls_visible("aura_panel"):
		game._draw_layout_scale_controls(aura_rect)

	var cards_rect = Rect2(game._cards_panel_pos(viewport, left_rect), Vector2(min(224.0, viewport.x * 0.46), 94.0) * game.hud_cards_panel_scale)
	var c_cards = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "cards_panel" else Color(1.0, 0.64, 0.18, 0.3)
	game.draw_rect(cards_rect, c_cards, false, 2)
	game._draw_centered("CARTAS HUD", cards_rect.get_center(), 13, Color.WHITE)
	if game._edit_layout_scale_controls_visible("cards_panel"):
		game._draw_layout_scale_controls(cards_rect)

	var coag_center = game._coagulum_hud_center(viewport, 120.0, 13.0, viewport.y - (42.0 if not portrait else 58.0))
	var coag_size = Vector2(160, 48) * game.hud_coagulum_scale
	var coag_rect = Rect2(coag_center - coag_size * 0.5, coag_size)
	var c_coag = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "coagulum" else Color(1.0, 0.12, 0.22, 0.3)
	game.draw_rect(coag_rect, c_coag, false, 2)
	game._draw_centered("COAGULO", coag_rect.get_center(), 13, Color.WHITE)
	if game._edit_layout_scale_controls_visible("coagulum"):
		game._draw_layout_scale_controls(coag_rect)

	if game._edit_layout_uses_virtual_controls():
		var skill_r = 46.0 * game._skill_scale()
		var skill_rect = Rect2(game._skill_pos(viewport), Vector2(skill_r * 2.0, skill_r * 2.0))
		var skill_c = skill_rect.get_center()
		game.draw_circle(skill_c, skill_r, Color(0.8, 0.8, 0.0, 0.4) if game.edit_layout_selected == "skill" else Color(game._manifestation_color().r, game._manifestation_color().g, game._manifestation_color().b, 0.4))
		game.draw_arc(skill_c, skill_r, 0, TAU, 32, Color(1.0, 1.0, 0.0) if game.edit_layout_selected == "skill" else game._manifestation_color(), 3)
		game._draw_centered("HAB1", skill_c, 18, Color.WHITE)
		if game._edit_layout_scale_controls_visible("skill"):
			var skill_scale_controls = game._circle_scale_control_rects(skill_c, skill_r, viewport)
			game._draw_small_rect_button(skill_scale_controls[0], "-", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))
			game._draw_small_rect_button(skill_scale_controls[1], "+", Color(0.2, 0.2, 0.2), Color(0.5, 0.5, 0.5))

	var pause_rect = Rect2(game._pause_pos(viewport), Vector2(52, 42))
	var c_pause = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "pause" else Color(1, 1, 1, 0.3)
	game.draw_rect(pause_rect, c_pause, false, 2)
	game._draw_centered("||", pause_rect.get_center(), 14, Color.WHITE)

	var call_rect = Rect2(game._boss_call_pos(viewport), Vector2(96, 42))
	var c_call = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "boss_call" else Color(1, 0.5, 0, 0.3)
	game.draw_rect(call_rect, c_call, false, 2)
	game._draw_centered("CALL", call_rect.get_center(), 14, Color.WHITE)

	game._draw_big_button(Rect2(viewport.x * 0.5 - 150, viewport.y - 80, 300, 60), "SALVAR & VOLTAR", Color(0.1, 0.3, 0.1), Color(0.2, 1.0, 0.4))


static func _draw_team_revival_hud(game: Node2D, viewport: Vector2) -> void:
	game.buttons.erase("revival_mobile")
	var panel_w: float = min(620.0, viewport.x * 0.78)
	var panel_h: float = 104.0
	var panel: Rect2 = Rect2(viewport.x * 0.5 - panel_w * 0.5, 76.0, panel_w, panel_h)
	var accent: Color = Color(0.0, 1.0, 0.82) if not game.is_dead else Color(1.0, 0.24, 0.3)
	game._draw_holo_panel(panel, accent, true, 0.82)
	var remaining: int = int(ceil(maxf(0.0, game.revival_timer)))
	var total: int = maxi(1, game.revival_fragments.size())
	var title: String = "VOCE FOI ELIMINADO" if game.is_dead else ("ALTARES DE REVIVE ATIVOS" if game.revival_altars_active else "RECONSTITUA O ALIADO")
	if game.revival_fragments_suspended:
		title = "FRAGMENTOS DISSIPADOS"
	game._draw_centered(title, Vector2(panel.get_center().x, panel.position.y + 25.0), game._readable_text_size(15), accent)
	if game.revival_fragments_suspended:
		var wait_info: String = "RETORNAM EM %ds  |  colete de novo para invocar os altares" % int(ceil(maxf(0.0, game.revival_fragment_respawn_timer)))
		game._draw_wrapped_clamped(wait_info, Rect2(panel.position.x + 24.0, panel.position.y + 48.0, panel.size.x - 48.0, 24.0), game._readable_text_size(12), Color(0.92, 0.96, 1.0), 1)
	elif game.revival_altars_active:
		var rate: float = game._revival_life_sacrifice_rate() * 100.0
		var cost: int = game._revival_points_cost()
		var info: String = "VERMELHO: sacrifica %.0f%% da vida e divide entre %d caido(s)  |  AZUL: %d pontos" % [rate, game._team_revival_dead_count(), cost]
		game._draw_wrapped_clamped(info, Rect2(panel.position.x + 24.0, panel.position.y + 48.0, panel.size.x - 48.0, 24.0), game._readable_text_size(12), Color(0.92, 0.96, 1.0), 1)
	else:
		var multi_rate: float = game.REVIVAL_MULTI_LIFE_SACRIFICE_RATE * (1.0 - game.REVIVE_LIFE_SACRIFICE_REDUCTION) * 100.0
		var info2: String = "FRAGMENTOS %d/%d  |  %ds  |  mais de um caido: 50s e sacrificio sobe para %.0f%%" % [game.revival_fragments_collected, total, remaining, multi_rate]
		game._draw_wrapped_clamped(info2, Rect2(panel.position.x + 24.0, panel.position.y + 48.0, panel.size.x - 48.0, 24.0), game._readable_text_size(12), Color(0.92, 0.96, 1.0), 1)
	game._draw_centered(game.revival_notice.to_upper(), Vector2(panel.get_center().x, panel.end.y - 18.0), game._readable_text_size(10), Color(1.0, 0.86, 0.24, 0.92))


static func _draw_health_tube_bar(game: Node2D, pos: Vector2, width: float, height: float, ratio: float, color: Color, hit_flash: float, alpha: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	alpha = clampf(alpha, 0.0, 1.0)
	var rect = Rect2(pos, Vector2(width, height))
	var fill_color: Color = Color(0.98, 0.12, 0.16).lerp(color, ratio)
	if hit_flash > 0.0:
		fill_color = fill_color.lerp(Color(1.0, 0.05, 0.04), hit_flash * 0.72)
	game.draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.48 * alpha), true)
	game.draw_rect(rect, Color(0.01, 0.018, 0.024, 0.94 * alpha), true)
	game.draw_rect(rect.grow(-2.0), Color(0.08, 0.18, 0.2, 0.26 * alpha), true)
	if ratio > 0.0:
		var liquid_rect = Rect2(rect.position + Vector2(3.0, 3.0), Vector2(maxf(0.0, (width - 6.0) * ratio), maxf(1.0, height - 6.0)))
		game.draw_rect(liquid_rect, Color(fill_color.r, fill_color.g, fill_color.b, 0.9 * alpha), true)
		game.draw_line(liquid_rect.position + Vector2(2.0, 2.0), liquid_rect.position + Vector2(maxf(2.0, liquid_rect.size.x - 3.0), 2.0), Color(1.0, 1.0, 1.0, 0.22 * alpha), 1.2)
	game.draw_line(rect.position + Vector2(4.0, 3.0), rect.position + Vector2(width - 5.0, 3.0), Color(1.0, 1.0, 1.0, 0.24 * alpha), 1.2)
	game.draw_line(rect.position + Vector2(2.0, height - 2.0), rect.position + Vector2(width - 3.0, height - 2.0), Color(0.22, 0.94, 1.0, 0.18 * alpha), 1.0)
	game.draw_rect(rect, Color(0.52, 0.96, 1.0, 0.72 * alpha), false, 1.8)
	game.draw_rect(rect.grow(-3.0), Color(1.0, 1.0, 1.0, 0.14 * alpha), false, 1.0)
	var danger: float = clampf((0.7 - ratio) / 0.7, 0.0, 1.0)
	if danger > 0.0:
		var crack_count: int = 1 + int(floor(danger * 6.0))
		for i in range(crack_count):
			var crack_seed: float = float(i + 1) * 17.23
			var cx: float = pos.x + width * fposmod(0.18 + crack_seed * 0.137, 0.76)
			var cy: float = pos.y + height * fposmod(0.2 + crack_seed * 0.091, 0.6)
			var crack_len: float = lerpf(5.0, 16.0, danger)
			var a: float = -0.75 + fposmod(crack_seed, 1.0) * 1.5
			var start = Vector2(cx, cy)
			var end = start + Vector2.from_angle(a) * crack_len
			game.draw_line(start, end, Color(0.84, 1.0, 1.0, 0.18 + danger * 0.52), 1.0)
			game.draw_line(start + Vector2(1.0, -1.0), start + Vector2.from_angle(a - 0.75) * crack_len * 0.44, Color(0.84, 1.0, 1.0, 0.14 + danger * 0.36), 1.0)


static func _draw_virtual_stick(game: Node2D, center: Vector2, radius: float, alpha: float = 1.0) -> void :
	var accent = Color(0.0, 1.0, 0.82)
	game.draw_circle(center, radius, Color(0.0, 0.72, 0.72, 0.055 * alpha))
	game.draw_arc(center, radius, - PI * 0.82, PI * 0.82, 42, Color(accent.r, accent.g, accent.b, 0.72 * alpha), 2.3)
	game.draw_arc(center, radius * 0.7, PI * 0.18, PI * 1.32, 34, Color(1.0, 1.0, 1.0, 0.22 * alpha), 1.4)
	for i in range(4):
		var a = i * PI * 0.5 + PI * 0.25
		game.draw_line(center + Vector2.from_angle(a) * radius * 0.78, center + Vector2.from_angle(a) * radius * 0.95, Color(accent.r, accent.g, accent.b, 0.38 * alpha), 1.5)
	var knob = center + game.touch_move * (radius * 0.46)
	game.draw_circle(knob, max(18.0, radius * 0.22), Color(accent.r, accent.g, accent.b, 0.26 * alpha))
	game.draw_circle(knob, max(9.0, radius * 0.11), Color(accent.r, accent.g, accent.b, 0.62 * alpha))
	game.draw_arc(knob, max(22.0, radius * 0.27), 0, TAU, 34, Color(1.0, 1.0, 1.0, 0.38 * alpha), 1.5)


static func _draw_attack_lock_preview(game: Node2D, viewport: Vector2) -> void :
	var center = game._attack_lock_preview_screen(viewport)
	var has_candidate = not game.attack_lock_candidate_kind.is_empty()
	var color = Color(1.0, 0.86, 0.18, 0.96) if has_candidate else Color(1.0, 0.34, 0.24, 0.72)
	var radius = 24.0 + sin(game.time_alive * 8.0) * 2.0
	game.draw_circle(center, radius, Color(color.r, color.g, color.b, 0.08))
	game.draw_arc(center, radius, 0.0, TAU, 36, color, 2.5)
	game.draw_line(center + Vector2( - radius - 8, 0), center + Vector2(-8, 0), color, 2.0)
	game.draw_line(center + Vector2(radius + 8, 0), center + Vector2(8, 0), color, 2.0)
	game.draw_line(center + Vector2(0, - radius - 8), center + Vector2(0, -8), color, 2.0)
	game.draw_line(center + Vector2(0, radius + 8), center + Vector2(0, 8), color, 2.0)


static func _draw_ability_cancel_button(game: Node2D, viewport: Vector2) -> void :
	var center = game._ability_cancel_center(viewport)
	var hovered = game._ability_cancel_has_point(game._active_ability_touch_pos(), viewport)
	var pulse = 1.0 + sin(game.time_alive * 9.0) * (0.06 if hovered else 0.025)
	var radius = game.ABILITY_CANCEL_RADIUS * pulse
	game.draw_circle(center, radius, Color(0.22, 0.01, 0.02, 0.84))
	game.draw_circle(center, radius * 0.78, Color(1.0, 0.06, 0.1, 0.34 if hovered else 0.18))
	game.draw_arc(center, radius, 0.0, TAU, 48, Color(1.0, 0.16, 0.18, 1.0), 4.0 if hovered else 2.5)
	var arm = radius * 0.3
	game.draw_line(center + Vector2( - arm, - arm), center + Vector2(arm, arm), Color.WHITE, 6.0, true)
	game.draw_line(center + Vector2(arm, - arm), center + Vector2( - arm, arm), Color.WHITE, 6.0, true)
