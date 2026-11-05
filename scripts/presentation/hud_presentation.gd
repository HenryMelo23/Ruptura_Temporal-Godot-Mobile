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


static func update_button_layout(game: Node2D, viewport: Vector2) -> void:
	var henry_colossus: bool = game.active_character_key == game.CHARACTER_HENRY and game.mutation_key == "colosso"
	if game._uses_desktop_ui() and game.mode != "edit_layout":
		var desktop_rects: Dictionary = RTHudLayout.desktop_button_rects(
			viewport,
			game.manifestation_key == "lacerante" or henry_colossus,
			game.shop_controller.manual_dev_access(),
			game._sanitize_desktop_hud_scale(game.desktop_hud_scale)
		)
		for key in ["attack", "skill", "secondary", "dash", "pause", "boss"]:
			game.buttons[key] = desktop_rects[key]
		for optional_key in ["lacerante_empower", "shop_manual"]:
			if desktop_rects.has(optional_key):
				game.buttons[optional_key] = desktop_rects[optional_key]
			else:
				game.buttons.erase(optional_key)
		return
	var touch_rects: Dictionary = RTHudLayout.touch_button_rects(
		game._attack_center(viewport), game._attack_scale(), game._skill_pos(viewport), game._skill_scale(),
		game._secondary_center(viewport), game._secondary_scale(), game._dash_center(viewport), game._dash_scale(),
		game._lacerante_empower_center(viewport), game._lacerante_empower_scale(),
		game.manifestation_key == "lacerante" or henry_colossus or game.mode == "edit_layout",
		game._pause_pos(viewport), game._boss_call_pos(viewport), game._manual_shop_pos(viewport),
		game.shop_controller.manual_dev_access()
	)
	var custom_combat_layout: bool = game.hud_attack_pos != Vector2.ZERO or game.hud_secondary_pos != Vector2.ZERO or game.hud_dash_pos != Vector2.ZERO or game.hud_skill_pos != Vector2(-1, -1) or game.hud_lacerante_empower_pos != Vector2(-1, -1)
	if game.mode != "edit_layout" and not custom_combat_layout and _touch_hub_has_overlap(touch_rects, viewport):
		var organized: Dictionary = RTHudLayout.organized_touch_button_rects(viewport, game._attack_scale(), game._skill_scale(), game._secondary_scale(), game._dash_scale(), game._lacerante_empower_scale(), game.manifestation_key == "lacerante" or henry_colossus)
		for key in ["attack", "skill", "secondary", "dash"]:
			if organized.has(key):
				touch_rects[key] = organized[key]
		if organized.has("extra"):
			touch_rects["lacerante_empower"] = organized["extra"]
	for key in ["attack", "skill", "secondary", "dash", "pause", "boss"]:
		game.buttons[key] = touch_rects[key]
	for optional_key in ["lacerante_empower", "shop_manual"]:
		if touch_rects.has(optional_key):
			game.buttons[optional_key] = touch_rects[optional_key]
		else:
			game.buttons.erase(optional_key)


static func _touch_hub_has_overlap(rects: Dictionary, viewport: Vector2) -> bool:
	var keys: Array[String] = ["attack", "skill", "secondary", "dash"]
	if rects.has("lacerante_empower"):
		keys.append("lacerante_empower")
	for i in range(keys.size()):
		var base_rect: Rect2 = rects[keys[i]]
		if base_rect.position.x < 0.0 or base_rect.position.y < 0.0 or base_rect.end.x > viewport.x or base_rect.end.y > viewport.y:
			return true
		var first: Rect2 = base_rect.grow(5.0)
		for j in range(i + 1, keys.size()):
			if first.intersects(rects[keys[j]].grow(5.0)):
				return true
	return false


static func _hud_rect_player_alpha(game: Node2D, rect: Rect2, viewport: Vector2, padding: float = 84.0) -> float:
	if game.is_dead or game.mode != "game":
		return 1.0
	var player_screen: Vector2 = game.player_pos - game._camera(viewport)
	var distance: float = game._distance_to_rect(player_screen, rect)
	if distance >= padding:
		return 1.0
	return lerpf(game.HUD_PLAYER_MIN_ALPHA, 1.0, clampf(distance / maxf(1.0, padding), 0.0, 1.0))


static func _with_alpha(color: Color, alpha_multiplier: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(color.a * alpha_multiplier, 0.0, 1.0))


static func _draw_hud_bar(game: Node2D, pos: Vector2, width: float, height: float, ratio: float, color: Color) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	var rect := Rect2(pos, Vector2(width, height))
	game.draw_rect(rect, Color(0.02, 0.03, 0.04, 0.86), true)
	game.draw_rect(Rect2(pos, Vector2(width * ratio, height)), Color(color.r, color.g, color.b, 0.94), true)
	game.draw_line(pos + Vector2(0, height + 3), pos + Vector2(width * ratio, height + 3), Color(color.r, color.g, color.b, 0.5), 2)


static func _draw_player_run_level(game: Node2D, panel: Rect2, scale_value: float = 1.0) -> void:
	var level: int = clampi(int(game.player_run_level), 1, 10)
	var xp: int = maxi(0, int(game.player_run_xp))
	var needed: int = game._player_run_level_controller().xp_to_next()
	var ratio: float = 1.0 if needed <= 0 else clampf(float(xp) / float(needed), 0.0, 1.0)
	var bar := Rect2(panel.position + Vector2(12.0 * scale_value, panel.size.y + 22.0 * scale_value), Vector2(panel.size.x - 24.0 * scale_value, 6.0 * scale_value))
	game.draw_rect(bar, Color(0.015, 0.035, 0.055, 0.86), true)
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.16, 0.82, 1.0, 0.92), true)
	game.draw_rect(bar, Color(0.34, 0.92, 1.0, 0.7), false, 1.0)
	var label := "NV %d  MAX" % level if level >= 10 else "NV %d  %d/%d" % [level, xp, needed]
	game.draw_string_outline(game.font, bar.position + Vector2(0.0, -5.0 * scale_value), label, HORIZONTAL_ALIGNMENT_LEFT, bar.size.x, int(11.0 * scale_value), 3, Color(0.01, 0.02, 0.03, 0.95))
	game.draw_string(game.font, bar.position + Vector2(0.0, -5.0 * scale_value), label, HORIZONTAL_ALIGNMENT_LEFT, bar.size.x, int(11.0 * scale_value), Color(0.66, 0.95, 1.0, 0.92))


## Relogio + ameaca no topo central. No retrato desce para baixo dos paineis laterais.
static func _clock_rect(game: Node2D, viewport: Vector2, compact: bool, below: float = 0.0) -> Rect2:
	var size := Vector2(160.0, 66.0) if compact else Vector2(204.0, 80.0)
	var y: float = 12.0
	if game._is_portrait(viewport):
		y = below + 8.0
	return Rect2(Vector2(viewport.x * 0.5 - size.x * 0.5, y), size)


static func _draw_desktop_fps_hud(game: Node2D, viewport: Vector2) -> void:
	var fps := Engine.get_frames_per_second()
	var fps_rect := Rect2(viewport.x - 116.0, viewport.y - 48.0, 100.0, 32.0)
	game._draw_scifi_frame(fps_rect, Color(0.0, 0.85, 1.0), 6.0, 0.88)
	game._draw_icon_ecg(Vector2(fps_rect.position.x + 20.0, fps_rect.position.y + 16.0), 18.0, Color(0.0, 0.88, 1.0))
	game._draw_centered("%d FPS" % fps, fps_rect.get_center() + Vector2(12.0, 1.0), 13, Color(0.2, 0.92, 1.0))


static func _draw_hud(game: Node2D, viewport: Vector2) -> void :
	if game._spectator_controls_locked():
		game._draw_spectator_hud(viewport)
		_draw_point_boost_hud(game, viewport)
		return
	if game._runtime_visual_budget_active():
		_draw_performance_status_hud(game, viewport)
		return
	if game._uses_desktop_ui():
		game._draw_desktop_hud(viewport)
		return
	var portrait = game._is_portrait(viewport)
	var sm = 1.25 if game.is_gamepad_active and not portrait else 1.0
	var left_w = (236.0 * sm) if not portrait else min(236.0, viewport.x * 0.46)
	var left_h = 76.0 * sm
	var left_rect = Rect2(game._left_panel_pos(viewport), Vector2(left_w, left_h))
	var left_alpha: float = _hud_rect_player_alpha(game, left_rect, viewport, 84.0)
	game.hud_feedback.health_panel(game, left_rect, left_alpha)
	var clock_rect: Rect2 = _clock_rect(game, viewport, true, left_rect.end.y)
	game.hud_feedback.clock_panel(game, clock_rect, _hud_rect_player_alpha(game, clock_rect, viewport, 84.0), true)

	var right_w = (220.0 * sm) if not portrait else min(220.0, viewport.x * 0.44)
	var right_rect = Rect2(game._right_panel_pos(viewport), Vector2(right_w, left_h))
	if game.buttons.has("pause") and right_rect.intersects(game.buttons["pause"]):
		right_rect.position.x = maxf(left_rect.end.x + 12.0, Rect2(game.buttons["pause"]).position.x - right_w - 12.0)
	var right_alpha: float = _hud_rect_player_alpha(game, right_rect, viewport, 84.0)
	game.hud_feedback.stats_panel(game, right_rect, right_alpha)

	if game.boss_active and game.boss_hp > 0.0 and not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		var boss_rect = Rect2(game._boss_panel_pos(viewport), Vector2(380 * sm, 30 * sm))
		game._draw_combat_panel(boss_rect, Color(1.0, 0.16, 0.3), 0.62)
		_draw_hud_bar(game, boss_rect.position + Vector2(14 * sm, 11 * sm), boss_rect.size.x - 28.0 * sm, 8.0 * sm, game.boss_hp / game.boss_hp_max, Color(1.0, 0.16, 0.28))
		game._draw_centered_outlined(String(game.boss_name), Vector2(boss_rect.get_center().x, boss_rect.end.y + 9.0 * sm), int(13 * sm), game.boss_title_color, Color(0.01, 0.02, 0.025, 0.96), maxi(1, int(2 * sm)))
		if game._boss_execute_threshold() > 0.0:
			game._draw_collector_threshold(boss_rect.position + Vector2(14 * sm, 11 * sm), boss_rect.size.x - 28.0 * sm, game._boss_execute_threshold(), game.boss_hp / game.boss_hp_max, 8.0 * sm)
		if game.current_phase == 1 and game.boss_hp / max(1.0, game.boss_hp_max) < game.BOSS1_REWIND_THRESHOLD and game.boss1_rewind_cooldown > 0.0:
			var chrono_text = "CRONO %.0fs" % ceil(game.boss1_rewind_cooldown)
			game.draw_string(game.font, boss_rect.position + Vector2(boss_rect.size.x - 94.0 * sm, 28.0 * sm), chrono_text, HORIZONTAL_ALIGNMENT_LEFT, 82.0 * sm, int(11 * sm), Color(0.48, 0.94, 1.0, 0.92))
		if game.current_phase == 3:
			var faith_rect = Rect2(boss_rect.position + Vector2(64 * sm, 48 * sm), Vector2(252 * sm, 24 * sm))
			game._draw_combat_panel(faith_rect, Color(0.62, 0.94, 0.18), 0.48)
			_draw_hud_bar(game, faith_rect.position + Vector2(54 * sm, 8 * sm), 184.0 * sm, 7.0 * sm, game.boss3_faith / 100.0, Color(0.66, 1.0, 0.22))
			game.draw_string(game.font, faith_rect.position + Vector2(8 * sm, 17 * sm), "FE %d" % int(game.boss3_faith), HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * sm), Color(0.86, 1.0, 0.58))
			if game.boss3_ritual_timer > 0.0:
				game._draw_centered("RITUAL %.1fs  %d/2" % [game.boss3_ritual_timer, game.boss3_ritual_destroyed], Vector2(viewport.x * 0.5, 112 * sm), int(20 * sm), Color(1.0, 0.42, 0.18))
	if game.is_multiplayer and game.online_connected:
		var ping_text = "PING %sms" % (str(game.net_ping_ms) if game.net_ping_ms >= 0 else "--")
		if game.net_remote_ping_ms >= 0:
			ping_text += "  PAR %dms" % game.net_remote_ping_ms
		if game._is_world_replica():
			ping_text += "  JIT %.0fms" % game.net_world_jitter_ms
		game.draw_string(game.font, Vector2(viewport.x * 0.5 - 118.0 * sm, clock_rect.end.y + 14.0 * sm), ping_text, HORIZONTAL_ALIGNMENT_CENTER, 236.0 * sm, int(12 * sm), Color(0.72, 0.96, 1.0, 0.86))
	_draw_point_boost_hud(game, viewport)
	game._draw_lacerante_coagulum_hud(viewport)
	game._draw_unlock_notifications(viewport)


static func _draw_performance_status_hud(game: Node2D, viewport: Vector2) -> void:
	var accent: Color = game._manifestation_color()
	var hp_ratio: float = clampf(float(game.player_hp) / maxf(1.0, float(game.player_hp_max)), 0.0, 1.0)
	var hp_color := Color(0.3, 1.0, 0.48) if hp_ratio >= 0.55 else (Color(1.0, 0.68, 0.18) if hp_ratio >= 0.25 else Color(1.0, 0.2, 0.28))
	var left_rect := Rect2(18.0, 16.0, minf(258.0, viewport.x * 0.42), 56.0)
	var right_rect := Rect2(viewport.x - minf(230.0, viewport.x * 0.38) - 18.0, 16.0, minf(230.0, viewport.x * 0.38), 56.0)
	game.draw_rect(left_rect, Color(0.015, 0.025, 0.035, 0.9), true)
	game.draw_rect(left_rect, hp_color, false, 1.0)
	game.draw_string(game.font, left_rect.position + Vector2(10.0, 18.0), "VIDA %d / %d" % [game.player_hp, game.player_hp_max], HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x - 20.0, 13, Color.WHITE)
	var hp_bar := Rect2(left_rect.position + Vector2(10.0, 27.0), Vector2(left_rect.size.x - 20.0, 9.0))
	game.draw_rect(hp_bar, Color(0.08, 0.11, 0.13, 0.96), true)
	game.draw_rect(Rect2(hp_bar.position, Vector2(hp_bar.size.x * hp_ratio, hp_bar.size.y)), hp_color, true)
	game.hud_feedback.heal_reduction_wire(game, hp_bar, 1.0)
	game.draw_string(game.font, left_rect.position + Vector2(10.0, 50.0), "NV %d  %s" % [int(game.player_run_level), game._phase_region_name(game.current_phase)], HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x - 20.0, 11, Color(accent.r, accent.g, accent.b, 0.9))
	var perf_clock := Rect2(viewport.x * 0.5 - 60.0, 16.0, 120.0, 36.0)
	game.draw_rect(perf_clock, Color(0.015, 0.025, 0.035, 0.9), true)
	game.draw_rect(perf_clock, game.hud_feedback.THREAT_COLORS[game.hud_feedback.threat_tier(game)], false, 1.0)
	game.draw_string(game.font, perf_clock.position + Vector2(0.0, 27.0), game.hud_feedback.clock_text(game), HORIZONTAL_ALIGNMENT_CENTER, perf_clock.size.x, 22, Color.WHITE)

	game.draw_rect(right_rect, Color(0.015, 0.025, 0.035, 0.9), true)
	game.draw_rect(right_rect, Color(0.12, 0.9, 1.0), false, 1.0)
	game.draw_string(game.font, right_rect.position + Vector2(10.0, 22.0), "PONTOS  %s" % game.hud_feedback.display_points(game, game.score), HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 20.0, 16, Color.WHITE)
	game.draw_string(game.font, right_rect.position + Vector2(10.0, 45.0), "CARTAS COMPRAVEIS: %d" % game._affordable_card_count(), HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 20.0, 11, Color(0.72, 0.96, 1.0))

	if game.boss_active and game.boss_hp > 0.0 and not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		var boss_rect := Rect2(viewport.x * 0.5 - 180.0, 18.0, 360.0, 24.0)
		game.draw_rect(boss_rect, Color(0.04, 0.015, 0.025, 0.92), true)
		game.draw_rect(Rect2(boss_rect.position, Vector2(boss_rect.size.x * clampf(game.boss_hp / maxf(1.0, game.boss_hp_max), 0.0, 1.0), boss_rect.size.y)), Color(0.92, 0.1, 0.22, 0.86), true)
		game.draw_rect(boss_rect, Color(1.0, 0.28, 0.38), false, 1.0)
		game._draw_centered(String(game.boss_name), boss_rect.get_center() + Vector2(0.0, 5.0), 11, Color.WHITE)

	if game.is_multiplayer and game.online_connected:
		game.draw_string(game.font, Vector2(viewport.x * 0.5 - 92.0, 58.0), "PING %sms" % (str(game.net_ping_ms) if game.net_ping_ms >= 0 else "--"), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 10, Color(0.72, 0.96, 1.0, 0.86))
	_draw_point_boost_hud(game, viewport)
	game._draw_lacerante_coagulum_hud(viewport)
	game._draw_unlock_notifications(viewport)


static func _draw_point_boost_hud(game: Node2D, viewport: Vector2) -> void:
	_draw_fury_hud(game, viewport)
	if not game.point_boost_pickup_controller.is_active():
		return
	var remaining: float = game.point_boost_pickup_controller.remaining()
	var duration: float = maxf(0.01, game.point_boost_pickup_controller.duration())
	var ratio: float = clampf(remaining / duration, 0.0, 1.0)
	var warning: bool = game.point_boost_pickup_controller.final_warning_active()
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * (12.0 if warning else 4.0))
	var width: float = minf(214.0, viewport.x * 0.42)
	var height := 44.0
	var y: float = 52.0 if not game.boss_active else 104.0
	if viewport.y < 520.0:
		y = 40.0 if not game.boss_active else 82.0
	var rect := Rect2(Vector2(viewport.x * 0.5 - width * 0.5, y), Vector2(width, height))
	var accent := Color(1.0, 0.46 + pulse * 0.2, 0.1, 0.96) if warning else Color(0.2, 1.0, 0.8, 0.94)
	game.draw_rect(rect, Color(0.025, 0.045, 0.045, 0.9), true)
	game.draw_rect(rect, accent, false, 2.0 + pulse * 0.8)
	var coin_center := rect.position + Vector2(23.0, 20.0)
	game.draw_circle(coin_center, 12.0 + pulse * 1.2, Color(0.08, 0.32, 0.28, 1.0))
	game.draw_circle(coin_center, 8.5, Color(1.0, 0.76, 0.12, 1.0))
	game.draw_arc(coin_center, 12.5, 0.0, TAU, 20, Color(0.26, 1.0, 0.82, 0.96), 1.8, true)
	game._draw_centered("x2", coin_center + Vector2(0.0, 4.0), 10, Color(0.2, 0.12, 0.01, 0.96))
	game.draw_string(game.font, rect.position + Vector2(43.0, 20.0), "x2 PONTOS", HORIZONTAL_ALIGNMENT_LEFT, width - 91.0, 16, Color(1.0, 0.91, 0.42))
	game.draw_string(game.font, rect.position + Vector2(width - 52.0, 20.0), "%02ds" % int(ceil(remaining)), HORIZONTAL_ALIGNMENT_RIGHT, 42.0, 15, Color.WHITE)
	var bar_rect := Rect2(rect.position + Vector2(43.0, 29.0), Vector2(width - 55.0, 6.0))
	game.draw_rect(bar_rect, Color(0.04, 0.09, 0.08, 0.94), true)
	game.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), accent, true)


## Barra da Furia (artefato de dano). Fica logo abaixo da barra do x2.
static func _draw_fury_hud(game: Node2D, viewport: Vector2) -> void:
	var artifacts: RTFieldArtifactController = game._field_artifacts()
	if artifacts.fury_remaining <= 0.0:
		return
	var ratio: float = clampf(artifacts.fury_remaining / RTFieldArtifactController.FURY_DURATION, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * (12.0 if artifacts.fury_remaining <= 3.0 else 5.0))
	var width: float = minf(214.0, viewport.x * 0.42)
	var y: float = (52.0 if not game.boss_active else 104.0) + (50.0 if game.point_boost_pickup_controller.is_active() else 0.0)
	if viewport.y < 520.0:
		y = (40.0 if not game.boss_active else 82.0) + (48.0 if game.point_boost_pickup_controller.is_active() else 0.0)
	var rect := Rect2(Vector2(viewport.x * 0.5 - width * 0.5, y), Vector2(width, 44.0))
	var accent := Color(1.0, 0.36 + pulse * 0.2, 0.14, 0.96)
	game.draw_rect(rect, Color(0.06, 0.02, 0.02, 0.9), true)
	game.draw_rect(rect, accent, false, 2.0 + pulse * 0.8)
	var icon := rect.position + Vector2(23.0, 20.0)
	game.draw_circle(icon, 12.0 + pulse * 1.2, Color(0.32, 0.06, 0.03, 1.0))
	game.draw_colored_polygon(PackedVector2Array([icon + Vector2(0, -9), icon + Vector2(6, 3), icon + Vector2(0, 8), icon + Vector2(-6, 3)]), Color(1.0, 0.74, 0.22))
	game.draw_string(game.font, rect.position + Vector2(43.0, 20.0), "FURIA +50%", HORIZONTAL_ALIGNMENT_LEFT, width - 91.0, 16, Color(1.0, 0.7, 0.42))
	game.draw_string(game.font, rect.position + Vector2(width - 52.0, 20.0), "%02ds" % int(ceil(artifacts.fury_remaining)), HORIZONTAL_ALIGNMENT_RIGHT, 42.0, 15, Color.WHITE)
	var bar_rect := Rect2(rect.position + Vector2(43.0, 29.0), Vector2(width - 55.0, 6.0))
	game.draw_rect(bar_rect, Color(0.1, 0.04, 0.03, 0.94), true)
	game.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), accent, true)


static func _draw_revive_heal_penalty_hud(game: Node2D, viewport: Vector2, anchor: Rect2) -> void :
	if game.revive_heal_penalty_timer <= 0.0:
		return
	var width: float = min(318.0, max(220.0, viewport.x * 0.35))
	var rect = Rect2(anchor.position + Vector2(0.0, anchor.size.y + 88.0), Vector2(width, 30.0))
	var accent = Color(1.0, 0.26, 0.36, 0.92)
	game.draw_rect(rect, Color(0.04, 0.02, 0.025, 0.72), true)
	game.draw_rect(rect, accent, false, 1.5)
	game.draw_string(game.font, rect.position + Vector2(10.0, 20.0), "SACRIFICIO: CURAS -50%%  %.0fs" % ceil(game.revive_heal_penalty_timer), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, game._readable_text_size(11), accent)


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
	var hud_scale: float = game.hud_coagulum_scale
	var size: Vector2 = RTHudLayout.COAGULUM_PANEL_SIZE
	var center: Vector2 = game._coagulum_hud_center(viewport, size.x, 0.0, 0.0)
	var pulse: float = clampf(game.lacerante_coagulum_pulse, 0.0, 1.0)
	var count: int = int(game.lacerante_coagula)
	var crimson := Color(0.94, 0.06, 0.16)
	game.draw_set_transform(center * (1.0 - hud_scale), 0.0, Vector2.ONE * hud_scale)
	var rect := Rect2(center - size * 0.5, size)
	game._draw_combat_panel(rect, crimson.lerp(Color(1.0, 0.7, 0.72), pulse * 0.5), 0.62 + pulse * 0.2)
	if pulse > 0.0:
		game.draw_rect(rect.grow(2.0 + pulse * 3.0), Color(1.0, 0.3, 0.36, pulse * 0.6), false, 2.0)
	# Gota de Coagulo (pulsa ao ganhar).
	var drop_c: Vector2 = rect.position + Vector2(24.0, 26.0)
	var drop_r: float = 10.0 * (1.0 + pulse * 0.35) + sin(game.time_alive * 3.4) * 0.6
	game.draw_circle(drop_c + Vector2(0, 2), drop_r + 6.0, Color(0.4, 0.0, 0.05, 0.45))
	_draw_blood_drop(game, drop_c, drop_r, Color(0.86, 0.03, 0.13), Color(1.0, 0.74, 0.76, 0.9))
	# Contagem e bonus atuais.
	game.draw_string(game.font, rect.position + Vector2(44.0, 16.0), "COÁGULOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.62, 0.66, 0.92))
	var count_size: int = 20 + int(pulse * 6.0)
	game.draw_string(game.font, rect.position + Vector2(44.0, 38.0), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, count_size, Color(1.0, 0.94, 0.94))
	var bonus := "+%s%% DANO  +%s%% VEL." % [("%.1f" % (float(count) * game.LACERANTE_COAGULUM_DAMAGE_RATE * 100.0)).replace(".", ","), ("%.1f" % (float(count) * game.LACERANTE_COAGULUM_ATTACK_SPEED_RATE * 100.0)).replace(".", ",")]
	game.draw_string(game.font, rect.position + Vector2(92.0, 22.0), bonus, HORIZONTAL_ALIGNMENT_LEFT, size.x - 98.0, 9, Color(0.98, 0.84, 0.84, 0.9))
	# Proximo marco: a cada 10 (+1 volta do Q) e a cada 20 (+5 px e +2 cortes).
	var next_mark: int = (count / 10 + 1) * 10
	var progress: float = float(count % 10) / 10.0
	var reward := "+5 PX · +2 CORTES" if next_mark % 20 == 0 else "Q +1 VOLTA"
	var bar := Rect2(rect.position + Vector2(92.0, 31.0), Vector2(size.x - 102.0, 5.0))
	game.draw_rect(bar, Color(0.12, 0.0, 0.02, 0.85), true)
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), crimson, true)
	game.draw_string(game.font, rect.position + Vector2(92.0, 46.0), "%d: %s" % [next_mark, reward], HORIZONTAL_ALIGNMENT_LEFT, size.x - 98.0, 8, Color(1.0, 0.6, 0.64, 0.82))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Gotas voando do alvo executado ate o painel.
	var fly: Array = game.lacerante_execution.coagulum_fly
	if not fly.is_empty():
		var camera: Vector2 = game._camera(viewport)
		var to: Vector2 = center + (drop_c - center) * hud_scale
		for f in fly:
			if float(f["t"]) < 0.0:
				continue
			var p: float = clampf(float(f["t"]) / RTLaceranteExecutionController.COAGULUM_FLY_TIME, 0.0, 1.0)
			var from: Vector2 = Vector2(f["from"]) - camera + Vector2(0, -30)
			var ctrl: Vector2 = from.lerp(to, 0.5) + Vector2(0, -120)
			var e: float = p * p
			var pos: Vector2 = from.lerp(ctrl, e).lerp(ctrl.lerp(to, e), e)
			for k in range(3):
				var tp: float = maxf(0.0, e - float(k + 1) * 0.06)
				var tail: Vector2 = from.lerp(ctrl, tp).lerp(ctrl.lerp(to, tp), tp)
				game.draw_circle(tail, 5.0 - float(k), Color(0.9, 0.04, 0.14, 0.5 - float(k) * 0.14))
			_draw_blood_drop(game, pos, 8.0, Color(0.94, 0.05, 0.15), Color(1.0, 0.8, 0.82, 0.9))


static func _draw_blood_drop(game: Node2D, c: Vector2, r: float, fill: Color, shine: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r * 1.75)])
	for i in range(9):
		var a: float = -0.25 * PI + float(i) / 8.0 * 1.5 * PI
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	game.draw_colored_polygon(pts, fill)
	game.draw_circle(c + Vector2(-r * 0.32, -r * 0.1), r * 0.26, shine)


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
	if game.manto_impulso_shield > 0.0 and game.manto_impulso_timer > 0.0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.3, 0.88, 1.0), 0.54)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "MANTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.46, 0.92, 1.0))
		game.draw_string(game.font, rect.position + Vector2(width - 92, 17), "%.0f HP" % game.manto_impulso_shield, HORIZONTAL_ALIGNMENT_RIGHT, 84, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "%.1fs" % game.manto_impulso_timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.78, 0.94, 1.0))
		y += 44.0
	if game.sutura_gradual_pending > 0.0 and game.sutura_gradual_timer > 0.0:
		var rect = Rect2(origin.x, y, width, 38.0)
		game._draw_combat_panel(rect, Color(0.52, 1.0, 0.62), 0.52)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "SUTURA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.64, 1.0, 0.7))
		game.draw_string(game.font, rect.position + Vector2(width - 92, 17), "+%.0f HP" % game.sutura_gradual_pending, HORIZONTAL_ALIGNMENT_RIGHT, 84, 11, Color.WHITE)
		game.draw_string(game.font, rect.position + Vector2(10, 32), "EM CORTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.98, 0.86))
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
	if game._card_count_by_id(game.CARD_PARADOX_ID) > 0:
		var rect = Rect2(origin.x, y, width, 42.0)
		var pulse: float = clampf(game.paradox_flash, 0.0, 1.0)
		game._draw_combat_panel(rect, Color(1.0, 0.34 + pulse * 0.12, 0.08), 0.62)
		game.draw_string(game.font, rect.position + Vector2(10, 17), "PARADOXO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.64, 0.24))
		var state_label: String = "ATIVO %.1fs" % game.paradox_active_timer if game.paradox_active_timer > 0.0 else ("PRONTO" if game.paradox_ready else "%d/%d" % [game.paradox_charge_hits, game.PARADOX_HITS_REQUIRED])
		game.draw_string(game.font, rect.position + Vector2(width - 88, 17), state_label, HORIZONTAL_ALIGNMENT_RIGHT, 80, 10, Color.WHITE)
		var progress: float = 1.0 if game.paradox_ready or game.paradox_active_timer > 0.0 else clampf(float(game.paradox_charge_hits) / float(game.PARADOX_HITS_REQUIRED), 0.0, 1.0)
		game.draw_rect(Rect2(rect.position + Vector2(10, 30), Vector2(width - 20, 5)), Color(0.08, 0.01, 0.01, 0.86), true)
		game.draw_rect(Rect2(rect.position + Vector2(10, 30), Vector2((width - 20) * progress, 5)), Color(1.0, 0.38, 0.08, 0.94), true)
		game.draw_rect(Rect2(rect.position + Vector2(10 + (width - 20) * progress - 2, 29), Vector2(4, 7)), Color(0.34, 0.94, 1.0, 0.84), true)
		y += 48.0
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
		"Incandescência":
			for i in range(8):
				var heat_ratio: float = float(i + 1) / 8.0
				var x: float = rect.position.x + 14.0 + float(i) * 14.0
				var height: float = 8.0 + sin(game.time_alive * 7.0 + float(i) * 1.2) * 3.0
				var heat_color := Color(1.0, 0.32 + heat_ratio * 0.42, 0.04, 0.9 if heat_ratio <= ratio else 0.16)
				game.draw_line(Vector2(x, rect.end.y - 8.0), Vector2(x + sin(float(i)) * 3.0, rect.end.y - 8.0 - height), heat_color, 3.0, true)
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
	var life_alpha: float = _hud_rect_player_alpha(game, life_rect, viewport, 84.0)
	game.hud_feedback.health_panel(game, life_rect, life_alpha)
	var clock_rect: Rect2 = _clock_rect(game, viewport, false)
	game.hud_feedback.clock_panel(game, clock_rect, _hud_rect_player_alpha(game, clock_rect, viewport, 84.0), false)
	var right_rect = Rect2(viewport.x - 300.0, 16.0, 220.0, 76.0)
	var right_alpha: float = _hud_rect_player_alpha(game, right_rect, viewport, 84.0)
	game.hud_feedback.stats_panel(game, right_rect, right_alpha)

	if game.boss_active and game.boss_hp > 0.0 and not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		var boss_rect = Rect2(game._boss_panel_pos(viewport), Vector2(380.0, 30.0))
		game._draw_scifi_frame(boss_rect, Color(1.0, 0.16, 0.3), 6.0, 0.88)
		_draw_hud_bar(game, boss_rect.position + Vector2(14.0, 11.0), boss_rect.size.x - 28.0, 8.0, game.boss_hp / game.boss_hp_max, Color(1.0, 0.16, 0.28))
		game._draw_centered_outlined(String(game.boss_name), Vector2(boss_rect.get_center().x, boss_rect.end.y + 9.0), 13, game.boss_title_color, Color(0.01, 0.02, 0.025, 0.96), 2)
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
		game.draw_string(game.font, Vector2(viewport.x * 0.5 - 118.0, clock_rect.end.y + 14.0), ping_text, HORIZONTAL_ALIGNMENT_CENTER, 236.0, 12, Color(0.72, 0.96, 1.0, 0.86))

	_draw_point_boost_hud(game, viewport)
	game._draw_lacerante_coagulum_hud(viewport)
	game._draw_unlock_notifications(viewport)


static func _draw_desktop_combat_hud(game: Node2D, viewport: Vector2) -> void :
	var icons = []
	var henry_colossus: bool = game.active_character_key == game.CHARACTER_HENRY and game.mutation_key == "colosso"

	var active_eletrica_secondary = game._active_eletrica_secondary()
	var toggle_ultimate_active = (game.manifestation_key == "prismatica" and game.time_alive - game.last_secondary_time < game.SECONDARY_PRISMATICA_DURATION) or (game.manifestation_key == "eletrica" and active_eletrica_secondary)
	var tp_visual_active = game.tp_cooldown_pending and not game.tp_effects.is_empty()
	var dash_label = "SALTO" if henry_colossus and game.henry_colossus_ability_controller.giant_active else ("ATIVO" if tp_visual_active else "TP")

	var q_charges = 0

	var tp_charges = 0
	if game.manifestation_key == "lacerante":
		tp_charges = game.lacerante_tp_charges

	var ult_color = Color(1.0, 0.78, 0.2, 0.95)
	var ult_label = "ULT"
	var ult_sub = "ULTIMATE"
	if henry_colossus:
		var fury_percent := int(round(game.henry_colossus_ability_controller.fury_ratio() * 100.0))
		ult_label = "%d%%" % fury_percent
		ult_sub = "FURIA"
		ult_color = Color(1.0, 0.34, 0.08, 0.98)

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
	icons.append({"id": "secondary", "label": ult_label, "sub": ult_sub, "active": toggle_ultimate_active, "charges": 0, "bind": game._compact_key_binding_name("secondary") if game._uses_desktop_ui() else "", "color": ult_color, "cd_elapsed": game.henry_colossus_ability_controller.fury if henry_colossus else game.time_alive - game.last_secondary_time, "cd_max": game.henry_colossus_ability_controller.FURY_MAX if henry_colossus else game._secondary_skill_cooldown(), "icon_type": "trident"})
	icons.append({"id": "dash", "label": "SALTO" if henry_colossus and game.henry_colossus_ability_controller.giant_active else dash_label, "active": dash_label != "TP", "sub": "Impacto" if henry_colossus and game.henry_colossus_ability_controller.giant_active else ("Teleporte" if dash_label == "TP" else ""), "charges": tp_charges, "bind": game._compact_key_binding_name("dash") if game._uses_desktop_ui() else "", "color": Color(1.0, 0.58, 0.18) if henry_colossus and game.henry_colossus_ability_controller.giant_active else Color(0.2, 0.9, 1.0), "cd_elapsed": game.time_alive - game.last_dash_time, "cd_max": game._current_dash_cooldown(), "icon_type": "portal"})

	if game.manifestation_key == "lacerante":
		icons.append({"id": "lacerante_empower", "label": "REFORÇO" if game.lacerante_empowered_ready else "+", "sub": "Reforço", "charges": 0, "bind": game._compact_key_binding_name("lacerante_empower") if game._uses_desktop_ui() else "", "color": Color(0.92, 0.03, 0.12, 0.92 if game.lacerante_empowered_ready else 0.68), "cd_elapsed": game._lacerante_exec().reforco_elapsed(), "cd_max": game._lacerante_exec().reforco_total, "icon_type": "star"})
	if henry_colossus:
		var colossus_controller = game.henry_colossus_ability_controller
		icons.append({"id": "lacerante_empower", "label": colossus_controller.reinforcement_label(), "sub": "Retaliacao" if colossus_controller.giant_active else "Reforco", "charges": 0, "bind": game._compact_key_binding_name("lacerante_empower") if game._uses_desktop_ui() else "", "color": Color(1.0, 0.54, 0.16, 0.96), "cd_elapsed": colossus_controller.REINFORCEMENT_COOLDOWN - colossus_controller.reinforcement_cooldown, "cd_max": colossus_controller.REINFORCEMENT_COOLDOWN, "icon_type": "star"})
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

	if game._should_draw_desktop_fps_counter():
		_draw_desktop_fps_hud(game, viewport)


static func _draw_touch_controls(game: Node2D, viewport: Vector2) -> void :
	var henry_colossus: bool = game.active_character_key == game.CHARACTER_HENRY and game.mutation_key == "colosso"
	if game._uses_desktop_ui():
		if game._runtime_visual_budget_active():
			_draw_performance_desktop_combat_hud(game, viewport)
			_draw_performance_desktop_session_buttons(game)
		else:
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
	var joy_alpha: float = _hud_rect_player_alpha(game, Rect2(joy - Vector2(joy_r, joy_r), Vector2(joy_r * 2.0, joy_r * 2.0)), viewport)
	if not game.is_gamepad_active:
		game._draw_virtual_stick(joy, joy_r, joy_alpha)

	var atk_c = game.buttons["attack"].position + game.buttons["attack"].size * 0.5
	var atk_r: float = minf(54.0 * game._attack_scale(), float(game.buttons["attack"].size.x) * 0.5)
	var atk_alpha: float = _hud_rect_player_alpha(game, Rect2(atk_c - Vector2(atk_r, atk_r), Vector2(atk_r * 2.0, atk_r * 2.0)), viewport)
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
	var skill_alpha: float = _hud_rect_player_alpha(game, Rect2(skill_c - Vector2(skill_r, skill_r), Vector2(skill_r * 2.0, skill_r * 2.0)), viewport)
	if not game.is_gamepad_active:
		game._draw_button(skill_c, skill_r, "HAB1", Color(game._manifestation_color().r, game._manifestation_color().g, game._manifestation_color().b, 0.7 * skill_alpha))
	var secondary_c = game.buttons["secondary"].position + game.buttons["secondary"].size * 0.5
	var secondary_r: float = minf(43.0 * game._secondary_scale(), float(game.buttons["secondary"].size.x) * 0.5)
	var secondary_alpha: float = _hud_rect_player_alpha(game, Rect2(secondary_c - Vector2(secondary_r, secondary_r), Vector2(secondary_r * 2.0, secondary_r * 2.0)), viewport)
	var active_eletrica_secondary = game._active_eletrica_secondary()
	var toggle_ultimate_active = not active_eletrica_secondary.is_empty() or not game._active_prismatica_secondary().is_empty()
	var cancel_danger = not active_eletrica_secondary.is_empty() and float(active_eletrica_secondary.get("active_time", 0.0)) >= game.SECONDARY_ELETRICA_DRAIN_DELAY
	var cancel_pulse = 0.5 + sin(game.time_alive * (10.0 if cancel_danger else 7.0)) * 0.5
	if toggle_ultimate_active:
		var outer_alpha = 0.28 + cancel_pulse * (0.24 if cancel_danger else 0.14)
		game.draw_circle(secondary_c, secondary_r + 9.0 + cancel_pulse * 5.0, Color(1.0, 0.0, 0.05, outer_alpha * secondary_alpha))
		game.draw_circle(secondary_c, secondary_r * 0.96, Color(0.4, 0.0, 0.02, 0.92 * secondary_alpha))
	if not game.is_gamepad_active:
		var secondary_label := "%d%%" % int(round(game.henry_colossus_ability_controller.fury_ratio() * 100.0)) if henry_colossus else ("CANCELAR" if toggle_ultimate_active else "ULT")
		game._draw_button(secondary_c, secondary_r, secondary_label, _with_alpha(Color(1.0, 0.34, 0.08, 0.9) if henry_colossus else (Color(1.0, 0.02, 0.06, 0.98) if toggle_ultimate_active else Color(1.0, 0.72, 0.22, 0.72)), secondary_alpha))
	if henry_colossus:
		var fury_ratio: float = game.henry_colossus_ability_controller.fury_ratio()
		game.draw_arc(secondary_c, secondary_r + 9.0, -PI * 0.5, -PI * 0.5 + TAU * fury_ratio, 64, Color(1.0, 0.22, 0.04, 0.98), 5.0, true)
		game._draw_centered("FURIA", secondary_c + Vector2(0, secondary_r + 15.0), 9, Color(1.0, 0.78, 0.42, 0.96))
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
	var dash_alpha: float = _hud_rect_player_alpha(game, Rect2(dash_c - Vector2(dash_r, dash_r), Vector2(dash_r * 2.0, dash_r * 2.0)), viewport)
	var tp_visual_active = game.tp_cooldown_pending and not game.tp_effects.is_empty()
	var dash_label = "SALTO" if henry_colossus and game.henry_colossus_ability_controller.giant_active else ("ATIVO" if tp_visual_active else "TP")
	if not game.is_gamepad_active:
		game._draw_button(dash_c, dash_r, dash_label, _with_alpha(Color(0.42, 0.28, 1.0, 0.88) if dash_label == "VOLTAR" else Color(0.2, 0.85, 1.0, 0.72), dash_alpha))
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
		if henry_colossus:
			var colossus_controller = game.henry_colossus_ability_controller
			if colossus_controller.reinforced_hit_ready or colossus_controller.retaliation_timer > 0.0:
				game.draw_circle(empower_c, empower_r + 7.0 + armed_pulse * 4.0, Color(1.0, 0.42, 0.08, 0.18 + armed_pulse * 0.18))
			if not game.is_gamepad_active:
				game._draw_button(empower_c, empower_r, colossus_controller.reinforcement_label(), Color(1.0, 0.48, 0.12, 0.92 if colossus_controller.reinforcement_ready() else 0.58))
				game._draw_centered("RETALIAR" if colossus_controller.giant_active else "REFORCO", empower_c + Vector2(0, empower_r + 13.0), 9, Color(1.0, 0.78, 0.48, 0.92))
			if not colossus_controller.reinforcement_ready():
				game._draw_cooldown_overlay(empower_c, empower_r, colossus_controller.REINFORCEMENT_COOLDOWN - colossus_controller.reinforcement_cooldown, colossus_controller.REINFORCEMENT_COOLDOWN)
		else:
			if game.lacerante_empowered_ready:
				game.draw_circle(empower_c, empower_r + 7.0 + armed_pulse * 4.0, Color(1.0, 0.02, 0.1, 0.18 + armed_pulse * 0.18))
			if not game.is_gamepad_active:
				game._draw_button(empower_c, empower_r, "R" if game.lacerante_empowered_ready else "+", Color(0.92, 0.03, 0.12, 0.92 if game.lacerante_empowered_ready else 0.68))
				game._draw_centered("REFORCO", empower_c + Vector2(0, empower_r + 13.0), 9, Color(1.0, 0.72, 0.74, 0.92))
			if not game.lacerante_empowered_ready:
				game._draw_cooldown_overlay(empower_c, empower_r, game._lacerante_exec().reforco_elapsed(), game._lacerante_exec().reforco_total)
	game._draw_cooldown_overlay(atk_c, atk_r, game.time_alive - game.last_attack_time, game._current_attack_interval())
	game._draw_cooldown_overlay(skill_c, skill_r, game.time_alive - game.last_skill_time, game._skill_cooldown())
	if not toggle_ultimate_active and not henry_colossus:
		game._draw_cooldown_overlay(secondary_c, secondary_r, game.time_alive - game.last_secondary_time, game._secondary_skill_cooldown())
	if game.tp_cooldown_pending and game.tp_cooldown_release_time <= 0.0 and not game.tp_effects.is_empty():
		var active_tp: Dictionary = game.tp_effects[0]
		game._draw_cooldown_overlay(dash_c, dash_r, float(active_tp.get("max", 1.0)) - float(active_tp.get("life", 0.0)), float(active_tp.get("max", 1.0)))
	else:
		game._draw_cooldown_overlay(dash_c, dash_r, game.time_alive - game.last_dash_time, game._current_dash_cooldown())
	game._draw_hud_rect_button(game.buttons["pause"], "II", _with_alpha(Color(0.0, 1.0, 0.82), _hud_rect_player_alpha(game, game.buttons["pause"], viewport, 72.0)))
	if game.buttons.has("shop_manual"):
		var shop_rect: Rect2 = game.buttons["shop_manual"]
		var shop_ready: bool = game._affordable_card_count() > 0 and game.mode == "game" and game._manual_shop_available()
		var shop_grace: bool = game._manual_shop_grace_active()
		var bargain_pending: bool = game.has_method("_bargain_pending_discount_remaining") and game._bargain_pending_discount_remaining() > 0.0
		var shop_cooldown: float = game._manual_shop_cooldown_remaining()
		var shop_accent = Color(1.0, 0.78, 0.22) if bargain_pending else Color(0.3, 1.0, 0.62) if shop_grace else Color(0.0, 1.0, 0.82) if shop_ready else Color(0.38, 0.42, 0.46)
		var shop_alpha: float = _hud_rect_player_alpha(game, shop_rect, viewport, 82.0)
		var shop_label: String = "REABRIR" if shop_grace else "LOJA"
		var shop_top: String = game._manual_shop_status_text()
		if shop_top == "":
			# As cartas compraveis ja aparecem no painel de pontos; aqui so status.
			shop_top = ""
		game._draw_hud_rect_button(shop_rect, shop_label, _with_alpha(shop_accent, shop_alpha))
		if shop_top != "":
			game._draw_centered(shop_top, shop_rect.get_center() + Vector2(0, -29), 11 if shop_top.length() > 14 else 12, Color(shop_accent.r, shop_accent.g, shop_accent.b, 0.96 * shop_alpha))
		if shop_cooldown > 0.0:
			var cooldown_total: float = maxf(0.01, game.SHOP_MANUAL_REOPEN_COOLDOWN)
			var progress: float = clampf(1.0 - shop_cooldown / cooldown_total, 0.0, 1.0)
			var ring_rect: Rect2 = shop_rect.grow(4.0)
			game.draw_arc(ring_rect.get_center(), maxf(ring_rect.size.x, ring_rect.size.y) * 0.5, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color(0.72, 0.9, 1.0, 0.78 * shop_alpha), 3.0, true)
		elif shop_grace:
			var grace_progress: float = clampf(game._manual_shop_grace_remaining() / maxf(0.01, game.SHOP_MANUAL_ACCIDENTAL_CLOSE_GRACE), 0.0, 1.0)
			game.draw_arc(shop_rect.get_center(), maxf(shop_rect.size.x, shop_rect.size.y) * 0.56, -PI * 0.5, -PI * 0.5 + TAU * grace_progress, 48, Color(0.46, 1.0, 0.62, 0.86 * shop_alpha), 3.0, true)
		elif game.shop_manual_cooldown_pulse > 0.0:
			var pulse_alpha: float = clampf(game.shop_manual_cooldown_pulse, 0.0, 1.0) * shop_alpha
			game.draw_rect(shop_rect.grow(5.0), Color(0.0, 1.0, 0.82, 0.22 * pulse_alpha), false, 2.0)
	if game.boss_ready and not game.boss_active and not game.boss_dead and game.experimental_phase_controller.should_show_boss_button():
		var boss_rect: Rect2 = game.buttons["boss"]
		var boss_alpha: float = _hud_rect_player_alpha(game, boss_rect, viewport, 82.0)
		game._draw_centered("BOSS PRONTO", boss_rect.get_center() + Vector2(0, -31), 16, Color(1.0, 0.82, 0.24, boss_alpha))
		game._draw_hud_rect_button(boss_rect, "BOSS", Color(1.0, 0.52, 0.16, boss_alpha))
	if game._ability_cancel_active():
		game._draw_ability_cancel_button(viewport)
	game._draw_dance_wheel(viewport)
	game._draw_player_dance_emote(game._camera(viewport))


static func _draw_performance_desktop_combat_hud(game: Node2D, viewport: Vector2) -> void:
	var henry_colossus: bool = game.active_character_key == game.CHARACTER_HENRY and game.mutation_key == "colosso"
	var active_eletrica: Dictionary = game._active_eletrica_secondary()
	var secondary_active: bool = not active_eletrica.is_empty() or not game._active_prismatica_secondary().is_empty()
	var dash_label := "SALTO" if henry_colossus and game.henry_colossus_ability_controller.giant_active else "TP"
	var entries: Array[Dictionary] = [
		{"label": "ATK", "bind": game._compact_key_binding_name("attack"), "elapsed": game.time_alive - game.last_attack_time, "cooldown": game._current_attack_interval(), "color": Color(1.0, 0.24, 0.28)},
		{"label": "HAB 1", "bind": game._compact_key_binding_name("skill"), "elapsed": game.time_alive - game.last_skill_time, "cooldown": game._skill_cooldown(), "color": Color(0.2, 0.75, 1.0)},
		{"label": "%d%%" % int(round(game.henry_colossus_ability_controller.fury_ratio() * 100.0)) if henry_colossus else ("CANCELAR" if secondary_active else "ULT"), "bind": game._compact_key_binding_name("secondary"), "elapsed": game.henry_colossus_ability_controller.fury if henry_colossus else (game._secondary_skill_cooldown() if secondary_active else game.time_alive - game.last_secondary_time), "cooldown": game.henry_colossus_ability_controller.FURY_MAX if henry_colossus else game._secondary_skill_cooldown(), "color": Color(1.0, 0.34, 0.08) if henry_colossus else (Color(1.0, 0.18, 0.24) if secondary_active else Color(1.0, 0.78, 0.2))},
		{"label": dash_label, "bind": game._compact_key_binding_name("dash"), "elapsed": game.time_alive - game.last_dash_time, "cooldown": game._current_dash_cooldown(), "color": Color(0.2, 0.9, 1.0)}
	]
	if game.manifestation_key == "lacerante":
		entries.append({"label": "REFORCO" if game.lacerante_empowered_ready else "+", "bind": game._compact_key_binding_name("lacerante_empower"), "elapsed": game._lacerante_exec().reforco_elapsed(), "cooldown": game._lacerante_exec().reforco_total, "color": Color(0.92, 0.03, 0.12)})
	elif henry_colossus:
		var colossus_controller = game.henry_colossus_ability_controller
		entries.append({"label": colossus_controller.reinforcement_label(), "bind": game._compact_key_binding_name("lacerante_empower"), "elapsed": colossus_controller.REINFORCEMENT_COOLDOWN - colossus_controller.reinforcement_cooldown, "cooldown": colossus_controller.REINFORCEMENT_COOLDOWN, "color": Color(1.0, 0.5, 0.14)})
	var width := 84.0
	var height := 48.0
	var gap := 8.0
	var total_width := width * entries.size() + gap * maxi(0, entries.size() - 1)
	var start := Vector2(viewport.x * 0.5 - total_width * 0.5, viewport.y - height - 20.0)
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var rect := Rect2(start + Vector2(float(index) * (width + gap), 0.0), Vector2(width, height))
		var color: Color = entry["color"]
		var cooldown: float = maxf(0.01, float(entry["cooldown"]))
		var ratio: float = clampf(float(entry["elapsed"]) / cooldown, 0.0, 1.0)
		game.draw_rect(rect, Color(0.015, 0.025, 0.035, 0.9), true)
		game.draw_string(game.font, rect.position + Vector2(7.0, 28.0), "%s  %s" % [String(entry["bind"]), String(entry["label"])], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 14.0, 10, Color.WHITE)
		game.draw_rect(Rect2(rect.position + Vector2(6.0, rect.size.y - 6.0), Vector2((rect.size.x - 12.0) * ratio, 2.0)), color, true)
	if game._should_draw_desktop_fps_counter():
		game.draw_string(game.font, Vector2(viewport.x - 94.0, viewport.y - 22.0), "%d FPS" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_RIGHT, 76.0, 11, Color(0.2, 0.92, 1.0))


static func _draw_performance_desktop_session_buttons(game: Node2D) -> void:
	var entries: Array[Dictionary] = []
	if game.buttons.has("pause"):
		entries.append({"rect": game.buttons["pause"], "label": "II", "color": Color(0.0, 1.0, 0.82)})
	if game.buttons.has("shop_manual"):
		var shop_label := "REABRIR" if game._manual_shop_grace_active() else "LOJA"
		var shop_color := Color(0.0, 1.0, 0.82) if game._affordable_card_count() > 0 else Color(0.38, 0.42, 0.46)
		entries.append({"rect": game.buttons["shop_manual"], "label": shop_label, "color": shop_color})
	if game.boss_ready and not game.boss_active and not game.boss_dead and game.buttons.has("boss") and game.experimental_phase_controller.should_show_boss_button():
		entries.append({"rect": game.buttons["boss"], "label": "BOSS", "color": Color(1.0, 0.52, 0.16)})
	for entry in entries:
		var rect: Rect2 = entry["rect"]
		var color: Color = entry["color"]
		game.draw_rect(rect, Color(0.015, 0.025, 0.035, 0.9), true)
		game.draw_string(game.font, rect.position + Vector2(5.0, rect.size.y * 0.5 + 5.0), String(entry["label"]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 10, color)


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

	if game.shop_controller.manual_dev_access():
		var shop_rect = Rect2(game._manual_shop_pos(viewport), Vector2(104, 42))
		game.buttons["shop_manual"] = shop_rect
		var c_shop = Color(1, 1, 0, 0.6) if game.edit_layout_selected == "shop_manual" else Color(0.0, 1.0, 0.82, 0.3)
		game.draw_rect(shop_rect, c_shop, false, 2)
		game._draw_centered("LOJA QA", shop_rect.get_center(), 14, Color.WHITE)
	else:
		game.buttons.erase("shop_manual")

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
	var coag_size = RTHudLayout.coagulum_panel_size(game.hud_coagulum_scale)
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
		var next_rate: float = game._revival_life_sacrifice_rate_for_dead_count(game._team_revival_dead_count() + 1) * 100.0
		var info2: String = "FRAGMENTOS %d/%d  |  %ds  |  cada caido adicional eleva o sacrificio para %.0f%%" % [game.revival_fragments_collected, total, remaining, next_rate]
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
