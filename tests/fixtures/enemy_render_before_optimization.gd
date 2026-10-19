extends RefCounted
## Frozen pre-optimization renderer. Test-only oracle for pixel parity and paired timings.
## Keep independent from the optimized profile reuse; no gameplay is implemented here.

static func _draw_enemies(game: Node2D, camera: Vector2) -> void :
	for enemy in game.enemies:
		if not game._world_point_in_view(Vector2(enemy.get("pos", Vector2.ZERO)), camera, 180.0):
			continue
		if String(enemy.get("type", "")) == game.ENEMY_AMBER_SUTURE_NODE:
			game.AmberSuturerPresentation.draw_node(game, enemy, camera)
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
		elif enemy["type"] == game.ENEMY_FLAGELANTE:
			modulate_color = Color(1.0, 0.9, 0.76, alpha)
		elif enemy["type"] == game.ENEMY_SALMODIANTE:
			modulate_color = Color(0.94, 0.8, 1.0, alpha)
		elif enemy["type"] == game.ENEMY_RELICARIO:
			modulate_color = Color(0.9, 0.96, 0.72, alpha)
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
		elif enemy["type"] == game.ENEMY_AMBER_SUTURER:
			modulate_color = Color(1.0, 0.96, 0.88, alpha)
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
		if static_stacks > 0 and static_timer > 0.0:
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
		if enemy["type"] == game.ENEMY_FLAGELANTE and float(enemy.get("phase3_surge_timer", 0.0)) > 0.0:
			var trail_dir := -Vector2(enemy.get("last_move_dir", Vector2.RIGHT)).normalized()
			game.draw_line(pos + trail_dir * 18.0, pos + trail_dir * 54.0, Color(0.72, 1.0, 0.3, 0.58), 4.0)
		if enemy["type"] == game.ENEMY_SALMODIANTE and float(enemy.get("phase3_chant_prepare", 0.0)) > 0.0:
			var chant_target := Vector2(enemy.get("phase3_chant_target", game.player_pos)) - camera
			var chant_dir := (chant_target - pos).normalized()
			for fan_angle in [-game.PHASE3_SALMODIANTE_FAN_ANGLE, 0.0, game.PHASE3_SALMODIANTE_FAN_ANGLE]:
				game.draw_line(pos, pos + chant_dir.rotated(float(fan_angle)) * 92.0, Color(0.82, 0.4, 1.0, 0.42), 2.0)
		if enemy["type"] == game.ENEMY_RELICARIO and float(enemy.get("phase3_relic_pulse", 0.0)) > 0.0:
			var relic_ratio := clampf(float(enemy.get("phase3_relic_pulse", 0.0)) / 0.7, 0.0, 1.0)
			game.draw_arc(pos, game.PHASE3_RELIC_RADIUS * (1.0 - relic_ratio * 0.55), 0.0, TAU, 48, Color(0.7, 0.92, 0.3, 0.42 * relic_ratio), 3.0)
		if float(enemy.get("phase3_fervor_timer", 0.0)) > 0.0:
			var fervor_pulse := 0.5 + 0.5 * sin(game.time_alive * 8.0 + float(int(enemy.get("uid", 0)) % 17))
			game.draw_arc(pos, visual_size.x * (0.42 + fervor_pulse * 0.05), 0.0, TAU, 24, Color(0.68, 1.0, 0.28, 0.46), 2.0)
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

