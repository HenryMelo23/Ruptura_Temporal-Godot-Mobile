extends RefCounted

# Draws through the main CanvasItem; state stays on the host during migration.


static func _draw_enemies(game: Node2D, camera: Vector2) -> void :
	for enemy in game.enemies:
		if not game._world_point_in_view(Vector2(enemy.get("pos", Vector2.ZERO)), camera, 180.0):
			continue
		var pos: Vector2 = enemy["pos"] - camera
		var tex = game._enemy_texture(enemy)
		var size = game._enemy_draw_size(enemy)
		var draw_pos = pos + game._enemy_visual_offset(enemy)
		var alpha = float(enemy.get("alpha", 1.0))
		var modulate_color = Color(1, 1, 1, alpha)
		if enemy["type"] == game.ENEMY_ATIRADOR:
			modulate_color = Color(0.7, 0.86, 1.0, alpha)
		elif enemy["type"] == game.ENEMY_KAMIKAZE:
			modulate_color = Color(1.0, 1.0, 1.0, alpha)
			if sin(game.time_alive * 12.0) > 0.0:
				modulate_color = Color(1.0, 0.92, 0.9, alpha)
		elif enemy["type"] == game.ENEMY_DEVOTO:
			modulate_color = Color(0.76, 1.0, 0.56, alpha)
		elif enemy["type"] == game.ENEMY_INCENSARIO:
			modulate_color = Color(0.88, 0.72, 1.0, alpha)
		elif enemy["type"] == game.ENEMY_GUARDIAO:
			modulate_color = Color(0.7, 0.76, 0.62, alpha)
		elif enemy["type"] == game.ENEMY_COUT_ATTACK_SPEED:
			modulate_color = Color(1.0, 0.66, 0.18, alpha)
		elif enemy["type"] == game.ENEMY_SHIELD_REFLECTOR:
			modulate_color = Color(0.62, 0.92, 1.0, alpha)
		elif enemy["type"] == game.ENEMY_PYRO_PENGUIN:
			modulate_color = Color(1.0, 1.0, 1.0, alpha)
		elif enemy["type"] == game.ENEMY_NEXUS_CARTOGRAPHER:
			modulate_color = Color(0.92, 0.24, 0.78, alpha)
		elif enemy["type"] == game.ENEMY_NEXUS_CHRONOPHAGE:
			modulate_color = Color(1.0, 0.68, 0.16, alpha)
		elif enemy["type"] == game.ENEMY_NEXUS_REFRACTOR:
			modulate_color = Color(0.24, 0.88, 1.0, alpha)
		elif enemy["type"] == game.ENEMY_NEXUS_WEAVER:
			modulate_color = Color(0.2, 1.0, 0.64, alpha)
		elif enemy["type"] == game.ENEMY_NEXUS_ECHO:
			modulate_color = Color(1.0, 0.34, 0.68, alpha * 0.82)
		elif enemy["type"] == game.ENEMY_MIASMA_EEL:
			modulate_color = Color(0.58, 1.0, 0.78, alpha)
		elif enemy["type"] == game.ENEMY_LODARIO:
			modulate_color = Color(0.86, 0.7, 0.46, alpha)
		elif enemy["type"] == game.ENEMY_FOSSIL_PUSTULE:
			modulate_color = Color(1.0, 0.62, 0.32, alpha)
		elif enemy["type"] == game.ENEMY_CHRONAL_LEECH:
			modulate_color = Color(0.92, 0.42, 0.72, alpha)
		elif enemy["type"] == game.ENEMY_CINERIDO:
			modulate_color = Color(1.0, 0.7, 0.42, alpha)
		elif enemy["type"] == game.ENEMY_PANGOLIRO:
			modulate_color = Color(1.0, 0.82, 0.48, alpha)
			if float(enemy.get("phase7_vulnerable", 0.0)) > 0.0:
				modulate_color = Color(1.0, 0.52, 0.22, alpha)
		elif enemy["type"] == game.ENEMY_CORVOL:
			modulate_color = Color(0.82, 0.82, 0.76, alpha)
		if enemy["type"] == game.ENEMY_MIASMA_EEL and float(enemy.get("eel_relocating", 0.0)) > 0.0:
			game._draw_miasma_eel_relocation_path(enemy, camera)
			continue
		if enemy["type"] == game.ENEMY_CHRONAL_LEECH:
			game._draw_sanguessuga_state(enemy, camera)
		var visual_size: Vector2 = size
		if enemy["type"] == game.ENEMY_PANGOLIRO and String(enemy.get("phase7_state", "walk")) == "roll":
			visual_size *= game.PHASE7_PANGOLIRO_ROLL_VISUAL_SCALE
		var reconstitute_ratio: float = clamp(float(enemy.get("reconstitute_time", 0.0)) / game.COUT_AS_RECONSTITUTE_TIME, 0.0, 1.0)
		if reconstitute_ratio > 0.0:
			var rebuild = 1.0 - reconstitute_ratio
			visual_size *= 0.72 + rebuild * 0.28
			draw_pos += Vector2(sin(game.time_alive * 36.0 + int(enemy["uid"])) * 4.0, -14.0 * reconstitute_ratio)
			modulate_color = modulate_color.lerp(Color(1.0, 0.58, 0.14, alpha), 0.55)
			for shard in range(5):
				var angle: float = game.time_alive * 4.5 + float(shard) * TAU / 5.0 + int(enemy["uid"]) * 0.01
				var shard_pos: Vector2 = pos + Vector2.from_angle(angle) * (18.0 + reconstitute_ratio * 42.0)
				game.draw_line(shard_pos, draw_pos, Color(1.0, 0.48, 0.1, 0.3 + reconstitute_ratio * 0.34), 2.0)
		var enemy_flip: bool = game._enemy_should_flip(enemy)
		game._draw_dynamic_shadow(tex, pos, visual_size, enemy_flip, 0.4 * alpha)
		var is_attack_target = game._attack_target_is_enemy(int(enemy["uid"]))
		if is_attack_target:
			game._draw_attack_target_marker(draw_pos + Vector2(0, visual_size.y * 0.3), visual_size.x * 0.43, game.locked_target_kind == "enemy" and game.locked_target_uid == int(enemy["uid"]))

		if not game._active_prismatica_secondary().is_empty() and enemy["pos"].distance_to(game.player_pos) < 900.0:
			var t = float(Time.get_ticks_msec()) * 0.001
			var hue = fmod(t * 0.8 + int(enemy["uid"]) * 0.15, 1.0)
			var c = Color.from_hsv(hue, 1.0, 1.0, 0.5)

			game.draw_circle(draw_pos + Vector2(0, 16), 46, Color(c.r, c.g, c.b, 0.18))
			modulate_color = c
		if is_attack_target:
			modulate_color = modulate_color.lerp(Color(1.0, 0.92, 0.34, alpha), 0.48)

		game._draw_phase7_enemy_vfx(enemy, camera, pos, draw_pos, visual_size)
		if enemy["type"] == game.ENEMY_PANGOLIRO and String(enemy.get("phase7_state", "walk")) == "roll":
			var roll_dir: Vector2 = Vector2(enemy.get("phase7_roll_dir", enemy.get("facing_dir", Vector2.LEFT))).normalized()
			var roll_sign: float = 1.0 if roll_dir.x >= 0.0 else -1.0
			var roll_turns: float = game.PHASE7_PANGOLIRO_ROLL_VISUAL_TURNS
			var roll_rotation: float = float(enemy.get("phase7_timer", 0.0)) / maxf(0.01, game.PHASE7_PANGOLIRO_ROLL_TIME) * TAU * roll_turns * roll_sign
			game._draw_entity_stretched_rotated(tex, draw_pos, visual_size, roll_rotation, modulate_color, enemy_flip)
		else:
			game._draw_entity(tex, draw_pos, visual_size, modulate_color, enemy_flip)
		if float(enemy.get("crepuscular_ocaso_mark", 0.0)) > 0.0:
			game._draw_crepuscular_ocaso_cracks(draw_pos, visual_size, int(enemy.get("uid", 0)), float(enemy.get("crepuscular_ocaso_mark", 0.0)))
		var enemy_bar_pos = draw_pos + Vector2(-30.0, -visual_size.y * 0.55 - 10.0)
		var enemy_hp_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
		var tesla_bar_shock = float(enemy.get("tesla_shock", 0.0))
		var enemy_bar_draw_pos: Vector2 = enemy_bar_pos
		if tesla_bar_shock > 0.0:
			var shake_power: float = clamp(tesla_bar_shock / 0.42, 0.0, 1.0)
			enemy_bar_draw_pos += Vector2(sin(game.time_alive * 90.0 + int(enemy["uid"])) * 2.8, cos(game.time_alive * 76.0 + int(enemy["uid"]) * 0.37) * 1.8) * shake_power
			game._draw_tesla_health_bar_fx(enemy_bar_draw_pos, 60.0, enemy_hp_ratio, tesla_bar_shock, int(enemy["uid"]))
		else:
			game._draw_enemy_health_bar(enemy, enemy_bar_draw_pos, 60.0, enemy_hp_ratio)
		if bool(enemy.get("sanguinaria_hunt", false)):
			game._draw_sanguinaria_hunt_mark(enemy_bar_draw_pos, 60.0)
		var static_stacks = int(enemy.get("eletrica_static_stacks", 0))
		var static_timer = float(enemy.get("eletrica_static_timer", 0.0))
		if game.manifestation_key == "eletrica" and static_stacks > 0 and static_timer > 0.0:
			game._draw_eletrica_static_indicator(game, enemy_bar_draw_pos + Vector2(30, -10), static_stacks, static_timer, int(enemy["uid"]))
		if game.execute_threshold > 0.0:
			game._draw_collector_threshold(enemy_bar_draw_pos, 60.0, game.execute_threshold, enemy_hp_ratio)
		if enemy["type"] == game.ENEMY_AGGLOMERATOR:
			for i in range(8):
				var ang = game.time_alive * 5.0 + i * TAU / 8.0
				game.draw_circle(pos + Vector2(cos(ang), sin(ang)) * 44.0, 3 + int(i % 3), Color(0.48, 0.48, 0.56, 0.75))
		if enemy["type"] == game.ENEMY_CURATER:
			game.draw_arc(pos, 92, 0, TAU, 48, Color(0.32, 1.0, 0.42, 0.35), 2)
			for i in range(7):
				var px = pos.x + cos(i * 1.7) * 30.0 + sin(game.time_alive * 2.0 + i) * 2.0
				var py = pos.y + 26.0 + sin(i * 1.3) * 8.0
				game.draw_line(Vector2(px, py), Vector2(px, py - 10 - (i % 3) * 3), Color(0.28, 0.86, 0.36), 2)
				game.draw_circle(Vector2(px + 3, py - 12), 4, Color(0.5, 1.0, 0.58))
		if enemy["type"] == game.ENEMY_PROJECTOR:
			var r = 24.0 + sin(game.time_alive * 9.0) * 3.0
			game.draw_arc(pos, r, 0, TAU, 40, Color(1.0, 0.76, 0.28, 0.86), 2)
			game.draw_circle(pos + Vector2(0, -12), 5, Color(1.0, 0.96, 0.62, 0.95))
		if enemy["type"] == game.ENEMY_CRYSTAL:
			game._draw_hex(pos, 38.0 + sin(game.time_alive * 4.0) * 8.0, Color(0.0, 0.78, 1.0, 0.7))
		if enemy["type"] == game.ENEMY_LARAPIO and int(enemy.get("stolen", 0)) > 0:
			var bag_pulse = 0.5 + 0.5 * sin(game.time_alive * 8.0)
			game.draw_circle(draw_pos + Vector2(23, -21), 11.0 + bag_pulse * 2.0, Color(1.0, 0.78, 0.18, 0.72))
			game.draw_circle(draw_pos + Vector2(23, -21), 5.0, Color(0.45, 0.24, 0.04, 0.88))
			game._draw_centered(str(int(enemy.get("stolen", 0))), draw_pos + Vector2(23, -39), 11, Color(1.0, 0.92, 0.42, 0.92))
		if enemy["type"] == game.ENEMY_LARAPIO and int(enemy.get("stolen", 0)) > 0 and enemy["hp"] < enemy["max_hp"] * 0.7:
			var ratio = clamp(float(enemy.get("portal", 0.0)) / game.LARAPIO_PORTAL_TIME, 0.0, 1.0)
			var portal_center = pos + Vector2(0, 28)
			var portal_radius: float = 18.0 + 42.0 * ratio
			var portal_tilt = -0.18 + sin(game.time_alive * 1.7 + int(enemy.get("uid", 0))) * 0.035
			game.draw_set_transform(portal_center, portal_tilt, Vector2(1.0 + ratio * 0.2, 0.34 + ratio * 0.06))
			game.draw_circle(Vector2.ZERO, portal_radius, Color(0.15, 0.0, 0.25, 0.44))
			game.draw_arc(Vector2.ZERO, portal_radius + 3.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 48, Color(0.75, 0.2, 1.0, 0.82), 3.2)
			game.draw_arc(Vector2.ZERO, portal_radius * 0.68, game.time_alive * 2.4, game.time_alive * 2.4 + PI * 1.45, 34, Color(1.0, 0.74, 0.32, 0.56), 2.0)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if enemy["type"] == game.ENEMY_COUT_ATTACK_SPEED:
			var stacks = int(enemy.get("as_stack", 0))
			var pulse = 0.5 + 0.5 * sin(game.time_alive * 9.0 + int(enemy["uid"]))
			var aura_alpha = 0.12 + stacks * 0.035
			var rebuild_pulse: float = clamp(float(enemy.get("reconstitute_pulse", 0.0)) / 0.55, 0.0, 1.0)
			game.draw_circle(pos, game.COUT_AS_AURA_RADIUS + rebuild_pulse * 18.0, Color(1.0, 0.5, 0.08, min(0.3, aura_alpha + rebuild_pulse * 0.08)))
			if rebuild_pulse > 0.0:
				game.draw_arc(pos, game.COUT_AS_AURA_RADIUS + 12.0 + rebuild_pulse * 28.0, - game.time_alive * 5.0, TAU - game.time_alive * 5.0, 64, Color(1.0, 0.76, 0.2, 0.88 * rebuild_pulse), 4.0)
			game.draw_arc(pos, 36.0 + pulse * 5.0, - game.time_alive * 2.4, TAU - game.time_alive * 2.4, 32, Color(1.0, 0.72, 0.16, 0.82), 2.6)
			if stacks > 0:
				game._draw_centered("x%d" % stacks, pos + Vector2(0, -66), 15, Color(1.0, 0.86, 0.34, 0.92))
		if enemy["type"] == game.ENEMY_INCENSARIO and float(enemy.get("prepare", 0.0)) > 0.0:
			var target = Vector2(enemy.get("miasma_target", game.player_pos)) - camera
			game.draw_circle(target, 64.0, Color(0.42, 0.72, 0.08, 0.13))
			game.draw_arc(target, 64.0, 0, TAU, 40, Color(0.72, 1.0, 0.28, 0.82), 3.0)
		if enemy["type"] == game.ENEMY_GUARDIAO:
			var shield_dir = Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
			game.draw_arc(pos + shield_dir * 26.0, 42.0, shield_dir.angle() - PI * 0.45, shield_dir.angle() + PI * 0.45, 24, Color(0.78, 0.92, 0.56, 0.82), 5.0)
		if enemy["type"] == game.ENEMY_SHIELD_REFLECTOR:
			var shield_dir = Vector2(enemy.get("facing_dir", Vector2.LEFT)).normalized()
			if game._shield_reflector_active(enemy):
				var flash = clamp(float(enemy.get("shield_flash", 0.0)) / 0.32, 0.0, 1.0)
				var shield_color = Color(0.76, 0.96, 1.0, 0.76 + flash * 0.22)
				game.draw_arc(pos + shield_dir * 28.0, 44.0 + flash * 9.0, shield_dir.angle() - PI * 0.46, shield_dir.angle() + PI * 0.46, 28, shield_color, 5.0 + flash * 3.0)
				game.draw_line(pos + shield_dir * 32.0 + shield_dir.orthogonal() * 24.0, pos + shield_dir * 32.0 - shield_dir.orthogonal() * 24.0, Color(0.86, 1.0, 1.0, 0.52), 2.0)
			else:
				var speed_pulse = 0.5 + 0.5 * sin(game.time_alive * 10.0 + int(enemy.get("uid", 0)))
				game.draw_line(pos - shield_dir * (30.0 + speed_pulse * 12.0), pos - shield_dir * 58.0, Color(1.0, 0.58, 0.18, 0.5), 3.0)
		if enemy["type"] == game.ENEMY_PYRO_PENGUIN:
			var flame_pulse = 0.5 + 0.5 * sin(game.time_alive * 9.0 + int(enemy["uid"]))
			game.draw_circle(draw_pos + Vector2(0, 24), 25.0 + flame_pulse * 5.0, Color(1.0, 0.12, 0.02, 0.13))
			game.draw_arc(draw_pos, 45.0, game.time_alive * 2.2, game.time_alive * 2.2 + PI * 1.35, 30, Color(1.0, 0.44, 0.08, 0.82), 3.0)
		if game.current_phase == 4:
			game._draw_phase4_enemy_identity(enemy, draw_pos, size)
		if int(enemy.get("laceracao", 0)) > 0:
			game._draw_centered("x%d" % int(enemy["laceracao"]), pos + Vector2(28, -36), 14, Color(1.0, 0.2, 0.25))
		if float(enemy.get("eclipsada_weak_time", 0.0)) > 0.0:
			game._draw_eclipsada_weakpoint(enemy, camera)
		if float(enemy.get("resonant_stun_notes", 0.0)) > 0.0:
			var note_time = game.time_alive * 8.0
			var note_text = "â™«" if int(note_time) % 2 == 0 else "â™ª"
			game._draw_centered(note_text, draw_pos + Vector2(0, -66.0 + sin(note_time) * 6.0), 24, Color(1.0, 0.74, 0.2, 0.9))


static func _draw_crepuscular_player_aura(game: Node2D, camera: Vector2, player_screen: Vector2) -> void:
	var phase: String = String(game.aura_state.get("crepuscular_phase", "alvorada"))
	var timer_ratio: float = clampf(float(game.aura_state.get("crepuscular_phase_timer", 0.0)) / game.AuraSystem.CREPUSCULAR_PHASE_TIME, 0.0, 1.0)
	var approach: float = 1.0 - timer_ratio
	var dawn = Color(1.0, 0.88, 0.44, 0.0)
	var dusk = Color(0.82, 0.22, 1.0, 0.0)
	var base: Color = dawn.lerp(dusk, approach) if phase == "alvorada" else dusk.lerp(dawn, approach)
	var flash: float = clampf(game.crepuscular_phase_flash_timer / 0.95, 0.0, 1.0)
	for ring in range(4):
		var radius: float = 38.0 + ring * 14.0 + sin(game.time_alive * (2.1 + ring * 0.25)) * (2.0 + approach * 4.0)
		var alpha: float = 0.16 + approach * 0.16 + flash * 0.18 - ring * 0.025
		game.draw_arc(player_screen, radius, -game.time_alive * (0.75 + ring * 0.18), TAU - game.time_alive * (0.75 + ring * 0.18), 58, Color(base.r, base.g, base.b, maxf(0.03, alpha)), 2.0 + flash)
	if game.crepuscular_spotlight_timer > 0.0:
		var ratio: float = clampf(game.crepuscular_spotlight_timer / 0.7, 0.0, 1.0)
		var top: Vector2 = player_screen + Vector2(0, -360.0)
		var beam = PackedVector2Array([
			top + Vector2(-44.0 * ratio, 0.0),
			top + Vector2(44.0 * ratio, 0.0),
			player_screen + Vector2(52.0, 46.0),
			player_screen + Vector2(-52.0, 46.0)
		])
		game.draw_polygon(beam, PackedColorArray([Color(1.0, 0.93, 0.52, 0.0), Color(1.0, 0.93, 0.52, 0.0), Color(1.0, 0.93, 0.52, 0.22 * ratio), Color(1.0, 0.93, 0.52, 0.22 * ratio)]))
		game.draw_circle(player_screen, 54.0 + sin(game.time_alive * 18.0) * 3.0, Color(1.0, 0.86, 0.35, 0.18 * ratio))


static func _draw_resonant_player_beat(game: Node2D, camera: Vector2) -> void :
	var center: Vector2 = game.player_pos - camera + Vector2(0, -4)
	var beat: float = fposmod(game.time_alive, game.RESONANT_BEAT_INTERVAL)
	var beat_progress: float = beat / game.RESONANT_BEAT_INTERVAL
	var cycle_progress: float = fposmod(game.time_alive, game.RESONANT_BEAT_INTERVAL * 4.0) / (game.RESONANT_BEAT_INTERVAL * 4.0)
	var to_hit: float = minf(beat, game.RESONANT_BEAT_INTERVAL - beat) / maxf(0.001, game.RESONANT_PERFECT_WINDOW)
	var perfect_ratio: float = 1.0 - clampf(to_hit, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 5.5)
	var radius: float = 82.0 + perfect_ratio * 11.0
	var alpha: float = 0.2 + perfect_ratio * 0.54
	game.draw_circle(center, radius + 18.0, Color(0.18, 0.72, 1.0, 0.03 + perfect_ratio * 0.035))
	game.draw_circle(center, 44.0 + perfect_ratio * 10.0, Color(1.0, 0.78, 0.18, 0.025 + perfect_ratio * 0.05))
	game.draw_arc(center, radius, 0.0, TAU, 96, Color(1.0, 0.78, 0.18, alpha), 2.0 + perfect_ratio * 1.9)
	game.draw_arc(center, radius + 12.0 + pulse * 3.0, 0.0, TAU, 96, Color(0.46, 0.94, 1.0, 0.16 + perfect_ratio * 0.26), 1.5)
	for i in range(4):
		var angle = - PI * 0.5 + TAU * (float(i) / 4.0)
		var gate_alpha = 0.34 + (0.46 if perfect_ratio > 0.0 and i == int(floor(cycle_progress * 4.0)) else 0.0)
		var gate_radius = radius + 2.0 + perfect_ratio * 8.0
		game.draw_arc(center, gate_radius, angle - 0.18, angle + 0.18, 18, Color(1.0, 0.96, 0.48, gate_alpha), 5.0)
		var note_pos = center + Vector2.from_angle(angle) * (gate_radius + 15.0)
		game.draw_circle(note_pos, 4.5 + perfect_ratio * 2.0, Color(1.0, 0.82, 0.22, 0.46 + perfect_ratio * 0.34))
	for i in range(16):
		var angle = - PI * 0.5 + TAU * (float(i) / 16.0)
		var wave = sin(game.time_alive * 3.6 + float(i) * 0.9)
		var inner: Vector2 = center + Vector2.from_angle(angle) * (radius - 8.0 + wave * 2.0)
		var outer: Vector2 = center + Vector2.from_angle(angle) * (radius + 12.0 + wave * 8.0 + perfect_ratio * 8.0)
		game.draw_line(inner, outer, Color(0.52, 0.94, 1.0, 0.16 + perfect_ratio * 0.3), 1.2)
	var hand_angle = - PI * 0.5 + cycle_progress * TAU
	var hand_end: Vector2 = center + Vector2.from_angle(hand_angle) * (radius + 22.0)
	game.draw_line(center, hand_end, Color(1.0, 0.86, 0.24, 0.28 + perfect_ratio * 0.36), 1.4 + perfect_ratio * 1.2)
	game.draw_circle(hand_end, 5.0 + perfect_ratio * 4.0 + pulse * perfect_ratio * 1.5, Color(1.0, 0.92, 0.3, 0.66 + perfect_ratio * 0.28))
	var beat_wave = radius * (0.52 + beat_progress * 0.62)
	game.draw_arc(center, beat_wave, 0.0, TAU, 72, Color(1.0, 0.96, 0.52, (0.26 + perfect_ratio * 0.36) * (1.0 - beat_progress * 0.45)), 2.0)
	if perfect_ratio > 0.05:
		game.draw_arc(center, radius + 24.0 + perfect_ratio * 8.0, - game.time_alive * 1.3, - game.time_alive * 1.3 + TAU * 0.62, 60, Color(1.0, 0.96, 0.52, perfect_ratio * 0.48), 2.8)


static func _draw_tesla_enemy_crown(game: Node2D, center: Vector2, shock_time: float, uid: int) -> void :
	var alpha: float = clamp(shock_time / 0.42, 0.18, 1.0)
	var radius: float = 34.0 + sin(game.time_alive * 12.0 + uid) * 3.0
	game.draw_arc(center, radius, game.time_alive * 2.2, game.time_alive * 2.2 + TAU * 0.72, 42, Color(0.35, 1.0, 1.0, 0.44 * alpha), 2.2)
	for i in range(5):
		var ang: float = game.time_alive * 4.6 + float(i) * TAU / 5.0 + float(uid) * 0.017
		var a: Vector2 = center + Vector2.from_angle(ang) * (radius * 0.55)
		var b: Vector2 = center + Vector2.from_angle(ang + 0.36) * (radius + 8.0)
		game.draw_line(a, b, Color(1.0, 1.0, 1.0, 0.44 * alpha), 1.5, true)


static func _draw_gravitante_enemy_distortion(game: Node2D, enemy: Dictionary, center_world: Vector2, camera: Vector2, radius: float, progress: float, intensity: float) -> void :
	var enemy_pos: Vector2 = enemy["pos"]
	var dist = enemy_pos.distance_to(center_world)
	var edge_ratio = game._gravitante_edge_ratio(dist, radius)
	var dir = (enemy_pos - center_world).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var tangent = dir.orthogonal()
	var tex = game._enemy_texture(enemy)
	var size = game._enemy_draw_size(enemy)
	var swirl = game.time_alive * (3.4 + intensity * 1.2) + float(enemy.get("uid", 0)) * 0.021
	var bend = tangent * sin(swirl) * (10.0 + edge_ratio * 22.0) - dir * (6.0 + (1.0 - edge_ratio) * 10.0)
	var ghost_pos = enemy_pos + bend
	var stretch = 1.0 + edge_ratio * 0.65 + intensity * 0.1
	var compress = 0.82 - edge_ratio * 0.18
	var ghost_size = Vector2(size.x * stretch, size.y * compress)
	var alpha = clamp(0.1 + edge_ratio * 0.22 + intensity * 0.04, 0.1, 0.42)
	game._draw_enemy_texture_raw(tex, ghost_pos - camera, ghost_size, dir.angle() + PI * 0.5 + sin(swirl) * 0.18, Color(0.46, 0.72, 1.0, alpha), game._enemy_should_flip(enemy))
	var smear_pos = enemy_pos + tangent * sin(swirl + 1.2) * (18.0 + edge_ratio * 18.0) - dir * 14.0
	game._draw_enemy_texture_raw(tex, smear_pos - camera, Vector2(size.x * (0.82 + edge_ratio * 0.35), size.y * 0.64), dir.angle() + PI * 0.5, Color(0.96, 0.42, 1.0, alpha * 0.42), game._enemy_should_flip(enemy))


static func _draw_player(game: Node2D, camera: Vector2) -> void :
	if game.is_dead:
		return
	if not game._active_lacerante_secondary().is_empty():
		return
	if game._draw_player_start_down(camera):
		return
	if game.attack_dragging:
		var p = game.player_pos - camera
		var color = game._manifestation_color()
		color.a = 0.65
		game.draw_arc(p, 68.0, 0, TAU, 36, color, 2.5)
		var ball_p = p + game.attack_drag_direction * 68.0
		color.a = 1.0
		game.draw_circle(ball_p, 8.0, color)
		game.draw_circle(ball_p, 14.0, Color(color.r, color.g, color.b, 0.26))
	var tex = game._player_texture()
	var center = game.player_pos - camera
	var profile = game._player_draw_profile()
	var move = game._read_move()
	var rotation = 0.0
	var flip_h = game._should_flip_player_sprite()
	if move.y < -0.2 and abs(move.x) > 0.2:
		rotation = deg_to_rad(15.0) if move.x > 0.0 else deg_to_rad(-15.0)
	if game._shadows_enabled() and tex != null:
		var s_rot = rotation + deg_to_rad(-10.0 if flip_h else 10.0)
		var s_scale = Vector2(-1.0 if flip_h else 1.0, -0.35)
		game.draw_set_transform(center + profile.get("offset", Vector2.ZERO) + Vector2(0, 38.0), s_rot, s_scale)
		var shadow_color = Color(0.0, 0.0, 0.0, 0.42)
		if bool(profile.get("preserve_height", false)):
			var tex_size = tex.get_size()
			if tex_size.y > 0.0:
				var target_height = float(profile.get("height", game.PLAYER_DRAW_LACERAR_HEIGHT))
				var draw_size = tex_size * (target_height / tex_size.y)
				var pos = Vector2( - draw_size.x * 0.5, game.PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
				game.draw_texture_rect(tex, Rect2(pos, draw_size), false, shadow_color)
		else:
			var draw_size = profile["size"]
			var pos = Vector2( - draw_size.x * 0.5, game.PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
			if bool(profile.get("fit_aspect", false)):
				var tex_size = tex.get_size()
				if tex_size.x > 0.0 and tex_size.y > 0.0:
					var fit_scale = min(draw_size.x / tex_size.x, draw_size.y / tex_size.y)
					draw_size = tex_size * fit_scale
					pos = Vector2( - draw_size.x * 0.5, game.PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
			game.draw_texture_rect(tex, Rect2(pos, draw_size), false, shadow_color)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var player_modulate = Color.WHITE
	if game._eclipsada_is_stealthed():
		player_modulate = Color(0.54, 0.82, 1.0, 0.46 + sin(game.time_alive * 9.0) * 0.07)
	if bool(profile.get("preserve_height", false)):
		game._draw_entity_by_height_rotated(tex, center + profile["offset"], float(profile.get("height", game.PLAYER_DRAW_LACERAR_HEIGHT)), rotation, player_modulate, flip_h)
	else:
		if bool(profile.get("fit_aspect", false)):
			game._draw_entity_fit_flipped(tex, center + profile["offset"], profile["size"], flip_h, player_modulate, true)
		else:
			game._draw_entity_stretched_rotated(tex, center + profile["offset"], profile["size"], rotation, player_modulate, flip_h)
	if game.is_multiplayer and game._is_local_run_leader():
		game._draw_leader_crown(center + Vector2(0.0, -62.0), 0.82, Color(1.0, 0.86, 0.18, 0.95))


static func _draw_player_start_down(game: Node2D, camera: Vector2) -> bool:
	if not game._player_start_down_active():
		return false
	if game._cancel_player_start_down_landing_on_move():
		return false
	var frames: Array = game.textures.get("player_lacerante_start_down" if game.manifestation_key == "lacerante" else "player_start_down", [])
	if frames.is_empty():
		return false
	var center: Vector2 = game.player_pos - camera
	var tex: Texture2D = null
	var draw_size = Vector2(66.0, 92.0)
	var air_offset = Vector2.ZERO
	if game.player_start_down_fall_timer > 0.0:
		var progress: float = clampf(1.0 - game.player_start_down_fall_timer / game.PLAYER_START_DOWN_FALL_TIME, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - progress, 3.0)
		var frame_idx: int = 2 if progress >= 0.78 else (int(floor(progress / game.PLAYER_START_DOWN_FRAME_TIME)) % 2)
		tex = frames[clampi(frame_idx, 0, frames.size() - 1)]
		air_offset = Vector2(0.0, -lerpf(game.PLAYER_START_DOWN_HEIGHT, 0.0, eased))
		var shadow_alpha: float = lerpf(0.12, 0.38, eased)
		game.draw_set_transform(center + Vector2(0.0, 40.0), 0.0, Vector2(1.0 + eased * 0.55, 0.26 + eased * 0.12))
		game.draw_circle(Vector2.ZERO, lerpf(18.0, 42.0, eased), Color(0.0, 0.0, 0.0, shadow_alpha))
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var elapsed: float = game.PLAYER_START_DOWN_LAND_TIME - game.player_start_down_landing_timer
		var landing_frame: int = int(floor(elapsed / game.PLAYER_START_DOWN_FRAME_TIME))
		var land_idx: int = 3 + (clampi(landing_frame, 0, 2) if game.manifestation_key == "lacerante" else landing_frame % 3)
		tex = frames[clampi(land_idx, 0, frames.size() - 1)]
		var squash: float = sin(clampf(elapsed / 0.32, 0.0, 1.0) * PI)
		draw_size = Vector2(70.0 + squash * 10.0, 86.0 - squash * 8.0)
		game.draw_set_transform(center + Vector2(0.0, 40.0), 0.0, Vector2(1.35, 0.32))
		game.draw_circle(Vector2.ZERO, 40.0, Color(0.0, 0.0, 0.0, 0.36))
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if tex == null:
		return false
	if game.manifestation_key == "lacerante":
		game._draw_entity_by_height_rotated(tex, center + air_offset, game.LaceranteSprites.DRAW_HEIGHT, 0.0)
	else:
		game._draw_entity_fit(tex, center + air_offset, draw_size, Color.WHITE, game._should_flip_player_sprite())
	return true


static func _draw_dynamic_shadow(game: Node2D, texture: Texture2D, center: Vector2, size: Vector2, flip_h: = false, alpha: = 0.42) -> void :
	if not game._shadows_enabled() or texture == null or alpha <= 0.0:
		return
	var foot = center + Vector2(0.0, size.y * 0.5)
	var light_sway = sin(game.time_alive * 0.72) * 2.0
	var cast_rotation = deg_to_rad(9.0) + sin(game.time_alive * 0.45) * 0.018
	var horizontal = -1.0 if flip_h else 1.0
	var rect = Rect2(Vector2( - size.x * 0.5, - size.y), size)
	game.draw_set_transform(foot + Vector2(10.0 + light_sway, 5.0), cast_rotation, Vector2(horizontal * 1.03, -0.3))
	game.draw_texture_rect(texture, rect, false, Color(0.0, 0.0, 0.0, alpha * 0.25))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	game.draw_set_transform(foot + Vector2(6.0 + light_sway * 0.45, 2.0), cast_rotation, Vector2(horizontal, -0.27))
	game.draw_texture_rect(texture, rect, false, Color(0.0, 0.0, 0.0, alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_dynamic_shadow_fit(game: Node2D, texture: Texture2D, center: Vector2, max_size: Vector2, flip_h: = false, align_bottom: = false, alpha: = 0.42) -> void :
	if not game._shadows_enabled() or texture == null:
		return
	var texture_size = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var fit_scale = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var draw_size = texture_size * fit_scale
	var visual_center = center
	if align_bottom:
		var top = center.y + max_size.y * 0.5 - draw_size.y
		visual_center.y = top + draw_size.y * 0.5
	game._draw_dynamic_shadow(texture, visual_center, draw_size, flip_h, alpha)


static func _draw_entity_fit(game: Node2D, texture: Texture2D, center: Vector2, max_size: Vector2, modulate: = Color.WHITE, align_bottom: = false) -> void :
	if texture == null:
		game.draw_circle(center, min(max_size.x, max_size.y) * 0.34, Color(1.0, 0.2, 0.4))
		return
	var tex_size = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		game._draw_entity(texture, center, max_size, modulate)
		return
	var scale = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size = tex_size * scale
	var pos = center - draw_size * 0.5
	if align_bottom:
		pos.y = center.y + max_size.y * 0.5 - draw_size.y
	game.draw_texture_rect(texture, Rect2(pos, draw_size), false, modulate)


static func _draw_entity_fit_flipped(game: Node2D, texture: Texture2D, center: Vector2, max_size: Vector2, flip_h: = false, modulate: = Color.WHITE, align_bottom: = false) -> void :
	if texture == null:
		game.draw_circle(center, min(max_size.x, max_size.y) * 0.34, Color(1.0, 0.2, 0.4))
		return
	var tex_size = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size = tex_size * scale
	var local_pos = - draw_size * 0.5
	if align_bottom:
		local_pos.y = max_size.y * 0.5 - draw_size.y
	game.draw_set_transform(center, 0.0, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	game.draw_texture_rect(texture, Rect2(local_pos, draw_size), false, modulate)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_entity_by_height_rotated(game: Node2D, texture: Texture2D, center: Vector2, target_height: float, rotation: float, modulate: = Color.WHITE, flip_h: = false) -> void :
	if texture == null:
		return
	var tex_size = texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale = target_height / tex_size.y
	var draw_size = tex_size * scale
	game.draw_set_transform(center, rotation, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	var pos = Vector2( - draw_size.x * 0.5, game.PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
	game.draw_texture_rect(texture, Rect2(pos, draw_size), false, modulate)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_enemy_health_bar(game: Node2D, enemy: Dictionary, pos: Vector2, width: float, ratio: float) -> void :
	var style = game._enemy_health_bar_style(enemy)
	var health_ratio: float = clamp(ratio, 0.0, 1.0)
	var height: float = float(style.get("height", 7.0))
	var fill = Color(style.get("fill", Color(0.3, 1.0, 0.42)))
	var back = Color(style.get("back", Color(0.04, 0.06, 0.06, 0.9)))
	var border = Color(style.get("border", Color(0.7, 1.0, 0.7)))
	var accent = Color(style.get("accent", fill.darkened(0.35)))
	if bool(enemy.get("sanguinaria_hunt", false)):
		fill = Color(1.0, 0.04, 0.08)
		back = Color(0.12, 0.0, 0.015, 0.94)
		border = Color(1.0, 0.18, 0.18)
		accent = Color(0.42, 0.0, 0.04)
	elif float(enemy.get("crepuscular_ocaso_mark", 0.0)) > 0.0:
		fill = fill.lerp(Color(0.18, 0.01, 0.035), 0.42)
		border = border.lerp(Color(0.02, 0.0, 0.0), 0.55)
		accent = Color(0.0, 0.0, 0.0, 0.82)
	var shape = String(style.get("shape", "common"))
	var outer = Rect2(pos + Vector2(-2.0, -2.0), Vector2(width + 4.0, height + 4.0))
	var inner = Rect2(pos, Vector2(width, height))
	game.draw_rect(outer, Color(0.0, 0.0, 0.0, 0.62), true)
	game.draw_rect(inner, back, true)
	if health_ratio > 0.0:
		game.draw_rect(Rect2(pos, Vector2(width * health_ratio, height)), fill, true)
	game.draw_rect(inner, border, false, 1.2)
	match shape:
		"swift":
			game.draw_line(pos + Vector2(width * 0.18, -2.0), pos + Vector2(width * 0.06, height + 3.0), accent, 1.4, true)
			game.draw_line(pos + Vector2(width * 0.88, -2.0), pos + Vector2(width * 0.76, height + 3.0), accent, 1.4, true)
		"projector":
			game.draw_circle(pos + Vector2(width + 4.0, height * 0.5), 3.0, border)
			game.draw_line(pos + Vector2(width * 0.72, height * 0.5), pos + Vector2(width + 3.0, height * 0.5), accent, 1.2, true)
		"crystal":
			var crystal = PackedVector2Array([
				pos + Vector2(width + 2.0, height * 0.5), 
				pos + Vector2(width - 4.0, -4.0), 
				pos + Vector2(width - 10.0, height * 0.5), 
				pos + Vector2(width - 4.0, height + 4.0)
			])
			game.draw_polygon(crystal, PackedColorArray([Color(border.r, border.g, border.b, 0.54)]))
			game.draw_polyline(crystal, border, 1.1, true)
		"curater":
			game.draw_line(pos + Vector2(width + 3.0, 1.0), pos + Vector2(width + 3.0, height + 5.0), border, 1.4)
			game.draw_line(pos + Vector2(width - 1.0, height * 0.5), pos + Vector2(width + 7.0, height * 0.5), border, 1.4)
		"stone":
			for i in range(3):
				var x = pos.x + width * (0.25 + i * 0.22)
				game.draw_line(Vector2(x, pos.y - 1.0), Vector2(x - 5.0, pos.y + height + 2.0), accent, 1.0, true)
		"thief":
			game.draw_circle(pos + Vector2(width + 5.0, height * 0.5), 3.8, Color(1.0, 0.82, 0.25, 0.92))
			game.draw_circle(pos + Vector2(width + 5.0, height * 0.5), 1.5, Color(0.35, 0.18, 0.04, 0.92))
		"ice":
			var cap = PackedVector2Array([
				pos + Vector2(-1.0, -3.0), 
				pos + Vector2(width * 0.22, -5.0), 
				pos + Vector2(width * 0.38, -2.0), 
				pos + Vector2(width * 0.56, -5.0), 
				pos + Vector2(width * 0.78, -2.0), 
				pos + Vector2(width + 1.0, -4.0)
			])
			game.draw_polyline(cap, Color(border.r, border.g, border.b, 0.72), 1.2, true)
		"shield":
			game.draw_arc(pos + Vector2(width + 3.0, height * 0.5), 5.0, - PI * 0.45, PI * 0.45, 8, border, 1.6, true)
		"nexus":
			var core = pos + Vector2(width + 4.0, height * 0.5)
			game.draw_circle(core, 5.0, Color(accent.r, accent.g, accent.b, 0.72))
			game.draw_arc(core, 8.0, game.time_alive * 2.0, game.time_alive * 2.0 + PI * 1.45, 14, border, 1.5, true)


static func _draw_multiplayer_menu(game: Node2D, viewport: Vector2) -> void :
	game._draw_holo_background(viewport, null, Color(1.0, 0.44, 0.88))
	game._draw_glitch_title("MULTIPLAYER ONLINE", Vector2(viewport.x * 0.5, 64), 34, Color(1.0, 0.44, 0.88))

	var panel = Rect2(viewport.x * 0.5 - 180, viewport.y * 0.5 - 120, 360, 240)
	if game.multiplayer_notice != "":
		var notice_rect = Rect2(panel.position.x, panel.position.y - 50.0, panel.size.x, 38.0)
		game._draw_holo_panel(notice_rect, Color(1.0, 0.24, 0.34), false, 0.78)
		game._draw_centered(game.multiplayer_notice, notice_rect.get_center() + Vector2(0, 5), 13, Color(1.0, 0.88, 0.9))
	game._draw_holo_panel(panel, Color(1.0, 0.44, 0.88), true, 0.6)

	game.buttons["mp_host"] = Rect2(panel.position.x + 20, panel.position.y + 40, panel.size.x - 40, 50)
	game.buttons["mp_client"] = Rect2(panel.position.x + 20, panel.position.y + 110, panel.size.x - 40, 50)
	game.buttons["mp_back"] = Rect2(panel.position.x + 20, panel.position.y + 180, panel.size.x - 40, 40)

	game._draw_big_button(game.buttons["mp_host"], "CRIAR SALA ONLINE", Color(0.1, 0.05, 0.1, 0.9), Color(1.0, 1.0, 1.0) if (game.is_gamepad_active and game.multiplayer_menu_selected == 0) else Color(1.0, 0.44, 0.88))
	game._draw_big_button(game.buttons["mp_client"], "ENTRAR ONLINE", Color(0.05, 0.1, 0.1, 0.9), Color(1.0, 1.0, 1.0) if (game.is_gamepad_active and game.multiplayer_menu_selected == 1) else Color(0.0, 1.0, 0.82))
	game._draw_big_button(game.buttons["mp_back"], "VOLTAR", Color(0.1, 0.05, 0.05, 0.9), Color(1.0, 1.0, 1.0) if (game.is_gamepad_active and game.multiplayer_menu_selected == 2) else Color(1.0, 0.2, 0.2))


static func _draw_phantom_player(game: Node2D, camera: Vector2) -> void :
	if not game.is_multiplayer:
		return
	if game.net_players_by_peer.is_empty():
		if not game.net_player_dead and game.net_player_has_snapshot:
			game._draw_remote_player_state(camera, game.net_player_peer_id, {
				"render_pos": game.net_player_render_pos, "dead": game.net_player_dead, "has_snapshot": game.net_player_has_snapshot, 
				"anim_state": game.net_player_anim_state, "frame_idx": game.net_player_frame_idx, "flip_h": game.net_player_flip_h, 
				"move": game.net_player_move, "name": game.net_player_name, "stealthed": false, 
				"manifestation": game.net_player_manifestation,
				"hp": game.net_player_hp, "hp_max": game.net_player_hp_max
			})
		return
	var peer_ids = game.net_players_by_peer.keys()
	peer_ids.sort()
	for peer_key in peer_ids:
		game._draw_remote_player_state(camera, int(peer_key), game.net_players_by_peer[peer_key])


static func _draw_remote_player_state(game: Node2D, camera: Vector2, peer_id: int, state: Dictionary) -> void :
	if bool(state.get("dead", false)) or not bool(state.get("has_snapshot", false)):
		return
	var p = Vector2(state.get("render_pos", state.get("pos", Vector2.ZERO))) - camera
	var anim_state = int(state.get("anim_state", game.NET_ANIM_IDLE))
	var frame_idx = int(state.get("frame_idx", 0))
	var flip_h = bool(state.get("flip_h", false))
	var size = game.PLAYER_DRAW_FROZEN_SIZE if anim_state == game.NET_ANIM_FROZEN else (game.PLAYER_DRAW_DAMAGE_SIZE if anim_state == game.NET_ANIM_DAMAGE else game.PLAYER_DRAW_BOX_SIZE)
	var rect = Rect2(p - size * 0.5, size)
	var accent = Color(1.0, 0.44, 0.88) if peer_id % 2 == 0 else Color(0.0, 1.0, 0.82)
	var is_leader: bool = game.is_multiplayer and peer_id == game.run_leader_peer_id
	if is_leader:
		accent = Color(1.0, 0.86, 0.18)
	game._draw_centered(String(state.get("name", "Player %d" % peer_id)), p + Vector2(0, -58), 12, accent)
	game._draw_ally_health_bar(p + Vector2(0, -44), 62.0, game._remote_player_health_ratio(state), accent)
	if is_leader:
		game._draw_leader_crown(p + Vector2(0, -62), 0.72, accent)
	game._draw_centered("%d/%d" % [int(state.get("hp", 0)), int(max(1.0, float(state.get("hp_max", 1.0))))], p + Vector2(0, -34), 9, Color(0.86, 1.0, 0.92, 0.96))
	var tex = game._net_player_texture_for_state(anim_state, frame_idx, int(state.get("manifestation", -1)))
	var is_lacerante: bool = game.LaceranteSprites.is_manifestation(game, int(state.get("manifestation", -1)))
	if is_lacerante:
		flip_h = false
		if tex != null:
			size = tex.get_size() * (game.LaceranteSprites.DRAW_HEIGHT / tex.get_height())
			rect = Rect2(p - size * 0.5, size)
	var directional_fire: bool = anim_state == game.NET_ANIM_FIRE and frame_idx >= 2 and frame_idx < 14
	if directional_fire and tex != null:
		size = tex.get_size() * (game.PLAYER_FIRE_CANVAS_HEIGHT / tex.get_height())
		rect = Rect2(p + Vector2(-size.x * 0.5, game.PLAYER_DRAW_BOX_SIZE.y * 0.5 - size.y), size)

	var rotation = 0.0
	var move = Vector2(state.get("move", Vector2.ZERO)).normalized()
	if move.y < -0.2 and abs(move.x) > 0.2:
		rotation = deg_to_rad(15.0) if move.x > 0.0 else deg_to_rad(-15.0)

	if game._shadows_enabled() and tex != null:
		var s_rot = rotation + deg_to_rad(-10.0 if flip_h else 10.0)
		var s_scale = Vector2(-1.0 if flip_h else 1.0, -0.35)
		game.draw_set_transform(rect.get_center() + Vector2(0, 38.0), s_rot, s_scale)
		var shadow_color = Color(0.0, 0.0, 0.0, 0.42)
		var draw_size = size
		var pos = Vector2( - draw_size.x * 0.5, game.PLAYER_DRAW_BOX_SIZE.y * 0.5 - draw_size.y)
		game.draw_texture_rect(tex, Rect2(pos, draw_size), false, shadow_color)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var alpha = 0.34 if bool(state.get("stealthed", false)) else 0.86
	if is_lacerante:
		game._draw_entity_by_height_rotated(tex, p, game.LaceranteSprites.DRAW_HEIGHT, rotation, Color(1.0, 1.0, 1.0, alpha))
	else:
		game._draw_entity_fit_flipped(tex, rect.get_center(), size, flip_h, Color(accent.r, accent.g, accent.b, alpha))


static func _draw_leader_crown(game: Node2D, center: Vector2, scale: float, color: Color) -> void:
	var s: float = maxf(0.45, scale)
	var base = PackedVector2Array([
		center + Vector2(-14.0, 7.0) * s,
		center + Vector2(14.0, 7.0) * s,
		center + Vector2(12.0, -3.0) * s,
		center + Vector2(5.0, 3.0) * s,
		center + Vector2(0.0, -12.0) * s,
		center + Vector2(-5.0, 3.0) * s,
		center + Vector2(-12.0, -3.0) * s
	])
	game.draw_polygon(base, PackedColorArray([Color(color.r, color.g, color.b, color.a * 0.92)]))
	game.draw_polyline(PackedVector2Array([base[0], base[1], base[2], base[3], base[4], base[5], base[6], base[0]]), Color(1.0, 1.0, 0.78, color.a), 1.4 * s, true)
	game.draw_line(center + Vector2(-10.0, 9.0) * s, center + Vector2(10.0, 9.0) * s, Color(0.08, 0.05, 0.01, color.a * 0.72), 2.0 * s, true)


static func _draw_ally_health_bar(game: Node2D, center: Vector2, width: float, ratio: float, accent: Color) -> void :
	var height: float = 6.0
	var pos: Vector2 = center + Vector2( - width * 0.5, - height * 0.5)
	var health_ratio: float = clampf(ratio, 0.0, 1.0)
	var fill: Color = Color(1.0, 0.18, 0.2).lerp(Color(0.22, 1.0, 0.42), health_ratio)
	game.draw_rect(Rect2(pos + Vector2(-2.0, -2.0), Vector2(width + 4.0, height + 4.0)), Color(0.0, 0.0, 0.0, 0.64), true)
	game.draw_rect(Rect2(pos, Vector2(width, height)), Color(0.02, 0.06, 0.05, 0.86), true)
	if health_ratio > 0.0:
		game.draw_rect(Rect2(pos, Vector2(width * health_ratio, height)), fill, true)
	game.draw_rect(Rect2(pos, Vector2(width, height)), Color(accent.r, accent.g, accent.b, 0.82), false, 1.2)


static func _draw_multiplayer_preload(game: Node2D, viewport: Vector2) -> void :
	game._draw_holo_background(viewport, null, Color(0.2, 0.82, 1.0))
	game._draw_glitch_title("PREPARANDO ONLINE", Vector2(viewport.x * 0.5, 64), 34, Color(0.2, 0.82, 1.0))
	var panel = Rect2(viewport.x * 0.5 - 220, viewport.y * 0.5 - 112, 440, 224)
	game._draw_holo_panel(panel, Color(0.2, 0.82, 1.0), true, 0.66)
	var stage = game.online_preload_stage if game.online_preload_stage != "" else "AGUARDANDO..."
	game._draw_centered(stage, panel.position + Vector2(220, 52), 18, Color.WHITE)
	var bar = Rect2(panel.position.x + 38, panel.position.y + 88, panel.size.x - 76, 18)
	game.draw_rect(bar, Color(0.02, 0.08, 0.12, 0.88), true)
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(game.online_preload_progress, 0.0, 1.0), bar.size.y)), Color(0.2, 0.82, 1.0, 0.92), true)
	game.draw_rect(bar, Color(0.78, 1.0, 1.0, 0.76), false, 2.0)
	var local_text = "LOCAL PRONTO" if game.online_preload_local_ready else "CARREGANDO LOCAL"
	var remote_text = game.online_preload_remote_stage if game.online_preload_remote_stage != "" else "AGUARDANDO PARES"
	game._draw_centered(local_text, panel.position + Vector2(220, 132), 14, Color(0.0, 1.0, 0.82) if game.online_preload_local_ready else Color(1.0, 0.82, 0.24))
	game._draw_centered(remote_text, panel.position + Vector2(220, 162), 14, Color(0.0, 1.0, 0.82) if game.online_preload_remote_ready else Color(0.72, 0.9, 1.0))
	if game.online_preload_started_ms > 0:
		var elapsed = float(Time.get_ticks_msec() - game.online_preload_started_ms) / 1000.0
		game._draw_centered("%.1fs" % elapsed, panel.position + Vector2(220, 194), 12, Color(0.74, 0.92, 1.0, 0.86))
