extends RefCounted

# Draws through the main CanvasItem; state stays on the host during migration.


static func _draw_eletrica_static_indicator(game: Node2D, ci: CanvasItem, pos: Vector2, stacks: int, timer: float, uid: int) -> void :
	if stacks <= 0 or timer <= 0.0:
		return
	var t = float(Time.get_ticks_msec()) * 0.001
	var timer_ratio = clampf(timer / 3.0, 0.0, 1.0)
	var draw_pos = pos + Vector2(0, -42)

	var base_col: Color = Color(0.2, 0.85, 1.0)
	if stacks == 2:
		base_col = Color(1.0, 0.9, 0.2)
	elif stacks >= 3:
		base_col = Color(1.0, 0.35, 0.15).lerp(Color.WHITE, sin(t * 30.0) * 0.5 + 0.5)

	base_col.a = clampf(timer_ratio * 1.2, 0.2, 1.0)

	var bar_w = 24.0
	var bar_h = 5.0
	var bar_rect = Rect2(draw_pos - Vector2(bar_w * 0.5, bar_h * 0.5), Vector2(bar_w, bar_h))

	ci.draw_rect(bar_rect.grow(1.0), Color(0.05, 0.06, 0.09, base_col.a * 0.85), true)

	var slot_w = (bar_w - 4.0) / 3.0
	for i in range(3):
		var slot_x = bar_rect.position.x + 1.0 + i * (slot_w + 1.0)
		var slot_r = Rect2(slot_x, bar_rect.position.y + 1.0, slot_w, bar_h - 2.0)
		if i < stacks:
			ci.draw_rect(slot_r, base_col, true)
			var spark_y = slot_r.position.y - 3.0 + sin(t * 18.0 + uid + i) * 1.5
			ci.draw_circle(Vector2(slot_r.get_center().x, spark_y), 1.5, Color.WHITE)
		else:
			ci.draw_rect(slot_r, Color(0.18, 0.22, 0.28, base_col.a * 0.5), true)

	var arc_rad = 16.0 + sin(t * 8.0 + uid) * 2.0
	var start_ang = t * (4.0 + stacks * 2.0) + uid
	var end_ang = start_ang + PI * (0.4 + stacks * 0.25)
	ci.draw_arc(draw_pos, arc_rad, start_ang, end_ang, 16, base_col, 2.0, true)


static func _draw_bombastica_powder_trail_world(game: Node2D, camera: Vector2) -> void:
	if game.bombastica_ult_state == "IDLE" or game.bombastica_ult_visual_path.size() < 2:
		return
		
	var points: PackedVector2Array = PackedVector2Array()
	for p in game.bombastica_ult_visual_path:
		points.append(Vector2(p) - camera)
		
	if points.size() >= 2:
		var trail_color: Color = Color(0.95, 0.45, 0.12, 0.85)
		if game.bombastica_ult_state == "BURNING":
			trail_color = Color(1.0, 0.65, 0.2, 0.95)
		elif game.bombastica_ult_state == "DETONATING":
			trail_color = Color(1.0, 0.85, 0.4, 1.0)
			
		game.draw_polyline(points, trail_color, 16.0, true)
		game.draw_polyline(points, Color(1.0, 0.95, 0.7, 0.9), 6.0, true)
		
	if game.bombastica_ult_state == "BURNING":
		var fuse_canvas: Vector2 = game.bombastica_ult_fuse_pos - camera
		game.draw_circle(fuse_canvas, 10.0, Color(1.0, 0.9, 0.4, 0.95))
		game.draw_circle(fuse_canvas, 5.0, Color(1.0, 1.0, 1.0, 1.0))


static func _draw_manifest_preview_ultimate(game: Node2D, rect: Rect2, key: String, t: float, accent: Color) -> void :
	var c = rect.get_center()
	var p = c + Vector2( - rect.size.x * 0.18, rect.size.y * 0.12)
	var pulse = 0.5 + 0.5 * sin(t * TAU)
	game._draw_preview_geovana(p, rect.size.y * 0.14, accent)
	for i in range(3):
		game._draw_preview_enemy(c + Vector2.from_angle(i * TAU / 3.0 + 0.35) * rect.size.y * 0.3, rect.size.y * 0.09, accent)
	match key:
		"eletrica":
			for i in range(8):
				var a = t * TAU + i * TAU / 8.0
				var endpoint = p + Vector2.from_angle(a) * (44.0 + pulse * 12.0)
				game._draw_preview_bolt(p, endpoint, accent, t + i, 1.5)
			game.draw_arc(p, 70.0, 0.0, TAU, 96, Color(0.5, 0.95, 1.0, 0.24), 2.0)
		"lacerante":
			for i in range(12):
				var a = t * TAU * 0.9 + i * TAU / 12.0
				game._draw_preview_slash(c + Vector2.from_angle(a) * (20.0 + i % 3 * 13.0), a, 58.0, Color(1.0, 0.06, 0.14, 0.6), 2.4)
			game.draw_circle(c, 76.0, Color(1.0, 0.02, 0.08, 0.08))
		"prismatica":
			for i in range(4):
				var a = t * TAU + i * PI * 0.5
				game.draw_line(c - Vector2.from_angle(a) * 78.0, c + Vector2.from_angle(a) * 78.0, Color.from_hsv(fposmod(t * 0.4 + i * 0.18, 1.0), 0.9, 1.0, 0.3), 8.0)
				game.draw_line(c - Vector2.from_angle(a) * 78.0, c + Vector2.from_angle(a) * 78.0, Color(1.0, 1.0, 1.0, 0.42), 2.0)
			game._draw_preview_diamond(c, 34.0 + pulse * 5.0, accent)
		"retornante":
			for i in range(5):
				var r = 28.0 + i * 18.0
				game.draw_arc(c, r, - t * TAU - i, - t * TAU - i + PI * 1.55, 72, Color(accent.r, accent.g, accent.b, 0.4 - i * 0.045), 2.5)
			game.draw_line(c + Vector2(-62, 20), c + Vector2(62, -24), Color(1.0, 0.42, 0.72, 0.32), 5.0)
		"parasitica":
			for i in range(12):
				var edge = Vector2(rect.position.x + (rect.size.x if i % 2 == 0 else 0.0), rect.position.y + rect.size.y * float(i) / 12.0)
				var target = c + Vector2.from_angle(i) * 24.0
				game._draw_preview_worm_path(edge, target, t + i * 0.1, accent)
			game.draw_circle(c, 58.0, Color(0.22, 0.72, 0.12, 0.2))
		"gravitante":
			game.draw_circle(c, 42.0, Color(0.0, 0.0, 0.0, 0.84))
			for i in range(5):
				game.draw_arc(c, 52.0 + i * 14.0 + pulse * 4.0, t * TAU + i, t * TAU + i + PI * 1.42, 78, Color(0.54, 0.78, 1.0, 0.34 - i * 0.04), 2.5)
			for i in range(8):
				var frag = c + Vector2.from_angle( - t * TAU + i) * (82.0 - pulse * 18.0)
				game.draw_rect(Rect2(frag - Vector2(4, 4), Vector2(8, 8)), Color(0.78, 0.9, 1.0, 0.38), true)
		"acorrentada":
			for i in range(3):
				var enemy_pos: Vector2 = c + Vector2.from_angle(i * TAU / 3.0 + 0.35) * rect.size.y * 0.3
				game._draw_acorrentada_chain(enemy_pos, c, Color(0.92, 0.12, 0.1, 0.72), 8.0, 1.0, false)
			game.draw_circle(c, 50.0 + pulse * 12.0, Color(0.18, 0.86, 1.0, 0.12))
			game.draw_arc(c, 62.0, - t * TAU, TAU - t * TAU, 72, Color(1.0, 0.22, 0.16, 0.58), 4.0)
		"eclipsada":
			game.draw_circle(c, 82.0, Color(0.02, 0.1, 0.28, 0.22))
			for i in range(10):
				var angle = t * TAU * 1.8 + float(i) * TAU / 10.0
				var cut_center: Vector2 = c + Vector2.from_angle(angle) * (28.0 + float(i % 3) * 18.0)
				game._draw_preview_slash(cut_center, angle + PI * 0.36, 58.0 + float(i % 2) * 18.0, Color(0.42, 0.82, 1.0, 0.82), 4.0)
			game.draw_arc(c, 86.0, - t * TAU * 2.0, - t * TAU * 2.0 + PI * 1.65, 72, Color(accent.r, accent.g, accent.b, 0.84), 4.0)
			game.draw_arc(c, 58.0, t * TAU * 2.4, t * TAU * 2.4 + PI * 1.42, 54, Color(1.0, 0.88, 0.32, 0.72), 2.5)
		_:
			for i in range(6):
				game.draw_arc(c, 34.0 + i * 13.0, t * TAU + i * 0.5, t * TAU + i * 0.5 + PI, 48, Color(accent.r, accent.g, accent.b, 0.38), 3.0)
			game.draw_line(c + Vector2(0, -68), c + Vector2(0, 68), Color(1.0, 0.78, 0.26, 0.46), 4.0)


static func _draw_preview_bolt(game: Node2D, start: Vector2, end: Vector2, color: Color, t: float, width: float) -> void :
	var points = PackedVector2Array()
	var dir = end - start
	var normal = dir.orthogonal().normalized()
	points.append(start)
	for i in range(1, 7):
		var k = float(i) / 7.0
		var jitter = sin(t * 18.0 + i * 2.17) * 9.0 + cos(t * 11.0 + i) * 4.0
		points.append(start.lerp(end, k) + normal * jitter)
	points.append(end)
	game.draw_polyline(points, Color(color.r, color.g, color.b, 0.42), width + 3.0, true)
	game.draw_polyline(points, Color(1.0, 1.0, 1.0, 0.84), max(1.0, width), true)


static func _draw_preview_diamond(game: Node2D, center: Vector2, radius: float, color: Color) -> void :
	var points = PackedVector2Array([
		center + Vector2(0, - radius), 
		center + Vector2(radius * 0.72, 0), 
		center + Vector2(0, radius), 
		center + Vector2( - radius * 0.72, 0)
	])
	game.draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.24))
	game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(1.0, 1.0, 1.0, 0.76), 2.0, true)


static func _draw_event_alert_world(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	if game.event_alert_timer <= 0.0:
		return
	var progress: float = clampf(1.0 - game.event_alert_timer / 4.0, 0.0, 1.0)
	var fade: float = sin(progress * PI)
	var center_world: Vector2 = game.player_pos.lerp(game.WORLD_SIZE * 0.5, 0.18)
	var center: Vector2 = center_world - camera
	var accent: Color = game.event_alert_color
	var t: float = game.time_alive * 2.8 + float(game.event_alert_seed % 97) * 0.013
	var max_radius: float = maxf(viewport.x, viewport.y) * 0.72
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(accent.r, accent.g, accent.b, 0.035 * fade), true)
	for ring in range(4):
		var ring_p: float = fposmod(progress + float(ring) * 0.18, 1.0)
		var radius: float = lerpf(70.0, max_radius, ring_p)
		var alpha: float = (1.0 - ring_p) * 0.32 * fade
		game.draw_arc(center, radius, t + float(ring), t + float(ring) + TAU * 0.78, 96, Color(accent.r, accent.g, accent.b, alpha), 3.0, true)
		game.draw_arc(center, radius * 0.72, -t * 0.9 - float(ring), -t * 0.9 - float(ring) + TAU * 0.38, 64, Color(1.0, 0.94, 1.0, alpha * 0.45), 1.6, true)
	var cracks: int = 11 if not game._memory_saver_active() else 6
	for i in range(cracks):
		var base_angle: float = float(i) * TAU / float(cracks) + sin(t + float(i)) * 0.18
		var a: Vector2 = center + Vector2.from_angle(base_angle) * (70.0 + sin(t * 1.7 + i) * 16.0)
		var b: Vector2 = center + Vector2.from_angle(base_angle + sin(t + i) * 0.08) * (max_radius * (0.42 + 0.18 * sin(float(i) * 1.3)))
		game.draw_line(a, b, Color(accent.r, accent.g, accent.b, 0.16 * fade), 2.0, true)
		if i % 3 == 0:
			var mid: Vector2 = a.lerp(b, 0.58)
			game.draw_line(mid, mid + Vector2.from_angle(base_angle + 0.72) * 34.0, Color(1.0, 0.82, 1.0, 0.12 * fade), 1.2, true)


static func _draw_game(game: Node2D, viewport: Vector2) -> void :
	var camera = game._camera(viewport)
	camera += game._screen_shake_offset()
	var map_texture = game._current_map_texture()
	if map_texture:
		if game.current_phase == 5 and game.phase5_transmute_active:
			game._draw_phase5_transmute_map_reveal(map_texture, game._desktop_stage_draw_rect(camera))
		else:
			game.draw_texture_rect(map_texture, game._desktop_stage_draw_rect(camera), false)
	else:
		game.draw_rect(Rect2( - camera, game.WORLD_SIZE), Color(0.05, 0.055, 0.08), true)
	game._draw_event_alert_world(camera, viewport)
	game._draw_boss6_necro_erosion(camera)
	game._draw_phase5_transmute_particles(camera)
	if game.vfx_director:
		game.vfx_director.draw_floor_effects(game, camera)

	if not game._active_prismatica_secondary().is_empty():
		var dr = Rect2( - camera, game.WORLD_SIZE)
		game.draw_rect(dr, Color(0.01, 0.0, 0.05, 0.85), true)
		var t = float(Time.get_ticks_msec()) * 0.001
		var p_pos = game.player_pos - camera
		if game.gfx_low_resource:
			var hue = fposmod(t * 0.32, 1.0)
			game.draw_circle(p_pos, 210.0 + sin(t * 2.4) * 18.0, Color.from_hsv(hue, 0.85, 1.0, 0.08))
			game.draw_arc(p_pos, 152.0, t * TAU, t * TAU + PI * 1.45, 96, Color.from_hsv(hue + 0.18, 0.9, 1.0, 0.28), 3.0)
			game.draw_arc(p_pos, 92.0, - t * TAU * 0.7, - t * TAU * 0.7 + PI * 1.2, 72, Color(1.0, 1.0, 1.0, 0.2), 2.0)
		else:


			var grid_size = 100.0
			var ox = fmod(camera.x, grid_size)
			var oy = fmod(camera.y, grid_size)
			for x in range(int(viewport.x / grid_size) + 2):
				for y in range(int(viewport.y / grid_size) + 2):
					if (x + y) % 2 == 0:
						var rect = Rect2(x * grid_size - ox, y * grid_size - oy, grid_size, grid_size)
						var hue = fmod(t * 0.4 + (x + y) * 0.05, 1.0)
						game.draw_rect(rect, Color.from_hsv(hue, 0.9, 1.0, 0.15), true)


			for i in range(4):
				var a = t * (1.2 + i * 0.3) + i * TAU / 4.0
				var center = Vector2(viewport.x / 2, viewport.y / 2) + Vector2(cos(a * 0.8), sin(a * 1.2)) * (300.0 + sin(t) * 50.0)
				var c = Color.from_hsv(fmod(t * 0.5 + i * 0.25, 1.0), 1.0, 1.0, 1.0)
				var base_r = 180.0 + sin(t * 3 + i) * 40.0

				for k in range(5):
					game.draw_circle(center, base_r * (1.0 - k * 0.15), Color(c.r, c.g, c.b, 0.04 + k * 0.02))

			for i in range(10):
				var r = 160.0 + sin(t * 2.5 + i) * 35.0 + i * 45.0
				var c = Color.from_hsv(fmod(t * 0.2 + i * 0.15, 1.0), 0.9, 1.0, 0.05)
				game.draw_circle(p_pos, r, c)

	if game.boss1_rain_active and game.weather_kind == "rain":
		game._draw_rain_puddles(camera)
	for anchor in (game.anchors + game.net_anchors):
		var p: Vector2 = anchor["pos"] - camera
		game.draw_circle(p, 52, Color(0.2, 0.86, 1.0, 0.1))
		game.draw_arc(p, 52, 0, TAU, 48, Color(0.4, 0.95, 1.0, 0.55), 2)
	for prism in (game.prisms + game.net_prisms):
		game._draw_prismatica_prism(prism, camera)
	game._draw_advanced_manifestation_world(camera)
	game._draw_teleport_effects(camera)
	game._draw_manifest_evolution_fields(camera)
	for link in (game.seed_links + game.net_seed_links):
		var enemy = game._enemy_by_uid(int(link.get("uid", -1)))
		if enemy:
			game.draw_arc(enemy["pos"] - camera, 34, 0, TAU, 32, Color(0.4, 1.0, 0.36, 0.66), 3)
	for slash in (game.slashes + game.net_slashes):
		var alpha = clamp(float(slash["life"]) / float(slash["max"]), 0.0, 1.0)
		var slash_kind = String(slash.get("kind", ""))
		if slash_kind == "lacerante_spin":
			game._draw_lacerante_spin(slash, camera, alpha)
		elif slash_kind == "lacerante_blade":
			game._draw_lacerante_blade(slash, camera, alpha)
		elif slash.has("points"):
			var c: Color = slash["color"]
			c.a = 0.22 + alpha * 0.55
			var packed = PackedVector2Array()
			for point in slash["points"]:
				packed.append(point - camera)
			game.draw_polyline(packed, c, float(slash["width"]) * alpha, true)
		else:
			var c: Color = slash["color"]
			c.a = 0.22 + alpha * 0.55
			game.draw_line(slash["a"] - camera, slash["b"] - camera, c, float(slash["width"]) * alpha)
	for wave in game.shockwaves:
		var w_kind = String(wave.get("kind", ""))
		var w_max = float(wave.get("max_life", 1.0))
		var w_life = float(wave.get("life", 0.0))
		var w_alpha = clamp(w_life / max(0.01, w_max), 0.0, 1.0)
		if w_kind == "sinfonia_silencio":
			game.draw_arc(wave["pos"] - camera, float(wave["radius"]), 0, TAU, 80, Color(1.0, 0.84, 0.2, w_alpha * 0.8), 6)
			game.draw_arc(wave["pos"] - camera, max(0.0, float(wave["radius"]) - 10.0), 0, TAU, 60, Color(1.0, 0.6, 0.1, w_alpha * 0.4), 2)
		else:
			game.draw_arc(wave["pos"] - camera, float(wave["radius"]), 0, TAU, 80, Color(0.2, 1.0, 1.0, 0.6), 4)
	game._draw_eletrica_kinetic_waves(camera)
	game._draw_eletrica_chains(camera)
	game._draw_manifestation_secondaries(camera)
	game._draw_network_ability_visuals(camera)
	if game.vfx_director:
		game.vfx_director.draw_world_vfx(game, camera)
	game._draw_parasite_spit_zones(camera)
	game._draw_phase6_pustule_pools(camera)
	game._draw_phase7_ember_patches(camera)
	game._draw_boss7_flame_waves(camera)
	game._draw_boss7_ultimate(camera)
	game._draw_boss7_ground_indicators(camera)
	game._draw_boss2_environment(camera)
	game._draw_phase3_environment(camera)
	game._draw_phase4_environment(camera)
	game._draw_phase5_environment(camera)
	if game.boss1_rain_active and game.current_phase == 2:
		game._draw_weather_precipitation(camera)
	game._draw_boss_attacks(camera)
	game._draw_boss6_miasma_ultimate(camera)
	game._draw_boss3_faith_link(camera)
	game._draw_boss1_rewind_world(camera)
	game._draw_network_rewind_visuals(camera)
	for orb in game.heal_orbs:
		game.draw_circle(orb["pos"] - camera, 15, Color(0.25, 1.0, 0.42, 0.78))
		game.draw_arc(orb["pos"] - camera, 22, 0, TAU, 32, Color(0.65, 1.0, 0.75, 0.65), 2)
	game._draw_larapio_ultimate_portals(camera)
	game._draw_larapio_coin_drops(camera)
	game._draw_arauto_card_drops(camera)
	game._draw_arauto_evolution_fragment(camera)
	game._draw_aura_world(camera)
	game._draw_remote_aura_world(camera)
	game._draw_devorador_world(camera)
	game._draw_common_card_world(camera)
	game._draw_rare_card_world(camera)
	game._draw_acorrentada_world(camera)
	game._draw_arauto(camera)
	game._draw_crepuscular_arauto_cracks(camera)
	game._draw_enemies(camera)
	game._draw_projectiles(camera)
	game._draw_boss3_miasma_clones(camera)
	if game.current_phase != 6:
		game._draw_boss_world(camera)
		game._draw_crepuscular_boss_cracks(camera)
	game._draw_parasite_marks(camera)
	game._draw_parasite_foreground(camera)
	if not game.phase_fragment.is_empty():
		game._draw_phase_fragment(camera)
	game._draw_team_revival_world(camera)
	if not game.online_local_spectator:
		game._draw_companions(camera)
		game._draw_boss6_fossil_echo(camera)
		game._draw_player(camera)
	if game.current_phase == 6:
		game._draw_boss_world(camera)
		game._draw_crepuscular_boss_cracks(camera)
	game._draw_phantom_player(camera)
	game._draw_effects(camera)
	game._draw_eclipsada_vfx(camera)
	game._draw_eclipsada_stealth_overlay(viewport, camera)
	if game.boss1_rain_active and game.current_phase != 2:
		game._draw_weather_precipitation(camera)
	if game.boss1_rewind_sequence.is_empty() and (game.mode == "game" or game.mode == "shop_countdown" or game.mode == "boss_call" or game.mode == "pause_countdown"):
		game._draw_ground_target_preview(viewport, camera)
	if game._boss3_miasma_active() and game.boss3_miasma_variant == 3:
		game._draw_boss3_miasma_clouds(camera)
	if game._boss3_miasma_active() and game.boss3_miasma_variant != 3 and not game._boss3_miasma_qte_active():
		game._draw_boss3_miasma_overlay(viewport, camera)
	if game._is_umbra_miasma_active():
		game._draw_umbra_miasma_overlay(viewport, camera)
	game._draw_apolo_phase5_exhibition_world(camera)
	if game.preview_capture_mode:
		return
	game.hud_feedback.overlay(game, viewport)
	game._draw_hud(viewport)
	game._draw_apolo_phase5_exhibition_overlay(viewport)
	game._draw_boss1_rewind_overlay(viewport, camera)
	if game.boss1_rewind_sequence.is_empty() and not game._spectator_controls_locked() and (game.mode == "game" or game.mode == "shop_countdown" or game.mode == "boss_call" or game.mode == "pause_countdown"):
		if game.teleport_dragging:
			game._draw_teleport_preview(viewport, camera)
		game._draw_touch_controls(viewport)
	game._draw_tutorial_overlay(viewport, camera)
	if game._boss3_miasma_qte_active():
		game._draw_boss3_miasma_overlay(viewport, camera)
	game._draw_revive_request(viewport)
	if game.secondary_drain_flash_timer > 0.0:
		game._draw_secondary_drain_border(viewport)


static func _draw_companions(game: Node2D, camera: Vector2) -> void :
	if game.trembo_charges > 0:
		var trembo_texture = game._companion_frame("trembo_" + game.trembo_facing, game.trembo_anim_time, 7.0)
		var trembo_screen = game.trembo_pos - camera
		game._draw_dynamic_shadow_fit(trembo_texture, trembo_screen, Vector2(66, 92), false, true, 0.38)
		game._draw_entity_fit(trembo_texture, trembo_screen, Vector2(66, 92), Color.WHITE, true)
		var pulse = 0.5 + sin(game.trembo_anim_time * 4.0) * 0.12
		game.draw_arc(trembo_screen + Vector2(0, 34), 25.0, 0, TAU, 30, Color(0.32, 0.84, 1.0, pulse), 2.0)
	if game.petro_active:
		var petro_texture = game._petro_frame()
		var size = Vector2(58, 72) if game.petro_evolution == 1 else (Vector2(86, 104) if game.petro_evolution == 2 else Vector2(122, 138))
		var petro_screen = game.petro_pos - camera
		game._draw_dynamic_shadow_fit(petro_texture, petro_screen, size, false, true, 0.42)
		game._draw_entity_fit(petro_texture, petro_screen, size, Color.WHITE, true)
		game._draw_bar(petro_screen + Vector2(-28, - size.y * 0.55), 56, clamp(game.petro_hp / max(1.0, game.petro_hp_max), 0.0, 1.0), Color(0.18, 0.94, 1.0))
		game._draw_centered("PETRO %d" % game.petro_evolution, petro_screen + Vector2(0, - size.y * 0.55 - 8), 12, Color(0.78, 1.0, 1.0, 0.92))


static func _draw_devorador_world(game: Node2D, camera: Vector2) -> void :
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for effect in game.devorador_effects:
		var pos: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
		var life: float = float(effect.get("life", 0.0))
		var max_life: float = max(0.01, float(effect.get("max", 1.0)))
		var ratio: float = clamp(life / max_life, 0.0, 1.0)
		var radius: float = float(effect.get("radius", 120.0)) * (1.0 - ratio * 0.28)
		var phase: float = float(effect.get("phase", 0.0))
		game.draw_circle(pos, radius * (1.0 - ratio) * 0.18, Color(0.1, 0.0, 0.08, 0.3 * ratio))
		game.draw_arc(pos, radius, 0, TAU, 96, Color(0.96, 0.12, 0.72, 0.18 + ratio * 0.24), 5.0)
		game.draw_arc(pos, radius * 0.64, phase + t * 2.2, phase + t * 2.2 + PI * 1.3, 48, Color(1.0, 0.38, 0.92, 0.54 * ratio), 4.0)
		for i in range(8):
			var a: float = phase + t * 1.6 + float(i) * TAU / 8.0
			var outer: Vector2 = pos + Vector2.from_angle(a) * radius * 0.92
			var inner: Vector2 = pos + Vector2.from_angle(a + sin(t + i) * 0.18) * radius * 0.2
			game.draw_line(outer, inner, Color(1.0, 0.22, 0.84, 0.34 * ratio), 2.0, true)
	if game.devorador_mark_kind != "":
		var mark_pos: Vector2 = game.devorador_mark_pos
		if game.devorador_mark_kind == "enemy":
			var enemy = game._enemy_by_uid(game.devorador_mark_uid)
			if enemy != null:
				mark_pos = Vector2(enemy.get("pos", mark_pos))
		elif game.devorador_mark_kind == "boss" and game.boss_active:
			mark_pos = game.boss_pos
		var p: Vector2 = mark_pos - camera
		var pulse: float = 0.5 + 0.5 * sin(t * 5.2)
		var r: float = 48.0 if game.devorador_mark_kind == "enemy" else 92.0
		game.draw_circle(p, r * 0.55, Color(0.12, 0.0, 0.1, 0.18 + pulse * 0.08))
		game.draw_arc(p, r, t * 1.8, t * 1.8 + PI * 1.65, 56, Color(1.0, 0.18, 0.82, 0.7), 3.0)
		game.draw_arc(p, r * 0.72, - t * 2.1, - t * 2.1 + PI * 1.45, 44, Color(0.34, 0.92, 1.0, 0.42), 2.0)
		var crown_y: float = p.y - r * 0.82
		game.draw_line(Vector2(p.x - 18, crown_y), Vector2(p.x, crown_y - 16.0 - pulse * 6.0), Color(1.0, 0.84, 0.24, 0.82), 2.5)
		game.draw_line(Vector2(p.x, crown_y - 16.0 - pulse * 6.0), Vector2(p.x + 18, crown_y), Color(1.0, 0.84, 0.24, 0.82), 2.5)
		game.draw_line(Vector2(p.x - 24, crown_y + 5), Vector2(p.x + 24, crown_y + 5), Color(1.0, 0.18, 0.82, 0.74), 2.5)
	if game.devorador_destiny_shield > 0.0 and game.devorador_shield_timer > 0.0:
		var shield_pos: Vector2 = game.player_pos - camera
		var shield_ratio: float = clamp(game.devorador_shield_timer / game.DEVORADOR_SHIELD_DURATION, 0.0, 1.0)
		var shield_pulse: float = 0.5 + 0.5 * sin(t * 7.0)
		var shield_radius: float = 50.0 + shield_pulse * 5.0
		game.draw_circle(shield_pos, shield_radius, Color(0.96, 0.12, 0.72, 0.08 + shield_ratio * 0.1))
		game.draw_arc(shield_pos, shield_radius, t * 2.5, t * 2.5 + PI * 1.55, 60, Color(1.0, 0.2, 0.84, 0.62 * shield_ratio), 3.0)
		game.draw_arc(shield_pos, shield_radius + 8.0, - t * 1.8, - t * 1.8 + PI * 1.1, 48, Color(0.36, 0.94, 1.0, 0.42 * shield_ratio), 2.0)


static func _draw_common_card_world(game: Node2D, camera: Vector2) -> void :
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for effect in game.common_card_effects:
		var pos: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
		var life: float = float(effect.get("life", 0.0))
		var max_life: float = max(0.01, float(effect.get("max", 1.0)))
		var ratio: float = clamp(life / max_life, 0.0, 1.0)
		var radius: float = float(effect.get("radius", 46.0)) * (1.0 - ratio * 0.18)
		var color: Color = Color(effect.get("color", Color(0.86, 0.94, 1.0)))
		match String(effect.get("kind", "")):
			"choque":
				color = Color(0.92, 0.86, 1.0, 0.7 * ratio)
				game.draw_circle(pos, radius * 0.25, Color(1.0, 1.0, 1.0, 0.2 * ratio))
				game.draw_arc(pos, radius, t * 4.0, t * 4.0 + PI * 1.35, 54, color, 4.0)
				game.draw_arc(pos, radius * 0.62, - t * 4.6, - t * 4.6 + PI * 1.1, 44, Color(0.42, 1.0, 1.0, 0.5 * ratio), 3.0)
			"choque_seed":
				game.draw_arc(pos, radius, 0.0, TAU, 20, Color(0.7, 0.92, 1.0, 0.26 * ratio), 2.0)
			"ferrolho":
				game.draw_arc(pos, radius, 0.0, TAU, 48, Color(0.92, 0.58, 1.0, 0.58 * ratio), 4.0)
				game.draw_line(pos + Vector2(0, - radius * 0.75), pos + Vector2(0, radius * 0.34), Color(0.96, 0.78, 1.0, 0.72 * ratio), 5.0, true)
			"limiar":
				game.draw_arc(pos, radius, 0.0, TAU * 0.7, 52, Color(color.r, color.g, color.b, 0.64 * ratio), 5.0)
				game.draw_arc(pos, radius * 0.58, PI, PI + TAU * 0.55, 38, Color(color.r, color.g, color.b, 0.4 * ratio), 3.0)
			"desvio_gain":
				game.draw_arc(game.player_pos - camera, 54.0, t * 2.2, t * 2.2 + PI * 1.25, 48, Color(0.74, 0.48, 1.0, 0.52 * ratio), 3.0)
			"desvio_hit":
				game.draw_arc(pos, radius, - t * 3.0, - t * 3.0 + PI * 1.5, 48, Color(0.74, 0.48, 1.0, 0.68 * ratio), 4.0)
			"ponto_cego":
				game.draw_arc(pos, radius, PI * 0.18, PI * 1.82, 44, Color(1.0, 0.86, 0.34, 0.62 * ratio), 3.0)
				game.draw_line(pos + Vector2(-18, - radius * 0.45), pos + Vector2(18, - radius * 0.45), Color(1.0, 0.86, 0.34, 0.72 * ratio), 3.0, true)
			"tregua":
				game.draw_circle(pos, radius * 0.46, Color(0.38, 1.0, 0.72, 0.1 * ratio))
				game.draw_arc(pos, radius, - t * 1.4, TAU - t * 1.4, 48, Color(0.38, 1.0, 0.72, 0.48 * ratio), 2.5)
				game.draw_arc(pos, radius * 0.68, t * 1.2, t * 1.2 + PI * 1.3, 36, Color(0.44, 0.92, 1.0, 0.38 * ratio), 2.0)
			"cinzas":
				game.draw_arc(pos, radius, t * 3.0, t * 3.0 + PI * 1.45, 40, Color(1.0, 0.58, 0.28, 0.58 * ratio), 3.0)
				game.draw_circle(pos, radius * 0.25, Color(0.4, 0.18, 0.08, 0.18 * ratio))
			"casulo":
				for i in range(5):
					var a = t * 1.8 + float(i) * TAU / 5.0
					var p = pos + Vector2.from_angle(a) * radius * 0.72
					game.draw_circle(p, 7.0, Color(0.54, 1.0, 0.86, 0.46 * ratio))
				game.draw_arc(pos, radius, - t * 2.0, TAU - t * 2.0, 54, Color(0.54, 1.0, 0.86, 0.52 * ratio), 3.0)
			"passagem":
				game.draw_circle(pos, radius * 0.38, Color(0.72, 0.9, 1.0, 0.13 * ratio))
				game.draw_arc(pos, radius, t * 2.6, t * 2.6 + PI * 1.6, 48, Color(0.72, 0.9, 1.0, 0.55 * ratio), 2.4)
			"ancora":
				game.draw_arc(pos, radius, 0.0, TAU, 60, Color(0.34, 1.0, 0.66, 0.42 * ratio), 2.6)
				game.draw_line(pos + Vector2(0, -18), pos + Vector2(0, 18), Color(0.34, 1.0, 0.66, 0.62 * ratio), 3.0, true)
				game.draw_line(pos + Vector2(-14, 8), pos + Vector2(14, 8), Color(0.34, 1.0, 0.66, 0.5 * ratio), 2.0, true)
			"rastro_spawn":
				game.draw_circle(pos, radius * 0.35, Color(0.34, 1.0, 0.86, 0.16 * ratio))
				game.draw_arc(pos, radius, t * 2.2, t * 2.2 + PI * 1.55, 44, Color(0.34, 1.0, 0.86, 0.58 * ratio), 2.3)
			"rebate", "rebate_fail":
				game.draw_arc(pos, radius, - t * 4.0, - t * 4.0 + PI * 1.7, 42, Color(1.0, 0.76, 0.24, 0.62 * ratio), 2.8)
				game.draw_line(pos + Vector2( - radius * 0.35, 0), pos + Vector2(radius * 0.35, 0), Color(1.0, 0.92, 0.5, 0.5 * ratio), 2.0, true)
			"impulso":
				game.draw_arc(pos, radius, - PI * 0.45, PI * 1.45, 48, Color(0.42, 0.78, 1.0, 0.6 * ratio), 3.0)
				game.draw_arc(pos, radius * 0.65, PI * 0.35, PI * 1.65, 34, Color(1.0, 0.78, 0.24, 0.48 * ratio), 2.0)
			"eco":
				for i in range(3):
					game.draw_arc(pos, radius * (0.55 + float(i) * 0.22), t * (1.0 + i), TAU + t * (1.0 + i), 48, Color(0.86, 0.64, 1.0, 0.34 * ratio), 1.6 + i)
			"zona":
				game.draw_circle(pos, radius, Color(0.44, 1.0, 0.7, 0.045 * ratio))
				game.draw_arc(pos, radius, 0.0, TAU, 72, Color(0.44, 1.0, 0.7, 0.46 * ratio), 3.0)
			"folego":
				var dir = game.last_facing.normalized()
				if dir.length() <= 0.05:
					dir = Vector2.RIGHT
				game.draw_line(pos - dir * radius * 0.65, pos + dir * radius * 0.7, Color(1.0, 0.56, 0.22, 0.54 * ratio), 4.0, true)
				game.draw_arc(pos, radius, dir.angle() - 0.65, dir.angle() + 0.65, 28, Color(1.0, 0.86, 0.34, 0.58 * ratio), 2.0)
			"margem", "margem_reduce":
				game.draw_arc(pos, radius, - t * 2.0, TAU - t * 2.0, 50, Color(1.0, 0.36, 0.46, 0.58 * ratio), 2.6)
				game.draw_rect(Rect2(pos - Vector2(18, 10), Vector2(36, 20)), Color(0.16, 0.02, 0.05, 0.18 * ratio), true)
			"ressonancia", "ressonancia_ready":
				for i in range(4):
					var a = t * 1.4 + float(i) * TAU / 4.0
					game.draw_circle(pos + Vector2.from_angle(a) * radius * 0.65, 4.8, Color(0.58, 1.0, 0.96, 0.72 * ratio))
				game.draw_arc(pos, radius, t, TAU + t, 64, Color(0.58, 1.0, 0.96, 0.38 * ratio), 2.0)
			"intervalo":
				game.draw_arc(pos, radius, - t * 3.0, - t * 3.0 + PI * 1.65, 54, Color(0.58, 0.84, 1.0, 0.62 * ratio), 3.0)
				game.draw_arc(pos, radius * 0.62, t * 4.2, t * 4.2 + PI * 1.15, 36, Color(0.86, 0.96, 1.0, 0.46 * ratio), 2.0)
				game.draw_line(pos + Vector2(-18, 0), pos + Vector2(18, 0), Color(0.58, 0.84, 1.0, 0.58 * ratio), 2.0, true)
			"nucleo":
				game.draw_circle(pos, radius * 0.42, Color(0.36, 1.0, 0.58, 0.12 * ratio))
				game.draw_arc(pos, radius, t * 1.7, t * 1.7 + PI * 1.72, 58, Color(0.36, 1.0, 0.58, 0.54 * ratio), 2.6)
				game.draw_arc(pos, radius * 0.7, - t * 1.2, - t * 1.2 + PI * 1.2, 42, Color(0.66, 1.0, 0.9, 0.42 * ratio), 1.8)
			"limiar_ruina":
				game.draw_arc(pos, radius, PI * 0.08, PI * 1.92, 50, Color(1.0, 0.32, 0.22, 0.64 * ratio), 3.4)
				game.draw_line(pos + Vector2( - radius * 0.42, - radius * 0.28), pos + Vector2(radius * 0.42, radius * 0.28), Color(1.0, 0.72, 0.26, 0.58 * ratio), 2.2, true)
				game.draw_circle(pos, radius * 0.18, Color(1.0, 0.18, 0.12, 0.16 * ratio))
			"estase":
				game.draw_circle(pos, radius * 0.48, Color(0.52, 1.0, 0.86, 0.1 * ratio))
				game.draw_arc(pos, radius, 0.0, TAU, 70, Color(0.52, 1.0, 0.86, 0.44 * ratio), 2.0)
				game.draw_arc(pos, radius * 0.78, PI * 0.15, PI * 0.85, 34, Color(0.86, 1.0, 0.96, 0.48 * ratio), 2.0)
	if game.desvio_probabilidade_charges > 0:
		var player_screen: Vector2 = game.player_pos - camera
		for i in range(game.desvio_probabilidade_charges):
			var angle: float = t * 2.4 + float(i) * TAU / float(max(1, game.desvio_probabilidade_charges))
			var p: Vector2 = player_screen + Vector2.from_angle(angle) * 58.0
			game.draw_circle(p, 5.5, Color(0.74, 0.48, 1.0, 0.76))
			game.draw_arc(p, 10.0, - angle, - angle + PI, 18, Color(0.92, 0.82, 1.0, 0.62), 1.8)
	var support_player_screen: Vector2 = game.player_pos - camera
	for vestige in game.rastro_vestiges:
		var vestige_pos: Vector2 = Vector2(vestige.get("pos", game.player_pos)) - camera
		var vestige_ratio: float = clamp(float(vestige.get("life", 0.0)) / maxf(0.01, float(vestige.get("max", 1.0))), 0.0, 1.0)
		var arm = float(vestige.get("arm", 0.0))
		var vestige_radius = game._rastro_activation_radius() * (0.62 + sin(t * 4.0 + float(vestige.get("phase", 0.0))) * 0.05)
		game.draw_circle(vestige_pos, vestige_radius, Color(0.34, 1.0, 0.86, 0.035 * vestige_ratio))
		game.draw_arc(vestige_pos, vestige_radius, t * 1.5, t * 1.5 + PI * 1.65, 56, Color(0.34, 1.0, 0.86, (0.22 if arm <= 0.0 else 0.1) * vestige_ratio), 2.0)
	if game.tregua_regenerativa_active:
		var pulse: float = 0.5 + sin(t * 5.0) * 0.5
		game.draw_circle(support_player_screen, 48.0 + pulse * 5.0, Color(0.38, 1.0, 0.72, 0.08 + pulse * 0.04))
		game.draw_arc(support_player_screen, 54.0, - t * 1.2, TAU - t * 1.2, 56, Color(0.38, 1.0, 0.72, 0.46), 2.0)
	if game.estase_reparadora_active:
		var estase_pulse: float = 0.5 + sin(t * 4.0) * 0.5
		game.draw_circle(support_player_screen, 50.0 + estase_pulse * 7.0, Color(0.52, 1.0, 0.86, 0.07 + estase_pulse * 0.05))
		game.draw_arc(support_player_screen, 60.0, t * 0.8, t * 0.8 + PI * 1.75, 64, Color(0.52, 1.0, 0.86, 0.48), 2.2)
		game.draw_arc(support_player_screen, 42.0, - t * 1.1, - t * 1.1 + PI * 1.25, 42, Color(0.86, 1.0, 0.96, 0.32), 1.8)
	if game.casulo_reativo_timer > 0.0:
		var casulo_world_ratio: float = clamp(game.casulo_reativo_timer / max(0.01, game._casulo_duration()), 0.0, 1.0)
		game.draw_circle(support_player_screen, 56.0, Color(0.54, 1.0, 0.86, 0.12 * casulo_world_ratio))
		game.draw_arc(support_player_screen, 62.0, t * 2.4, t * 2.4 + PI * 1.5, 52, Color(0.54, 1.0, 0.86, 0.68 * casulo_world_ratio), 4.0)
	if game.passagem_intangivel_timer > 0.0:
		var passagem_world_ratio: float = clamp(game.passagem_intangivel_timer / max(0.01, game._passagem_duration()), 0.0, 1.0)
		game.draw_circle(support_player_screen, 44.0, Color(0.72, 0.9, 1.0, 0.1 * passagem_world_ratio))
		game.draw_arc(support_player_screen, 50.0, - t * 3.0, - t * 3.0 + PI * 1.8, 48, Color(0.72, 0.9, 1.0, 0.64 * passagem_world_ratio), 2.6)
	if not game.ancora_vital_state.is_empty():
		var anchor_pos: Vector2 = Vector2(game.ancora_vital_state.get("pos", game.player_pos)) - camera
		var radius = float(game.ancora_vital_state.get("radius", game._ancora_radius()))
		var ancora_world_ratio: float = clamp(float(game.ancora_vital_state.get("life", 0.0)) / max(0.01, float(game.ancora_vital_state.get("max", game.ANCORA_VITAL_LIFE))), 0.0, 1.0)
		game.draw_circle(anchor_pos, radius, Color(0.34, 1.0, 0.66, 0.045 * ancora_world_ratio))
		game.draw_arc(anchor_pos, radius, t * 1.4, TAU + t * 1.4, 72, Color(0.34, 1.0, 0.66, 0.42 * ancora_world_ratio), 2.4)
		game.draw_circle(anchor_pos, 13.0 + sin(t * 7.0) * 2.0, Color(0.34, 1.0, 0.66, 0.48 * ancora_world_ratio))


static func _draw_rare_card_world(game: Node2D, camera: Vector2) -> void :
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for effect in game.rare_card_effects:
		var pos: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
		var life: float = float(effect.get("life", 0.0))
		var max_life: float = max(0.01, float(effect.get("max", 1.0)))
		var ratio: float = clamp(life / max_life, 0.0, 1.0)
		var radius: float = float(effect.get("radius", 84.0))
		match String(effect.get("kind", "")):
			"mandamento":
				var law_color = Color(1.0, 0.78, 0.24, 0.68 * ratio)
				for i in range(3):
					var a = t * 2.6 + float(i) * TAU / 3.0
					game.draw_arc(pos, radius * (0.62 + float(i) * 0.18), a, a + PI * 1.05, 48, law_color, 3.0)
				game.draw_line(pos + Vector2( - radius * 0.52, 0.0), pos + Vector2(radius * 0.52, 0.0), Color(1.0, 0.96, 0.7, 0.48 * ratio), 2.0, true)
			"carta_zero":
				for i in range(4):
					var r = radius * (0.35 + float(i) * 0.18) * (1.0 + (1.0 - ratio) * 0.18)
					game.draw_arc(pos, r, t * (1.4 + i * 0.3), t * (1.4 + i * 0.3) + PI * 1.42, 54, Color(0.9, 0.96, 1.0, (0.42 - i * 0.06) * ratio), 2.0)
				game.draw_circle(pos, 10.0 + 10.0 * (1.0 - ratio), Color(1.0, 1.0, 1.0, 0.18 * ratio))
			"necro_spawn", "necro_ready":
				game.draw_circle(pos, radius * 0.36, Color(0.22, 0.02, 0.42, 0.2 * ratio))
				game.draw_arc(pos, radius, - t * 2.0, - t * 2.0 + PI * 1.7, 56, Color(0.46, 1.0, 0.94, 0.52 * ratio), 3.0)
				game.draw_arc(pos, radius * 0.68, t * 2.8, t * 2.8 + PI * 1.1, 38, Color(0.78, 0.38, 1.0, 0.46 * ratio), 2.0)
			"antimatter":
				game.draw_circle(pos, radius * (1.0 - ratio) * 0.72, Color(0.04, 0.0, 0.09, 0.42 * ratio))
				for i in range(7):
					var a = t * 5.0 + float(i) * TAU / 7.0
					var outer = pos + Vector2.from_angle(a) * radius * (0.92 - (1.0 - ratio) * 0.18)
					game.draw_line(outer, pos, Color(0.84, 0.28, 1.0, 0.36 * ratio), 2.2, true)
				game.draw_arc(pos, radius, t * 3.2, t * 3.2 + PI * 1.55, 72, Color(0.84, 0.28, 1.0, 0.72 * ratio), 4.0)
			"egide":
				game.draw_circle(pos, radius * 0.42, Color(0.4, 0.02, 0.02, 0.18 * ratio))
				game.draw_arc(pos, radius, t * 2.4, t * 2.4 + PI * 1.62, 62, Color(1.0, 0.72, 0.22, 0.66 * ratio), 3.2)
				game.draw_arc(pos, radius * 0.72, - t * 2.0, - t * 2.0 + PI * 1.22, 44, Color(1.0, 0.24, 0.3, 0.52 * ratio), 2.2)
				game.draw_line(pos + Vector2(-18, -10), pos + Vector2(0, 16), Color(1.0, 0.86, 0.44, 0.54 * ratio), 2.4, true)
				game.draw_line(pos + Vector2(18, -10), pos + Vector2(0, 16), Color(1.0, 0.86, 0.44, 0.54 * ratio), 2.4, true)
	if game._mandamento_count() > 0 and game.mandamento_invulnerability > 0.0:
		var p: Vector2 = game.player_pos - camera
		var r: float = 52.0 + sin(t * 12.0) * 4.0
		game.draw_circle(p, r, Color(1.0, 0.78, 0.24, 0.12))
		game.draw_arc(p, r, t * 2.8, t * 2.8 + PI * 1.6, 54, Color(1.0, 0.86, 0.36, 0.74), 3.0)
	if game.antimatter_armed:
		var p: Vector2 = game.player_pos - camera
		var pulse: float = 0.5 + sin(t * 9.0) * 0.5
		game.draw_arc(p, 64.0 + pulse * 9.0, - t * 3.4, TAU - t * 3.4, 70, Color(0.84, 0.26, 1.0, 0.54 + pulse * 0.18), 3.0)
	elif game._rare_card_count("coracao_antimateria") > 0 and game.antimatter_charge > 0.0:
		var ratio: float = clamp(game.antimatter_charge / max(1.0, game._antimatter_required_charge()), 0.0, 1.0)
		game.draw_arc(game.player_pos - camera, 48.0, - PI * 0.5, - PI * 0.5 + TAU * ratio, 48, Color(0.84, 0.26, 1.0, 0.5), 2.0)
	if game.stored_excess > 1.0:
		var vault_ratio: float = clamp(game.stored_excess / max(1.0, game.player_damage * 12.0), 0.0, 1.0)
		var p: Vector2 = game.player_pos - camera + Vector2(0, 30)
		game.draw_arc(p, 42.0 + vault_ratio * 18.0, t * 1.6, t * 1.6 + PI * 1.25, 42, Color(1.0, 0.72, 0.2, 0.4 + vault_ratio * 0.2), 3.0)
	if game.egide_hemofaga_shield > 0.0:
		var p: Vector2 = game.player_pos - camera
		var limit = maxf(1.0, game._egide_shield_limit())
		var shield_ratio = clampf(game.egide_hemofaga_shield / limit, 0.0, 1.0)
		var pulse = 0.5 + sin(t * 5.6) * 0.5
		var r = 56.0 + shield_ratio * 14.0 + pulse * 4.0
		game.draw_circle(p, r, Color(1.0, 0.28, 0.18, 0.05 + shield_ratio * 0.09))
		game.draw_arc(p, r, t * 1.5, t * 1.5 + PI * 1.62, 68, Color(1.0, 0.72, 0.22, 0.34 + shield_ratio * 0.26), 2.6)
		game.draw_arc(p, r * 0.78, - t * 1.8, - t * 1.8 + PI * 1.12, 44, Color(1.0, 0.22, 0.26, 0.26 + shield_ratio * 0.22), 1.8)
	for specter in game.active_necro_specters:
		var pos: Vector2 = Vector2(specter.get("pos", game.player_pos)) - camera
		var life_ratio: float = clamp(float(specter.get("life", 0.0)) / max(0.01, float(specter.get("max", 1.0))), 0.0, 1.0)
		var tex: Texture2D = game._enemy_texture(specter)
		var size = Vector2(62, 62) if not bool(specter.get("elite", false)) else Vector2(76, 76)
		game._draw_dynamic_shadow_fit(tex, pos + Vector2(0, 5), size, false, true, 0.24 * life_ratio)
		game._draw_entity_fit(tex, pos + Vector2(0, sin(t * 5.0 + float(specter.get("phase", 0.0))) * 3.0), size, Color(0.5, 1.0, 0.94, 0.46 + life_ratio * 0.3), true)
		game.draw_arc(pos, size.x * 0.52, t * 2.0, t * 2.0 + PI * 1.2, 36, Color(0.46, 1.0, 0.94, 0.46 * life_ratio), 2.0)


static func _draw_acorrentada_world(game: Node2D, camera: Vector2) -> void :
	if game.manifestation_key != "acorrentada" and game.acorrentada_links.is_empty() and game.acorrentada_visuals.is_empty():
		return
	var t: float = float(Time.get_ticks_msec()) * 0.001
	game._draw_acorrentada_worn_chains(camera, t)
	for link in game.acorrentada_links:
		var fade: float = clampf(float(link.get("life", 0.0)) / max(0.01, float(link.get("max", 1.0))), 0.0, 1.0)
		match String(link.get("kind", "")):
			"pair", "triad":
				var targets: Array = link.get("targets", [])
				var chains: Dictionary = link.get("chains", {})
				for i in range(targets.size()):
					for j in range(i + 1, targets.size()):
						if not game._acorrentada_target_alive(targets[i]) or not game._acorrentada_target_alive(targets[j]):
							continue
						var key = "%d_%d" % [i, j]
						if chains.has(key):
							game._draw_physical_chain(chains[key], camera, Color(0.2, 0.84, 1.0, 0.82 * fade), 8.0, fade, false)
						else:
							game._draw_acorrentada_chain(game._acorrentada_target_pos(targets[i]) - camera, game._acorrentada_target_pos(targets[j]) - camera, Color(0.2, 0.84, 1.0, 0.82 * fade), 8.0, fade, false)
			"anchor":
				var target: Dictionary = link.get("target", {})
				var anchor = Vector2(link.get("anchor", game.player_pos))
				if target.is_empty():
					game.draw_arc(anchor - camera, 38.0, 0.0, TAU, 28, Color(0.2, 0.84, 1.0, 0.42 * fade), 2.0)
				elif game._acorrentada_target_alive(target):
					if link.has("physics"):
						game._draw_physical_chain(link["physics"], camera, Color(0.2, 0.84, 1.0, 0.78 * fade), 7.0, fade, false)
					else:
						game._draw_acorrentada_chain(game._acorrentada_target_pos(target) - camera, anchor - camera, Color(0.2, 0.84, 1.0, 0.78 * fade), 7.0, fade, false)
					game.draw_arc(anchor - camera, 28.0 + sin(t * 6.0) * 3.0, 0.0, TAU, 28, Color(0.88, 0.16, 0.12, 0.52 * fade), 2.0)
			"boss":
				if game.boss_active and game.boss_hp > 0.0:
					game.draw_arc(game.boss_pos - camera, 132.0 + sin(t * 4.0) * 5.0, 0.0, TAU, 72, Color(0.2, 0.84, 1.0, 0.3 * fade), 3.0)
					game.draw_arc(game.boss_pos - camera, 94.0, t, t + PI * 1.3, 54, Color(0.88, 0.16, 0.12, 0.46 * fade), 3.0)
	for visual in game.acorrentada_visuals:
		var fade: float = clampf(float(visual.get("life", 0.0)) / max(0.01, float(visual.get("max", 1.0))), 0.0, 1.0)
		match String(visual.get("kind", "")):
			"light":
				if visual.has("physics"):
					game._draw_physical_chain(visual["physics"], camera, Color(0.18, 0.86, 1.0, 0.88 * fade), 6.0, fade, true)
				else:
					game._draw_acorrentada_chain(Vector2(visual.get("a", game.player_pos)) - camera, Vector2(visual.get("b", game.player_pos)) - camera, Color(0.18, 0.86, 1.0, 0.88 * fade), 6.0, fade, true)
			"heavy":
				if visual.has("physics"):
					game._draw_physical_chain(visual["physics"], camera, Color(0.92, 0.12, 0.1, 0.84 * fade), 10.0, fade, false)
				else:
					game._draw_acorrentada_chain(Vector2(visual.get("a", game.player_pos)) - camera, Vector2(visual.get("b", game.player_pos)) - camera, Color(0.92, 0.12, 0.1, 0.84 * fade), 10.0, fade, false)
			"cross":
				if visual.has("physics_1") and visual.has("physics_2"):
					game._draw_physical_chain(visual["physics_1"], camera, Color(0.18, 0.86, 1.0, 0.9 * fade), 8.0, fade, true)
					game._draw_physical_chain(visual["physics_2"], camera, Color(0.92, 0.12, 0.1, 0.88 * fade), 10.0, fade, false)
				else:
					var a = Vector2(visual.get("a", game.player_pos))
					var b = Vector2(visual.get("b", game.player_pos))
					var dir = (b - a).normalized()
					if dir.length() <= 0.01:
						dir = Vector2.RIGHT
					var side = dir.orthogonal() * 42.0
					game._draw_acorrentada_chain(a + side - camera, b - side - camera, Color(0.18, 0.86, 1.0, 0.9 * fade), 8.0, fade, true)
					game._draw_acorrentada_chain(a - side - camera, b + side - camera, Color(0.92, 0.12, 0.1, 0.88 * fade), 10.0, fade, false)
				var b = Vector2(visual.get("b", game.player_pos))
				game.draw_circle(b - camera, 18.0 + 16.0 * (1.0 - fade), Color(1.0, 1.0, 1.0, 0.3 * fade))
			"sweep":
				var origin = Vector2(visual.get("pos", game.player_pos)) - camera
				var dir = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
				var radius = float(visual.get("radius", 260.0))
				var start_a = dir.angle() - deg_to_rad(58.0)
				var end_a = dir.angle() + deg_to_rad(58.0)
				for k in range(4):
					game.draw_arc(origin, radius * (0.52 + float(k) * 0.12), start_a, end_a, 36, Color(0.92, 0.12, 0.1, (0.26 + k * 0.06) * fade), 3.0 + k)
			"implosion":
				var center = Vector2(visual.get("pos", game.player_pos)) - camera
				var radius = float(visual.get("radius", 300.0)) * (0.35 + 0.65 * fade)
				game.draw_circle(center, radius, Color(0.12, 0.0, 0.0, 0.1 * fade))
				game.draw_arc(center, radius, - t * 2.4, TAU - t * 2.4, 80, Color(1.0, 0.18, 0.14, 0.52 * fade), 4.0)
	for enemy in game.enemies:
		var count: int = game._acorrentada_enemy_elos(enemy)
		if count <= 0:
			continue
		var pos: Vector2 = Vector2(enemy["pos"]) - camera
		var flash = clampf(float(enemy.get("acorrentada_flash", 0.0)) / 0.7, 0.0, 1.0)
		for i in range(count):
			var angle: float = t * (1.2 + count * 0.18) + float(i) * TAU / float(max(1, count))
			var p: Vector2 = pos + Vector2.from_angle(angle) * (34.0 + count * 4.0)
			game.draw_arc(p, 8.0 + flash * 3.0, angle, angle + PI * 1.55, 16, Color(0.18, 0.86, 1.0, 0.62 + flash * 0.26), 2.0)
	if game.boss_active and game.boss_hp > 0.0 and game.acorrentada_boss_elos > 0:
		var pos: Vector2 = game.boss_pos - camera
		for i in range(game.acorrentada_boss_elos):
			var angle: float = t * 0.9 + float(i) * TAU / float(max(1, game.acorrentada_boss_elos))
			game.draw_arc(pos + Vector2.from_angle(angle) * 72.0, 14.0, angle, angle + PI * 1.55, 18, Color(0.18, 0.86, 1.0, 0.48), 2.4)
	if game.acorrentada_boss_crack_timer > 0.0 and game.boss_active:
		game.draw_arc(game.boss_pos - camera, 108.0, - t * 1.2, TAU - t * 1.2, 64, Color(1.0, 0.22, 0.16, 0.48), 3.0)


static func _draw_acorrentada_worn_chains(game: Node2D, camera: Vector2, t: float) -> void :
	if game.manifestation_key != "acorrentada":
		return
	var base_fade: float = 0.58 + clampf(game.acorrentada_tension / 100.0, 0.0, 1.0) * 0.34
	for entry in game.acorrentada_worn_chains:
		if not entry.has("physics"):
			continue
		var index = int(entry.get("index", 0))
		var warm = index % 2 == 1
		var attacking: bool = entry.has("attack_motion")
		var color = Color(1.0, 0.16, 0.1, base_fade) if warm else Color(0.05, 0.92, 1.0, base_fade)
		var width = (8.8 if warm else 7.6) if attacking else (6.2 if warm else 5.2)
		var chain_fade = minf(1.0, base_fade + (0.3 if attacking else 0.0))
		game._draw_physical_chain(entry["physics"], camera, color, width, chain_fade, not warm)
		if attacking:
			var tip = Vector2(entry["physics"].get("b", game.player_pos)) - camera
			game.draw_circle(tip, 8.0, Color(color.r, color.g, color.b, 0.18 * chain_fade))
			game.draw_arc(tip, 13.0, - t * 5.0, TAU - t * 5.0, 18, Color(1.0, 0.92, 0.72, 0.68 * chain_fade), 2.0)
		var pulse_center: Vector2 = game.player_pos - camera + Vector2.from_angle(t * (1.4 + index * 0.12) + float(index)) * (28.0 + index * 3.0)
		game.draw_circle(pulse_center, 3.2 + sin(t * 8.0 + index) * 1.2, Color(color.r, color.g, color.b, 0.32 * base_fade))


static func _draw_acorrentada_chain(game: Node2D, a: Vector2, b: Vector2, color: Color, width: float, fade: float, light: = false) -> void :
	var delta = b - a
	var length = delta.length()
	if length <= 4.0:
		return
	var dir = delta / length
	var normal = dir.orthogonal()
	var spacing = 18.0 if light else 22.0
	var count: int = max(2, int(length / spacing))
	game._draw_acorrentada_chain_glow(PackedVector2Array([a, b]), color, width, fade)
	for i in range(count + 1):
		var k = float(i) / float(count)
		var center: Vector2 = a.lerp(b, k) + normal * sin(k * TAU * 2.0 + game.time_alive * 8.0) * (2.0 if light else 4.0)
		var tangent = dir * (7.0 if light else 9.0)
		var side = normal * (4.0 if light else 6.0)
		var p1: Vector2 = center - tangent
		var p2: Vector2 = center + side
		var p3: Vector2 = center + tangent
		var p4: Vector2 = center - side
		var link_color = game._acorrentada_link_color(color, fade, i, light)
		game.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), game._acorrentada_link_outline_color(color, fade), max(2.0, width * 0.42), true)
		game.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), link_color, max(1.4, width * 0.24), true)
		if i % 3 == 0:
			game.draw_circle(center, max(1.5, width * 0.19), game._acorrentada_link_outline_color(color, fade * 0.65))
			game.draw_circle(center, max(1.1, width * 0.15), Color(1.0, 0.96, 0.7, 0.42 * fade))


static func _draw_physical_chain(game: Node2D, chain: Dictionary, camera: Vector2, color: Color, width: float, fade: float, light: = false) -> void :
	var points: Array = chain.get("points", [])
	var num_nodes: int = points.size()
	if num_nodes < 2:
		return

	var backing_points: PackedVector2Array = PackedVector2Array()
	for i in range(num_nodes):
		var p: Dictionary = points[i]
		backing_points.append(Vector2(p.get("pos", Vector2.ZERO)) - camera)
	game._draw_acorrentada_chain_glow(backing_points, color, width, fade)

	for i in range(num_nodes - 1):
		var p1: Vector2 = Vector2(points[i].get("pos", Vector2.ZERO)) - camera
		var p2: Vector2 = Vector2(points[i + 1].get("pos", Vector2.ZERO)) - camera
		var segment: Vector2 = p2 - p1
		var dist: float = segment.length()
		if dist < 1.0:
			continue
		var dir: Vector2 = segment / dist
		var normal: Vector2 = dir.orthogonal()

		var center: Vector2 = p1 + segment * 0.5

		var is_wide: bool = (i % 2 == 0)
		var link_tangent_len: float = 7.0 if light else 9.0
		var link_side_len: float = (5.5 if light else 8.0) if is_wide else (3.2 if light else 4.5)

		var tangent: Vector2 = dir * link_tangent_len
		var side: Vector2 = normal * link_side_len

		var pt1: Vector2 = center - tangent
		var pt2: Vector2 = center + side
		var pt3: Vector2 = center + tangent
		var pt4: Vector2 = center - side

		game.draw_polyline(PackedVector2Array([pt1, pt2, pt3, pt4, pt1]), game._acorrentada_link_outline_color(color, fade), max(2.0, width * 0.42), true)
		game.draw_polyline(PackedVector2Array([pt1, pt2, pt3, pt4, pt1]), game._acorrentada_link_color(color, fade, i, light), max(1.4, width * 0.24), true)
		if i % 3 == 0:
			game.draw_circle(center, max(1.4, width * 0.18), game._acorrentada_link_outline_color(color, fade * 0.62))
			game.draw_circle(center, max(1.0, width * 0.13), Color(1.0, 0.96, 0.7, 0.38 * fade))


static func _draw_eclipsada_weakpoint(game: Node2D, enemy: Dictionary, camera: Vector2) -> void :
	var p = game._eclipsada_weakpoint_pos(enemy) - camera
	var flash = clampf(float(enemy.get("eclipsada_weak_flash", 0.0)) / 0.45, 0.0, 1.0)
	var alpha = clampf(float(enemy.get("eclipsada_weak_time", 0.0)) / game.ECLIPSADA_Q_WEAKPOINT_TIME, 0.22, 1.0)
	var color = game._eclipsada_color().lerp(Color(1.0, 0.86, 0.28), 0.35 + flash * 0.45)
	game.draw_circle(p, 12.0 + flash * 5.0, Color(color.r, color.g, color.b, 0.18 * alpha))
	game.draw_arc(p, 15.0 + flash * 7.0, - game.time_alive * 5.0, TAU - game.time_alive * 5.0, 32, Color(1.0, 0.88, 0.32, 0.88 * alpha), 2.4 + flash * 1.5)
	game.draw_line(p + Vector2(-7, 0), p + Vector2(7, 0), Color(1.0, 1.0, 1.0, 0.72 * alpha), 1.6)
	game.draw_line(p + Vector2(0, -7), p + Vector2(0, 7), Color(1.0, 1.0, 1.0, 0.72 * alpha), 1.6)


static func _draw_aura_world(game: Node2D, camera: Vector2) -> void :
	if game.aura_state.is_empty():
		return
	var name = String(game.aura_state.get("name", ""))
	var color = game._aura_color()
	var player_screen: Vector2 = game.player_pos - camera
	if name == "Crepuscular":
		game._draw_crepuscular_player_aura(camera, player_screen)
	elif name == "Sanguinaria":
		game._draw_sanguinaria_hunt_path(camera)
		game._draw_sanguinaria_blood_drop(camera)
	if name == "Racional":
		game._draw_rational_aura_world(camera, player_screen, color)
	elif name == "Vanguarda" and float(game.aura_state.get("vanguard_ring", 0.0)) > 0.0:
		game.draw_circle(player_screen, 150.0, Color(1.0, 0.1, 0.02, 0.07))
		for i in range(24):
			var angle = i * TAU / 24.0 + sin(game.time_alive * 3.0 + i) * 0.08
			var foot: Vector2 = player_screen + Vector2.from_angle(angle) * 145.0
			game.draw_line(foot, foot - Vector2(0, 12.0 + sin(game.time_alive * 9.0 + i) * 7.0), Color(1.0, 0.32, 0.04, 0.72), 3.0)
	elif name == "Abissal" and float(game.aura_state.get("abyss_tide", 0.0)) > 0.0:
		for i in range(5): game.draw_arc(player_screen, 190.0 - i * 27.0, game.time_alive * (0.4 + i * 0.12), game.time_alive * (0.4 + i * 0.12) + PI * 1.55, 54, Color(color.r, color.g, color.b, 0.26 - i * 0.025), 5.0 - i * 0.5)
	elif name == "Insana":
		for echo in Array(game.aura_state.get("insane_queue", [])):
			var p = Vector2(echo.get("pos", game.player_pos)) - camera
			game._draw_insane_echo_copy(p, Vector2(echo.get("dir", Vector2.RIGHT)), 0.58, game.time_alive + float(echo.get("delay", 0.0)))
		for echo in game.insane_echo_visuals:
			var ratio: float = clamp(float(echo.get("life", 0.0)) / maxf(0.01, float(echo.get("max", 1.0))), 0.0, 1.0)
			game._draw_insane_echo_copy(Vector2(echo.get("pos", game.player_pos)) - camera, Vector2(echo.get("dir", Vector2.RIGHT)), ratio * 0.72, game.time_alive + float(echo.get("phase", 0.0)))
	elif name == "Voraz":
		for drop in Array(game.aura_state.get("voracious_drops", [])):
			var p = Vector2(drop.get("pos", Vector2.ZERO)) - camera
			var pulse = 0.5 + sin(game.time_alive * 8.0 + p.x) * 0.5
			var boss_particle = bool(drop.get("boss_particle", false))
			game.draw_circle(p, (9.0 if boss_particle else 7.0) + pulse * 3.0, Color(0.92, 0.08, 0.02, 0.9) if boss_particle else Color(0.68, 0.02, 0.03, 0.84))
			game.draw_arc(p, (16.0 if boss_particle else 12.0) + pulse * 3.0, - game.time_alive * 2.8, TAU - game.time_alive * 2.8, 20, Color(1.0, 0.62, 0.08, 0.78) if boss_particle else Color(1.0, 0.34, 0.08, 0.56), 2.5 if boss_particle else 2.0)
	for enemy in game.enemies:
		var p = Vector2(enemy["pos"]) - camera
		if float(enemy.get("aura_burn", 0.0)) > 0.0:
			for i in range(5): game.draw_line(p + Vector2(-18 + i * 9, 22), p + Vector2(-14 + i * 8, -18 - sin(game.time_alive * 11.0 + i) * 8.0), Color(1.0, 0.3 + i * 0.06, 0.02, 0.66), 3.0)
		if float(enemy.get("aura_null", 0.0)) > 0.0:
			game.draw_arc(p, 40.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 40, Color(0.76, 0.96, 1.0, 0.84), 3.0)
			game.draw_circle(p, 30.0, Color(0.0, 0.04, 0.08, 0.2))
		if float(enemy.get("aura_prophecy", 0.0)) > 0.0 or int(game.aura_state.get("prophecy_uid", -1)) == int(enemy.get("uid", -2)):
			var eye = p + Vector2(0, -58)
			game.draw_arc(eye, 15.0, PI * 0.12, PI * 0.88, 18, Color(1.0, 0.9, 0.32, 0.92), 3.0)
			game.draw_arc(eye, 15.0, PI * 1.12, PI * 1.88, 18, Color(1.0, 0.9, 0.32, 0.92), 3.0)
			game.draw_circle(eye, 4.0, Color.WHITE)
		if float(enemy.get("aura_wound", 0.0)) > 0.0:
			for i in range(3): game.draw_line(p + Vector2(-18 + i * 12, -28), p + Vector2(-4 + i * 12, 24), Color(1.0, 0.04, 0.1, 0.82), 3.0)


static func _draw_crepuscular_ocaso_cracks(game: Node2D, center: Vector2, size: Vector2, seed: int, timer: float) -> void:
	var alpha: float = clampf(timer / 3.5, 0.0, 1.0)
	var radius: float = max(size.x, size.y) * 0.34
	for i in range(7):
		var seed_value: int = seed * 37 + i * 71
		var angle: float = float(posmod(seed_value, 360)) * PI / 180.0
		var start_jitter: float = 0.18 + float(posmod(seed * 17 + i * 43, 100)) * 0.0024
		var mid_jitter: float = 0.52 + float(i % 3) * 0.12
		var end_jitter: float = 0.86 + float(i % 2) * 0.14
		var start: Vector2 = center + Vector2.from_angle(angle) * radius * start_jitter
		var mid: Vector2 = center + Vector2.from_angle(angle + sin(float(seed + i)) * 0.35) * radius * mid_jitter
		var end: Vector2 = center + Vector2.from_angle(angle + cos(float(seed - i)) * 0.28) * radius * end_jitter
		game.draw_line(start, mid, Color(0.0, 0.0, 0.0, 0.62 * alpha), 2.8, true)
		game.draw_line(mid, end, Color(0.0, 0.0, 0.0, 0.56 * alpha), 2.2, true)
		if i % 2 == 0:
			game.draw_circle(end, 2.0 + float(i % 3), Color(0.02, 0.0, 0.0, 0.52 * alpha))


static func _draw_sanguinaria_hunt_path(game: Node2D, camera: Vector2) -> void:
	var hunted = game._sanguinaria_find_hunt_enemy()
	if hunted.is_empty():
		return
	var start: Vector2 = Vector2(hunted.get("pos", game.player_pos)) - camera
	var finish: Vector2 = game.player_pos - camera
	var dir: Vector2 = finish - start
	var dist: float = dir.length()
	if dist <= 10.0:
		return
	dir /= dist
	var normal = Vector2(-dir.y, dir.x)
	var steps = clampi(int(dist / 20.0), 10, 32)
	var flow = fmod(game.time_alive * 0.42, 1.0)
	for layer in range(3):
		var layer_offset = float(layer) * 1.71
		var previous = start
		for i in range(1, steps + 1):
			var t: float = float(i) / float(steps)
			var drift: float = sin(t * TAU * 1.65 + game.time_alive * (1.25 + layer * 0.18) + layer_offset) * (7.0 + layer * 4.0)
			drift += sin(t * TAU * 4.2 - game.time_alive * (1.7 + layer * 0.25)) * (2.5 + layer)
			var current = start.lerp(finish, t) + normal * drift
			current += dir * sin(game.time_alive * 2.1 + t * 8.0 + layer_offset) * 3.0
			var segment_alpha = (0.24 - float(layer) * 0.04) * (0.72 + 0.28 * sin(game.time_alive * 3.0 + t * 9.0 + layer_offset))
			var broken = fmod(t + flow + float(layer) * 0.18, 1.0)
			if broken < 0.72:
				game.draw_line(previous, current, Color(0.62 + layer * 0.08, 0.0, 0.045, segment_alpha), 1.2 + layer * 0.35, true)
			previous = current
	for i in range(steps):
		var t: float = (float(i) + 0.35) / float(steps)
		var wave: float = sin(t * TAU * 2.35 + game.time_alive * 2.4) * 13.0 + sin(t * TAU * 5.0 - game.time_alive * 1.8) * 4.0
		var p = start.lerp(finish, t) + normal * wave
		var pulse = 0.72 + 0.28 * sin(game.time_alive * 5.0 + float(i) * 1.37)
		var fade = 1.0 - t * 0.38
		var radius = (11.0 + 7.0 * pulse) * fade
		var alpha = 0.24 * fade
		game.draw_circle(p, radius * 1.25, Color(0.06, 0.0, 0.018, alpha * 0.72))
		game.draw_circle(p, radius, Color(0.62, 0.0, 0.05, alpha))
		if i % 3 == 0:
			game.draw_circle(p + normal * radius * 0.55, radius * 0.46, Color(1.0, 0.07, 0.13, alpha))
		if i % 4 == 1:
			game.draw_arc(p + normal * 3.0, radius * 0.74, game.time_alive * 1.8 + float(i), game.time_alive * 1.8 + float(i) + PI * 0.9, 10, Color(1.0, 0.05, 0.08, alpha * 1.15), 1.3, true)
	for spark in range(9):
		var t: float = fmod(float(spark) * 0.143 + game.time_alive * 0.18, 1.0)
		var jitter = sin(game.time_alive * 6.0 + spark * 2.4) * 8.0
		var p = start.lerp(finish, t) + normal * jitter
		game.draw_circle(p, 1.5 + 0.8 * sin(game.time_alive * 7.0 + spark), Color(1.0, 0.18, 0.16, 0.32))


static func _draw_remote_aura_world(game: Node2D, camera: Vector2) -> void :
	if not game.is_multiplayer or game.net_player_dead or not game.net_player_has_snapshot:
		return
	var aura_index = clampi(game.net_player_secondary_manifestation, 0, game.AURAS.size() - 1)
	var aura_name = String(game.AURAS[aura_index].get("name", ""))
	var color: Color = game.AuraSystem.COLORS.get(aura_name, Color.WHITE)
	var center: Vector2 = game.net_player_render_pos - camera
	var pulse: float = 0.5 + sin(game.time_alive * 5.0 + float(game.net_player_peer_id % 17)) * 0.5
	match aura_name:
		"Racional":
			for ring in range(3):
				game.draw_arc(center, 42.0 + ring * 16.0, - game.time_alive * (0.7 + ring * 0.2), TAU - game.time_alive * (0.7 + ring * 0.2), 42, Color(color.r, color.g, color.b, 0.22 - ring * 0.04), 1.8)
		"Impulsiva":
			for ray in range(8):
				var angle: float = game.time_alive * 1.8 + float(ray) * TAU / 8.0
				game.draw_line(center + Vector2.from_angle(angle) * 35.0, center + Vector2.from_angle(angle) * (52.0 + pulse * 13.0), Color(color.r, color.g, color.b, 0.54), 2.4)
		"Devota":
			for shield in range(3):
				var angle: float = game.time_alive * 0.8 + float(shield) * TAU / 3.0
				game.draw_arc(center + Vector2.from_angle(angle) * 45.0, 12.0, angle - 1.0, angle + 1.0, 16, Color(color.r, color.g, color.b, 0.66), 2.2)
		"Vanguarda":
			for flame in range(12):
				var angle: float = float(flame) * TAU / 12.0
				var foot: Vector2 = center + Vector2.from_angle(angle) * 52.0
				game.draw_line(foot, foot - Vector2(0, 8.0 + pulse * 11.0), Color(color.r, color.g, color.b, 0.58), 2.5)
		"Insana":
			for echo in range(3):
				var offset: Vector2 = - game.net_player_move.normalized() * (18.0 + echo * 13.0)
				game.draw_circle(center + offset, 24.0 - echo * 3.0, Color(color.r, color.g, color.b, 0.1 - echo * 0.02))
		"Voraz":
			for drop in range(5):
				var angle: float = - game.time_alive * 1.2 + float(drop) * TAU / 5.0
				game.draw_circle(center + Vector2.from_angle(angle) * (42.0 + pulse * 7.0), 4.0, Color(color.r, color.g, color.b, 0.72))
		"Nula":
			game.draw_circle(center, 48.0 + pulse * 8.0, Color(0.0, 0.025, 0.05, 0.22))
			game.draw_arc(center, 55.0, - game.time_alive * 1.7, TAU - game.time_alive * 1.7, 44, Color(color.r, color.g, color.b, 0.54), 2.2)
		"Abissal":
			for tide in range(4):
				game.draw_arc(center, 48.0 + tide * 13.0, game.time_alive * (0.35 + tide * 0.12), game.time_alive * (0.35 + tide * 0.12) + PI * 1.5, 44, Color(color.r, color.g, color.b, 0.24 - tide * 0.035), 2.5)
		"Profetica":
			var eye: Vector2 = center + Vector2(0, -54)
			game.draw_arc(eye, 14.0, PI * 0.12, PI * 0.88, 18, Color(color.r, color.g, color.b, 0.82), 2.5)
			game.draw_arc(eye, 14.0, PI * 1.12, PI * 1.88, 18, Color(color.r, color.g, color.b, 0.82), 2.5)
			game.draw_circle(eye, 3.5, Color.WHITE)
		"Sanguinaria":
			for cut in range(3):
				var x = -18.0 + cut * 18.0
				game.draw_line(center + Vector2(x - 8.0, -38.0), center + Vector2(x + 8.0, 38.0), Color(color.r, color.g, color.b, 0.58), 2.8)


static func _draw_rational_aura_world(game: Node2D, camera: Vector2, player_screen: Vector2, color: Color) -> void :
	var viewport = game.get_viewport_rect().size
	var dilation = float(game.aura_state.get("rational_dilation", 0.0))
	var rebound = float(game.aura_state.get("rational_rebound", 0.0))
	var still = float(game.aura_state.get("still", 0.0))
	var ready = float(game.aura_state.get("rational_cooldown", 0.0)) <= 0.0

	# 1. Passiva Parada - Campo de Análise Analítica (Idle Observation Field & Charge Arc)
	if still > 0.0:
		var still_ratio: float = clampf(still / 4.5, 0.0, 1.0)
		game._draw_rational_analysis_field(player_screen, still_ratio, color)

	# 2. Dilatação Temporal (Active Dilation - 8s)
	if dilation > 0.0:
		var flash: float = clampf(game.rational_dilation_flash / 0.55, 0.0, 1.0)
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.22, 0.48, 0.16 + flash * 0.14), true)
		game._draw_rational_border_oscilloscope(viewport, color, 0.65 + flash * 0.35, false)
		for i in range(6):
			game.draw_arc(player_screen, 48.0 + i * 30.0 + sin(game.time_alive * 4.4 + i) * 6.0, - game.time_alive * (1.2 + i * 0.08), TAU - game.time_alive * (1.2 + i * 0.08), 72, Color(color.r, color.g, color.b, 0.2 - i * 0.018), 2.0)

	# 3. Rebote Temporal (Active Rebound - 3s after dilation)
	elif rebound > 0.0:
		var rebound_pulse: float = 0.5 + 0.5 * sin(game.time_alive * 12.0)
		var amber_color: Color = Color(1.0, 0.48, 0.08)
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.38, 0.14, 0.02, 0.12 + rebound_pulse * 0.08), true)
		game._draw_rational_border_oscilloscope(viewport, amber_color, 0.7 + rebound_pulse * 0.3, true)
		game._draw_rational_rebound_warning(player_screen, amber_color)

	game._draw_rational_trail(camera, color)
	if ready and dilation <= 0.0 and rebound <= 0.0:
		game._draw_rational_ready_sparks(player_screen, color)


static func _draw_rational_analysis_field(game: Node2D, player_screen: Vector2, progress: float, color: Color) -> void :
	# Concentric analytical circles
	game.draw_arc(player_screen, 38.0, game.time_alive * 0.8, game.time_alive * 0.8 + TAU * 0.82, 48, Color(color.r, color.g, color.b, 0.45 * progress), 2.0)
	game.draw_arc(player_screen, 58.0, - game.time_alive * 0.6, - game.time_alive * 0.6 + TAU * 0.7, 54, Color(0.18, 0.88, 1.0, 0.3 * progress), 1.6)
	game.draw_arc(player_screen, 78.0, game.time_alive * 0.4, game.time_alive * 0.4 + TAU * 0.6, 60, Color(0.72, 0.95, 1.0, 0.2 * progress), 1.2)

	# Clock ticks (12 notches)
	for i in range(12):
		var angle: float = float(i) * TAU / 12.0 + game.time_alive * 0.5
		var p1: Vector2 = player_screen + Vector2.from_angle(angle) * 34.0
		var p2: Vector2 = player_screen + Vector2.from_angle(angle) * 42.0
		game.draw_line(p1, p2, Color(color.r, color.g, color.b, 0.55 * progress), 1.5)

	# Digital crosshair scanning lines
	var line_len: float = 85.0 * progress
	game.draw_line(player_screen + Vector2(-line_len, 0), player_screen + Vector2(line_len, 0), Color(0.18, 0.88, 1.0, 0.22 * progress), 1.0)
	game.draw_line(player_screen + Vector2(0, -line_len), player_screen + Vector2(0, line_len), Color(0.18, 0.88, 1.0, 0.22 * progress), 1.0)

	# 360-degree radial charging arc & tip spark
	var arc_end: float = - PI * 0.5 + progress * TAU
	game.draw_arc(player_screen, 48.0, - PI * 0.5, arc_end, 52, Color(0.18, 0.88, 1.0, 0.88), 3.4)
	var tip: Vector2 = player_screen + Vector2.from_angle(arc_end) * 48.0
	game.draw_circle(tip, 4.0, Color(1.0, 0.95, 0.5, 0.95))

	# Floating badge showing percentage
	game._draw_centered("ANÁLISE %d%%" % int(progress * 100.0), player_screen + Vector2(0, -62), 11, Color(0.2, 0.9, 1.0, 0.92))


static func _draw_rational_border_oscilloscope(game: Node2D, viewport: Vector2, color: Color, alpha: float, is_rebound: bool) -> void :
	var time_factor: float = 14.0 if is_rebound else 9.0

	# Top and Bottom Oscilloscope Waveforms
	for i in range(24):
		var tx: float = float(i) / 24.0
		var x: float = tx * viewport.x
		var wave_t: float = sin(game.time_alive * time_factor + tx * 18.0) * (8.0 if is_rebound else 5.0)

		game.draw_line(Vector2(x, 0.0), Vector2(x, 14.0 + wave_t), Color(color.r, color.g, color.b, alpha * 0.42), 2.0)
		game.draw_line(Vector2(x, viewport.y), Vector2(x, viewport.y - 14.0 - wave_t), Color(color.r, color.g, color.b, alpha * 0.42), 2.0)

	# Left and Right Oscilloscope Waveforms
	for j in range(16):
		var ty: float = float(j) / 16.0
		var y: float = ty * viewport.y
		var wave_l: float = cos(game.time_alive * time_factor + ty * 14.0) * (8.0 if is_rebound else 5.0)

		game.draw_line(Vector2(0.0, y), Vector2(14.0 + wave_l, y), Color(color.r, color.g, color.b, alpha * 0.42), 2.0)
		game.draw_line(Vector2(viewport.x, y), Vector2(viewport.x - 14.0 - wave_l, y), Color(color.r, color.g, color.b, alpha * 0.42), 2.0)

	# Broken clock ticks along screen corners
	for corner in [Vector2(24, 24), Vector2(viewport.x - 24, 24), Vector2(24, viewport.y - 24), Vector2(viewport.x - 24, viewport.y - 24)]:
		game.draw_arc(corner, 18.0, game.time_alive * 3.0, game.time_alive * 3.0 + PI * 1.4, 16, Color(color.r, color.g, color.b, alpha * 0.7), 2.2)


static func _draw_rational_trail(game: Node2D, camera: Vector2, color: Color) -> void :
	var previous = Vector2.ZERO
	var has_previous = false
	var texture = game._player_texture()
	var draw_index = 0
	for point in game.rational_trail_points:
		var ratio: float = clamp(float(point.get("life", 0.0)) / maxf(0.01, float(point.get("max", 1.0))), 0.0, 1.0)
		var p = Vector2(point.get("pos", game.player_pos)) - camera
		if has_previous:
			game._draw_rational_speed_segment(previous, p, ratio, draw_index)
		if draw_index % 2 == 0:
			var ghost_size = Vector2(54, 80) * (0.78 + ratio * 0.18)
			var ghost_offset = Vector2(sin(game.time_alive * 18.0 + float(draw_index)) * 5.0, -4.0 + cos(game.time_alive * 13.0 + float(draw_index)) * 3.0)
			game._draw_entity_fit(texture, p + ghost_offset, ghost_size, Color(0.22, 0.86, 1.0, 0.13 * ratio), true)
			game._draw_entity_fit(texture, p + ghost_offset + Vector2(-4, 0), ghost_size * 0.96, Color(1.0, 0.86, 0.18, 0.11 * ratio), true)
		game._draw_rational_body_energy(p, ratio, draw_index)
		previous = p
		has_previous = true
		draw_index += 1


static func _draw_rational_speed_segment(game: Node2D, a: Vector2, b: Vector2, ratio: float, index: int) -> void :
	var delta: Vector2 = b - a
	if delta.length() <= 2.0:
		return
	var dir: Vector2 = delta.normalized()
	var normal: Vector2 = dir.orthogonal()
	game.draw_line(a, b, Color(0.04, 0.86, 1.0, 0.24 * ratio), 8.0 * ratio + 2.0, true)
	game.draw_line(a + normal * 5.0, b + normal * 5.0, Color(1.0, 0.82, 0.15, 0.42 * ratio), 3.2 * ratio + 1.0, true)
	game.draw_line(a - normal * 7.0, b - normal * 7.0, Color(0.42, 0.96, 1.0, 0.36 * ratio), 2.4 * ratio + 1.0, true)
	for branch in range(2):
		var t: float = 0.25 + float(branch) * 0.38
		var base: Vector2 = a.lerp(b, t)
		var z: float = sin(game.time_alive * 24.0 + float(index * 7 + branch))
		var end: Vector2 = base - dir * (18.0 + 18.0 * ratio) + normal * z * (22.0 + 12.0 * ratio)
		game.draw_line(base, end, Color(1.0, 0.9, 0.26, 0.56 * ratio), 2.0, true)
		game.draw_line(base + normal * 3.0, end, Color(0.56, 1.0, 1.0, 0.34 * ratio), 1.2, true)


static func _draw_rational_body_energy(game: Node2D, p: Vector2, ratio: float, index: int) -> void :
	var yellow: Color = Color(1.0, 0.86, 0.18, 0.78 * ratio)
	var cyan: Color = Color(0.32, 0.96, 1.0, 0.62 * ratio)
	for i in range(3):
		var angle: float = game.time_alive * (5.0 + float(i)) + float(index) * 0.31 + float(i) * TAU / 3.0
		var start: Vector2 = p + Vector2.from_angle(angle) * (20.0 + i * 7.0)
		var mid: Vector2 = p + Vector2.from_angle(angle + 0.7) * (34.0 + i * 5.0)
		var finish: Vector2 = mid + Vector2.from_angle(angle - 1.3) * (12.0 + 7.0 * ratio)
		game.draw_line(start, mid, yellow if i % 2 == 0 else cyan, 2.0, true)
		game.draw_line(mid, finish, cyan if i % 2 == 0 else yellow, 1.2, true)
	game.draw_circle(p + Vector2(0, -14), 16.0 + 8.0 * ratio, Color(1.0, 0.84, 0.12, 0.055 * ratio))


static func _draw_insane_echo_copy(game: Node2D, screen_pos: Vector2, direction: Vector2, alpha: float, phase: float) -> void :
	var frames: Array = game.textures.get("player_fire", [])
	if frames.is_empty():
		frames = game.textures.get("player_idle", [])
	var texture: Texture2D = null
	if not frames.is_empty():
		texture = frames[posmod(int(phase * 9.0), frames.size())]
	var wobble = Vector2(sin(phase * 11.0) * 3.0, cos(phase * 8.0) * 2.0)
	var rect = Rect2(screen_pos - game.PLAYER_DRAW_SHOT_SIZE * 0.5 + wobble, game.PLAYER_DRAW_SHOT_SIZE)
	game.draw_circle(screen_pos + Vector2(0, 26), 23.0, Color(0.34, 0.04, 0.58, 0.16 * alpha))
	game._draw_texture_contain(texture, rect.grow(3.0), Color(0.96, 0.16, 1.0, 0.25 * alpha))
	game._draw_texture_contain(texture, Rect2(rect.position + Vector2(3, -2), rect.size), Color(0.12, 1.0, 0.82, 0.34 * alpha))
	game._draw_texture_contain(texture, rect, Color(0.78, 0.38, 1.0, 0.78 * alpha))
	var dir = direction.normalized() if direction.length() > 0.05 else Vector2.RIGHT
	game.draw_line(screen_pos + dir * 16.0, screen_pos + dir * 48.0, Color(0.35, 1.0, 0.52, 0.58 * alpha), 4.0)
	game.draw_arc(screen_pos, 34.0 + sin(phase * 6.0) * 3.0, phase * 1.7, phase * 1.7 + TAU * 0.78, 32, Color(0.34, 1.0, 0.45, 0.64 * alpha), 3.0)


static func _draw_larapio_coin_drops(game: Node2D, camera: Vector2) -> void :
	for coin in game.larapio_coin_drops:
		var pos = Vector2(coin.get("pos", Vector2.ZERO)) - camera
		var life_ratio = clamp(float(coin.get("life", 0.0)) / max(0.01, float(coin.get("max", 1.0))), 0.0, 1.0)
		var collectable = bool(coin.get("collectable", false))
		var radius = 7.0 if collectable else 4.5
		var shine = 0.5 + 0.5 * sin(float(coin.get("phase", 0.0)) * 3.2)
		var alpha = 0.95 if collectable else clamp(life_ratio, 0.0, 0.85)
		game.draw_circle(pos + Vector2(0, 5), radius * 1.25, Color(0.05, 0.035, 0.0, 0.22 * alpha))
		game.draw_circle(pos, radius, Color(1.0, 0.76 + shine * 0.16, 0.12, alpha))
		game.draw_arc(pos, radius + 2.0, 0, TAU, 20, Color(0.5, 0.3, 0.03, 0.86 * alpha), 1.3)
		game.draw_line(pos + Vector2( - radius * 0.35, - radius * 0.35), pos + Vector2(radius * 0.35, radius * 0.35), Color(1.0, 1.0, 0.72, 0.55 * alpha), 1.2)
		if collectable:
			game.draw_arc(pos, radius + 7.0 + shine * 2.0, 0, TAU, 24, Color(1.0, 0.82, 0.2, 0.36), 1.4)


static func _draw_larapio_ultimate_portals(game: Node2D, camera: Vector2) -> void :
	for enemy in game.enemies:
		if String(enemy.get("type", "")) != game.ENEMY_LARAPIO:
			continue
		var timer = float(enemy.get("larapio_ult_timer", 0.0))
		if timer <= 0.0:
			continue
		var portals: Array = Array(enemy.get("larapio_ult_portals", []))
		var fade = clampf(timer / 1.2, 0.0, 1.0)
		for i in range(portals.size()):
			var portal: Dictionary = Dictionary(portals[i])
			var p = Vector2(portal.get("pos", Vector2.ZERO)) - camera
			var phase: float = float(portal.get("phase", 0.0)) + game.time_alive * (2.2 + float(i) * 0.08)
			var pulse = 0.5 + 0.5 * sin(phase * 2.1)
			game.draw_set_transform(p, -0.16 + sin(phase) * 0.035, Vector2(1.0, 0.36))
			game.draw_circle(Vector2.ZERO, game.LARAPIO_ULTIMATE_PORTAL_RADIUS * (0.82 + pulse * 0.1), Color(0.12, 0.0, 0.24, 0.42 * fade))
			game.draw_arc(Vector2.ZERO, game.LARAPIO_ULTIMATE_PORTAL_RADIUS, - phase, TAU - phase, 54, Color(0.76, 0.22, 1.0, 0.88 * fade), 3.0)
			game.draw_arc(Vector2.ZERO, game.LARAPIO_ULTIMATE_PORTAL_RADIUS * 0.58, phase * 1.35, phase * 1.35 + PI * 1.45, 38, Color(1.0, 0.76, 0.24, 0.64 * fade), 2.0)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_arauto_card_drops(game: Node2D, camera: Vector2) -> void :
	for drop in game.arauto_card_drops:
		var drop_id = String(drop.get("drop_id", ""))
		if not game._reward_owned_by_local(drop) or (drop_id != "" and game.net_collected_drop_ids.has(drop_id)):
			continue
		var card: Dictionary = drop.get("card", {})
		if not game._card_drop_texture_available(card):
			continue
		var p = Vector2(drop.get("pos", game.player_pos)) - camera
		var age = float(drop.get("age", 0.0))
		var alpha: float = clamp(float(drop.get("life", 0.0)) / 1.2, 0.0, 1.0)
		var accent = game._card_rarity_color(card)
		var bob = sin(age * 5.0 + float(drop.get("phase", 0.0))) * 5.0
		var rect = Rect2(p + Vector2(-22, -30 + bob), Vector2(44, 60))
		game.draw_circle(rect.get_center(), 42.0, Color(accent.r, accent.g, accent.b, 0.12 * alpha))
		game.draw_rect(rect.grow(3.0), Color(0.01, 0.03, 0.05, 0.78 * alpha), true)
		game.draw_rect(rect.grow(3.0), accent, false, 2.0)
		var tex: Texture2D = game._card_texture(card)
		if tex:
			game._draw_texture_contain(tex, rect.grow(-5.0), Color(1, 1, 1, alpha))
		else:
			game.draw_rect(rect.grow(-9.0), Color(accent.r, accent.g, accent.b, 0.32 * alpha), true)
		game._draw_centered("CARTA", p + Vector2(0, 42 + bob), 10, Color(0.88, 0.96, 1.0, 0.86 * alpha))


static func _draw_arauto_evolution_fragment(game: Node2D, camera: Vector2) -> void :
	if game.is_multiplayer:
		for fragment in game.arauto_evolution_fragments:
			var fragment_id = String(fragment.get("fragment_id", ""))
			if game._reward_owned_by_local(fragment) and not game.net_collected_fragment_ids.has(fragment_id):
				game._draw_arauto_evolution_fragment_item(fragment, camera)
		return
	if not game.arauto_evolution_fragment.is_empty():
		game._draw_arauto_evolution_fragment_item(game.arauto_evolution_fragment, camera)


static func _draw_arauto_evolution_fragment_item(game: Node2D, fragment: Dictionary, camera: Vector2) -> void :
	var pos = Vector2(fragment.get("pos", game.player_pos)) - camera
	var pulse_t = float(fragment.get("pulse", 0.0))
	var age = float(fragment.get("life", 0.0))
	var pulse = 0.5 + 0.5 * sin(pulse_t)
	var hover = sin(age * 2.3) * 7.0
	pos.y += hover
	var accent = game._manifestation_color()
	var outer_r = 34.0 + pulse * 9.0
	game.draw_circle(pos, outer_r * 1.28, Color(0.06, 0.0, 0.12, 0.3))
	game.draw_circle(pos, outer_r, Color(accent.r, accent.g, accent.b, 0.16 + pulse * 0.08))
	game.draw_arc(pos, outer_r + 10.0, pulse_t, pulse_t + PI * 1.45, 64, Color(accent.r, accent.g, accent.b, 0.92), 3.0)
	game.draw_arc(pos, outer_r * 0.72, - pulse_t * 0.8, - pulse_t * 0.8 + PI * 1.65, 56, Color(0.24, 0.94, 1.0, 0.82), 2.0)
	for i in range(5):
		var ang = pulse_t * 1.4 + float(i) * TAU / 5.0
		var shard = pos + Vector2.from_angle(ang) * (outer_r + 9.0)
		var sz = 6.0 + float(i % 2) * 2.0
		var points = PackedVector2Array([
			shard + Vector2(0, - sz), 
			shard + Vector2(sz * 0.58, 0), 
			shard + Vector2(0, sz), 
			shard + Vector2( - sz * 0.58, 0)
		])
		game.draw_polygon(points, PackedColorArray([Color(0.9, 0.96, 1.0, 0.86)]))
		game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(accent.r, accent.g, accent.b, 0.78), 1.4, true)
	game.draw_circle(pos, 13.0 + pulse * 3.0, Color(0.94, 0.9, 1.0, 0.95))
	game._draw_centered("EVOLUCAO", pos + Vector2(0, 58.0), 11, Color(0.9, 0.96, 1.0, 0.92))


static func _draw_arauto(game: Node2D, camera: Vector2) -> void :
	game._draw_arauto_vfx(camera)
	if not game._arauto_active():
		return
	if game._arauto_is_aguilhao():
		game._draw_aguilhao_arauto(camera)
		return
	var pos = Vector2(game.arauto["pos"]) - camera
	var world_pos = Vector2(game.arauto["pos"])
	var phase = float(game.arauto.get("anim", 0.0))
	var entry_ratio: float = 1.0 - clamp(float(game.arauto.get("entry_timer", 0.0)) / game.ARAUTO_ENTRY_TIME, 0.0, 1.0)
	for enemy in game.enemies:
		if bool(enemy.get("eco_vinculado", false)):
			var ep = Vector2(enemy["pos"]) - camera
			var pulse = 0.35 + sin(game.time_alive * 5.0 + int(enemy["uid"]) * 0.01) * 0.1
			game.draw_line(pos, ep, Color(0.42, 0.78, 1.0, pulse), 2.0, true)
			game.draw_arc(ep, game._enemy_radius(enemy) + 9.0, phase * 1.8, phase * 1.8 + PI * 1.35, 24, Color(0.62, 0.92, 1.0, 0.72), 2.0)
	if bool(game.arauto.get("gaze_active", false)):
		var origin = game._arauto_eye_pos() - camera
		var target = Vector2(game.arauto.get("gaze_target", world_pos)) - camera
		var charge: float = game.ARAUTO_GAZE_CHARGE_PHASE2 if bool(game.arauto.get("phase2", false)) else game.ARAUTO_GAZE_CHARGE
		var ratio: float = clamp(float(game.arauto.get("gaze_age", 0.0)) / max(0.01, charge), 0.0, 1.0)
		var c = Color(1.0, 0.22, 0.78, 0.22 + ratio * 0.52)
		game.draw_line(origin, target, Color(c.r, c.g, c.b, 0.28), 12.0 + ratio * 8.0, true)
		game.draw_line(origin, target, Color(1.0, 0.78, 1.0, 0.82), 2.0 + ratio * 2.0, true)
		game.draw_arc(target, 42.0 + ratio * 16.0, 0.0, TAU, 42, Color(1.0, 0.22, 0.78, 0.82), 3.0)
	if bool(game.arauto.get("silence_active", false)):
		var target = Vector2(game.arauto.get("silence_target", world_pos)) - camera
		var charge: float = game.ARAUTO_SILENCE_WARNING * (0.82 if bool(game.arauto.get("phase2", false)) else 1.0)
		var ratio: float = clamp(float(game.arauto.get("silence_age", 0.0)) / max(0.01, charge), 0.0, 1.0)
		var radius: float = game.ARAUTO_SILENCE_RADIUS * (1.14 if bool(game.arauto.get("phase2", false)) else 1.0)
		game.draw_circle(target, radius, Color(0.18, 0.78, 1.0, 0.1 + ratio * 0.08))
		game.draw_arc(target, radius + ratio * 10.0, - PI * 0.5, TAU * ratio - PI * 0.5, 42, Color(0.66, 0.94, 1.0, 0.72), 3.0)
		game.draw_arc(target, radius * 0.55 + sin(game.time_alive * 12.0) * 4.0, 0.0, TAU, 32, Color(0.36, 0.84, 1.0, 0.42), 2.0)
	var tex = game._arauto_texture()
	var draw_size: Vector2 = game.ARAUTO_SIZE * (0.82 + entry_ratio * 0.18)
	var modulate = Color(0.88, 0.82, 1.0, 0.35 + entry_ratio * 0.65)
	if bool(game.arauto.get("phase2", false)):
		modulate = modulate.lerp(Color(1.0, 0.5, 0.92, modulate.a), 0.35 + 0.18 * sin(game.time_alive * 7.0))
	game._draw_dynamic_shadow_fit(tex, pos + Vector2(0, 14), draw_size, float(game.arauto.get("facing", 1.0)) < 0.0, true, 0.38 * entry_ratio)
	if tex:
		game._draw_entity_fit_flipped(tex, pos, draw_size, float(game.arauto.get("facing", 1.0)) < 0.0, modulate, true)
	else:
		game._draw_arauto_fallback(pos, draw_size, modulate)
	var eye = game._arauto_eye_pos() - camera
	game.draw_circle(eye, 9.0, Color(0.02, 0.0, 0.08, 0.92))
	game.draw_circle(eye, 4.0 + sin(game.time_alive * 8.0) * 1.2, Color(0.92, 0.26, 1.0, 0.95))
	game.draw_arc(pos + Vector2(0, 28), 68.0 + sin(game.time_alive * 3.2) * 5.0, phase, phase + PI * 1.65, 48, Color(0.48, 0.72, 1.0, 0.65), 2.0)
	if game._attack_target_is_arauto():
		game._draw_attack_target_marker(pos + Vector2(0, 44), 65.0, game.locked_target_kind == "arauto")
	var hp_ratio: float = float(game.arauto["hp"]) / max(1.0, float(game.arauto["max_hp"]))
	game._draw_bar(pos + Vector2(-74, -86), 148.0, hp_ratio, Color(0.66, 0.24, 1.0))
	var echo_count = game._count_arauto_echoes()
	var protect = int(min(game.ARAUTO_MAX_DAMAGE_REDUCTION, float(echo_count) * game.ARAUTO_ECHO_DAMAGE_REDUCTION) * 100.0)
	game._draw_centered("ARAUTO", pos + Vector2(0, -110), 16, Color(0.78, 0.92, 1.0))
	game._draw_centered("ECOS %d  PROTECAO %d%%" % [echo_count, protect], pos + Vector2(0, -67), 11, Color(0.64, 0.88, 1.0, 0.94))


static func _draw_arauto_vfx(game: Node2D, camera: Vector2) -> void :
	for ray in game.arauto_rays:
		var alpha: float = clamp(float(ray.get("life", 0.0)) / max(0.01, float(ray.get("max", 0.42))), 0.0, 1.0)
		var a = Vector2(ray.get("a", game.player_pos)) - camera
		var b = Vector2(ray.get("b", game.player_pos)) - camera
		var blocked = bool(ray.get("blocked", false))
		var c = Color(0.48, 0.92, 1.0, 0.55 * alpha) if blocked else Color(1.0, 0.18, 0.72, 0.62 * alpha)
		game.draw_line(a, b, Color(c.r, c.g, c.b, 0.18 * alpha), 18.0 * alpha, true)
		game.draw_line(a, b, c, 4.0 * alpha, true)
	for fx in game.arauto_echo_breaks:
		var alpha: float = clamp(float(fx.get("life", 0.0)) / max(0.01, float(fx.get("max", 0.5))), 0.0, 1.0)
		var p = Vector2(fx.get("pos", game.player_pos)) - camera
		var fx_color: Color = fx.get("color", Color(0.58, 0.92, 1.0))
		for i in range(8):
			var ang: float = float(i) * TAU / 8.0 + float(fx.get("phase", 0.0)) + game.time_alive * 1.4
			game.draw_line(p, p + Vector2.from_angle(ang) * (18.0 + 34.0 * (1.0 - alpha)), Color(fx_color.r, fx_color.g, fx_color.b, 0.58 * alpha), 2.0)


static func _draw_aguilhao_arauto(game: Node2D, camera: Vector2) -> void :
	var pos = Vector2(game.arauto["pos"]) - camera
	var world_pos = Vector2(game.arauto["pos"])
	var phase = float(game.arauto.get("anim", 0.0))
	var entry_ratio: float = 1.0 - clamp(float(game.arauto.get("entry_timer", 0.0)) / game.ARAUTO_ENTRY_TIME, 0.0, 1.0)
	for enemy in game.enemies:
		if bool(enemy.get("aguilhao_nodule", false)):
			var ep = Vector2(enemy["pos"]) - camera
			var pulse = 0.26 + sin(game.time_alive * 5.8 + float(enemy.get("phase", 0.0))) * 0.08
			game.draw_line(pos, ep, Color(0.46, 1.0, 0.18, pulse), 3.0, true)
			game.draw_arc(ep, game._enemy_radius(enemy) + 12.0, - phase * 1.4, TAU - phase * 1.4, 36, Color(0.62, 1.0, 0.24, 0.62), 2.2)
	var state = String(game.arauto.get("state", "idle"))
	if state == "charge_windup":
		var dir = Vector2(game.arauto.get("charge_dir", Vector2.RIGHT)).normalized()
		var end = world_pos + dir * 780.0
		var ratio: float = 1.0 - clamp(float(game.arauto.get("state_timer", 0.0)) / (game.AGUILHAO_CHARGE_WINDUP_PHASE2 if bool(game.arauto.get("phase2", false)) else game.AGUILHAO_CHARGE_WINDUP), 0.0, 1.0)
		game.draw_line(pos, end - camera, Color(0.38, 1.0, 0.12, 0.18 + ratio * 0.32), 26.0, true)
		game.draw_line(pos, end - camera, Color(0.86, 1.0, 0.38, 0.76), 3.0 + ratio * 3.0, true)
		game.draw_arc(end - camera, game.AGUILHAO_CHARGE_HIT_WIDTH + ratio * 10.0, 0.0, TAU, 36, Color(0.7, 1.0, 0.22, 0.68), 2.0)
	elif state == "pulse":
		var stage = int(game.arauto.get("pulse_stage", 0))
		var warn = game.AGUILHAO_PULSE_WARNING if stage == 0 else 0.42
		var ratio: float = 1.0 - clamp(float(game.arauto.get("state_timer", 0.0)) / maxf(0.01, warn), 0.0, 1.0)
		var radius = game.AGUILHAO_PULSE_RADIUS * (1.22 if bool(game.arauto.get("phase2", false)) and stage > 0 else 1.0)
		game.draw_circle(pos, radius, Color(0.26, 1.0, 0.1, 0.08 + ratio * 0.08))
		game.draw_arc(pos, radius + ratio * 12.0, - PI * 0.5, TAU * ratio - PI * 0.5, 54, Color(0.7, 1.0, 0.22, 0.72), 3.0)
	elif state == "seed":
		for spot in Array(game.arauto.get("seed_spots", [])):
			var sp = Vector2(spot) - camera
			var ratio: float = 1.0 - clamp(float(game.arauto.get("state_timer", 0.0)) / game.AGUILHAO_SEED_WARNING, 0.0, 1.0)
			game.draw_circle(sp, 26.0 + ratio * 12.0, Color(0.36, 1.0, 0.12, 0.1))
			game.draw_arc(sp, 34.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 36, Color(0.74, 1.0, 0.24, 0.58), 2.2)
	var tex = game._arauto_texture()
	var draw_size: Vector2 = game.AGUILHAO_SIZE * (0.82 + entry_ratio * 0.18)
	var modulate = Color(0.82, 1.0, 0.64, 0.35 + entry_ratio * 0.65)
	if bool(game.arauto.get("phase2", false)):
		modulate = modulate.lerp(Color(0.56, 1.0, 0.18, modulate.a), 0.34 + 0.2 * sin(game.time_alive * 7.0))
	if float(game.arauto.get("aguilhao_vulnerable", 0.0)) > 0.0:
		modulate = modulate.lerp(Color(1.0, 0.88, 0.24, modulate.a), 0.48)
	game._draw_dynamic_shadow_fit(tex, pos + Vector2(0, 18), draw_size, float(game.arauto.get("facing", 1.0)) < 0.0, true, 0.42 * entry_ratio)
	if tex:
		game._draw_entity_fit_flipped(tex, pos, draw_size, float(game.arauto.get("facing", 1.0)) < 0.0, modulate, true)
	else:
		game._draw_arauto_fallback(pos, draw_size, modulate)
	game.draw_circle(pos + Vector2(14.0 * float(game.arauto.get("facing", 1.0)), -10), 12.0 + sin(game.time_alive * 6.0) * 2.5, Color(0.46, 1.0, 0.12, 0.34))
	game.draw_arc(pos + Vector2(0, 30), 82.0 + sin(game.time_alive * 3.4) * 5.0, phase, phase + PI * 1.45, 52, Color(0.46, 1.0, 0.18, 0.58), 2.0)
	if game._attack_target_is_arauto():
		game._draw_attack_target_marker(pos + Vector2(0, 34), 72.0, game.locked_target_kind == "arauto")
	var hp_ratio: float = float(game.arauto["hp"]) / max(1.0, float(game.arauto["max_hp"]))
	game._draw_bar(pos + Vector2(-84, -72), 168.0, hp_ratio, Color(0.44, 1.0, 0.2))
	var nodes = game._count_aguilhao_nodules()
	var protect = int(min(game.AGUILHAO_MAX_NODE_REDUCTION, float(nodes) * game.AGUILHAO_NODE_DAMAGE_REDUCTION) * 100.0)
	game._draw_centered("AGUILHAO", pos + Vector2(0, -96), 16, Color(0.78, 1.0, 0.46))
	game._draw_centered("NODULOS %d  PROTECAO %d%%" % [nodes, protect], pos + Vector2(0, -52), 11, Color(0.68, 1.0, 0.32, 0.94))


static func _draw_parasite_spit_zones(game: Node2D, camera: Vector2) -> void :
	for zone in game.parasite_spit_zones:
		var state = String(zone.get("state", "flying"))
		var phase = float(zone.get("phase", 0.0))
		if state == "flying":
			var progress = clamp(float(zone.get("age", 0.0)) / max(0.01, float(zone.get("travel", game.PARASITE_SPIT_TRAVEL))), 0.0, 1.0)
			var world_pos = Vector2(zone["origin"]).lerp(Vector2(zone["target"]), progress) + Vector2(0, - sin(progress * PI) * 92.0)
			var pos = world_pos - camera
			game.draw_circle(pos, 21.0, Color(0.18, 0.3, 0.05, 0.3))
			for worm_index in range(4):
				var angle = phase + progress * 10.0 + worm_index * TAU / 4.0
				game._draw_parasite_worm(pos + Vector2.from_angle(angle) * 13.0, angle + PI * 0.5, 0.62, game.time_alive * 8.0 + worm_index, 0.96)
			var shadow = Vector2(zone["origin"]).lerp(Vector2(zone["target"]), progress) - camera
			game.draw_set_transform(shadow, 0.0, Vector2(1.0, 0.34))
			game.draw_circle(Vector2.ZERO, 20.0 + progress * 10.0, Color(0.05, 0.04, 0.02, 0.28))
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		var center = Vector2(zone["target"]) - camera
		var fade = clamp(float(zone.get("life", 0.0)) / max(0.01, float(zone.get("max", game.PARASITE_SPIT_DURATION))), 0.0, 1.0)
		var pulse = 0.5 + 0.5 * sin(game.time_alive * 5.5 + phase)
		game.draw_circle(center, game.PARASITE_SPIT_RADIUS, Color(0.22, 0.34, 0.05, 0.1 * fade))
		game.draw_arc(center, game.PARASITE_SPIT_RADIUS + pulse * 5.0, 0.0, TAU, 56, Color(0.58, 0.88, 0.18, 0.54 * fade), 2.4)
		game.draw_arc(center, game.PARASITE_SPIT_RADIUS * 0.72, game.time_alive * 0.35, game.time_alive * 0.35 + PI * 1.55, 40, Color(0.78, 1.0, 0.32, 0.28 * fade), 1.2)
		for crack_index in range(11):
			var angle = phase + crack_index * TAU / 11.0
			var start = center + Vector2.from_angle(angle) * (24.0 + (crack_index % 3) * 13.0)
			var finish = center + Vector2.from_angle(angle + sin(crack_index * 2.4) * 0.1) * (72.0 + (crack_index % 4) * 14.0)
			game.draw_line(start, finish, Color(0.1, 0.075, 0.025, 0.58 * fade), 2.0)
		for worm_index in range(7):
			var angle = game.time_alive * (0.34 + worm_index * 0.015) + phase + worm_index * TAU / 7.0
			var radius = game.PARASITE_SPIT_RADIUS * (0.25 + 0.55 * float((worm_index % 3) + 1) / 3.0)
			var worm_pos = center + Vector2.from_angle(angle) * radius
			game._draw_parasite_worm(worm_pos, angle + PI * 0.58, 0.46 + (worm_index % 2) * 0.1, game.time_alive * 5.0 + worm_index, fade)


static func _draw_miasma_eel_relocation_path(game: Node2D, enemy: Dictionary, camera: Vector2) -> void :
	var progress = clampf(float(enemy.get("eel_relocating", 0.0)), 0.0, 1.0)
	if progress <= 0.0:
		return
	var from = Vector2(enemy.get("eel_relocate_from", enemy.get("pos", Vector2.ZERO)))
	var to = Vector2(enemy.get("eel_relocate_to", enemy.get("pos", Vector2.ZERO)))
	var bend = float(enemy.get("eel_relocate_bend", 0.0))
	var phase = float(enemy.get("eel_relocate_phase", 0.0))
	var head = game._parasite_curve_point(from, to, progress, bend) - camera
	var before = game._parasite_curve_point(from, to, maxf(0.0, progress - 0.025), bend) - camera
	var move_dir = (head - before).normalized()
	if move_dir.length() <= 0.05:
		move_dir = (to - from).normalized()
	var side = move_dir.orthogonal()
	var trail = PackedVector2Array()
	var samples = 9
	for i in range(samples):
		var back = minf(100.0, float(i) * 13.5)
		var t = maxf(0.0, progress - back / maxf(1.0, from.distance_to(to)))
		var base = game._parasite_curve_point(from, to, t, bend) - camera
		var wobble = sin(game.time_alive * 7.0 + phase + float(i) * 0.9) * (8.0 - float(i) * 0.45)
		trail.append(base + side * wobble)
	if trail.size() >= 2:
		game.draw_polyline(trail, Color(0.055, 0.06, 0.05, 0.62), 18.0, true)
		game.draw_polyline(trail, Color(0.42, 0.43, 0.35, 0.72), 8.0, true)
		game.draw_polyline(trail, Color(0.22, 0.78, 0.18, 0.2), 2.2, true)
	for i in range(18):
		var drift = fposmod(game.time_alive * (0.4 + float(i % 5) * 0.03) + phase + float(i) * 0.137, 1.0)
		var back = drift * 104.0
		var t = maxf(0.0, progress - back / maxf(1.0, from.distance_to(to)))
		var center = game._parasite_curve_point(from, to, t, bend) - camera
		var scatter = side * sin(phase + float(i) * 1.73) * (3.0 + fposmod(float(i) * 7.31 + phase, 16.0))
		var lift = Vector2(0, -1) * sin(drift * PI) * (2.0 + fposmod(float(i) * 3.17 + phase, 6.0))
		var alpha = (1.0 - drift) * 0.46
		var color = Color(0.38, 0.4, 0.33, alpha) if i % 3 != 0 else Color(0.3, 0.8, 0.18, alpha * 0.72)
		game.draw_circle(center + scatter + lift, 1.6 + fposmod(float(i) * 1.11 + phase, 3.2), color)
	game.draw_circle(head, 25.0, Color(0.1, 0.12, 0.09, 0.48))
	game.draw_circle(head + move_dir * 7.0, 15.0, Color(0.46, 0.48, 0.38, 0.58))
	game.draw_arc(head, 24.0, phase + game.time_alive * 2.2, phase + game.time_alive * 2.2 + PI * 1.3, 24, Color(0.54, 0.8, 0.28, 0.44), 2.2)


static func _draw_sanguessuga_state(game: Node2D, enemy: Dictionary, camera: Vector2) -> void :
	var state = String(enemy.get("leech_state", game.SANGUESSUGA_STATE_DORMANT))
	var center = Vector2(enemy.get("pos", Vector2.ZERO)) - camera
	match state:
		game.SANGUESSUGA_STATE_FALL_WARNING:
			var p = 1.0 - clampf(float(enemy.get("leech_timer", 0.0)) / game.SANGUESSUGA_FALL_WARNING_TIME, 0.0, 1.0)
			game.draw_circle(center, 28.0 + p * 9.0, Color(0.68, 1.0, 0.2, 0.12 + p * 0.12))
			game.draw_arc(center, 30.0 + p * 10.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 38, Color(0.78, 1.0, 0.24, 0.62), 2.0)
		game.SANGUESSUGA_STATE_FALLING:
			var p = clampf(1.0 - float(enemy.get("leech_timer", 0.0)) / maxf(0.01, float(enemy.get("leech_fall_duration", game.SANGUESSUGA_FALL_TIME_MAX))), 0.0, 1.0)
			game.draw_line(center + Vector2(0, -150.0 * (1.0 - p)), center, Color(0.58, 1.0, 0.18, 0.36), 3.0, true)
		game.SANGUESSUGA_STATE_DORMANT:
			var life = float(enemy.get("leech_life", game.SANGUESSUGA_DORMANT_TIME))
			var fade = clampf(life / 3.0, 0.28, 1.0) if life <= 3.0 else 1.0
			game.draw_circle(center, game.SANGUESSUGA_DETECTION_RADIUS, Color(0.28, 1.0, 0.18, 0.045 * fade))
			game.draw_arc(center, game.SANGUESSUGA_DETECTION_RADIUS + sin(game.time_alive * 4.4 + float(enemy.get("phase", 0.0))) * 4.0, - game.time_alive * 0.6, TAU - game.time_alive * 0.6, 72, Color(0.58, 1.0, 0.2, 0.24 * fade), 1.4)
		game.SANGUESSUGA_STATE_TRIGGERED:
			game.draw_circle(center, 38.0 + sin(game.time_alive * 18.0) * 4.0, Color(1.0, 0.18, 0.16, 0.2))
			game.draw_arc(center, 42.0, - game.time_alive * 4.0, TAU - game.time_alive * 4.0, 42, Color(1.0, 0.42, 0.18, 0.78), 2.4)
		game.SANGUESSUGA_STATE_LEAPING:
			var from = Vector2(enemy.get("leech_leap_from", enemy.get("pos", Vector2.ZERO))) - camera
			game.draw_line(from, center, Color(0.68, 1.0, 0.18, 0.44), 4.0, true)


static func _draw_parasite_marks(game: Node2D, camera: Vector2) -> void :
	for enemy in game.enemies:
		var mark_time = float(enemy.get("parasite_mark_time", 0.0))
		if mark_time <= 0.0 or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		game._draw_parasite_host(Vector2(enemy["pos"]) - camera, 30.0, int(enemy.get("seeds", 1)), int(enemy["uid"]), mark_time)
	if game.boss_active and game.boss_hp > 0.0 and game.boss_parasite_mark_time > 0.0:
		game._draw_parasite_host(game.boss_pos - camera, 78.0, max(3, game.boss_parasite_seeds), -9173, game.boss_parasite_mark_time)
	if game._arauto_active() and float(game.arauto.get("parasite_mark_time", 0.0)) > 0.0:
		game._draw_parasite_host(Vector2(game.arauto["pos"]) - camera, 58.0, max(2, int(game.arauto.get("seeds", 1))), -8121, float(game.arauto.get("parasite_mark_time", 0.0)))


static func _draw_parasite_host(game: Node2D, center: Vector2, radius: float, seeds: int, uid: int, mark_time: float) -> void :
	var pulse = 0.5 + 0.5 * sin(game.time_alive * 7.0 + uid * 0.013)
	var fade = clamp(mark_time / game.PARASITE_MARK_DURATION, 0.0, 1.0)
	game.draw_circle(center, radius * 0.82, Color(0.12, 0.22, 0.04, 0.07 + pulse * 0.04))
	for vein_index in range(5):
		var vein_angle = game.time_alive * 0.16 + uid * 0.007 + vein_index * TAU / 5.0
		var inner = center + Vector2.from_angle(vein_angle + sin(game.time_alive * 2.0 + vein_index) * 0.12) * radius * 0.34
		var outer = center + Vector2.from_angle(vein_angle) * radius * (0.78 + pulse * 0.1)
		game.draw_line(inner, outer, Color(0.36, 0.68, 0.12, 0.34 * fade), 3.4)
		game.draw_line(inner, outer, Color(0.76, 1.0, 0.32, 0.54 * fade), 1.0)
	var worm_count = clamp(seeds + 1, 3, 6)
	for worm_index in range(worm_count):
		var angle = game.time_alive * (0.72 + worm_index * 0.035) + worm_index * TAU / worm_count + uid * 0.001
		var orbit = radius * (0.7 + 0.13 * sin(game.time_alive * 2.7 + worm_index))
		var worm_pos = center + Vector2.from_angle(angle) * orbit
		game._draw_parasite_worm(worm_pos, angle + PI * 0.56, 0.72 + (worm_index % 3) * 0.1, game.time_alive * 5.0 + worm_index, fade)
	for drop_index in range(3):
		var cycle = fposmod(game.time_alive * (0.58 + drop_index * 0.08) + drop_index * 0.31 + abs(uid) * 0.0007, 1.0)
		var drop_alpha = sin(cycle * PI) * fade
		var x = center.x + sin(uid * 0.017 + drop_index * 2.1) * radius * 0.52
		var start_y = center.y + radius * 0.34
		var larva_pos = Vector2(x + sin(cycle * 8.0 + drop_index) * 3.0, start_y + cycle * (radius * 0.82 + 24.0))
		game.draw_line(Vector2(x, start_y - 3.0), larva_pos, Color(0.42, 0.7, 0.16, 0.18 * drop_alpha), 1.0)
		game._draw_parasite_larva_drop(larva_pos, 0.62 + drop_index * 0.08, drop_alpha)


static func _draw_parasite_worm(game: Node2D, origin: Vector2, angle: float, scale: float, phase: float, alpha: = 1.0) -> void :
	var points = PackedVector2Array()
	var segments = 8
	for segment in range(segments):
		var along = (float(segment) / float(segments - 1) - 0.5) * 30.0 * scale
		var local = Vector2(along, sin(phase + segment * 0.92) * 4.2 * scale)
		points.append(origin + local.rotated(angle))
	if points.size() < 2:
		return
	game.draw_polyline(points, Color(0.035, 0.055, 0.018, 0.92 * alpha), 9.0 * scale, true)
	game.draw_polyline(points, Color(0.42, 0.68, 0.15, 0.96 * alpha), 6.0 * scale, true)
	game.draw_polyline(points, Color(0.78, 0.96, 0.32, 0.46 * alpha), 1.4 * scale, true)
	for segment in range(1, segments - 1):
		var segment_radius = (2.4 + (segment % 2) * 0.7) * scale
		game.draw_circle(points[segment], segment_radius, Color(0.54, 0.78, 0.2, 0.88 * alpha))
	var head = points[points.size() - 1]
	var head_dir = (head - points[points.size() - 2]).normalized()
	var side = head_dir.orthogonal()
	game.draw_circle(head, 5.4 * scale, Color(0.2, 0.32, 0.08, 0.96 * alpha))
	game.draw_circle(head + head_dir * 1.4 * scale, 3.8 * scale, Color(0.62, 0.84, 0.22, 0.96 * alpha))
	game.draw_circle(head + side * 2.1 * scale, 0.85 * scale, Color(1.0, 0.76, 0.18, alpha))
	game.draw_circle(head - side * 2.1 * scale, 0.85 * scale, Color(1.0, 0.76, 0.18, alpha))
	game.draw_line(head + head_dir * 3.0 * scale, head + head_dir * 7.0 * scale + side * 3.0 * scale, Color(0.92, 0.92, 0.48, 0.92 * alpha), 1.4 * scale)
	game.draw_line(head + head_dir * 3.0 * scale, head + head_dir * 7.0 * scale - side * 3.0 * scale, Color(0.92, 0.92, 0.48, 0.92 * alpha), 1.4 * scale)


static func _draw_cartographic_marks(game: Node2D, camera: Vector2) -> void :
	var points = game._cartographic_coord_points()
	if points.size() >= 2:
		for i in range(points.size()):
			if points.size() == 2 and i > 0:
				break
			var a: Vector2 = points[i] - camera
			var b: Vector2 = points[(i + 1) % points.size()] - camera
			var alpha = 0.24 + (0.38 if game.cartographic_route_timer > 0.0 else 0.0) + (0.18 if game.cartographic_trace_flash > 0.0 else 0.0)
			var route_color = game._cartographic_coord_color(i)
			game.draw_line(a, b, Color(route_color.r, route_color.g, route_color.b, alpha * 0.28), game.CARTO_ROUTE_WIDTH, true)
			game.draw_line(a, b, Color(0.78, 1.0, 0.42, alpha), 2.4, true)
	if points.size() >= 3:
		var poly = PackedVector2Array([points[0] - camera, points[1] - camera, points[2] - camera])
		var map_alpha = 0.055 if game.cartographic_complete_map_timer <= 0.0 else 0.145
		game.draw_polygon(poly, PackedColorArray([Color(0.1, 1.0, 0.7, map_alpha)]))
	for coord in game.cartographic_coords:
		var p = game._cartographic_coord_world_pos(coord) - camera
		var life_ratio = clamp(float(coord.get("life", 0.0)) / max(0.01, float(coord.get("max", game.CARTO_COORD_LIFE))), 0.0, 1.0)
		var phase = float(coord.get("phase", 0.0)) + game.time_alive * 2.0
		var slot = int(coord.get("slot", 0))
		var color = game._cartographic_coord_color(slot)
		game.draw_circle(p, 26.0, Color(color.r, color.g, color.b, 0.09 * life_ratio))
		game.draw_arc(p, 29.0 + sin(phase) * 2.0, phase, phase + TAU * 0.72, 48, Color(color.r, color.g, color.b, 0.88 * life_ratio), 2.0)
		game.draw_line(p + Vector2(-18, 0), p + Vector2(18, 0), Color(1.0, 0.82, 0.24, 0.58 * life_ratio), 1.4)
		game.draw_line(p + Vector2(0, -18), p + Vector2(0, 18), Color(1.0, 0.82, 0.24, 0.58 * life_ratio), 1.4)
	for enemy in game.enemies:
		var stacks = int(enemy.get("carto_trace_stacks", 0))
		if stacks <= 0 and float(enemy.get("carto_point_timer", 0.0)) <= 0.0:
			continue
		var p_enemy = Vector2(enemy.get("pos", game.player_pos)) - camera
		var ring_color = Color(1.0, 0.84, 0.3) if float(enemy.get("carto_point_timer", 0.0)) > 0.0 else Color(0.34, 1.0, 0.82)
		for i in range(max(1, stacks)):
			game.draw_arc(p_enemy, 34.0 + i * 5.0, game.time_alive * (1.4 + i * 0.2), game.time_alive * (1.4 + i * 0.2) + TAU * 0.64, 36, Color(ring_color.r, ring_color.g, ring_color.b, 0.46), 1.8)


static func _draw_mnesic_marks(game: Node2D, camera: Vector2) -> void :
	for enemy in game.enemies:
		var memories: Array = enemy.get("mnesic_memories", [])
		var dejavu = float(enemy.get("mnesic_dejavu", 0.0))
		if memories.is_empty() and dejavu <= 0.0 and float(enemy.get("mnesic_tricked", 0.0)) <= 0.0:
			continue
		var p = Vector2(enemy["pos"]) - camera
		var alpha = 0.3 + min(0.45, memories.size() * 0.12)
		game.draw_arc(p, 38.0, - game.time_alive * 1.2, TAU - game.time_alive * 1.2, 48, Color(0.86, 0.58, 1.0, alpha), 2.0)
		for i in range(memories.size()):
			game.draw_circle(p + Vector2.from_angle(game.time_alive * 1.6 + i * TAU / 3.0) * 27.0, 4.0, Color(1.0, 0.72, 1.0, 0.8))


static func _draw_necro_aliado_health_bar(game: Node2D, pos: Vector2, width: float, ratio: float, alpha: float) -> void :
	var height = 6.0
	var rect = Rect2(pos, Vector2(width, height))
	game.draw_rect(rect.grow(1.5), Color(0.02, 0.08, 0.12, 0.85 * alpha), true)
	game.draw_rect(rect, Color(0.04, 0.16, 0.22, 0.9 * alpha), true)
	if ratio > 0.0:
		var fill_rect = Rect2(pos, Vector2(width * clampf(ratio, 0.0, 1.0), height))
		game.draw_rect(fill_rect, Color(0.22, 0.92, 0.62, 0.95 * alpha), true)
	game.draw_rect(rect, Color(0.42, 0.96, 1.0, 0.85 * alpha), false, 1.2)


static func _draw_necronada_world(game: Node2D, camera: Vector2) -> void :
	for vestige in game.necronada_vestiges:
		var p = Vector2(vestige.get("pos", game.player_pos)) - camera
		var phase: float = float(vestige.get("phase", 0.0)) + game.time_alive * 1.4
		var depth = int(vestige.get("depth", 1))
		game.draw_circle(p + Vector2(0, 10), 13.0 + sin(phase) * 1.2, Color(0.04, 0.05, 0.09, 0.36))
		game.draw_line(p + Vector2(0, 8), p + Vector2(0, -12), Color(0.22, 0.62, 0.32, 0.92), 2.2)
		game.draw_line(p + Vector2(0, 1), p + Vector2(-8, -3), Color(0.2, 0.74, 0.42, 0.76), 2.0)
		game.draw_line(p + Vector2(0, 3), p + Vector2(8, -1), Color(0.16, 0.56, 0.35, 0.76), 2.0)
		for petal in range(6):
			var angle = phase * 0.18 + float(petal) * TAU / 6.0
			var petal_pos = p + Vector2.from_angle(angle) * (5.0 + depth * 0.5) + Vector2(0, -16)
			game.draw_circle(petal_pos, 4.4, Color(0.32, 0.8, 1.0, 0.88))
			game.draw_circle(petal_pos + Vector2(0, -0.8), 2.0, Color(0.76, 0.96, 1.0, 0.9))
		game.draw_circle(p + Vector2(0, -16), 4.2, Color(0.54, 0.34, 0.92, 0.94))
		for i in range(depth):
			game.draw_arc(p + Vector2(0, -8), 19.0 + i * 4.0, - phase * (0.6 + i * 0.1), TAU - phase * (0.6 + i * 0.1), 36, Color(0.72, 0.96, 1.0, 0.28), 1.1)
	for remnant in game.necronada_remnants:
		var p = Vector2(remnant.get("pos", game.player_pos)) - camera
		var profile: Dictionary = Dictionary(remnant.get("profile", {}))
		var color: Color = profile.get("color", game._necronada_accent())
		var summon_time = float(remnant.get("summon", 0.0))
		var summon_pct = 1.0 - clampf(summon_time / game.NECRONADA_REMNANT_SUMMON_TIME, 0.0, 1.0)


		var mock_enemy = {
			"type": String(remnant.get("enemy_type", game.ENEMY_COMMON)), 
			"phase": float(remnant.get("phase", 0.0)), 
			"facing_dir": Vector2(remnant.get("facing_dir", Vector2.LEFT)), 
			"pos": Vector2(remnant.get("pos", game.player_pos))
		}
		var tex = game._enemy_texture(mock_enemy)
		var base_size = game._enemy_draw_size(mock_enemy)

		var size = base_size * (0.2 + 0.8 * summon_pct)
		var draw_pos = p + game._enemy_visual_offset(mock_enemy)
		var flip = game._enemy_should_flip(mock_enemy)


		game._draw_dynamic_shadow(tex, p, size, flip, 0.38 * summon_pct)


		if summon_time > 0.0:
			var anim_rot = (game.NECRONADA_REMNANT_SUMMON_TIME - summon_time) * 4.0
			game.draw_circle(p, base_size.x * 0.5 * summon_pct, Color(0.2, 0.9, 0.85, 0.28 * (1.0 - summon_time / game.NECRONADA_REMNANT_SUMMON_TIME)))
			game.draw_arc(p, base_size.x * (0.6 - 0.2 * summon_pct), anim_rot, anim_rot + TAU * 0.75, 32, Color(0.5, 0.95, 1.0, 0.85), 2.2)


		game.draw_circle(p, size.x * 0.44, Color(0.18, 0.58, 0.95, 0.26 * summon_pct))
		game.draw_arc(p, size.x * 0.48, game.time_alive * 2.5, game.time_alive * 2.5 + TAU * 0.62, 32, Color(0.65, 0.92, 1.0, 0.52 * summon_pct), 1.8)


		var glitch_jitter = Vector2(game.rng.randf_range(-3.0, 3.0), game.rng.randf_range(-2.0, 2.0)) if (int(game.time_alive * 24.0 + float(remnant.get("id", 0))) % 6 == 0) else Vector2.ZERO
		var ghost_modulate = Color(0.68, 0.88, 1.0, 0.92 * summon_pct)
		game._draw_entity(tex, draw_pos + glitch_jitter, size, ghost_modulate, flip)
		if glitch_jitter != Vector2.ZERO:

			game._draw_entity(tex, draw_pos - glitch_jitter * 1.5, size, Color(0.1, 0.95, 0.85, 0.38 * summon_pct), flip)


		if summon_time <= 0.0:
			var hp_ratio = clampf(float(remnant.get("hp", 1.0)) / maxf(1.0, float(remnant.get("max_hp", 1.0))), 0.0, 1.0)
			game._draw_necro_aliado_health_bar(p + Vector2(-25.0, - size.y * 0.55 - 12.0), 50.0, hp_ratio, 1.0)

		var target_pos = Vector2(remnant.get("target_pos", remnant.get("pos", game.player_pos))) - camera
		if target_pos.distance_to(p) > 22.0 and summon_time <= 0.0:
			var line_alpha = 0.34 if float(remnant.get("empower_timer", 0.0)) > 0.0 else 0.16
			game.draw_line(p, target_pos, Color(color.r, color.g, color.b, line_alpha), 1.2)
			if float(remnant.get("empower_timer", 0.0)) > 0.0:
				game.draw_arc(p, 34.0 + sin(game.time_alive * 7.0) * 4.0, 0.0, TAU, 42, Color(0.78, 0.46, 1.0, 0.52), 2.0)
	for enemy in game.enemies:
		if not bool(enemy.get("necronada_epitaph", false)):
			continue
		var p_enemy = Vector2(enemy.get("pos", game.player_pos)) - camera
		var depth_enemy = int(enemy.get("necronada_epitaph_depth", 1))
		var alpha = clampf(0.55 + float(enemy.get("necronada_epitaph_flash", 0.0)) * 0.45, 0.0, 1.0)
		for i in range(depth_enemy):
			var arc_radius = 34.0 + i * 4.5
			var arc_color = Color(0.8, 0.4, 1.0, alpha * (0.54 + float(i) * 0.045))
			game.draw_arc(p_enemy, arc_radius, - game.time_alive * (1.0 + i * 0.18), TAU - game.time_alive * (1.0 + i * 0.18), 52, arc_color, 1.8)
			game.draw_arc(p_enemy, arc_radius + 1.5, game.time_alive * (0.75 + i * 0.12), game.time_alive * (0.75 + i * 0.12) + TAU * 0.34, 32, Color(0.72, 0.96, 1.0, alpha * 0.3), 1.1)
		var stack_label = "E x%d" % depth_enemy
		var badge_w = 58.0
		var badge_h = 23.0
		var badge_rect = Rect2(p_enemy + Vector2( - badge_w * 0.5, -62.0), Vector2(badge_w, badge_h))
		game.draw_rect(badge_rect.grow(2.0), Color(0.45, 0.1, 0.78, 0.22 * alpha), true)
		game.draw_rect(badge_rect, Color(0.035, 0.018, 0.075, 0.9 * alpha), true)
		game.draw_rect(badge_rect, Color(0.86, 0.38, 1.0, 0.96 * alpha), false, 1.7)
		game.draw_line(badge_rect.position + Vector2(4, badge_h - 3), badge_rect.position + Vector2(badge_w - 4, badge_h - 3), Color(0.72, 0.96, 1.0, 0.34 * alpha), 1.0)
		game.draw_string(game.font, badge_rect.position + Vector2(0, 16.0), stack_label, HORIZONTAL_ALIGNMENT_CENTER, badge_w, game._readable_text_size(12), Color(0.95, 0.98, 1.0, alpha))
	for visual in game.necronada_vfx:
		var kind = String(visual.get("kind", ""))
		var alpha_v = clampf(float(visual.get("life", 0.0)) / maxf(0.01, float(visual.get("max", 0.3))), 0.0, 1.0)
		if kind == "remnant_strike" or kind == "remnant_bolt" or kind == "remnant_shock":
			var color_v: Color = visual.get("color", game._necronada_accent())
			var a_pos = Vector2(visual.get("a", game.player_pos)) - camera
			var b_pos = Vector2(visual.get("b", game.player_pos)) - camera
			if kind == "remnant_bolt":
				game.draw_line(a_pos, b_pos, Color(0.16, 0.06, 0.3, 0.52 * alpha_v), 7.0)
				game.draw_line(a_pos, b_pos, Color(color_v.r, color_v.g, color_v.b, 0.82 * alpha_v), 2.4)
			elif kind == "remnant_shock":
				game.draw_arc(b_pos, 24.0 + (1.0 - alpha_v) * 46.0, 0.0, TAU, 42, Color(color_v.r, color_v.g, color_v.b, 0.55 * alpha_v), 2.4)
			else:
				game.draw_line(a_pos, b_pos, Color(color_v.r, color_v.g, color_v.b, 0.72 * alpha_v), 3.0)
		elif kind == "empower_target":
			var pos_target = Vector2(visual.get("pos", game.player_pos)) - camera
			game.draw_circle(pos_target, 32.0 + sin(game.time_alive * 9.0) * 4.0, Color(0.08, 0.03, 0.14, 0.24 * alpha_v))
			game.draw_arc(pos_target, 44.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 54, Color(0.74, 0.44, 1.0, 0.56 * alpha_v), 2.0)
		elif kind == "tp_dust_fan":
			var fan_origin = Vector2(visual.get("pos", game.player_pos)) - camera
			var fan_dir = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
			var fan_radius = float(visual.get("radius", game.NECRONADA_TP_DUST_RADIUS))
			var points = PackedVector2Array([fan_origin])
			for i in range(11):
				var ratio = float(i) / 10.0
				var angle = fan_dir.angle() - game.NECRONADA_TP_DUST_HALF_ANGLE + game.NECRONADA_TP_DUST_HALF_ANGLE * 2.0 * ratio
				points.append(fan_origin + Vector2.from_angle(angle) * fan_radius * (0.86 + sin(game.time_alive * 18.0 + float(i)) * 0.035))
			game.draw_polygon(points, PackedColorArray([Color(0.18, 0.05, 0.28, 0.2 * alpha_v)]))
			for i in range(7):
				var angle = fan_dir.angle() - game.NECRONADA_TP_DUST_HALF_ANGLE + game.NECRONADA_TP_DUST_HALF_ANGLE * 2.0 * float(i) / 6.0
				game.draw_line(fan_origin + Vector2.from_angle(angle) * 18.0, fan_origin + Vector2.from_angle(angle) * fan_radius, Color(0.7, 0.36, 1.0, 0.2 * alpha_v), 2.0, true)
		elif kind == "dust_hit" or kind == "requiem_impact":
			var pos_hit = Vector2(visual.get("pos", game.player_pos)) - camera
			for i in range(7):
				var angle: float = float(i) * TAU / 7.0 + game.time_alive * 1.8
				game.draw_circle(pos_hit + Vector2.from_angle(angle) * (10.0 + (1.0 - alpha_v) * 28.0), 4.0 * alpha_v, Color(0.68, 0.34, 1.0, 0.52 * alpha_v))
		elif kind == "requiem_echo":
			var center = Vector2(visual.get("pos", game.player_pos)) - camera
			var radius_v = lerpf(32.0, 122.0, 1.0 - alpha_v)
			game.draw_circle(center, radius_v, Color(0.04, 0.06, 0.14, 0.18 * alpha_v))
			game.draw_arc(center, radius_v, 0.0, TAU, 64, Color(0.72, 0.96, 1.0, 0.58 * alpha_v), 2.2)
		elif kind == "rose_summon_ring":
			var center = Vector2(visual.get("pos", game.player_pos)) - camera
			var radius_v = float(visual.get("radius", game.NECRONADA_ROSE_SUMMON_RADIUS))
			game.draw_circle(center, radius_v, Color(0.12, 0.04, 0.2, 0.055 * alpha_v))
			game.draw_arc(center, radius_v, 0.0, TAU, 96, Color(0.72, 0.96, 1.0, 0.28 * alpha_v), 2.0)
		else:
			var pos = Vector2(visual.get("pos", game.player_pos)) - camera
			game.draw_circle(pos, 18.0 * alpha_v, Color(0.72, 0.96, 1.0, 0.36 * alpha_v))
	if not game.necronada_requiem.is_empty() and String(game.necronada_requiem.get("kind", "")) == "necrotic_wave":
		var origin = Vector2(game.necronada_requiem.get("origin", game.player_pos)) - camera
		var progress = 1.0 - clampf(float(game.necronada_requiem.get("life", 0.0)) / maxf(0.01, float(game.necronada_requiem.get("max", 1.0))), 0.0, 1.0)
		var radius = lerpf(42.0, game.NECRONADA_ULTIMATE_RADIUS, progress)
		game.draw_circle(origin, radius, Color(0.035, 0.015, 0.055, 0.16 * (1.0 - progress)))
		for i in range(18):
			var angle = float(i) * TAU / 18.0 + sin(game.time_alive + float(i)) * 0.1
			var local_ratio = 0.72 + 0.28 * (0.5 + 0.5 * sin(float(i) * 2.13 + game.time_alive * 2.4))
			var dust_pos = origin + Vector2.from_angle(angle) * (radius * local_ratio)
			game.draw_circle(dust_pos, 4.0 + 5.0 * (0.5 + 0.5 * cos(float(i) * 1.7 + game.time_alive * 3.1)), Color(0.44, 0.16, 0.7, 0.28 * (1.0 - progress)))
		game.draw_arc(origin, radius, - game.time_alive * 1.2, TAU - game.time_alive * 1.2, 96, Color(0.72, 0.42, 1.0, 0.58 * (1.0 - progress)), 4.0)


static func _draw_resonant_world_marks(game: Node2D, camera: Vector2) -> void :
	for enemy in game.enemies:
		var notes: Array = enemy.get("resonant_notes", [])
		if notes.is_empty() and float(enemy.get("resonant_flash", 0.0)) <= 0.0:
			continue
		var p = Vector2(enemy["pos"]) - camera
		for i in range(max(1, notes.size())):
			var angle = game.time_alive * 2.4 + i * TAU / 3.0
			game.draw_circle(p + Vector2.from_angle(angle) * 31.0, 4.5, Color(1.0, 0.8, 0.24, 0.75))
		game.draw_arc(p, 42.0, game.time_alive * 1.7, game.time_alive * 1.7 + TAU * 0.55, 40, Color(0.36, 0.92, 1.0, 0.48), 2.0)


static func _draw_contractual_notifications(game: Node2D, camera: Vector2) -> void :
	for trap in game.contractual_notifications:
		var p = Vector2(trap.get("pos", game.player_pos)) - camera
		var alpha = clamp(float(trap.get("life", 0.0)) / max(0.01, float(trap.get("max", game.CONTRACT_TRAP_LIFE))), 0.0, 1.0)
		var phase = float(trap.get("phase", 0.0))
		game.draw_circle(p, 48.0, Color(1.0, 0.54, 0.18, 0.08 * alpha))
		for i in range(4):
			var a = phase + game.time_alive * 1.4 + i * PI * 0.5
			var corner = p + Vector2.from_angle(a) * 38.0
			game.draw_line(corner - Vector2.from_angle(a) * 14.0, corner + Vector2.from_angle(a + PI * 0.5) * 10.0, Color(1.0, 0.82, 0.38, 0.7 * alpha), 2.0)
	for enemy in game.enemies:
		if not enemy.has("contract_clause"):
			continue
		var p = Vector2(enemy["pos"]) - camera
		var infractions = int(enemy.get("contract_infractions", 0))
		var clause = String(enemy.get("contract_clause", "aproximacao"))
		var clause_color = game._contract_clause_color(clause)
		var alpha = 0.46 + 0.16 * infractions + float(enemy.get("contract_flash", 0.0)) * 0.34
		game.draw_arc(p, 43.0, - PI * 0.5, PI * 1.5, 52, Color(clause_color.r, clause_color.g, clause_color.b, alpha), 2.2)
		game.draw_arc(p, 49.0 + sin(game.time_alive * 5.0 + float(infractions)) * 2.5, game.time_alive * 0.55, game.time_alive * 0.55 + TAU * 0.32, 36, Color(1.0, 0.92, 0.62, 0.28 + float(enemy.get("contract_flash", 0.0)) * 0.36), 1.6)
		var paper_center = p + Vector2(39, -42)
		var paper_rect = Rect2(paper_center - Vector2(11, 15), Vector2(22, 30))
		game.draw_rect(paper_rect, Color(0.96, 0.88, 0.66, 0.92), true)
		game.draw_rect(paper_rect, Color(clause_color.r, clause_color.g, clause_color.b, 0.82), false, 1.6)
		game.draw_line(paper_center + Vector2(-6, -5), paper_center + Vector2(6, -5), Color(0.38, 0.22, 0.08, 0.52), 1.0)
		game.draw_line(paper_center + Vector2(-5, 2), paper_center + Vector2(5, 2), Color(0.38, 0.22, 0.08, 0.42), 1.0)
		game._draw_centered(game._contract_clause_letter(clause), paper_center + Vector2(0, 10), 14, Color(0.18, 0.1, 0.04, 0.94))
		if infractions > 0:
			game._draw_centered("x%d" % infractions, paper_center + Vector2(15, -16), 9, Color(1.0, 0.32, 0.16, 0.92))
	for visual in game.contractual_vfx:
		if String(visual.get("kind", "")) != "gavel":
			continue
		var center = Vector2(visual.get("pos", game.player_pos)) - camera
		var v_alpha = clampf(float(visual.get("life", 0.0)) / maxf(0.01, float(visual.get("max", 1.0))), 0.0, 1.0)
		var progress = 1.0 - v_alpha
		var clause = String(visual.get("clause", "aproximacao"))
		var clause_color = game._contract_clause_color(clause)
		var strike = sin(clampf(progress, 0.0, 1.0) * PI)
		var hammer_pos = center + Vector2(-16.0 + strike * 14.0, -78.0 + strike * 42.0)
		game.draw_line(center + Vector2(-28, -47), center + Vector2(28, -47), Color(1.0, 0.86, 0.44, 0.46 * v_alpha), 2.0)
		game.draw_set_transform(hammer_pos, -0.68 + strike * 0.92, Vector2.ONE)
		game.draw_rect(Rect2(Vector2(-18, -6), Vector2(36, 12)), Color(0.72, 0.52, 0.28, 0.92 * v_alpha), true)
		game.draw_rect(Rect2(Vector2(-13, -3), Vector2(26, 6)), Color(1.0, 0.82, 0.44, 0.7 * v_alpha), true)
		game.draw_rect(Rect2(Vector2(-4, 5), Vector2(8, 32)), Color(0.34, 0.18, 0.08, 0.9 * v_alpha), true)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		game.draw_circle(center + Vector2(0, -42), 22.0 + strike * 14.0, Color(clause_color.r, clause_color.g, clause_color.b, 0.15 * v_alpha))
		game.draw_arc(center + Vector2(0, -42), 29.0 + strike * 10.0, 0.0, TAU, 38, Color(1.0, 0.9, 0.48, 0.58 * v_alpha), 2.2)
		game._draw_centered(game._contract_clause_letter(clause), center + Vector2(0, -66 - progress * 16.0), 15, Color(1.0, 0.92, 0.62, 0.88 * v_alpha))


static func _draw_manifest_evolution_fields(game: Node2D, camera: Vector2) -> void :
	if game.manifest_evolution_state.is_empty():
		return
	for field in Array(game.manifest_evolution_state.get("fields", [])):
		var center = Vector2(field.get("pos", game.player_pos)) - camera
		var radius = float(field.get("radius", 150.0))
		var max_life = maxf(0.01, float(field.get("max", 1.0)))
		var alpha = clampf(float(field.get("life", 0.0)) / max_life, 0.0, 1.0)
		var color: Color = field.get("color", game._manifestation_color())
		game.draw_circle(center, radius, Color(color.r, color.g, color.b, 0.06 * alpha))
		game.draw_arc(center, radius, 0.0, TAU, 96, Color(color.r, color.g, color.b, 0.42 * alpha), 3.0)
		game.draw_arc(center, radius * (0.68 + 0.06 * sin(game.time_alive * 6.0)), 0.0, TAU, 72, Color(1.0, 1.0, 1.0, 0.16 * alpha), 1.5)


static func _draw_manifestation_secondaries(game: Node2D, camera: Vector2) -> void :
	for secondary in game.manifestation_secondaries:
		match String(secondary.get("kind", "")):
			"eletrica":
				game._draw_secondary_eletrica(secondary, camera)
			"lacerante":
				game._draw_secondary_lacerante(secondary, camera)
			"prismatica":
				game._draw_secondary_prismatica(secondary, camera)
			"retornante":
				game._draw_secondary_retornante(secondary, camera)
			"parasitica":
				game._draw_secondary_parasitica(secondary, camera)
			"gravitante":
				game._draw_secondary_gravitante(secondary, camera)
			"ancorada":
				game._draw_secondary_ancorada(secondary, camera)
			"acorrentada":
				game._draw_secondary_acorrentada(secondary, camera)
			"eclipsada", "eclipsada_sol", "eclipsada_lua_eclipse":
				game._draw_secondary_eclipsada(secondary, camera)
			"bombastica":
				game._draw_secondary_bombastica(secondary, camera)
			"cartografica", "mnesica", "ressonante", "contratual":
				game._draw_secondary_advanced(secondary, camera)
	game._draw_bombastica_world(camera)


static func _draw_bombastica_world(game: Node2D, camera: Vector2) -> void :
	game._draw_bombastica_powder_trail_world(camera)
	for bomb in game.bombastica_bombs:
		if bool(bomb.get("exploded", false)):
			continue
		if String(bomb.get("kind", "")) == "ultimate_bomb":
			game._draw_bombastica_ultimate_bomb(bomb, camera)
			continue

		var p = Vector2(bomb.get("pos", game.player_pos)) - camera
		var state = String(bomb.get("state", "armed"))
		
		# Parabolic Arc Ground Shadow during Throw (Section 29)
		if state == "flying":
			var target_p = Vector2(bomb.get("target", game.player_pos)) - camera
			var age = float(bomb.get("age", 0.0))
			var travel = maxf(0.01, float(bomb.get("travel", 0.28)))
			var progress = clampf(age / travel, 0.0, 1.0)
			var height_factor = sin(progress * PI)
			var shadow_rx = lerpf(14.0, 6.0, height_factor)
			var shadow_ry = lerpf(7.0, 3.0, height_factor)
			var shadow_alpha = lerpf(0.55, 0.22, height_factor)
			game.draw_ellipse(target_p + Vector2(0, 10), shadow_rx, shadow_ry, Color(0.02, 0.02, 0.04, shadow_alpha))
			
		var radius = float(bomb.get("radius", game.BOMBASTICA_Q_RADIUS))
		var fuse = maxf(0.0, float(bomb.get("fuse", 0.0)))
		var fuse_total = maxf(0.01, float(bomb.get("fuse_total", game.BOMBASTICA_Q_FUSE_MIN)))
		var ratio = clampf(fuse / fuse_total, 0.0, 1.0)
		var urgent = 1.0 - ratio
		var pulse = 0.5 + 0.5 * sin(game.time_alive * lerpf(4.0, 16.0, urgent) + float(bomb.get("phase", 0.0)))
		var aura = Color(1.0, 0.44, 0.08, 0.08 + urgent * 0.08)
		if bool(bomb.get("critical", false)):
			aura = Color(1.0, 0.1, 0.08, 0.18 + pulse * 0.08)
			
		# Range Telegraph Circle
		game.draw_circle(p, radius, aura)
		game.draw_arc(p, radius + pulse * 5.0, - game.time_alive * 1.7, TAU - game.time_alive * 1.7, 72, Color(1.0, 0.58, 0.1, 0.58 + urgent * 0.3), 2.6)
		
		# Bomb Body & Fuse
		game.draw_circle(p, 18.0 + pulse * 2.0, Color(0.04, 0.04, 0.06, 0.92))
		game.draw_circle(p, 11.0, Color(1.0, 0.46, 0.06, 0.88))
		game.draw_circle(p - Vector2(3, 4), 4.0, Color(1.0, 0.95, 0.62, 0.92))
		var fuse_start = p + Vector2(0, -18)
		var fuse_tip = p + Vector2(cos(game.time_alive * 6.0) * 8.0, -32.0 - pulse * 5.0)
		game.draw_line(fuse_start, fuse_tip, Color(0.18, 0.88, 1.0, 0.68), 2.2)
		game.draw_circle(fuse_tip, 4.0 + pulse * 2.0, Color(1.0, 0.92, 0.44, 0.92))
		if fuse <= 1.0:
			game.draw_arc(p, 27.0 + pulse * 6.0, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.74), 2.0)
		game._draw_centered("%.1f" % fuse, p + Vector2(0, -47), 11, Color(1.0, 0.88, 0.48, 0.92))


static func _draw_bombastica_ultimate_bomb(game: Node2D, bomb: Dictionary, camera: Vector2) -> void :
	var p: Vector2 = Vector2(bomb.get("pos", game.player_pos)) - camera
	var radius: float = float(bomb.get("radius", game.BOMBASTICA_ULTIMATE_RADIUS))
	var spin_angle: float = float(bomb.get("spin_angle", 0.0))
	var squash_x: float = float(bomb.get("squash_x", 1.0))
	var squash_y: float = float(bomb.get("squash_y", 1.0))
	var flash_timer: float = float(bomb.get("flash_timer", 0.0))
	var grounded_timer: float = float(bomb.get("grounded_timer", 0.0))
	var bounce_phase: float = float(bomb.get("bounce_phase", 0.0))
	var hit_count: int = int(bomb.get("hit_count", 0))

	# 1. Rastro Laranja / Azul de Trajetória e Redirecionamento
	var trails: Array = bomb.get("trail_history", [])
	if trails.size() > 1:
		for i in range(trails.size() - 1):
			var t1: Dictionary = trails[i]
			var t2: Dictionary = trails[i + 1]
			var p1: Vector2 = Vector2(t1.get("pos", game.player_pos)) - camera
			var p2: Vector2 = Vector2(t2.get("pos", game.player_pos)) - camera
			var alpha_t: float = float(i) / float(trails.size())
			var trail_color: Color = Color(1.0, 0.52, 0.1, 0.6 * alpha_t) if i % 2 == 0 else Color(0.18, 0.88, 1.0, 0.6 * alpha_t)
			game.draw_line(p1, p2, trail_color, 4.0 * alpha_t + 1.0, true)

	# 2. Sombra e Área de Impacto
	game.draw_ellipse(p + Vector2(0, 16), 38.0 * squash_x, 16.0 * squash_y, Color(0.02, 0.02, 0.04, 0.5))
	var pulse_area: float = 0.5 + 0.5 * sin(game.time_alive * 5.0)
	game.draw_circle(p, radius, Color(1.0, 0.42, 0.08, 0.06 + pulse_area * 0.04))
	game.draw_arc(p, radius, 0.0, TAU, 72, Color(1.0, 0.55, 0.12, 0.45 + pulse_area * 0.25), 2.4)
	game.draw_arc(p, radius * (0.65 + pulse_area * 0.1), - game.time_alive * 2.0, - game.time_alive * 2.0 + TAU * 0.75, 48, Color(0.18, 0.88, 1.0, 0.35), 1.8)

	# 3. Corpo da Bomba com Compressão/Extensão (Squash/Stretch) & Rotação
	game.draw_set_transform(p, spin_angle, Vector2(squash_x, squash_y))
	var core_color: Color = Color(1.0, 0.45, 0.06, 0.95) if flash_timer <= 0.0 else Color(1.0, 0.95, 0.5, 1.0)
	game.draw_circle(Vector2.ZERO, 34.0, Color(0.04, 0.04, 0.06, 0.95))
	game.draw_circle(Vector2.ZERO, 25.0, core_color)
	game.draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 36, Color(0.18, 0.88, 1.0, 0.85), 3.0)
	game.draw_circle(Vector2(-7, -9), 7.0, Color(1.0, 0.95, 0.65, 0.92))
	for i in range(4):
		var angle: float = float(i) * PI * 0.5 + spin_angle
		var spike_tip: Vector2 = Vector2.from_angle(angle) * 32.0
		game.draw_line(Vector2.ZERO, spike_tip, Color(1.0, 0.68, 0.18, 0.8), 2.2)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 4. Telegraph de Controle: Anel Pulsante + Tag "ATIRE PARA GUIAR"
	var is_shootable: bool = grounded_timer > 0.0 or bounce_phase < 0.35 or bounce_phase > (game.BOMBASTICA_ULTIMATE_BOUNCE_PERIOD - 0.35)
	if is_shootable:
		var shoot_pulse: float = sin(game.time_alive * 10.0) * 5.0
		game.draw_arc(p, 54.0 + shoot_pulse, 0.0, TAU, 48, Color(1.0, 0.7, 0.12, 0.9), 3.2)
		game.draw_arc(p, 68.0 - shoot_pulse, 0.0, TAU, 48, Color(0.18, 0.88, 1.0, 0.7), 2.0)

		# Label Badge "ATIRE PARA GUIAR"
		var badge_y: float = - 62.0 + sin(game.time_alive * 6.0) * 4.0
		var badge_center: Vector2 = p + Vector2(0, badge_y)
		var badge_rect: Rect2 = Rect2(badge_center - Vector2(62, 12), Vector2(124, 24))
		game.draw_rect(badge_rect, Color(0.06, 0.05, 0.08, 0.88), true)
		game.draw_rect(badge_rect, Color(1.0, 0.58, 0.12, 0.92), false, 1.8)
		game._draw_centered("ATIRE PARA GUIAR", badge_center + Vector2(0, 4), 11, Color(1.0, 0.92, 0.54, 0.95))

	# 5. Badge de Multiplicador de Tiros Aceitos
	if hit_count > 0:
		game._draw_centered("[+x%d]" % hit_count, p + Vector2(0, -92), 12, Color(0.2, 0.9, 1.0, 0.95))
		
	for visual in game.bombastica_vfx:
		var alpha = clampf(float(visual.get("life", 0.0)) / maxf(0.01, float(visual.get("max", 1.0))), 0.0, 1.0)
		match String(visual.get("kind", "")):
			"explosion":
				if game.bombastica_use_old_vfx:
					var center = Vector2(visual.get("pos", game.player_pos)) - camera
					var max_radius = float(visual.get("radius", game.BOMBASTICA_Q_RADIUS))
					var grow = 1.0 - alpha
					var explosion_seed = int(visual.get("seed", 0))
					var chain_power = 1.0 + float(int(visual.get("chain_depth", 0))) * 0.12
					game.draw_circle(center, max_radius * (0.36 + grow * 0.54), Color(1.0, 0.2, 0.04, 0.11 * alpha * chain_power))
					game.draw_circle(center, max_radius * grow, Color(1.0, 0.52, 0.06, 0.18 * alpha))
					game.draw_circle(center, max_radius * 0.24 * (0.55 + grow), Color(1.0, 0.92, 0.46, 0.34 * alpha))
					game.draw_arc(center, max_radius * grow, 0.0, TAU, 92, Color(1.0, 0.8, 0.22, 0.88 * alpha), 6.0)
					game.draw_arc(center, max_radius * (0.62 + grow * 0.34), - game.time_alive * 5.2, TAU - game.time_alive * 5.2, 72, Color(0.18, 0.88, 1.0, 0.48 * alpha), 2.6)
					game.draw_arc(center, max_radius * (0.42 + grow * 0.46), game.time_alive * 4.0, game.time_alive * 4.0 + TAU * 0.68, 64, Color(1.0, 0.22, 0.08, 0.62 * alpha), 3.2)
					for i in range(16):
						var angle: float = float(i) * TAU / 16.0 + float(explosion_seed % 97) * 0.017 + sin(game.time_alive * 3.0 + i) * 0.08
						var inner = center + Vector2.from_angle(angle) * max_radius * 0.14 * grow
						var outer = center + Vector2.from_angle(angle) * max_radius * (0.45 + grow * (0.42 + float(i % 4) * 0.045))
						var spark_color = Color(1.0, 0.92 - float(i % 3) * 0.08, 0.36, 0.52 * alpha)
						game.draw_line(inner, outer, spark_color, 1.8 + float(i % 3) * 0.45)
						if i % 3 == 0:
							game.draw_circle(outer, 3.0 + grow * 2.0, Color(1.0, 0.58, 0.14, 0.54 * alpha))
			"link":
				var a = Vector2(visual.get("a", game.player_pos)) - camera
				var b = Vector2(visual.get("b", game.player_pos)) - camera
				var color: Color = visual.get("color", Color(1.0, 0.52, 0.1))
				var dir = (b - a).normalized()
				if dir.length() <= 0.01:
					dir = Vector2.RIGHT
				var side = dir.orthogonal()
				var link_seed = int(visual.get("seed", 0))
				game.draw_line(a, b, Color(color.r, color.g, color.b, 0.22 * alpha), 10.0, true)
				game.draw_line(a, b, Color(color.r, color.g, color.b, 0.82 * alpha), 2.4, true)
				for i in range(5):
					var t = (float(i) + 0.5) / 5.0
					var spark = a.lerp(b, t) + side * sin(game.time_alive * 14.0 + float(i) + float(link_seed % 31)) * 9.0
					game.draw_circle(spark, 3.6, Color(1.0, 0.92, 0.42, 0.7 * alpha))


static func _draw_secondary_bombastica(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var maximum = maxf(0.01, float(secondary.get("max", game.BOMBASTICA_E_DURATION)))
	var alpha = clampf(float(secondary.get("life", 0.0)) / maximum, 0.0, 1.0)
	var center = Vector2(secondary.get("center", game.player_pos)) - camera
	var phase: float = game.time_alive * 2.8 + float(secondary.get("seed", 0)) * 0.001
	game.draw_circle(center, 128.0, Color(1.0, 0.48, 0.08, 0.045 * alpha))
	game.draw_arc(center, 128.0, phase, phase + TAU * 0.86, 84, Color(1.0, 0.58, 0.1, 0.34 * alpha), 2.0)
	var mine_points: Array = []
	for mine in Array(secondary.get("mines", [])):
		if bool(mine.get("triggered", false)):
			continue
		var p = Vector2(mine.get("pos", game.player_pos)) - camera
		mine_points.append(p)
		var armed = bool(mine.get("armed", false))
		var mine_alpha = alpha * (0.92 if armed else 0.42)
		game.draw_circle(p, game.BOMBASTICA_E_MINE_RADIUS, Color(1.0, 0.42, 0.06, 0.06 * mine_alpha))
		game.draw_arc(p, game.BOMBASTICA_E_MINE_RADIUS, - phase, TAU - phase, 44, Color(1.0, 0.62, 0.18, 0.62 * mine_alpha), 2.0)
		game.draw_circle(p, 10.0, Color(0.06, 0.05, 0.06, 0.88 * mine_alpha))
		game.draw_circle(p, 5.0, Color(1.0, 0.68, 0.18, 0.92 * mine_alpha))
		if not armed:
			game._draw_centered("ARM", p + Vector2(0, -24), 9, Color(0.18, 0.88, 1.0, 0.8 * mine_alpha))
	for i in range(mine_points.size()):
		for j in range(i + 1, mine_points.size()):
			if mine_points[i].distance_to(mine_points[j]) <= 135.0:
				game.draw_line(mine_points[i], mine_points[j], Color(0.18, 0.88, 1.0, 0.14 * alpha), 2.0, true)


static func _draw_eletrica_kinetic_wave_at(game: Node2D, pos_world: Vector2, direction: Vector2, age: float, phase: float, camera: Vector2, alpha: float) -> void :
	var dir = direction.normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var side = dir.orthogonal()
	var pos = pos_world - camera
	var pulse = 0.5 + 0.5 * sin(age * 22.0 + phase)
	game.draw_circle(pos, game.ELETRICA_WAVE_RADIUS * 1.42, Color(0.08, 0.7, 1.0, 0.055 * alpha))
	game.draw_circle(pos, game.ELETRICA_WAVE_RADIUS * 0.78, Color(0.56, 0.96, 1.0, 0.105 * alpha))
	game.draw_circle(pos, game.ELETRICA_WAVE_RADIUS * 0.4, Color(0.88, 1.0, 1.0, 0.28 * alpha))
	for arc_index in range(3):
		var radius = game.ELETRICA_WAVE_RADIUS * (0.42 + arc_index * 0.13) + pulse * 5.0
		var start = age * (5.0 + arc_index) + arc_index * TAU / 3.0
		game.draw_arc(pos, radius, start, start + PI * 1.45, 38, Color(0.56, 0.96, 1.0, (0.62 - arc_index * 0.12) * alpha), 2.0)
	var core_a = pos - dir * 28.0 + side * sin(age * 19.0 + phase) * 7.0
	var core_b = pos - dir * 4.0 - side * sin(age * 26.0 + phase) * 8.0
	var core_c = pos + dir * 24.0
	game.draw_polyline(PackedVector2Array([core_a, core_b, core_c]), Color(0.86, 0.28, 1.0, 0.46 * alpha), 11.0, true)
	game.draw_polyline(PackedVector2Array([core_a, core_b, core_c]), Color(0.74, 1.0, 1.0, 0.9 * alpha), 4.0, true)
	for spark_index in range(5):
		var spark_angle = phase + age * 9.0 + spark_index * TAU / 5.0
		var inner = pos + Vector2.from_angle(spark_angle) * (game.ELETRICA_WAVE_RADIUS * 0.28)
		var outer = pos + Vector2.from_angle(spark_angle + sin(age * 7.0 + spark_index) * 0.12) * (game.ELETRICA_WAVE_RADIUS * (0.7 + pulse * 0.18))
		game.draw_line(inner, outer, Color(0.74, 1.0, 1.0, 0.34 * alpha), 1.4)


static func _draw_eletrica_chains(game: Node2D, camera: Vector2) -> void :
	for chain in game.eletrica_chains:
		var age = float(chain.get("age", 0.0))
		var life = float(chain.get("life", 0.0))
		var max_life = maxf(0.01, float(chain.get("max", game.ELETRICA_WAVE_CHAIN_DURATION)))
		var alpha = clampf(life / max_life, 0.0, 1.0)
		var reached_depth = int(floor(age / game.ELETRICA_WAVE_CHAIN_LEVEL_DELAY))
		var seed = int(chain.get("seed", 0))
		var origin_fallback = Vector2(chain.get("origin_pos", Vector2.ZERO))
		for link in Array(chain.get("links", [])):
			var depth = int(link.get("depth", 0))
			if depth > reached_depth:
				continue
			var a_uid = int(link.get("a", -1))
			var b_uid = int(link.get("b", -1))
			var a_pos = game._eletrica_chain_entity_pos(a_uid, origin_fallback)
			var b_pos = game._eletrica_chain_entity_pos(b_uid, a_pos)
			if a_pos == Vector2.ZERO or b_pos == Vector2.ZERO:
				continue
			var link_alpha = alpha * clampf((age - float(depth) * game.ELETRICA_WAVE_CHAIN_LEVEL_DELAY) / 0.22, 0.0, 1.0)
			game._draw_tesla_bolt(a_pos - camera, b_pos - camera, seed + a_uid * 17 + b_uid * 31, link_alpha, 4.2)
		for uid_value in Array(chain.get("targets", [])):
			var uid = int(uid_value)
			var depths: Dictionary = chain.get("depths", {})
			if int(depths.get(uid, 999)) > reached_depth:
				continue
			var enemy = game._enemy_by_uid(uid)
			if enemy != null and float(enemy.get("hp", 0.0)) > 0.0:
				var t_shock = float(enemy.get("tesla_shock", 0.0))
				if t_shock > 0.0:
					game._draw_tesla_enemy_crown(Vector2(enemy["pos"]) - camera, clampf(t_shock / 0.42, 0.0, 1.0), uid)


static func _draw_network_ability_visuals(game: Node2D, camera: Vector2) -> void :
	for visual in game.net_ability_visuals:
		var action = int(visual.get("action", game.NET_ABILITY_SKILL))
		var manifestation = clampi(int(visual.get("manifestation", 0)), 0, game.MANIFESTATIONS.size() - 1)
		var kind = String(game.MANIFESTATIONS[manifestation].get("key", "eletrica"))
		var color: Color = game.MANIFESTATIONS[manifestation].get("color", Color.WHITE)
		var origin = Vector2(visual.get("origin", game.net_player_render_pos)) - camera
		var target = Vector2(visual.get("target", game.net_player_render_pos)) - camera
		var maximum = maxf(0.01, float(visual.get("max", 1.0)))
		var life = maxf(0.0, float(visual.get("life", 0.0)))
		var progress = clampf(1.0 - life / maximum, 0.0, 1.0)
		var fade = clampf(minf(progress * 5.0, life * 4.0), 0.0, 1.0)
		match action:
			game.NET_ABILITY_ATTACK:
				var direction = (target - origin).normalized()
				if direction.length() <= 0.01:
					direction = Vector2.RIGHT
				var reach = minf(origin.distance_to(target), 260.0)
				var tip = origin + direction * reach * minf(1.0, progress * 3.0)
				if kind == "lacerante":
					var side = direction.orthogonal() * (24.0 + float(visual.get("extra", 0.0)) * 8.0)
					var world_origin = Vector2(visual.get("origin", game.net_player_render_pos))
					var world_tip = Vector2(visual.get("target", game.net_player_render_pos))
					game._draw_lacerante_blade({"points": [world_origin - side, world_origin.lerp(world_tip, 0.55) + side, world_tip], "empowered": float(visual.get("extra", 0.0)) > 2.0}, camera, life / maximum)
				elif kind == "acorrentada":
					var stage = clampi(int(visual.get("extra", 1.0)), 1, 3)
					var travel = game._acorrentada_replica_travel(stage, progress)
					var arc = 26.0 if stage == 1 else (64.0 if stage == 2 else 42.0)
					var windup_ratio = game._acorrentada_attack_windup_time(stage) / game._acorrentada_attack_duration(stage)
					var hit_ratio = (game._acorrentada_attack_windup_time(stage) + game._acorrentada_attack_out_time(stage)) / game._acorrentada_attack_duration(stage)
					var arc_phase = 0.0
					if progress < windup_ratio:
						arc_phase = - sin(clampf(progress / maxf(0.01, windup_ratio), 0.0, 1.0) * PI) * 0.18
					else:
						arc_phase = sin(clampf((progress - windup_ratio) / maxf(0.01, hit_ratio - windup_ratio), 0.0, 1.0) * PI)
					tip = origin.lerp(target, travel) + direction.orthogonal() * arc_phase * arc * (-1.0 if stage != 2 else 1.0)
					var width = 6.0 if stage == 1 else (9.0 if stage == 2 else 11.0)
					var chain_color = Color(0.18, 0.86, 1.0, 0.86 * fade) if stage == 1 else Color(0.92, 0.12, 0.1, 0.82 * fade)
					if stage == 3:
						var side = direction.orthogonal() * 18.0
						game._draw_acorrentada_chain(origin + side, tip - side, Color(0.18, 0.86, 1.0, 0.88 * fade), width, fade, true)
						game._draw_acorrentada_chain(origin - side, tip + side, Color(0.92, 0.12, 0.1, 0.88 * fade), width, fade, false)
					else:
						game._draw_acorrentada_chain(origin, tip, chain_color, width, fade, stage == 1)
				elif kind == "eclipsada":
					var stage = clampi(int(visual.get("extra", 1.0)), 1, 4)
					var slash_radius = 80.0
					var side = direction.orthogonal() * slash_radius
					var center = origin.lerp(target, minf(1.0, progress * 2.4))
					game.draw_line(center - side, center + side, Color(0.0, 0.02, 0.12, 0.78 * fade), 20.0 if stage >= 4 else 14.0, true)
					game.draw_line(center - side, center + side, Color(color.r, color.g, color.b, 0.92 * fade), 7.0 if stage >= 4 else 5.0, true)
					game.draw_line(center - side, center + side, Color(0.92, 0.98, 1.0, 0.9 * fade), 1.8, true)
					if stage >= 4:
						game.draw_arc(center, slash_radius, - game.time_alive * 3.4, TAU - game.time_alive * 3.4, 42, Color(1.0, 0.86, 0.28, 0.6 * fade), 2.6)
				else:
					var orb = origin.lerp(target, minf(1.0, progress * 2.0))
					game.draw_circle(orb, 12.0, Color(color.r, color.g, color.b, 0.26 * fade))
					game.draw_circle(orb, 5.0, Color(1.0, 1.0, 1.0, 0.92 * fade))
			game.NET_ABILITY_SKILL:
				match kind:
					"eletrica":
						var wave_dir = (target - origin).normalized()
						if wave_dir.length() <= 0.01:
							wave_dir = Vector2.RIGHT
						var travel = minf(origin.distance_to(target), game.ELETRICA_WAVE_SPEED * maximum)
						var wave_pos = origin + wave_dir * minf(travel, game.ELETRICA_WAVE_SPEED * progress * maximum)
						game._draw_eletrica_kinetic_wave_at(wave_pos + camera, wave_dir, progress * maximum, float(visual.get("seed", 0)) * 0.001, camera, fade)
					"lacerante":
						game._draw_lacerante_spin({"center": Vector2(visual.get("origin", game.net_player_render_pos)), "radius": 128.0, "life": life, "max": maximum, "rotations": float(visual.get("rotations", game.LACERANTE_Q_ROTATIONS))}, camera, fade)
					"parasitica":
						game._draw_network_parasite_spit_replica(visual, camera)
					"prismatica":
						game._draw_prismatica_prism({
							"pos": Vector2(visual.get("target", target + camera)), 
							"life": life, 
							"max_life": maximum, 
							"network_fade": fade
						}, camera)
					"acorrentada":
						var side = (target - origin).normalized().orthogonal() * 18.0
						game._draw_acorrentada_chain(origin + side, target - side, Color(0.18, 0.86, 1.0, 0.84 * fade), 6.0, fade, true)
						game._draw_acorrentada_chain(origin - side, target + side, Color(0.92, 0.12, 0.1, 0.74 * fade), 8.0, fade, false)
					"eclipsada":
						var q_dir = (target - origin).normalized()
						if q_dir.length() <= 0.01:
							q_dir = Vector2.RIGHT
						var q_start = origin - q_dir * 54.0
						var q_finish = target + q_dir * 42.0
						game.draw_line(q_start, q_finish, Color(0.0, 0.03, 0.14, 0.82 * fade), 28.0, true)
						game.draw_line(q_start, q_finish, Color(color.r, color.g, color.b, 0.86 * fade), 6.0, true)
						for endpoint in [origin, target]:
							game.draw_circle(endpoint, 28.0, Color(0.03, 0.16, 0.42, 0.24 * fade))
							game.draw_arc(endpoint, 30.0 + progress * 16.0, - game.time_alive * 4.0, - game.time_alive * 4.0 + PI * 1.55, 42, Color(0.48, 0.88, 1.0, 0.78 * fade), 3.0)
					"bombastica":
						var bomb_p = target
						var pulse = 0.5 + 0.5 * sin(game.time_alive * 12.0 + float(visual.get("seed", 0)))
						game.draw_circle(bomb_p, game.BOMBASTICA_Q_RADIUS, Color(1.0, 0.42, 0.08, 0.08 * fade))
						game.draw_arc(bomb_p, game.BOMBASTICA_Q_RADIUS + pulse * 6.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 68, Color(1.0, 0.58, 0.12, 0.72 * fade), 3.0)
						game.draw_circle(bomb_p, 18.0 + pulse * 3.0, Color(0.08, 0.05, 0.03, 0.72 * fade))
						game.draw_circle(bomb_p, 8.0, Color(1.0, 0.7, 0.18, 0.9 * fade))
						game.draw_line(origin, bomb_p, Color(0.18, 0.88, 1.0, 0.28 * fade), 5.0, true)
					_:
						var skill_center = origin if kind in ["eletrica", "ancorada", "retornante", "cartografica", "mnesica", "ressonante", "contratual"] else target
						var radius = lerpf(24.0, 170.0, minf(1.0, progress * 2.0))
						game.draw_circle(skill_center, radius, Color(color.r, color.g, color.b, 0.055 * fade))
						game.draw_arc(skill_center, radius, - game.time_alive * 1.8, TAU - game.time_alive * 1.8, 64, Color(color.r, color.g, color.b, 0.72 * fade), 4.0)
			game.NET_ABILITY_SECONDARY:
				game._draw_network_secondary_replica(visual, camera)
			game.NET_ABILITY_TELEPORT:
				game._draw_network_teleport_replica(visual, camera, kind, color, progress, fade)


static func _draw_prismatica_prism(game: Node2D, prism: Dictionary, camera: Vector2) -> void :
	var p: Vector2 = Vector2(prism.get("pos", game.player_pos)) - camera
	var life = float(prism.get("life", prism.get("max_life", 1.0)))
	var fade = clampf(float(prism.get("network_fade", 1.0)), 0.0, 1.0)
	var pulse = 0.5 + 0.5 * sin(life * 8.0)
	var size = float(prism.get("radius", 42.0)) + pulse * (9.0 if bool(prism.get("tp_prism", false)) else 6.0)
	var points = PackedVector2Array([
		p + Vector2(0, - size), 
		p + Vector2(size, 0), 
		p + Vector2(0, size), 
		p + Vector2( - size, 0)
	])
	game.draw_polygon(points, PackedColorArray([Color(0.27, 0.96, 1.0, 0.14 * fade)]))
	game.draw_polyline(points, Color(0.27, 0.96, 1.0, 0.82 * fade), 3.0)
	game.draw_circle(p, size * 0.45, Color(1.0, 0.45, 0.72, (0.22 + pulse * 0.15) * fade))
	game.draw_arc(p, size * 0.45, 0, TAU, 32, Color(1.0, 0.45, 0.72, 0.82 * fade), 1.5)


static func _draw_network_secondary_replica(game: Node2D, visual: Dictionary, camera: Vector2) -> void :
	match String(visual.get("kind", "")):
		"eletrica": game._draw_secondary_eletrica(visual, camera)
		"lacerante": game._draw_secondary_lacerante(visual, camera)
		"prismatica": game._draw_secondary_prismatica(visual, camera)
		"retornante": game._draw_secondary_retornante(visual, camera)
		"parasitica": game._draw_secondary_parasitica(visual, camera)
		"gravitante": game._draw_secondary_gravitante(visual, camera)
		"ancorada": game._draw_secondary_ancorada(visual, camera)
		"acorrentada": game._draw_secondary_acorrentada(visual, camera)
		"eclipsada": game._draw_secondary_eclipsada(visual, camera)
		"bombastica": game._draw_secondary_bombastica(visual, camera)
		"cartografica", "mnesica", "ressonante", "contratual": game._draw_secondary_advanced(visual, camera)
	game._draw_ancorada_spinning_anchors(camera)


static func _draw_network_parasite_spit_replica(game: Node2D, visual: Dictionary, camera: Vector2) -> void :
	var maximum = maxf(0.01, float(visual.get("max", 3.2)))
	var elapsed = maximum - float(visual.get("life", maximum))
	var travel = game.PARASITE_SPIT_TRAVEL
	var origin = Vector2(visual.get("origin", game.net_player_render_pos))
	var target = Vector2(visual.get("target", origin))
	var phase = float(visual.get("phase", 0.0))
	if elapsed < travel:
		var progress = clampf(elapsed / travel, 0.0, 1.0)
		var world_pos = origin.lerp(target, progress) + Vector2(0, - sin(progress * PI) * 92.0)
		var pos = world_pos - camera
		game.draw_circle(pos, 21.0, Color(0.18, 0.3, 0.05, 0.3))
		for worm_index in range(4):
			var angle = phase + progress * 10.0 + worm_index * TAU / 4.0
			game._draw_parasite_worm(pos + Vector2.from_angle(angle) * 13.0, angle + PI * 0.5, 0.62, game.time_alive * 8.0 + worm_index, 0.96)
		return
	var center = target - camera
	var fade = clampf(float(visual.get("life", 0.0)) / maximum, 0.0, 1.0)
	var pulse = 0.5 + 0.5 * sin(game.time_alive * 5.5 + phase)
	game.draw_circle(center, game.PARASITE_SPIT_RADIUS, Color(0.22, 0.34, 0.05, 0.1 * fade))
	game.draw_arc(center, game.PARASITE_SPIT_RADIUS + pulse * 5.0, 0.0, TAU, 56, Color(0.58, 0.88, 0.18, 0.54 * fade), 2.4)
	for worm_index in range(7):
		var angle: float = game.time_alive * (0.34 + worm_index * 0.015) + phase + float(worm_index) * TAU / 7.0
		var radius = game.PARASITE_SPIT_RADIUS * (0.25 + 0.55 * float((worm_index % 3) + 1) / 3.0)
		game._draw_parasite_worm(center + Vector2.from_angle(angle) * radius, angle + PI * 0.58, 0.46 + (worm_index % 2) * 0.1, game.time_alive * 5.0 + worm_index, fade)


static func _draw_secondary_eclipsada(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	if String(secondary.get("kind", "")) == "eclipsada_sol":
		var sol_life = maxf(0.0, float(secondary.get("life", 0.0)))
		var sol_max = maxf(0.01, float(secondary.get("max", game.ECLIPSADA_SOL_E_DURATION)))
		var sol_alpha = clampf(sol_life / sol_max, 0.0, 1.0)
		var sol_color: Color = secondary.get("color", game._eclipsada_color())
		var sol_pos = Vector2(secondary.get("pos", game.player_pos)) - camera
		var sol_radius = float(secondary.get("radius", game.ECLIPSADA_SOL_E_RADIUS))
		var sol_phase: float = float(secondary.get("phase", 0.0)) + game.time_alive * 3.2
		game.draw_circle(sol_pos, sol_radius, Color(1.0, 0.58, 0.12, 0.055 * sol_alpha))
		game.draw_circle(sol_pos, sol_radius * 0.54, Color(sol_color.r, sol_color.g, sol_color.b, 0.07 * sol_alpha))
		for i in range(5):
			var angle = sol_phase + float(i) * TAU / 5.0
			game.draw_arc(sol_pos, sol_radius * (0.44 + float(i % 3) * 0.16), angle, angle + PI * 1.24, 54, Color(sol_color.r, sol_color.g, sol_color.b, (0.46 - i * 0.045) * sol_alpha), 3.2)
		for ray in range(12):
			var ray_angle: float = sol_phase * 0.55 + float(ray) * TAU / 12.0
			var a = sol_pos + Vector2.from_angle(ray_angle) * sol_radius * 0.22
			var b = sol_pos + Vector2.from_angle(ray_angle + sin(game.time_alive * 4.0 + ray) * 0.04) * sol_radius * 0.92
			game.draw_line(a, b, Color(1.0, 0.92, 0.46, 0.2 * sol_alpha), 2.0, true)
		return
	if String(secondary.get("kind", "")) == "eclipsada_lua_eclipse":
		var lua_life = maxf(0.0, float(secondary.get("life", 0.0)))
		var lua_max = maxf(0.01, float(secondary.get("max", game.ECLIPSADA_LUA_E_DURATION)))
		var lua_alpha = clampf(lua_life / lua_max, 0.0, 1.0)
		var lua_color: Color = secondary.get("color", game._eclipsada_color())
		var lua_pos = Vector2(secondary.get("center", game.player_pos)) - camera
		var lua_radius = float(secondary.get("radius", game.ECLIPSADA_LUA_E_RADIUS))
		var lua_phase: float = float(secondary.get("phase", 0.0)) + game.time_alive * 2.1
		game.draw_circle(lua_pos, lua_radius, Color(0.01, 0.03, 0.12, 0.075 * lua_alpha))
		game.draw_circle(lua_pos, lua_radius * 0.48, Color(0.12, 0.22, 0.52, 0.085 * lua_alpha))
		for ring in range(4):
			var radius = lua_radius * (0.34 + float(ring) * 0.18)
			game.draw_arc(lua_pos, radius, lua_phase + float(ring) * 0.58, lua_phase + float(ring) * 0.58 + PI * 1.36, 58, Color(lua_color.r, lua_color.g, lua_color.b, (0.58 - ring * 0.07) * lua_alpha), 2.6)
		for blade in range(6):
			var angle = lua_phase * -0.55 + float(blade) * TAU / 6.0
			var a = lua_pos + Vector2.from_angle(angle) * lua_radius * 0.18
			var b = lua_pos + Vector2.from_angle(angle + sin(game.time_alive * 3.4 + blade) * 0.06) * lua_radius * 0.92
			game.draw_line(a, b, Color(0.03, 0.05, 0.14, 0.56 * lua_alpha), 8.0, true)
			game.draw_line(a, b, Color(lua_color.r, lua_color.g, lua_color.b, 0.42 * lua_alpha), 2.5, true)
		return
	var life = maxf(0.0, float(secondary.get("life", 0.0)))
	var maximum = maxf(0.01, float(secondary.get("max", game.ECLIPSADA_E_MAX_TARGET_TIME)))
	var alpha = clampf(life / maximum, 0.0, 1.0)
	var color: Color = secondary.get("color", game._eclipsada_color())
	var target: Dictionary = secondary.get("target", {})
	var center: Vector2 = Vector2(secondary.get("last_pos", game.player_pos))
	if not target.is_empty() and game._eclipsada_target_alive(target):
		center = game._eclipsada_target_pos(target)
	var p: Vector2 = center - camera
	var phase: float = float(secondary.get("phase", 0.0)) + game.time_alive * 8.0
	game.draw_circle(p, 62.0, Color(0.01, 0.04, 0.16, 0.34 * alpha))
	game.draw_circle(p, 54.0, Color(color.r, color.g, color.b, 0.13 * alpha))
	game.draw_arc(p, 58.0, phase, phase + PI * 1.72, 56, Color(color.r, color.g, color.b, 0.88 * alpha), 4.0)
	game.draw_arc(p, 67.0, - phase * 0.72, - phase * 0.72 + PI * 1.32, 52, Color(0.28, 0.78, 1.0, 0.52 * alpha), 2.4)
	game.draw_arc(p, 30.0 + sin(game.time_alive * 10.0) * 4.0, - phase * 1.3, TAU - phase * 1.3, 36, Color(1.0, 0.86, 0.28, 0.7 * alpha), 2.6)
	for i in range(8):
		var angle = phase + float(i) * PI * 0.5
		var a = p + Vector2.from_angle(angle) * 14.0
		var b = p + Vector2.from_angle(angle + 0.42) * (54.0 + 7.0 * sin(game.time_alive * 11.0 + i))
		game.draw_line(a, b, Color(0.02, 0.06, 0.18, 0.72 * alpha), 8.0, true)
		game.draw_line(a, b, Color(color.r, color.g, color.b, 0.82 * alpha), 3.0, true)
	var cuts_left = int(secondary.get("cuts_left", 0))
	if cuts_left > 0:
		game._draw_centered(str(cuts_left), p + Vector2(0, -68), 16, Color(1.0, 0.88, 0.34, 0.86 * alpha))


static func _draw_eclipsada_vfx(game: Node2D, camera: Vector2) -> void :
	for visual in game.eclipsada_vfx:
		match String(visual.get("kind", "")):
			"attack":
				game._draw_eclipsada_attack_vfx(visual, camera)
			"q_dash", "q_sol":
				game._draw_eclipsada_q_vfx(visual, camera)
			"e_entry", "e_cut", "e_chain", "e_exit":
				game._draw_eclipsada_e_vfx(visual, camera)
			"form_swap", "shuriken_fall", "sol_burst", "sol_pulse", "lua_eclipse_pulse":
				game._draw_eclipsada_special_vfx(visual, camera)


static func _draw_eclipsada_attack_vfx(game: Node2D, visual: Dictionary, camera: Vector2) -> void :
	var center = Vector2(visual.get("center", game.player_pos)) - camera
	var direction = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var radius = float(visual.get("radius", game.ECLIPSADA_ATTACK_SLASH_RADIUS))
	var step = clampi(int(visual.get("step", 1)), 1, 4)
	var progress = game._eclipsada_vfx_progress(visual)
	var fade = game._eclipsada_vfx_fade(visual)
	var color: Color = visual.get("color", game._eclipsada_color())
	if String(visual.get("style", "")) == "lua_blades":
		var origin: Vector2 = Vector2(visual.get("origin", game.player_pos)) - camera
		var side: Vector2 = direction.orthogonal()
		var crit: bool = bool(visual.get("crit", false))
		var sweep: float = sin(progress * PI)
		for lane in [-1.0, 1.0]:
			var offset: Vector2 = side * lane * (13.0 + sweep * 5.0)
			var start: Vector2 = origin + direction * 18.0 + offset
			var finish: Vector2 = origin + direction * radius + offset + side * lane * 10.0 * sweep
			var mid: Vector2 = start.lerp(finish, 0.52) + side * lane * (18.0 + 12.0 * sweep)
			var trail = PackedVector2Array([start, mid, finish])
			game.draw_polyline(trail, Color(0.0, 0.015, 0.08, 0.84 * fade), 22.0 if crit else 17.0, true)
			game.draw_polyline(trail, Color(color.r, color.g, color.b, 0.32 * fade), 14.0 if crit else 10.0, true)
			game.draw_polyline(trail, Color(color.r, color.g, color.b, 0.96 * fade), 5.0 if crit else 3.8, true)
			game.draw_polyline(trail, Color(0.88, 0.97, 1.0, 0.95 * fade), 1.5, true)
		if crit:
			game.draw_arc(origin, radius * 0.72, direction.angle() - 0.62, direction.angle() + 0.62, 54, Color(0.82, 0.92, 1.0, 0.7 * fade), 4.0)
			game.draw_circle(origin + direction * radius * 0.8, 18.0 + sweep * 18.0, Color(color.r, color.g, color.b, 0.18 * fade))
		return
	var swing_sign = -1.0 if step % 2 == 0 else 1.0
	var head_angle = direction.angle() - swing_sign * 1.22 + swing_sign * 2.44 * ease(progress, 0.34)
	var trail = PackedVector2Array()
	for index in range(24):
		var ratio = float(index) / 23.0
		var angle = head_angle - swing_sign * (1.58 - ratio * 1.58)
		var blade_radius = radius * (0.78 + sin(ratio * PI) * 0.18)
		trail.append(center + Vector2.from_angle(angle) * blade_radius)
	game.draw_polyline(trail, Color(0.01, 0.03, 0.12, 0.78 * fade), 22.0 if step >= 4 else 16.0, true)
	game.draw_polyline(trail, Color(color.r, color.g, color.b, 0.3 * fade), 15.0 if step >= 4 else 11.0, true)
	game.draw_polyline(trail, Color(color.r, color.g, color.b, 0.96 * fade), 6.0 if step >= 4 else 4.5, true)
	game.draw_polyline(trail, Color(0.88, 0.97, 1.0, 0.96 * fade), 1.7, true)
	var tip = trail[trail.size() - 1]
	var tangent = Vector2.from_angle(head_angle + PI * 0.5)
	game.draw_line(tip - tangent * 13.0, tip + tangent * 20.0, Color(0.78, 0.94, 1.0, 0.86 * fade), 3.0, true)
	if step >= 4:
		game.draw_circle(center, radius * (0.3 + progress * 0.32), Color(color.r, color.g, color.b, 0.08 * fade))
		game.draw_arc(center, radius, - head_angle, TAU - head_angle, 72, Color(0.32, 0.82, 1.0, 0.72 * fade), 4.0)
		game.draw_arc(center, radius * 0.68, head_angle, head_angle + PI * 1.55, 54, Color(1.0, 0.86, 0.3, 0.7 * fade), 2.8)
		var cross_dir = direction.orthogonal()
		game.draw_line(center - cross_dir * radius * 0.72, center + cross_dir * radius * 0.72, Color(0.92, 0.98, 1.0, 0.72 * fade), 3.0, true)


static func _draw_eclipsada_q_vfx(game: Node2D, visual: Dictionary, camera: Vector2) -> void :
	var kind = String(visual.get("kind", "q_dash"))
	var origin = Vector2(visual.get("origin", game.player_pos)) - camera
	var target = Vector2(visual.get("target", game.player_pos)) - camera
	var direction = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var progress = game._eclipsada_vfx_progress(visual)
	var fade = game._eclipsada_vfx_fade(visual)
	var color: Color = visual.get("color", game._eclipsada_color())
	if kind == "q_sol":
		var side = direction.orthogonal()
		for lane in range(3):
			var offset = (float(lane) - 1.0) * 26.0
			var start_sol = origin + side * offset
			var finish_sol = start_sol.lerp(target + side * offset * 0.45, minf(1.0, progress * 1.35))
			game.draw_line(start_sol, finish_sol, Color(0.16, 0.06, 0.0, 0.52 * fade), 18.0, true)
			game.draw_line(start_sol, finish_sol, Color(color.r, color.g, color.b, 0.82 * fade), 5.0, true)
			game.draw_circle(finish_sol, 12.0 + sin(game.time_alive * 10.0 + lane) * 2.0, Color(1.0, 0.92, 0.46, 0.42 * fade))
		game.draw_arc(origin, 48.0 + progress * 24.0, - game.time_alive * 5.0, TAU - game.time_alive * 5.0, 58, Color(1.0, 0.78, 0.24, 0.74 * fade), 3.5)
		return
	var start = origin - direction * 54.0
	var finish = target + direction * 42.0
	var side = direction.orthogonal()
	var path = PackedVector2Array([start, origin + side * sin(progress * PI) * 13.0, finish])
	game.draw_polyline(path, Color(0.0, 0.03, 0.14, 0.82 * fade), 30.0, true)
	game.draw_polyline(path, Color(0.12, 0.5, 1.0, 0.3 * fade), 20.0, true)
	game.draw_polyline(path, Color(color.r, color.g, color.b, 0.92 * fade), 6.0, true)
	for index in range(5):
		var ratio = float(index) / 4.0
		var ghost = start.lerp(finish, ratio) + side * sin(progress * 8.0 + index) * 7.0
		game.draw_arc(ghost, 18.0 + index * 2.0, direction.angle() - 1.1, direction.angle() + 1.1, 22, Color(0.42, 0.82, 1.0, (0.18 + ratio * 0.1) * fade), 3.0)
	for endpoint in [origin, target]:
		game.draw_circle(endpoint, 28.0 * (1.0 - progress * 0.45), Color(0.03, 0.16, 0.42, 0.28 * fade))
		game.draw_arc(endpoint, 30.0 + progress * 18.0, game.time_alive * 4.0, game.time_alive * 4.0 + PI * 1.52, 42, Color(0.46, 0.88, 1.0, 0.78 * fade), 3.0)


static func _draw_eclipsada_e_vfx(game: Node2D, visual: Dictionary, camera: Vector2) -> void :
	var kind = String(visual.get("kind", "e_cut"))
	var progress = game._eclipsada_vfx_progress(visual)
	var fade = game._eclipsada_vfx_fade(visual)
	var color: Color = visual.get("color", game._eclipsada_color())
	var target = Vector2(visual.get("target", game.player_pos)) - camera
	if kind == "e_entry":
		var origin = Vector2(visual.get("origin", game.player_pos)) - camera
		var direction = (target - origin).normalized()
		if direction.length() <= 0.01:
			direction = Vector2.RIGHT
		var side = direction.orthogonal()
		var streak = PackedVector2Array([origin - direction * 28.0, origin.lerp(target, 0.55) + side * 26.0 * sin(progress * PI), target])
		game.draw_polyline(streak, Color(0.0, 0.02, 0.12, 0.82 * fade), 34.0, true)
		game.draw_polyline(streak, Color(color.r, color.g, color.b, 0.86 * fade), 7.0, true)
		game.draw_arc(target, 66.0 * (0.45 + progress * 0.55), - game.time_alive * 5.0, TAU - game.time_alive * 5.0, 60, Color(0.42, 0.84, 1.0, 0.84 * fade), 4.0)
	elif kind == "e_cut":
		var direction = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
		var length = 62.0 + sin(progress * PI) * 22.0
		var start = target - direction * length
		var finish = target + direction * length
		game.draw_line(start, finish, Color(0.0, 0.02, 0.12, 0.88 * fade), 24.0, true)
		game.draw_line(start, finish, Color(color.r, color.g, color.b, 0.96 * fade), 8.0, true)
		game.draw_line(start, finish, Color(0.94, 0.99, 1.0, 0.98 * fade), 2.0, true)
		var cross = direction.orthogonal()
		game.draw_line(target - cross * length * 0.48, target + cross * length * 0.48, Color(0.36, 0.78, 1.0, 0.56 * fade), 3.0, true)
		game.draw_circle(target, 12.0 + progress * 18.0, Color(0.7, 0.92, 1.0, 0.24 * fade))
	elif kind == "e_chain":
		var origin = Vector2(visual.get("origin", game.player_pos)) - camera
		var delta = target - origin
		var side = delta.normalized().orthogonal() if delta.length() > 0.01 else Vector2.UP
		var path = PackedVector2Array([origin, origin.lerp(target, 0.5) + side * sin(progress * PI) * 38.0, target])
		game.draw_polyline(path, Color(0.0, 0.03, 0.14, 0.8 * fade), 22.0, true)
		game.draw_polyline(path, Color(0.38, 0.82, 1.0, 0.9 * fade), 5.0, true)
		for index in range(4):
			game.draw_circle(origin.lerp(target, (float(index) + progress) / 4.0), 4.0, Color(0.9, 0.98, 1.0, 0.82 * fade))
	else:
		var collapse = 74.0 * (1.0 - progress * 0.72)
		var exit_color = Color(0.32, 0.58, 0.72) if bool(visual.get("cancelled", false)) else color
		game.draw_circle(target, collapse * 0.52, Color(0.01, 0.05, 0.16, 0.28 * fade))
		game.draw_arc(target, collapse, game.time_alive * 6.0, game.time_alive * 6.0 + PI * 1.68, 56, Color(exit_color.r, exit_color.g, exit_color.b, 0.82 * fade), 4.0)
		game.draw_arc(target, collapse * 0.62, - game.time_alive * 8.0, - game.time_alive * 8.0 + PI * 1.38, 42, Color(0.82, 0.96, 1.0, 0.7 * fade), 2.0)


static func _draw_eclipsada_special_vfx(game: Node2D, visual: Dictionary, camera: Vector2) -> void :
	var kind = String(visual.get("kind", "form_swap"))
	var progress = game._eclipsada_vfx_progress(visual)
	var fade = game._eclipsada_vfx_fade(visual)
	var color: Color = visual.get("color", game._eclipsada_color())
	var target = Vector2(visual.get("target", game.player_pos)) - camera
	match kind:
		"form_swap":
			var solar = String(visual.get("form", game.ECLIPSADA_FORM_LUA)) == game.ECLIPSADA_FORM_SOL
			var opposite = Color(0.58, 0.42, 1.0) if solar else Color(1.0, 0.66, 0.18)
			for ring in range(3):
				var radius = 26.0 + progress * (34.0 + ring * 18.0)
				game.draw_arc(target, radius, game.time_alive * (4.0 + ring) + ring, game.time_alive * (4.0 + ring) + ring + PI * 1.55, 58, Color(color.r, color.g, color.b, (0.76 - ring * 0.14) * fade), 3.0)
				game.draw_arc(target, radius * 0.76, - game.time_alive * (3.0 + ring), - game.time_alive * (3.0 + ring) + PI * 1.1, 44, Color(opposite.r, opposite.g, opposite.b, (0.46 - ring * 0.1) * fade), 2.0)
			game.draw_circle(target, 18.0 + sin(game.time_alive * 12.0) * 3.0, Color(color.r, color.g, color.b, 0.2 * fade))
		"shuriken_fall":
			var radius = 18.0 + progress * 22.0
			game.draw_circle(target, radius * 0.7, Color(0.02, 0.02, 0.04, 0.28 * fade))
			game.draw_arc(target, radius, game.time_alive * 5.0, game.time_alive * 5.0 + PI * 1.6, 36, Color(color.r, color.g, color.b, 0.72 * fade), 2.4)
			for i in range(4):
				var dir = Vector2.from_angle(float(i) * TAU / 4.0 + progress * 2.5)
				game.draw_line(target, target + dir * (12.0 + progress * 28.0), Color(color.r, color.g, color.b, 0.34 * fade), 1.5, true)
		"sol_burst", "sol_pulse":
			var radius = float(visual.get("radius", game.ECLIPSADA_SOL_SPLASH_RADIUS))
			var current = radius * (0.3 + progress * 0.7)
			game.draw_circle(target, current, Color(color.r, color.g, color.b, 0.07 * fade))
			game.draw_arc(target, current, - game.time_alive * 4.0, TAU - game.time_alive * 4.0, 64, Color(color.r, color.g, color.b, 0.82 * fade), 3.8)
			game.draw_arc(target, current * 0.62, game.time_alive * 6.0, game.time_alive * 6.0 + PI * 1.35, 46, Color(1.0, 0.94, 0.58, 0.62 * fade), 2.4)
			for ray in range(8):
				var ray_angle: float = game.time_alive * 0.9 + float(ray) * TAU / 8.0
				game.draw_line(target + Vector2.from_angle(ray_angle) * current * 0.18, target + Vector2.from_angle(ray_angle) * current, Color(1.0, 0.86, 0.32, 0.24 * fade), 1.8, true)
		"lua_eclipse_pulse":
			var radius = float(visual.get("radius", game.ECLIPSADA_LUA_E_RADIUS))
			var current = radius * (0.5 + progress * 0.5)
			game.draw_circle(target, current, Color(0.02, 0.04, 0.18, 0.055 * fade))
			game.draw_arc(target, current, game.time_alive * 3.2, game.time_alive * 3.2 + PI * 1.64, 72, Color(color.r, color.g, color.b, 0.72 * fade), 3.4)
			game.draw_arc(target, current * 0.72, - game.time_alive * 4.4, - game.time_alive * 4.4 + PI * 1.18, 58, Color(0.48, 0.82, 1.0, 0.46 * fade), 2.2)


static func _draw_eclipsada_stealth_overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void :
	var alpha = game._eclipsada_stealth_overlay_alpha()
	if alpha <= 0.0:
		return
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.015, 0.16, 0.38, alpha), true)
	var edge_alpha = alpha * 1.75
	var edge_size = 10.0
	game.draw_rect(Rect2(0.0, 0.0, viewport.x, edge_size), Color(0.18, 0.62, 1.0, edge_alpha), true)
	game.draw_rect(Rect2(0.0, viewport.y - edge_size, viewport.x, edge_size), Color(0.08, 0.38, 0.82, edge_alpha), true)
	game.draw_rect(Rect2(0.0, 0.0, edge_size, viewport.y), Color(0.08, 0.38, 0.82, edge_alpha), true)
	game.draw_rect(Rect2(viewport.x - edge_size, 0.0, edge_size, viewport.y), Color(0.18, 0.62, 1.0, edge_alpha), true)
	var player_screen: Vector2 = game.player_pos - camera
	var pulse = 0.5 + 0.5 * sin(game.time_alive * 5.0)
	game.draw_arc(player_screen, 58.0 + pulse * 6.0, game.time_alive * 1.8, game.time_alive * 1.8 + PI * 1.55, 52, Color(0.46, 0.86, 1.0, 0.4 + pulse * 0.12), 2.4)


static func _draw_network_teleport_replica(game: Node2D, visual: Dictionary, camera: Vector2, kind: String, color: Color, progress: float, fade: float) -> void :
	var origin = Vector2(visual.get("origin", game.net_player_render_pos)) - camera
	var target = Vector2(visual.get("target", game.net_player_render_pos)) - camera
	var direction = (target - origin).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	if kind == "eletrica":
		game._draw_tesla_bolt(origin, target, int(visual.get("seed", 0)), fade, 5.0)
	elif kind == "prismatica":
		for endpoint in [origin, target]:
			var radius = 22.0 + progress * 28.0
			var diamond = PackedVector2Array([endpoint + Vector2(0, - radius), endpoint + Vector2(radius, 0), endpoint + Vector2(0, radius), endpoint + Vector2( - radius, 0), endpoint + Vector2(0, - radius)])
			game.draw_polyline(diamond, Color(0.72, 1.0, 1.0, 0.88 * fade), 3.0, true)
	elif kind == "parasitica":
		for index in range(6):
			var point = origin.lerp(target, float(index) / 5.0)
			game.draw_circle(point, 9.0, Color(0.38, 0.72, 0.12, 0.72 * fade))
	elif kind == "acorrentada":
		game._draw_acorrentada_chain(origin, target, Color(0.18, 0.86, 1.0, 0.88 * fade), 8.0, fade, true)
		game._draw_acorrentada_chain(origin + direction.orthogonal() * 10.0, target - direction.orthogonal() * 10.0, Color(0.92, 0.12, 0.1, 0.54 * fade), 5.0, fade, false)
	else:
		var side = direction.orthogonal()
		var middle = origin.lerp(target, 0.5) + side * sin(progress * PI) * 18.0
		var path = PackedVector2Array([origin, middle, target])
		game.draw_polyline(path, Color(color.r, color.g, color.b, 0.24 * fade), 28.0, true)
		game.draw_polyline(path, Color(color.r, color.g, color.b, 0.88 * fade), 6.0, true)
	game.draw_circle(origin, 28.0 * (1.0 - progress), Color(color.r, color.g, color.b, 0.36 * fade))
	game.draw_circle(target, 18.0 + progress * 20.0, Color(color.r, color.g, color.b, 0.3 * fade))


static func _draw_secondary_advanced(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var kind = String(secondary.get("kind", ""))
	var alpha: float = clamp(float(secondary.get("life", 0.0)) / max(0.01, float(secondary.get("max", 1.0))), 0.0, 1.0)
	var color = game._damage_color(kind)
	var center: Vector2 = Vector2(secondary.get("center", game.player_pos)) - camera
	match kind:
		"cartografica":
			game.draw_arc(center, 210.0 + sin(game.time_alive * 4.0) * 5.0, game.time_alive, game.time_alive + TAU * 0.82, 84, Color(color.r, color.g, color.b, 0.36 * alpha), 3.0)
		"mnesica":
			game.draw_circle(center, game.MNESIC_REENACT_RADIUS * 0.55, Color(color.r, color.g, color.b, 0.035 * alpha))
			game.draw_arc(center, game.MNESIC_REENACT_RADIUS * 0.55, - game.time_alive * 0.7, TAU - game.time_alive * 0.7, 88, Color(color.r, color.g, color.b, 0.3 * alpha), 2.0)
		"ressonante":
			var r = 110.0 + sin(game.time_alive * 8.0) * 8.0
			game.draw_arc(center, r, 0, TAU, 64, Color(color.r, color.g, color.b, 0.48 * alpha), 3.0)

			for i in range(24):
				var angle = i * TAU / 24.0
				var bar_len = 10.0 + sin(game.time_alive * 12.0 + i) * 15.0
				var p1 = center + Vector2.from_angle(angle) * r
				var p2 = center + Vector2.from_angle(angle) * (r + bar_len)
				game.draw_line(p1, p2, Color(1.0, 0.8, 0.3, 0.6 * alpha), 4.0)

			for i in range(3):
				var laser_angle = game.time_alive * 1.5 + i * TAU / 3.0
				game.draw_line(center, center + Vector2.from_angle(laser_angle) * 800.0, Color(1.0, 0.9, 0.5, 0.15 * alpha), 25.0)
				game.draw_line(center, center + Vector2.from_angle(laser_angle) * 800.0, Color(1.0, 1.0, 1.0, 0.25 * alpha), 6.0)
		"contratual":
			game.draw_arc(center, 180.0, - PI * 0.5, PI * 1.5, 72, Color(color.r, color.g, color.b, 0.4 * alpha), 2.2)
			game.draw_line(center + Vector2(-90, -72), center + Vector2(90, -72), Color(1.0, 0.86, 0.48, 0.38 * alpha), 2.0)


static func _draw_secondary_eletrica(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var active_time = float(secondary.get("active_time", 0.0))
	var ring_radius = game._secondary_eletrica_radius(active_time)
	var center_world = Vector2(secondary.get("center", game.player_pos))
	var center = center_world - camera


	var shock_age: float = game.time_alive - float(secondary.get("last_shock_time", -999.0))
	var shock_pulse_bonus = 0.0
	if shock_age >= 0.0 and shock_age < 0.2:
		shock_pulse_bonus = (1.0 - shock_age / 0.2) * 6.0


	var drain_age: float = game.time_alive - float(secondary.get("last_drain_time", -999.0))
	var drain_pulse_shrink = 0.0
	if drain_age >= 0.0 and drain_age < 0.25:
		drain_pulse_shrink = (1.0 - drain_age / 0.25) * 8.0

	var effective_radius = ring_radius + shock_pulse_bonus - drain_pulse_shrink


	var state_hue = Color(0.36, 0.98, 1.0)
	var rot_speed = 0.45
	var outer_alpha = 0.22

	if active_time >= 15.0:
		state_hue = Color(1.0, 0.12, 0.24)
		rot_speed = 1.65
		outer_alpha = 0.45
	elif active_time >= 13.0:
		var t = (active_time - 13.0) / 2.0
		state_hue = Color(1.0, lerpf(0.55, 0.15, t), 0.1)
		rot_speed = 1.2
		outer_alpha = 0.38
	elif active_time >= 10.0:
		var t = (active_time - 10.0) / 3.0
		state_hue = Color(lerpf(0.36, 1.0, t), lerpf(0.98, 0.85, t), lerpf(1.0, 0.2, t))
		rot_speed = 0.8
		outer_alpha = 0.3


	game.draw_circle(center, effective_radius, Color(state_hue.r, state_hue.g, state_hue.b, 0.04))
	game.draw_circle(center, effective_radius * 0.66, Color(state_hue.r, state_hue.g, state_hue.b, 0.03))

	for band in range(3):
		var radius: float = effective_radius - float(band) * 18.0 + sin(game.time_alive * (2.2 + band * 0.3)) * 3.0
		var band_rot: float = game.time_alive * (rot_speed + float(band) * 0.12)
		game.draw_arc(center, radius, - band_rot, TAU - band_rot, 96, Color(state_hue.r, state_hue.g, state_hue.b, outer_alpha - float(band) * 0.045), 1.6)


	var ray_count = 22
	var pulse: float = 0.5 + sin(game.time_alive * (7.0 if active_time < 13.0 else 14.0)) * 0.5
	for i in range(ray_count):
		var ang: float = game.time_alive * (rot_speed * 1.2) + float(i) * TAU / float(ray_count)
		var inner: Vector2 = center + Vector2.from_angle(ang + sin(game.time_alive * 2.0 + float(i)) * 0.04) * (effective_radius * game.rng_deterministic_wave(i, 0.5, 0.8))
		var outer: Vector2 = center + Vector2.from_angle(ang) * (effective_radius + sin(game.time_alive * 8.0 + float(i)) * 8.0)
		game.draw_line(inner, outer, Color(state_hue.r, state_hue.g, state_hue.b, 0.13 + pulse * 0.1), 1.3)


	if active_time >= 13.0:
		var tendon_count = 6
		var chest_pos = center + Vector2(0, -14)
		for t in range(tendon_count):
			var ang: float = game.time_alive * 2.4 + float(t) * TAU / float(tendon_count)
			var rim_pt = center + Vector2.from_angle(ang) * (effective_radius * 0.45)
			var tendon_col = Color(1.0, 0.4, 0.2, 0.45 + pulse * 0.3) if active_time < 15.0 else Color(1.0, 0.9, 0.95, 0.7 + pulse * 0.25)
			game.draw_line(rim_pt, chest_pos, tendon_col, 1.5)


	for enemy in game.enemies:
		var dist = Vector2(enemy["pos"]).distance_to(center_world)
		if dist <= ring_radius + game._enemy_radius(enemy) * 0.55:
			var target = Vector2(enemy["pos"]) - camera
			var shock_alpha: float = 0.34 + clamp(float(enemy.get("tesla_shock", 0.0)) / 0.42, 0.0, 1.0) * 0.58
			game._draw_tesla_bolt(center + Vector2(0, -18), target + Vector2(0, -16), int(enemy.get("uid", 0)) + int(active_time * 10.0), shock_alpha, 4.2)
			game._draw_tesla_enemy_crown(target, float(enemy.get("tesla_shock", 0.0)), int(enemy.get("uid", 0)))
	if game.boss_active and game.boss_hp > 0.0 and game.boss_pos.distance_to(center_world) <= ring_radius + 68.0:
		var boss_alpha: float = 0.34 + clamp(float(secondary.get("boss_tesla_shock", 0.0)) / 0.42, 0.0, 1.0) * 0.48
		game._draw_tesla_bolt(center + Vector2(0, -18), game.boss_pos - camera + Vector2(0, -30), int(secondary.get("seed", 0)) + 99, boss_alpha, 5.2)


	game._draw_tesla_bar(secondary, camera)


static func _draw_tesla_bar(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var active_time = float(secondary.get("active_time", 0.0))
	var safe_progress = clampf(active_time / game.SECONDARY_ELETRICA_DRAIN_DELAY, 0.0, 1.0)
	var overload_time = maxf(0.0, active_time - game.SECONDARY_ELETRICA_DRAIN_DELAY)
	var overload_tier = int(floor(overload_time / game.SECONDARY_ELETRICA_DRAIN_TIER_SECONDS))
	var tier_progress_sec = fmod(overload_time, game.SECONDARY_ELETRICA_DRAIN_TIER_SECONDS)


	var bar_base: Vector2 = game.player_pos - camera + Vector2(0, -58)


	var vibrate_offset = Vector2.ZERO
	var allow_vibration: bool = bool(game.gfx_screen_shake)

	if allow_vibration:
		if active_time >= 15.0:
			var drain_age: float = game.time_alive - float(secondary.get("last_drain_time", -999.0))
			if drain_age >= 0.0 and drain_age < 0.25:
				var p = 1.0 - drain_age / 0.25
				vibrate_offset = Vector2(round(sin(drain_age * 60.0) * 3.0 * p), round(cos(drain_age * 50.0) * 2.0 * p))
			else:
				vibrate_offset = Vector2(round(sin(game.time_alive * 30.0) * 0.8), round(cos(game.time_alive * 24.0) * 0.5))
		elif active_time >= 14.0:
			vibrate_offset = Vector2(round(sin(game.time_alive * 44.0) * 1.5), round(cos(game.time_alive * 36.0) * 1.0))
		elif active_time >= 13.0:
			vibrate_offset = Vector2(round(sin(game.time_alive * 28.0) * 1.0), round(cos(game.time_alive * 22.0) * 0.5))
		elif active_time >= 10.0:
			vibrate_offset = Vector2(round(sin(game.time_alive * 18.0) * 0.5), 0)

	var bar_center: Vector2 = bar_base + vibrate_offset


	var bar_w = 44.0
	var bar_h = 6.0
	var inner_w = 42.0
	var inner_h = 4.0

	var frame_rect = Rect2(bar_center.x - bar_w * 0.5, bar_center.y - bar_h * 0.5, bar_w, bar_h)
	var inner_rect = Rect2(bar_center.x - inner_w * 0.5, bar_center.y - inner_h * 0.5, inner_w, inner_h)


	var fill_color = Color(0.02, 0.7, 1.0)
	if active_time >= 15.0:
		var red_pulse = 0.5 + 0.5 * sin(game.time_alive * 16.0)
		fill_color = Color(1.0, 0.05 + red_pulse * 0.15, 0.12 + red_pulse * 0.2)
	elif active_time >= 14.0:
		var t = active_time - 14.0
		fill_color = Color(1.0, lerpf(0.45, 0.12, t), 0.05)
	elif active_time >= 13.0:
		var t = active_time - 13.0
		fill_color = Color(1.0, lerpf(0.9, 0.45, t), 0.05)
	elif active_time >= 10.0:
		var t = (active_time - 10.0) / 3.0
		fill_color = Color(lerpf(0.02, 1.0, t), lerpf(0.7, 0.9, t), lerpf(1.0, 0.05, t))


	game.draw_rect(frame_rect, Color(0.03, 0.05, 0.09, 0.92), true)
	game.draw_rect(inner_rect, Color(0.02, 0.04, 0.07, 0.95), true)


	var fill_px = int(round(safe_progress * inner_w))
	if fill_px > 0:
		var fill_rect = Rect2(inner_rect.position.x, inner_rect.position.y, float(fill_px), inner_h)
		game.draw_rect(fill_rect, fill_color, true)
		game.draw_line(fill_rect.position + Vector2(0, 1), fill_rect.position + Vector2(fill_rect.size.x, 1), Color(1.0, 1.0, 1.0, 0.5), 1.0)


	game.draw_rect(frame_rect, Color(0.18, 0.24, 0.34, 0.85), false, 1.0)


	var pin_count = 4
	for p in range(pin_count):
		var pin_x = inner_rect.position.x + (float(p + 1) / float(pin_count + 1)) * inner_w
		var pin_lit = false
		if active_time >= 15.0:
			pin_lit = (tier_progress_sec >= float(p + 1))
		var pin_col = Color(1.0, 0.92, 0.35) if pin_lit else Color(0.12, 0.16, 0.24)
		game.draw_rect(Rect2(pin_x - 1.0, inner_rect.position.y - 1.0, 2.0, 2.0), pin_col, true)
		if pin_lit:
			game.draw_rect(Rect2(pin_x - 1.0, inner_rect.position.y + inner_h - 1.0, 2.0, 2.0), pin_col, true)


	if overload_tier > 0:
		var notch_col = Color(1.0, 0.3, 0.2, 0.9)
		for t in range(mini(overload_tier, 5)):
			var notch_x = inner_rect.position.x + (float(t + 1) * 7.0)
			game.draw_line(Vector2(notch_x, frame_rect.position.y - 2.0), Vector2(notch_x + 2.0, frame_rect.position.y + bar_h + 2.0), notch_col, 1.0)


	if active_time >= 10.0:
		var spark_count = 1 if active_time < 13.0 else (3 if active_time <= 15.0 else 2)
		for s in range(spark_count):
			var spark_t: float = game.time_alive * 12.0 + float(s) * 2.3
			var spark_x = inner_rect.position.x + fmod(abs(sin(spark_t)) * inner_w, inner_w)
			var spark_y = inner_rect.position.y + sin(spark_t * 3.1) * 3.0
			var spark_col = Color(1.0, 0.9, 0.3) if active_time < 13.0 else Color(1.0, 0.35, 0.15)
			game.draw_rect(Rect2(spark_x, spark_y, 1.5, 1.5), spark_col, true)


static func _draw_tesla_bolt(game: Node2D, start: Vector2, finish: Vector2, seed: int, alpha: float, width: float) -> void :
	var delta = finish - start
	var length = delta.length()
	if length <= 4.0:
		return
	var dir = delta / length
	var normal = dir.orthogonal()
	var points = PackedVector2Array()
	var segments = 9
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var taper = sin(t * PI)
		var jitter = sin(float(seed) * 0.73 + float(i) * 2.41 + game.time_alive * 31.0) * 18.0 * taper
		var small = cos(float(seed) * 1.19 + float(i) * 5.17 + game.time_alive * 19.0) * 6.0 * taper
		points.append(start + delta * t + normal * jitter + dir.rotated(PI * 0.5) * small)
	if points.size() < 2:
		return
	game.draw_polyline(points, Color(0.1, 0.92, 1.0, 0.2 * alpha), width + 7.0, true)
	game.draw_polyline(points, Color(0.54, 0.96, 1.0, 0.72 * alpha), width, true)
	game.draw_polyline(points, Color(1.0, 1.0, 1.0, 0.92 * alpha), maxf(1.0, width * 0.34), true)
	for branch in range(2):
		var branch_t = 0.28 + float(branch) * 0.28 + 0.08 * sin(float(seed + branch) + game.time_alive * 9.0)
		var base = start + delta * branch_t
		var branch_dir = dir.rotated((0.65 if branch == 0 else -0.65) + sin(game.time_alive * 7.0 + branch + seed) * 0.28)
		var branch_end = base + branch_dir * (26.0 + 14.0 * sin(game.time_alive * 11.0 + seed + branch))
		game.draw_line(base, branch_end, Color(0.42, 0.92, 1.0, 0.38 * alpha), maxf(1.0, width * 0.42), true)


static func _draw_lacerante_blade(game: Node2D, slash: Dictionary, camera: Vector2, alpha: float) -> void :
	var path = PackedVector2Array()
	for point in slash.get("points", []):
		path.append(Vector2(point) - camera)
	if path.size() < 2:
		return
	var empowered = bool(slash.get("empowered", false))
	var appear = clamp((1.0 - alpha) * 5.0, 0.0, 1.0)
	var fade = clamp(alpha * 1.7, 0.0, 1.0) * appear
	var glow = 22.0 if empowered else 15.0
	game.draw_polyline(path, Color(0.2, 0.0, 0.025, 0.72 * fade), glow + 10.0, true)
	game.draw_polyline(path, Color(1.0, 0.01, 0.08, (0.3 if empowered else 0.2) * fade), glow + 18.0, true)
	game.draw_polyline(path, Color(0.82, 0.015, 0.08, 0.94 * fade), 8.5 if empowered else 6.5, true)
	game.draw_polyline(path, Color(1.0, 0.28, 0.34, 0.94 * fade), 4.2, true)
	game.draw_polyline(path, Color(1.0, 0.92, 0.9, 0.96 * fade), 1.7, true)
	var finish = path[path.size() - 1]
	var direction = (finish - path[path.size() - 2]).normalized()
	var side = direction.orthogonal()
	var blade = PackedVector2Array([
		finish + direction * (24.0 if empowered else 18.0), 
		finish + side * (8.0 if empowered else 6.0), 
		finish - direction * 9.0, 
		finish - side * (8.0 if empowered else 6.0)
	])
	game.draw_polygon(blade, PackedColorArray([Color(1.0, 0.16, 0.22, 0.86 * fade)]))
	game.draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), Color(1.0, 0.88, 0.86, 0.9 * fade), 1.4, true)


static func _draw_lacerante_spin(game: Node2D, slash: Dictionary, camera: Vector2, alpha: float) -> void :
	var center = Vector2(slash.get("center", game.player_pos)) - camera
	var radius = float(slash.get("radius", 128.0))
	var max_life = max(0.01, float(slash.get("max", game.LACERANTE_Q_DURATION)))
	var progress = clamp(1.0 - float(slash.get("life", 0.0)) / max_life, 0.0, 1.0)
	var rotations = float(slash.get("rotations", game.LACERANTE_Q_ROTATIONS))
	var head_angle = - PI * 0.5 + progress * TAU * rotations
	var fade = clamp(alpha * 1.8, 0.0, 1.0)
	game.draw_circle(center, radius + 24.0, Color(0.2, 0.0, 0.025, 0.055 * fade))
	game.draw_arc(center, radius, 0.0, TAU, 80, Color(1.0, 0.04, 0.1, 0.13 * fade), 1.3)
	var trail = PackedVector2Array()
	var trail_span = 1.55
	for i in range(30):
		var t = float(i) / 29.0
		var angle = head_angle - trail_span + trail_span * t
		var wobble = sin(t * PI) * 4.0
		trail.append(center + Vector2.from_angle(angle) * (radius + wobble))
	game.draw_polyline(trail, Color(0.28, 0.0, 0.035, 0.72 * fade), 24.0, true)
	game.draw_polyline(trail, Color(1.0, 0.0, 0.08, 0.2 * fade), 34.0, true)
	game.draw_polyline(trail, Color(0.94, 0.03, 0.1, 0.92 * fade), 9.0, true)
	game.draw_polyline(trail, Color(1.0, 0.42, 0.44, 0.96 * fade), 4.0, true)
	game.draw_polyline(trail, Color(1.0, 0.96, 0.9, 0.94 * fade), 1.6, true)
	var tip = center + Vector2.from_angle(head_angle) * radius
	var tangent = Vector2.from_angle(head_angle + PI * 0.5)
	var radial = Vector2.from_angle(head_angle)
	var blade = PackedVector2Array([
		tip + tangent * 31.0, 
		tip + radial * 10.0, 
		tip - tangent * 18.0, 
		tip - radial * 10.0
	])
	game.draw_polygon(blade, PackedColorArray([Color(0.94, 0.04, 0.1, 0.94 * fade)]))
	game.draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), Color(1.0, 0.92, 0.88, 0.96 * fade), 2.0, true)
	for i in range(6):
		var spark_angle = head_angle - float(i) * 0.19
		var spark = center + Vector2.from_angle(spark_angle) * (radius + sin(game.time_alive * 17.0 + i) * 9.0)
		game.draw_line(spark, spark - Vector2.from_angle(spark_angle + PI * 0.5) * (10.0 + i * 2.0), Color(1.0, 0.34, 0.4, (0.72 - i * 0.08) * fade), 1.5, true)


static func _draw_teleport_effects(game: Node2D, camera: Vector2) -> void :
	for effect in game.tp_effects:
		var kind = String(effect.get("kind", ""))
		var fade: float = clampf(float(effect.get("life", 0.0)) / max(0.01, float(effect.get("max", 1.0))), 0.0, 1.0)
		var progress: float = 1.0 - fade
		if kind == "parasite_egg":
			var pos: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
			var phase: float = float(effect.get("phase", 0.0))
			var forward = Vector2.from_angle(phase) * 9.0
			game.draw_circle(pos, 10.0, Color(0.18, 0.08, 0.02, 0.88 * fade))
			game.draw_arc(pos, 10.0, 0.0, TAU, 18, Color(0.62, 1.0, 0.22, 0.92 * fade), 2.0)
			game.draw_line(pos - forward, pos + forward, Color(0.82, 1.0, 0.42, 0.78 * fade), 3.0, true)
		elif kind == "eletrica":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			var points = PackedVector2Array([a])
			for i in range(1, 12):
				var t = float(i) / 12.0
				var base = a.lerp(b, t)
				var normal = (b - a).normalized().orthogonal()
				points.append(base + normal * sin(game.time_alive * 24.0 + i * 2.1) * 14.0)
			points.append(b)
			game.draw_polyline(points, Color(0.08, 0.5, 1.0, 0.25 * fade), 22.0, true)
			game.draw_polyline(points, Color(0.3, 0.96, 1.0, 0.88 * fade), 5.0, true)
			game.draw_polyline(points, Color.WHITE, 1.4, true)
			for endpoint in [a, b]:
				game.draw_circle(endpoint, 34.0 * (0.35 + progress), Color(0.22, 0.92, 1.0, 0.16 * fade))
				for i in range(8):
					var angle: float = game.time_alive * 5.0 + float(i) * TAU / 8.0
					game.draw_line(endpoint, endpoint + Vector2.from_angle(angle) * (22.0 + 18.0 * progress), Color(0.72, 1.0, 1.0, 0.62 * fade), 2.0, true)
		elif kind == "prismatica":
			var path: Array = effect.get("path", [Vector2(effect.get("a", game.player_pos)), Vector2(effect.get("b", game.player_pos))])
			var points: PackedVector2Array = PackedVector2Array()
			for raw_point in path:
				points.append(Vector2(raw_point) - camera)
			if points.size() >= 2:
				var spark: Vector2 = game._point_on_polyline(points, progress)
				for i in range(points.size()):
					var hue: float = fposmod(game.time_alive * 0.72 + float(i) * 0.18, 1.0)
					var radius: float = 8.0 + sin(progress * PI + float(i)) * 4.0
					game.draw_circle(points[i], radius + 12.0 * fade, Color.from_hsv(hue, 0.85, 1.0, 0.18 * fade))
					game.draw_arc(points[i], radius + 18.0, game.time_alive * 2.4 + float(i), game.time_alive * 2.4 + float(i) + PI * 1.35, 30, Color.from_hsv(hue, 0.65, 1.0, 0.74 * fade), 2.0, true)
				game.draw_circle(spark, 12.0 + 10.0 * sin(progress * PI), Color(0.85, 1.0, 1.0, 0.78 * fade))
		elif kind == "retornante":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			var center: Vector2 = a.lerp(b, 0.5)
			game.draw_arc(a, 32.0 + 8.0 * sin(game.time_alive * 9.0), -game.time_alive * 4.0, TAU - game.time_alive * 4.0, 40, Color(0.72, 0.54, 1.0, 0.75 * fade), 2.0)
			game.draw_arc(b, 42.0 + 10.0 * sin(game.time_alive * 7.0), game.time_alive * 4.0, TAU + game.time_alive * 4.0, 48, Color(0.9, 0.72, 1.0, 0.75 * fade), 2.0)
			game.draw_line(a, center, Color(0.62, 0.42, 1.0, 0.3 * fade), 4.0, true)
			game.draw_line(center, b, Color(0.78, 0.64, 1.0, 0.3 * fade), 4.0, true)
		elif kind == "parasitica":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			var dir: Vector2 = (b - a).normalized()
			if dir.length() <= 0.01:
				dir = Vector2.RIGHT
			var side: Vector2 = dir.orthogonal()
			var trail: PackedVector2Array = PackedVector2Array()
			for i in range(12):
				var t: float = float(i) / 11.0
				trail.append(a.lerp(b, t) + side * sin(t * PI * 3.0 + game.time_alive * 6.0) * 8.0)
			game.draw_polyline(trail, Color(0.06, 0.12, 0.02, 0.72 * fade), 28.0, true)
			game.draw_polyline(trail, Color(0.48, 0.95, 0.18, 0.5 * fade), 8.0, true)
			var head: Vector2 = a.lerp(b, progress) + side * sin(progress * PI * 3.0 + game.time_alive * 6.0) * 8.0
			game.draw_circle(head, 14.0, Color(0.58, 1.0, 0.22, 0.65 * fade))
			game.draw_circle(a, 26.0, Color(0.1, 0.05, 0.02, 0.38 * fade))
			game.draw_circle(b, 30.0, Color(0.18, 0.1, 0.04, 0.42 * fade))
		elif kind == "gravitante":
			var a: Vector2 = Vector2(effect.get("a", effect.get("center", game.player_pos))) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			for endpoint in [a, b]:
				game.draw_circle(endpoint, 42.0 + 24.0 * progress, Color(0.02, 0.04, 0.12, 0.55 * fade))
				game.draw_arc(endpoint, 44.0 + 18.0 * progress, game.time_alive * 3.4, TAU * 0.88 + game.time_alive * 3.4, 64, Color(0.52, 0.78, 1.0, 0.78 * fade), 4.0)
				game.draw_arc(endpoint, 25.0 + 12.0 * progress, -game.time_alive * 5.0, TAU - game.time_alive * 5.0, 48, Color(0.9, 0.96, 1.0, 0.48 * fade), 2.0)
			game.draw_line(a, b, Color(0.34, 0.68, 1.0, 0.18 * fade), 16.0, true)
		elif kind == "cartografica_pin":
			var pos: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
			var pin_tip: Vector2 = pos
			var pin_head: Vector2 = pos + Vector2(0.0, -42.0 - 12.0 * sin(progress * PI))
			game.draw_line(pin_head, pin_tip, Color(0.75, 1.0, 0.92, 0.95 * fade), 3.0, true)
			game.draw_circle(pin_head, 12.0, Color(0.04, 0.16, 0.14, 0.9 * fade))
			game.draw_arc(pin_tip, 28.0 + 8.0 * sin(game.time_alive * 8.0), 0.0, TAU, 42, Color(0.38, 1.0, 0.82, 0.7 * fade), 2.0)
		elif kind == "cartografica":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			game.draw_line(a, b, Color(0.08, 0.5, 0.38, 0.28 * fade), 18.0, true)
			for i in range(7):
				var t: float = fposmod(progress + float(i) * 0.16, 1.0)
				var dot: Vector2 = a.lerp(b, t)
				game.draw_circle(dot, 5.0 + float(i % 2) * 2.0, Color(0.42, 1.0, 0.84, 0.68 * fade))
			game.draw_arc(b, 38.0, game.time_alive * 4.0, TAU + game.time_alive * 4.0, 48, Color(0.38, 1.0, 0.82, 0.72 * fade), 2.5)
		elif kind == "mnesica":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			for i in range(18):
				var angle: float = float(i) * TAU / 18.0 + sin(game.time_alive * 3.0 + i) * 0.2
				var length: float = 18.0 + 96.0 * progress + float(i % 4) * 6.0
				var shard: Vector2 = a + Vector2.from_angle(angle) * length
				game.draw_line(a + Vector2.from_angle(angle) * 8.0, shard, Color(0.86, 0.58, 1.0, 0.48 * fade), 3.0, true)
			game.draw_circle(a, 34.0 + 48.0 * progress, Color(0.64, 0.34, 1.0, 0.16 * fade))
			game.draw_circle(b, 28.0, Color(0.92, 0.72, 1.0, 0.22 * fade))
		elif kind == "contratual":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			for i in range(16):
				var t: float = clampf(progress + sin(float(i) * 2.13) * 0.08, 0.0, 1.0)
				var side: Vector2 = (b - a).normalized().orthogonal()
				var scrap: Vector2 = a.lerp(b, t) + side * sin(game.time_alive * 8.0 + i) * (18.0 + float(i % 3) * 8.0)
				var paper: Rect2 = Rect2(scrap - Vector2(5.0, 7.0), Vector2(10.0, 14.0))
				game.draw_rect(paper, Color(0.96, 0.86, 0.62, 0.78 * fade), true)
				game.draw_rect(paper, Color(1.0, 0.58, 0.24, 0.72 * fade), false, 1)
			game.draw_line(a, b, Color(1.0, 0.58, 0.24, 0.16 * fade), 12.0, true)
		elif kind == "necronada":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			var dir: Vector2 = (b - a).normalized()
			if dir.length() <= 0.01:
				dir = Vector2.RIGHT
			var side: Vector2 = dir.orthogonal()
			var cloud: Vector2 = a.lerp(b, progress)
			game.draw_line(a, b, Color(0.12, 0.02, 0.18, 0.45 * fade), 24.0, true)
			for i in range(22):
				var t: float = clampf(progress - 0.26 + float(i) / 22.0 * 0.52, 0.0, 1.0)
				var p: Vector2 = a.lerp(b, t) + side * sin(game.time_alive * 7.0 + i * 1.7) * (12.0 + float(i % 5) * 3.0)
				var c: Color = Color(0.54, 0.2, 0.88, 0.5 * fade) if i % 4 != 0 else Color(0.02, 0.0, 0.04, 0.65 * fade)
				game.draw_circle(p, 3.0 + float(i % 4), c)
			game.draw_circle(cloud, 30.0, Color(0.38, 0.12, 0.62, 0.24 * fade))
		elif kind == "ancorada":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			var dir: Vector2 = (b - a).normalized()
			if dir.length() <= 0.01:
				dir = Vector2.RIGHT
			var side: Vector2 = dir.orthogonal()
			var arc_pos: Vector2 = a.lerp(b, progress) - Vector2(0.0, sin(progress * PI) * 88.0)
			var anchor_angle: float = game.time_alive * 12.0 + progress * TAU * 2.0
			game.draw_polyline(PackedVector2Array([a, a.lerp(b, 0.5) - Vector2(0, 76), b]), Color(0.32, 1.0, 0.42, 0.18 * fade), 7.0, true)
			var arm: Vector2 = Vector2.from_angle(anchor_angle) * 18.0
			game.draw_line(arc_pos - arm, arc_pos + arm, Color(0.82, 1.0, 0.86, 0.92 * fade), 4.0, true)
			game.draw_line(arc_pos, arc_pos + dir * 24.0, Color(0.34, 1.0, 0.42, 0.9 * fade), 5.0, true)
			game.draw_arc(arc_pos + dir * 18.0, 16.0, anchor_angle, anchor_angle + PI, 20, Color(0.34, 1.0, 0.42, 0.9 * fade), 3.0)
			game.draw_line(b, a.lerp(b, maxf(0.0, progress - 0.12)), Color(0.62, 1.0, 0.68, 0.32 * fade), 4.0, true)
		elif kind == "acorrentada":
			if effect.has("physics"):
				game._draw_physical_chain(effect["physics"], camera, Color(0.18, 0.86, 1.0, 0.88 * fade), max(8.0, float(effect.get("width", 34.0)) * 0.2), fade, true)
			else:
				game._draw_acorrentada_chain(Vector2(effect.get("a", game.player_pos)) - camera, Vector2(effect.get("b", game.player_pos)) - camera, Color(0.18, 0.86, 1.0, 0.88 * fade), max(8.0, float(effect.get("width", 34.0)) * 0.2), fade, true)
		elif kind == "eclipsada_lua_tp" or kind == "eclipsada_sol_tp":
			var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
			var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
			var color: Color = effect.get("color", game._eclipsada_color())
			var dir = (b - a).normalized()
			if dir.length() <= 0.01:
				dir = Vector2.RIGHT
			var side = dir.orthogonal()
			if kind == "eclipsada_lua_tp":
				var path = PackedVector2Array([a, a.lerp(b, 0.5) + side * sin(progress * PI) * 24.0, b])
				game.draw_polyline(path, Color(0.0, 0.02, 0.11, 0.8 * fade), 28.0, true)
				game.draw_polyline(path, Color(color.r, color.g, color.b, 0.82 * fade), 5.0, true)
				game.draw_arc(b, 32.0 + progress * 18.0, game.time_alive * 5.0, game.time_alive * 5.0 + PI * 1.4, 42, Color(0.48, 0.84, 1.0, 0.72 * fade), 2.5)
			else:
				game.draw_line(a, b, Color(0.15, 0.05, 0.0, 0.56 * fade), 22.0, true)
				game.draw_line(a, b, Color(color.r, color.g, color.b, 0.82 * fade), 4.5, true)
				game.draw_circle(b, 30.0 + progress * 32.0, Color(color.r, color.g, color.b, 0.13 * fade))
				game.draw_arc(b, 48.0 + progress * 22.0, - game.time_alive * 4.0, TAU - game.time_alive * 4.0, 58, Color(1.0, 0.9, 0.44, 0.75 * fade), 3.0)


static func _draw_secondary_acorrentada(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var center_world = Vector2(secondary.get("center", game.player_pos))
	var center = center_world - camera
	var maximum = maxf(0.01, float(secondary.get("max", 0.65)))
	var life = maxf(0.0, float(secondary.get("life", maximum)))
	var progress = clampf(1.0 - life / maximum, 0.0, 1.0)
	var fade = clampf(minf(progress * 3.5, life * 5.0), 0.0, 1.0)
	var radius = float(secondary.get("radius", game.ACORRENTADA_E_RADIUS))
	var overcharged = bool(secondary.get("overcharged", false))
	var pulse = 0.5 + 0.5 * sin(game.time_alive * 10.0)
	game.draw_circle(center, radius, Color(0.3, 0.02, 0.025, 0.055 * fade))
	game.draw_arc(center, radius, - game.time_alive * 1.9, TAU - game.time_alive * 1.9, 96, Color(0.92, 0.12, 0.1, 0.7 * fade), 4.0)
	game.draw_arc(center, radius * 0.7, game.time_alive * 1.3, TAU + game.time_alive * 1.3, 80, Color(0.18, 0.86, 1.0, 0.54 * fade), 2.5)
	if overcharged:
		game.draw_arc(center, radius + 18.0 + pulse * 8.0, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, 0.44 * fade), 2.0)
	for i in range(10):
		var angle: float = game.time_alive * 0.75 + float(i) * TAU / 10.0
		var inner = center + Vector2.from_angle(angle) * (radius * 0.25 + pulse * 8.0)
		var outer = center + Vector2.from_angle(angle + sin(game.time_alive * 2.0 + i) * 0.08) * (radius * (0.7 + 0.08 * float(i % 3)))
		game.draw_line(inner, outer, Color(0.9, 0.1, 0.09, 0.16 * fade), 3.0, true)
	var target_positions = []
	for raw_pos in secondary.get("target_positions", []):
		target_positions.append(Vector2(raw_pos))
	if target_positions.is_empty():
		for target in secondary.get("targets", []):
			if typeof(target) != TYPE_DICTIONARY:
				continue
			var target_dict: Dictionary = target
			if game._acorrentada_target_alive(target_dict):
				target_positions.append(game._acorrentada_target_pos(target_dict))
	var chains: Array = secondary.get("chains", [])
	for i in range(mini(target_positions.size(), 8)):
		var target_pos = Vector2(target_positions[i]) - camera
		var width = 7.0 + float(i % 2) * 2.0
		var color = Color(0.18, 0.86, 1.0, 0.62 * fade) if i % 2 == 0 else Color(0.92, 0.12, 0.1, 0.62 * fade)
		if i < chains.size():
			game._draw_physical_chain(chains[i], camera, color, width, fade, i % 2 == 0)
		else:
			game._draw_acorrentada_chain(center, target_pos, color, width, fade, i % 2 == 0)
		game.draw_circle(target_pos, 18.0 + pulse * 4.0, Color(color.r, color.g, color.b, 0.12 * fade))


static func _draw_secondary_lacerante(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var center_world: Vector2 = secondary.get("center", game.player_pos)
	var center = center_world - camera
	var pulse = 132.0 + 30.0 * pow(sin(game.time_alive * 5.0), 2.0)
	game.draw_circle(center, pulse, Color(0.12, 0.0, 0.03, 0.12))
	game.draw_arc(center, pulse, 0, TAU, 56, Color(0.55, 0.0, 0.1, 0.75), 2.0)
	game.draw_arc(center, max(42.0, pulse * 0.58), 0, TAU, 42, Color(1.0, 0.18, 0.24, 0.82), 1.5)
	for cut in secondary.get("cuts", []):
		var fade = clamp(float(cut.get("life", 0.0)) / max(0.01, float(cut.get("max", 0.36))), 0.0, 1.0)
		var world_a: Vector2 = cut["a"]
		var world_b: Vector2 = cut["b"]
		var a = world_a - camera
		var b = world_b - camera
		var width = max(1.0, 10.0 * fade)
		game.draw_line(a, b, Color(0.37, 0.0, 0.05, 0.82), width + 5.0)
		game.draw_line(a, b, Color(1.0, 0.16, 0.22, 0.94), width)
		game.draw_line(a, b, Color(1.0, 0.9, 0.88, 0.92), max(1.0, width * 0.26))


static func _draw_secondary_prismatica(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var center_world: Vector2 = secondary.get("center", game.player_pos)
	var center = center_world - camera
	var ring = 42.0 + sin(game.time_alive * 4.2) * 6.0
	game.draw_arc(center, ring, 0.0, TAU, 32, Color(0.42, 1.0, 0.96, 0.68), 2.2)
	game.draw_arc(center, ring + 12.0, game.time_alive * 1.4, game.time_alive * 1.4 + PI * 1.3, 26, Color(1.0, 0.54, 0.78, 0.82), 1.8)
	var angle = float(secondary.get("angle", 0.0))
	var beam_dirs = game._secondary_prismatica_beam_dirs(angle)
	for beam_index in range(beam_dirs.size()):
		var dir: Vector2 = beam_dirs[beam_index]
		var hue = fposmod(game.time_alive * 0.65 + float(beam_index) * 0.19, 1.0)
		var disco = Color.from_hsv(hue, 0.82, 1.0, 0.22)
		var disco_alt = Color.from_hsv(fposmod(hue + 0.34, 1.0), 0.76, 1.0, 0.16)
		var beam_start = center_world - dir * game.SECONDARY_PRISMATICA_BEAM_RANGE - camera
		var beam_end = center_world + dir * game.SECONDARY_PRISMATICA_BEAM_RANGE - camera
		game.draw_line(beam_start, beam_end, disco, game.SECONDARY_PRISMATICA_BEAM_WIDTH * 0.78)
		game.draw_line(beam_start, beam_end, disco_alt, game.SECONDARY_PRISMATICA_BEAM_WIDTH * 0.36)
		game.draw_line(beam_start, beam_end, Color(1.0, 1.0, 1.0, 0.28), 1.4)
		game.draw_line(beam_start, beam_end, Color.from_hsv(hue, 0.55, 1.0, 0.24), 0.8)
		var side = dir.orthogonal().normalized()
		for tip_dir in [-1.0, 1.0]:
			var tip = center + dir * game.SECONDARY_PRISMATICA_BEAM_RANGE * tip_dir
			var diamond_dir = dir * tip_dir
			var diamond = PackedVector2Array([
				tip + diamond_dir * 10.0, 
				tip + side * 6.0, 
				tip - diamond_dir * 10.0, 
				tip - side * 6.0
			])
			game.draw_polygon(diamond, PackedColorArray([Color(disco_alt.r, disco_alt.g, disco_alt.b, 0.18)]))
			game.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(1.0, 1.0, 1.0, 0.34), 1.0, true)
	for i in range(3):
		var phase_offset = float(i + 1) * 0.08
		var ghost_alpha = 0.1 - i * 0.025
		for ghost_index in range(beam_dirs.size()):
			var dir: Vector2 = game._secondary_prismatica_beam_dirs(angle - phase_offset)[ghost_index]
			var ghost_color = Color.from_hsv(fposmod(game.time_alive * 0.65 + float(ghost_index) * 0.19 - phase_offset, 1.0), 0.82, 1.0, ghost_alpha)
			var ga = center_world - dir * game.SECONDARY_PRISMATICA_BEAM_RANGE - camera
			var gb = center_world + dir * game.SECONDARY_PRISMATICA_BEAM_RANGE - camera
			game.draw_line(ga, gb, ghost_color, max(1.0, game.SECONDARY_PRISMATICA_BEAM_WIDTH * (0.16 - i * 0.035)))
	for beam in secondary.get("beams", []):
		var fade = clamp(float(beam.get("life", 0.0)) / max(0.01, float(beam.get("max", 0.28))), 0.0, 1.0)
		var beam_color: Color = beam.get("color", Color(0.32, 1.0, 0.96))
		for segment in beam.get("segments", []):
			var a = Vector2(segment["a"]) - camera
			var b = Vector2(segment["b"]) - camera
			game.draw_line(a, b, Color(beam_color.r, beam_color.g, beam_color.b, 0.18 + fade * 0.22), 6.0)
			game.draw_line(a, b, Color(beam_color.r, beam_color.g, beam_color.b, 0.85), 3.0)
			game.draw_line(a, b, Color(1.0, 1.0, 1.0, 0.92), 1.0)
	for zap in secondary.get("zaps", []):
		game._draw_secondary_prismatica_zap(zap, camera)


static func _draw_prismatica_ultimate_dance(game: Node2D, secondary: Dictionary, center: Vector2) -> void :
	var tex = game._prismatica_ultimate_frame_texture(secondary)
	if tex == null:
		return
	var max_life = maxf(0.01, float(secondary.get("max", game.SECONDARY_PRISMATICA_DURATION)))
	var life = float(secondary.get("life", max_life))
	var start_ratio = clampf((max_life - life) / 0.45, 0.0, 1.0)
	var end_ratio = clampf(life / 0.35, 0.0, 1.0)
	var alpha = minf(start_ratio, end_ratio)
	var pulse = 1.0 + sin(game.time_alive * TAU * 2.0) * 0.025
	game._draw_entity_fit(tex, center, Vector2(60, 86) * pulse, Color(1.0, 1.0, 1.0, alpha), true)


static func _draw_secondary_prismatica_zap(game: Node2D, zap: Dictionary, camera: Vector2) -> void :
	var life = float(zap.get("life", 0.0))
	var max_life = maxf(0.01, float(zap.get("max", game.SECONDARY_PRISMATICA_ZAP_LIFE)))
	var alpha = clampf(life / max_life, 0.0, 1.0)
	if alpha <= 0.0:
		return
	var start = Vector2(zap.get("start", game.player_pos)) - camera
	var target = Vector2(zap.get("target", game.player_pos)) - camera
	var hue = float(zap.get("hue", 0.0))
	var color = Color.from_hsv(hue, 0.72, 1.0, alpha)
	game._draw_prismatica_colored_bolt(start, target, int(zap.get("seed", 0)), color, alpha, 3.6)


static func _draw_prismatica_colored_bolt(game: Node2D, start: Vector2, finish: Vector2, seed: int, color: Color, alpha: float, width: float) -> void :
	var delta = finish - start
	var length = delta.length()
	if length <= 4.0:
		return
	var dir = delta / length
	var normal = dir.orthogonal()
	var points = PackedVector2Array()
	var segments = 7
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var taper = sin(t * PI)
		var jitter = sin(float(seed) * 0.37 + float(i) * 2.83 + game.time_alive * 38.0) * 14.0 * taper
		var small = cos(float(seed) * 1.11 + float(i) * 4.41 + game.time_alive * 23.0) * 5.0 * taper
		points.append(start + delta * t + normal * jitter + dir.rotated(PI * 0.5) * small)
	game.draw_polyline(points, Color(color.r, color.g, color.b, 0.26 * alpha), width + 6.0, true)
	game.draw_polyline(points, Color(color.r, color.g, color.b, 0.78 * alpha), width, true)
	game.draw_polyline(points, Color(1.0, 1.0, 1.0, 0.92 * alpha), maxf(1.0, width * 0.33), true)
	for branch in range(2):
		var branch_t = 0.34 + float(branch) * 0.24 + 0.05 * sin(game.time_alive * 9.0 + float(seed + branch))
		var base = start + delta * branch_t
		var branch_dir = dir.rotated((0.52 if branch == 0 else -0.52) + sin(game.time_alive * 8.0 + float(seed)) * 0.18)
		game.draw_line(base, base + branch_dir * 24.0, Color(color.r, color.g, color.b, 0.42 * alpha), maxf(1.0, width * 0.38), true)


static func _draw_secondary_retornante(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var center_world = Vector2(secondary.get("center", game.player_pos))
	var center = center_world - camera
	game.draw_arc(center, 34.0 + sin(game.time_alive * 5.4) * 4.0, 0.0, TAU, 28, Color(0.72, 0.48, 1.0, 0.58), 2.0)
	for bullet in game.return_bullets:
		if float(bullet.get("paradox_until", 0.0)) < game.time_alive:
			continue
		var pos = Vector2(bullet["pos"]) - camera
		var phase = float(bullet.get("phase", 0.0))
		game.draw_line(center, pos, Color(0.8, 0.6, 1.0, 0.42), 3.0)
		game.draw_line(center, pos, Color(1.0, 1.0, 1.0, 0.78), 1.0)
		game.draw_arc(pos, 18.0 + sin(phase * 2.0) * 4.0, phase, phase + PI * 1.45, 22, Color(1.0, 0.5, 0.84, 0.86), 2.0)
	for ghost in secondary.get("ghosts", []):
		var ang = float(ghost.get("base_angle", 0.0)) + float(secondary.get("ghost_tick", 0.0)) * 0.9
		var endpoint = center_world + Vector2(cos(ang) * float(ghost.get("radius_x", 260.0)), sin(ang + float(ghost.get("phase", 0.0)) * 0.18) * float(ghost.get("radius_y", 210.0)))
		var draw_end = endpoint - camera
		game.draw_line(center, draw_end, Color(0.66, 0.42, 1.0, 0.28), 2.5)
		game.draw_circle(draw_end, 8.0, Color(0.94, 0.76, 1.0, 0.82))
		game.draw_circle(draw_end, 14.0, Color(0.52, 0.3, 0.92, 0.22))


static func _draw_secondary_parasitica(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	for target in secondary.get("targets", []):
		if bool(target.get("done", false)):
			continue
		var target_world = game._parasite_ultimate_target_pos(target)
		if target_world == Vector2.ZERO:
			continue
		var age = float(target.get("age", 0.0))
		if not bool(target.get("arrived", false)):
			for worm in target.get("worms", []):
				var travel = clamp((age - float(worm.get("delay", 0.0))) / max(0.01, float(worm.get("duration", 1.2))), 0.0, 1.0)
				if age < float(worm.get("delay", 0.0)):
					continue
				game._draw_parasite_burrow(worm, target_world + Vector2(0, 26), travel, camera)
			var warning = clamp(age / max(0.01, float(target.get("arrival", 1.95))), 0.0, 1.0)
			game._draw_parasite_emergence(target_world + Vector2(0, 26) - camera, warning, int(target.get("seed", 0)))
		else:
			game._draw_parasite_feast_ground(target, target_world, camera)


static func _draw_parasite_burrow(game: Node2D, worm: Dictionary, finish: Vector2, t: float, camera: Vector2) -> void :
	var start = Vector2(worm.get("start", finish))
	var bend = float(worm.get("bend", 0.0))
	var phase = float(worm.get("phase", 0.0))
	var scale = float(worm.get("scale", 1.0))
	var trail = PackedVector2Array()
	var trail_start = max(0.0, t - 0.11)
	for sample in range(9):
		var sample_t = lerp(trail_start, t, float(sample) / 8.0)
		trail.append(game._parasite_curve_point(start, finish, sample_t, bend) - camera)
	if trail.size() >= 2:
		game.draw_polyline(trail, Color(0.07, 0.055, 0.025, 0.52), 8.0 * scale, true)
		game.draw_polyline(trail, Color(0.34, 0.28, 0.1, 0.6), 3.5 * scale, true)
		game.draw_polyline(trail, Color(0.64, 0.74, 0.18, 0.18), 1.0 * scale, true)
		for groove_index in range(1, trail.size(), 2):
			var groove = trail[groove_index]
			var groove_side = Vector2.from_angle(phase + groove_index * 1.7) * 6.0 * scale
			game.draw_line(groove - groove_side, groove + groove_side, Color(0.22, 0.15, 0.05, 0.48), 1.5)
	for break_index in range(1, 9):
		var break_t = float(break_index) / 9.0
		if break_t > t:
			continue
		var break_world = game._parasite_curve_point(start, finish, break_t, bend)
		var before = game._parasite_curve_point(start, finish, max(0.0, break_t - 0.015), bend)
		var after = game._parasite_curve_point(start, finish, min(1.0, break_t + 0.015), bend)
		var break_heading = (after - before).angle()
		var break_fade = clamp(1.0 - (t - break_t) * 1.15, 0.18, 1.0)
		game._draw_parasite_ground_break(break_world - camera, break_heading, scale, phase + break_index * 1.73, break_fade)
	var mound = game._parasite_curve_point(start, finish, t, bend) - camera
	var next_t = min(1.0, t + 0.02)
	var heading = (game._parasite_curve_point(start, finish, next_t, bend) - game._parasite_curve_point(start, finish, max(0.0, t - 0.02), bend)).normalized()
	game.draw_set_transform(mound, heading.angle(), Vector2(1.0, 0.42))
	game.draw_circle(Vector2.ZERO, 15.0 * scale, Color(0.08, 0.055, 0.025, 0.72))
	game.draw_circle(Vector2.ZERO, 10.5 * scale, Color(0.42, 0.31, 0.1, 0.72))
	game.draw_arc(Vector2.ZERO, 18.0 * scale, 0.0, TAU, 28, Color(0.72, 0.82, 0.22, 0.3), 1.6)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for dirt_index in range(5):
		var dirt_angle = phase + dirt_index * 2.3 + t * 10.0
		var dirt_pos = mound + Vector2.from_angle(dirt_angle) * (10.0 + dirt_index * 2.1) * scale
		game.draw_circle(dirt_pos, (2.6 - dirt_index * 0.24) * scale, Color(0.38, 0.27, 0.08, 0.72))
	if t > 0.76:
		var emerge = smoothstep(0.76, 1.0, t)
		var worm_pos = finish - camera + Vector2(0, 12.0 - emerge * 26.0)
		game._draw_parasite_worm(worm_pos, - PI * 0.5 + sin(phase + t * 8.0) * 0.18, scale, phase + t * 12.0, emerge)


static func _draw_parasite_ground_break(game: Node2D, center: Vector2, heading: float, scale: float, seed: float, fade: float) -> void :
	var forward = Vector2.from_angle(heading)
	var side = forward.orthogonal()
	game.draw_set_transform(center, heading, Vector2(1.0, 0.42))
	game.draw_circle(Vector2.ZERO, 13.0 * scale, Color(0.045, 0.032, 0.014, 0.46 * fade))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for branch_index in range(5):
		var branch_angle = heading + (branch_index - 2) * 0.48 + sin(seed + branch_index * 2.2) * 0.16
		var inner = center + forward * sin(seed + branch_index) * 3.0 * scale
		var joint = inner + Vector2.from_angle(branch_angle) * (7.0 + branch_index % 2 * 3.0) * scale
		var outer = joint + Vector2.from_angle(branch_angle + sin(seed * 1.7 + branch_index) * 0.34) * (6.0 + branch_index % 3 * 2.0) * scale
		game.draw_line(inner, joint, Color(0.035, 0.025, 0.01, 0.86 * fade), 2.4 * scale)
		game.draw_line(joint, outer, Color(0.12, 0.075, 0.018, 0.72 * fade), 1.5 * scale)
	var chunk_center = center + side * sin(seed * 2.4) * 8.0 * scale - Vector2(0, 3.0 * scale)
	var chunk = PackedVector2Array([
		chunk_center + Vector2(-5.0, 3.0) * scale, 
		chunk_center + Vector2(-1.0, -5.0) * scale, 
		chunk_center + Vector2(6.0, 1.0) * scale
	])
	game.draw_polygon(chunk, PackedColorArray([Color(0.34, 0.24, 0.075, 0.72 * fade)]))
	game.draw_polyline(PackedVector2Array([chunk[0], chunk[1], chunk[2], chunk[0]]), Color(0.09, 0.055, 0.016, 0.82 * fade), 1.2, true)


static func _draw_parasite_emergence(game: Node2D, foot: Vector2, progress: float, seed: int) -> void :
	if progress < 0.58:
		return
	var reveal = smoothstep(0.58, 1.0, progress)
	game.draw_set_transform(foot, 0.0, Vector2(1.0, 0.38))
	game.draw_circle(Vector2.ZERO, 34.0 * reveal, Color(0.1, 0.07, 0.025, 0.34 * reveal))
	game.draw_arc(Vector2.ZERO, 37.0 * reveal, 0.0, TAU, 36, Color(0.58, 0.72, 0.16, 0.52 * reveal), 2.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for crack_index in range(7):
		var angle = seed * 0.001 + crack_index * TAU / 7.0
		var inner = foot + Vector2.from_angle(angle) * 8.0 * reveal
		var outer = foot + Vector2.from_angle(angle + sin(seed + crack_index) * 0.08) * (24.0 + (crack_index % 3) * 7.0) * reveal
		game.draw_line(inner, outer, Color(0.16, 0.1, 0.03, 0.78 * reveal), 2.2)


static func _draw_parasite_feast_foreground(game: Node2D, target: Dictionary, target_world: Vector2, camera: Vector2) -> void :
	var center = target_world - camera
	var scale = 1.45 if bool(target.get("boss", false)) else 1.0
	var seed = int(target.get("seed", 0))
	for worm_index in range(4):
		var angle = game.time_alive * (0.84 + worm_index * 0.05) + worm_index * TAU / 4.0 + seed * 0.002
		var orbit = (31.0 + worm_index * 5.0 + sin(game.time_alive * 3.0 + worm_index) * 4.0) * scale
		var worm_pos = center + Vector2.from_angle(angle) * orbit + Vector2(0, 5.0 * sin(angle * 2.0))
		var facing = (center - worm_pos).angle()
		game._draw_parasite_worm(worm_pos, facing, (0.78 + worm_index * 0.07) * scale, game.time_alive * 7.0 + worm_index, 1.0)
	for drip_index in range(5):
		var cycle = fposmod(game.time_alive * (0.72 + drip_index * 0.035) + drip_index * 0.19 + seed * 0.0003, 1.0)
		var drip = center + Vector2(sin(seed * 0.03 + drip_index * 1.8) * 30.0 * scale, 14.0 * scale + cycle * 54.0 * scale)
		game._draw_parasite_larva_drop(drip, (0.58 + drip_index * 0.045) * scale, sin(cycle * PI))
	var feed_left = float(target.get("feed_left", 0.0))
	game._draw_centered("DEVORANDO %.1fs" % feed_left, center + Vector2(0, -68.0 * scale), 13, Color(0.74, 1.0, 0.38, 0.88))


static func _draw_parasite_foreground(game: Node2D, camera: Vector2) -> void :
	for secondary in game.manifestation_secondaries:
		if String(secondary.get("kind", "")) != "parasitica":
			continue
		for target in secondary.get("targets", []):
			if bool(target.get("done", false)) or not bool(target.get("arrived", false)):
				continue
			var target_world = game._parasite_ultimate_target_pos(target)
			if target_world != Vector2.ZERO:
				game._draw_parasite_feast_foreground(target, target_world, camera)


static func _draw_secondary_gravitante(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var center_world: Vector2 = secondary.get("center", game.player_pos)
	var center = center_world - camera
	var progress = 1.0 - float(secondary.get("life", 0.0)) / max(0.01, float(secondary.get("max", game.SECONDARY_GRAVITANTE_DURATION)))
	var radius = game._gravitante_radius(progress)
	var captured = int(secondary.get("captured", 0))
	var orbital_bonus = int(secondary.get("orbital_bonus", 0))
	var capture_power = float(secondary.get("capture_power", 0.0))
	var spin_speed = float(secondary.get("spin_speed", 250.0))
	var intensity = clamp(float(captured + orbital_bonus) / 10.0 + capture_power * 0.34 + progress * 0.25, 0.25, 2.3)
	var t = game.time_alive
	var spin = t * (0.72 + spin_speed * 0.006)

	game._draw_gravitante_map_distortion(center_world, camera, radius, progress, intensity, spin)
	game.draw_circle(center, radius * 1.04, Color(0.02, 0.03, 0.08, 0.08 + 0.05 * intensity))
	for lens_index in range(11):
		var ring = radius * (0.18 + lens_index * 0.075) + sin(t * 2.0 + lens_index) * (5.0 + intensity * 3.0)
		var rot = spin * (0.18 + lens_index * 0.012) + lens_index * 0.27
		var stretch = Vector2(1.0 + sin(lens_index * 1.7) * 0.1, 0.58 + cos(t + lens_index) * 0.07)
		var alpha = clamp(0.2 - lens_index * 0.01 + intensity * 0.03, 0.04, 0.3)
		game.draw_set_transform(center, rot, stretch)
		game.draw_arc(Vector2.ZERO, ring, - PI * 0.78, PI * 1.22, 64, Color(0.54, 0.74, 1.0, alpha), 1.1 + intensity * 0.22)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for lane in range(18):
		var ang = spin * (1.0 + lane % 3 * 0.08) + lane * TAU / 18.0
		var edge = center + Vector2.from_angle(ang) * radius * (0.76 + 0.12 * sin(t * 3.0 + lane))
		var inner = center + Vector2.from_angle(ang + 0.36 + intensity * 0.08) * radius * (0.18 + 0.04 * (lane % 4))
		var lane_alpha = 0.07 + intensity * 0.028
		game.draw_line(edge, inner, Color(0.44, 0.7, 1.0, lane_alpha), 1.2)
		if lane % 3 == 0:
			game.draw_circle(edge, 2.2 + intensity, Color(0.76, 0.9, 1.0, 0.28))

	game.draw_arc(center, radius, spin * 0.55, spin * 0.55 + TAU, 96, Color(0.56, 0.82, 1.0, 0.62 + min(0.24, intensity * 0.1)), 2.2 + intensity * 0.45)
	game.draw_arc(center, radius * 0.72, - spin * 0.95, - spin * 0.95 + PI * 1.65, 86, Color(0.96, 0.36, 1.0, 0.26 + intensity * 0.05), 3.0)

	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var dist = Vector2(enemy["pos"]).distance_to(center_world)
		if dist <= radius:
			var draw_pos = enemy["pos"] - camera
			var edge_ratio = game._gravitante_edge_ratio(dist, radius)
			var beam_alpha = 0.1 + edge_ratio * 0.16 + min(0.12, intensity * 0.04)
			game.draw_line(draw_pos, center, Color(0.58, 0.82, 1.0, beam_alpha), 1.2 + edge_ratio * 1.8)
			game._draw_gravitante_enemy_distortion(enemy, center_world, camera, radius, progress, intensity)

	var core_r = 40.0 + progress * 42.0 + intensity * 5.0
	for glow_index in range(5):
		game.draw_circle(center, core_r + 56.0 - glow_index * 10.0, Color(0.26, 0.08, 0.46, 0.035 + glow_index * 0.012))
	game.draw_circle(center, core_r * 1.18, Color(0.01, 0.0, 0.03, 0.82))
	game.draw_circle(center, core_r * 0.74, Color(0.0, 0.0, 0.0, 0.96))
	game.draw_arc(center, core_r * 1.28, spin * 1.55, spin * 1.55 + PI * 1.72, 76, Color(0.82, 0.94, 1.0, 0.9), 3.0 + intensity * 0.55)
	game.draw_arc(center, core_r * 1.56, - spin * 1.18, - spin * 1.18 + PI * 1.38, 72, Color(0.54, 0.22, 1.0, 0.54), 5.0)
	game.draw_arc(center, core_r * 0.96, spin * 2.25, spin * 2.25 + TAU * 0.72, 52, Color(0.18, 0.88, 1.0, 0.64), 2.0)


static func _draw_gravitante_map_distortion(game: Node2D, center_world: Vector2, camera: Vector2, radius: float, progress: float, intensity: float, spin: float) -> void :
	var map_texture = game._current_map_texture()
	if map_texture == null:
		return
	var center = center_world - camera
	var map_rect = game._desktop_stage_draw_rect(camera)
	var tex_size = map_texture.get_size()
	var t = game.time_alive
	var event_radius = 64.0 + progress * 44.0 + intensity * 7.0

	game._draw_gravitante_map_mask(map_texture, map_rect, tex_size, center, radius, event_radius, progress, intensity, spin)

	for ring_index in range(5):
		var ring_ratio = 0.24 + float(ring_index) * 0.145
		var sample_radius = radius * ring_ratio
		var pieces = 12 + ring_index * 5
		for piece_index in range(pieces):
			if piece_index % 2 == 1 and ring_index >= 3:
				continue
			var seed = float(piece_index * 37 + ring_index * 113)
			var angle = spin * (0.22 + ring_index * 0.065) + piece_index * TAU / float(pieces) + sin(t * 1.7 + seed) * 0.035
			var radial = Vector2.from_angle(angle)
			var tangent = radial.orthogonal()
			var source_center = center + radial * sample_radius + tangent * sin(t * 2.4 + seed) * (8.0 + intensity * 5.0)
			if not map_rect.has_point(source_center):
				continue
			var source_size = 34.0 - ring_index * 2.4 + intensity * 4.0
			var source_rect = Rect2(source_center - Vector2(source_size, source_size) * 0.5, Vector2(source_size, source_size))
			var src = game._map_screen_rect_to_source(map_rect, tex_size, source_rect)
			if src.size.x <= 1.0 or src.size.y <= 1.0:
				continue
			var pull = 0.18 + progress * 0.16 + intensity * 0.045 + float(4 - ring_index) * 0.018
			var sink = source_center.lerp(center, pull)
			sink += tangent * (22.0 + ring_index * 4.0) * sin(spin * 0.8 + seed)
			var stretch = 1.1 + ring_ratio * 1.45 + intensity * 0.14
			var crush = 0.4 + ring_index * 0.035
			var dest_size = Vector2(source_size * stretch, source_size * crush)
			var alpha = clamp(0.28 + intensity * 0.08 - ring_index * 0.025, 0.18, 0.58)
			game.draw_set_transform(sink, angle + PI * 0.5 + sin(t + seed) * 0.22, Vector2.ONE)
			game.draw_texture_rect_region(map_texture, Rect2( - dest_size * 0.5, dest_size), src, Color(1.0, 1.0, 1.0, alpha))
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for shard_index in range(34):
		var shard_seed = float(shard_index) * 19.73
		var cycle = fposmod(t * (0.1 + intensity * 0.025) + shard_seed * 0.017, 1.0)
		var start_radius = radius * (0.96 - float(shard_index % 5) * 0.055)
		var end_radius = event_radius * (1.02 + float(shard_index % 3) * 0.16)
		var shard_radius = lerp(start_radius, end_radius, pow(cycle, 0.72))
		var angle = spin * (0.52 + float(shard_index % 4) * 0.055) + shard_seed + cycle * TAU * (0.18 + intensity * 0.04)
		var dir = Vector2.from_angle(angle)
		var tangent = dir.orthogonal()
		var pos = center + dir * shard_radius + tangent * sin(t * 3.1 + shard_seed) * 14.0
		var shard_alpha = sin(cycle * PI) * clamp(0.26 + intensity * 0.1, 0.22, 0.52)
		var shard_len = lerp(26.0, 8.0, cycle) + intensity * 3.0
		var shard_w = 5.0 + float(shard_index % 4) * 1.4
		var shard = PackedVector2Array([
			pos + dir * shard_len, 
			pos + tangent * shard_w, 
			pos - dir * shard_len * 0.62, 
			pos - tangent * shard_w * 0.72
		])
		game.draw_polygon(shard, PackedColorArray([Color(0.7, 0.74, 0.68, shard_alpha), Color(0.42, 0.38, 0.46, shard_alpha * 0.92), Color(0.16, 0.12, 0.2, shard_alpha), Color(0.86, 0.82, 0.72, shard_alpha * 0.78)]))
		game.draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(0.02, 0.01, 0.04, shard_alpha * 0.6), 1.0, true)

	for beam_index in range(22):
		var beam_seed = float(beam_index) * 41.0
		var angle = - spin * (0.34 + float(beam_index % 3) * 0.035) + beam_index * TAU / 22.0
		var outer = center + Vector2.from_angle(angle) * radius * (0.86 + 0.08 * sin(t * 1.4 + beam_seed))
		var mid = center + Vector2.from_angle(angle + 0.34 + intensity * 0.03) * radius * (0.45 + 0.04 * sin(beam_seed))
		var inner = center + Vector2.from_angle(angle + 0.68) * event_radius * (1.04 + 0.08 * sin(t * 4.0 + beam_seed))
		var beam_alpha = 0.08 + intensity * 0.035
		game.draw_polyline(PackedVector2Array([outer, mid, inner]), Color(0.92, 0.98, 1.0, beam_alpha), 2.0 + intensity * 0.32, true)
		game.draw_polyline(PackedVector2Array([outer, mid, inner]), Color(0.48, 0.18, 1.0, beam_alpha * 0.7), 5.0 + intensity * 0.7, true)

	for crack_index in range(18):
		var crack_angle = spin * 0.12 + crack_index * TAU / 18.0 + sin(t + crack_index) * 0.045
		var dir = Vector2.from_angle(crack_angle)
		var start = center + dir * (event_radius + 24.0)
		var finish = center + dir * radius * (0.58 + float(crack_index % 4) * 0.055)
		game.draw_line(start, finish, Color(0.0, 0.0, 0.02, 0.2 + intensity * 0.035), 2.4)
		game.draw_line(start.lerp(finish, 0.54), finish, Color(0.62, 0.82, 1.0, 0.08 + intensity * 0.025), 1.0)


static func _draw_gravitante_map_mask(game: Node2D, map_texture: Texture2D, map_rect: Rect2, tex_size: Vector2, center: Vector2, radius: float, event_radius: float, progress: float, intensity: float, spin: float) -> void :
	var outer_radius = radius * 0.82
	var inner_radius = max(28.0, event_radius * 0.48)
	var rings = 5
	var segments = 28
	for ring_index in range(rings):
		var ring_a = float(ring_index) / float(rings)
		var ring_b = float(ring_index + 1) / float(rings)
		var r0 = lerp(inner_radius, outer_radius, ring_a)
		var r1 = lerp(inner_radius, outer_radius, ring_b)
		for segment in range(segments):
			var a0 = float(segment) * TAU / float(segments)
			var a1 = float(segment + 1) * TAU / float(segments)
			var p0 = center + Vector2.from_angle(a0) * r0
			var p1 = center + Vector2.from_angle(a1) * r0
			var p2 = center + Vector2.from_angle(a1) * r1
			var p3 = center + Vector2.from_angle(a0) * r1
			var uv0 = game._gravitante_distorted_map_uv(p0, center, map_rect, tex_size, radius, progress, intensity, spin)
			var uv1 = game._gravitante_distorted_map_uv(p1, center, map_rect, tex_size, radius, progress, intensity, spin)
			var uv2 = game._gravitante_distorted_map_uv(p2, center, map_rect, tex_size, radius, progress, intensity, spin)
			var uv3 = game._gravitante_distorted_map_uv(p3, center, map_rect, tex_size, radius, progress, intensity, spin)
			var edge = clamp((r0 + r1) * 0.5 / max(1.0, outer_radius), 0.0, 1.0)
			var horizon = 1.0 - clamp((r0 - inner_radius) / max(1.0, outer_radius - inner_radius), 0.0, 1.0)
			var light = 0.82 - horizon * 0.48 + edge * 0.18
			var alpha = clamp(0.54 + intensity * 0.08 - horizon * 0.1, 0.36, 0.78)
			var color = Color(light * 0.8, light * 0.86, light, alpha)
			var colors = PackedColorArray([color, color, color, color])
			game.draw_polygon(PackedVector2Array([p0, p1, p2, p3]), colors, PackedVector2Array([uv0, uv1, uv2, uv3]), map_texture)

	game.draw_circle(center, outer_radius, Color(0.02, 0.0, 0.04, 0.15 + intensity * 0.04))
	for veil_index in range(6):
		var r = lerp(inner_radius * 1.15, outer_radius, float(veil_index) / 5.0)
		var alpha = 0.12 + intensity * 0.018 - veil_index * 0.01
		game.draw_arc(center, r, spin * (0.48 + veil_index * 0.05), spin * (0.48 + veil_index * 0.05) + TAU * 0.72, 80, Color(0.02, 0.0, 0.08, alpha), 9.0 - veil_index * 0.8)
		game.draw_arc(center, r * 0.98, - spin * (0.36 + veil_index * 0.04), - spin * (0.36 + veil_index * 0.04) + TAU * 0.46, 72, Color(0.72, 0.88, 1.0, 0.055 + intensity * 0.01), 2.0)


static func _draw_ancorada_spinning_anchors(game: Node2D, camera: Vector2) -> void :
	for spin in game.ancorada_spinning:
		if float(spin.get("life", 0.0)) <= 0.0:
			continue
		var center: Vector2 = game.player_pos - camera
		var alpha: float = clampf(float(spin.get("life", 0.0)) / maxf(0.01, float(spin.get("max", 5.0))), 0.0, 1.0)
		var arm_count = 4
		for arm_i in range(arm_count):
			var arm_angle: float = float(spin.get("angle", 0.0)) + float(arm_i) * TAU / float(arm_count)
			var arm_start: Vector2 = center + Vector2.from_angle(arm_angle) * 22.0
			var arm_end: Vector2 = center + Vector2.from_angle(arm_angle) * 92.0
			game.draw_line(arm_start, arm_end, Color(0.02, 0.08, 0.03, 0.58 * alpha), 6.0)
			game.draw_line(arm_start, arm_end, Color(0.24, 1.0, 0.38, 0.72 * alpha), 2.4)
			game._draw_ancorada_anchor_icon(arm_end, 32.0, arm_angle + PI * 0.5, alpha, 0.82)
		game.draw_arc(center, 92.0, 0.0, TAU, 48, Color(0.3, 1.0, 0.42, 0.28 * alpha), 1.8)


static func _draw_ancorada_anchor_icon(game: Node2D, center: Vector2, size: = 32.0, draw_rotation: = 0.0, alpha: = 1.0, energy: = 1.0) -> void :
	var s = size / 32.0
	var outline = Color(0.01, 0.03, 0.015, 0.92 * alpha)
	var body = Color(0.07, 0.43, 0.16, 0.96 * alpha)
	var edge = Color(0.32, 1.0, 0.38, 0.98 * alpha)
	var core = Color(0.84, 1.0, 0.72, 0.92 * alpha)
	game.draw_set_transform(center, draw_rotation, Vector2.ONE)
	game.draw_arc(Vector2(0.0, -9.8) * s, 6.2 * s, 0.0, TAU, 26, outline, 4.8 * s, true)
	game.draw_arc(Vector2(0.0, -9.8) * s, 6.2 * s, 0.0, TAU, 26, edge, 2.2 * s, true)
	game.draw_line(Vector2(0.0, -4.0) * s, Vector2(0.0, 11.5) * s, outline, 6.2 * s, true)
	game.draw_line(Vector2(0.0, -4.0) * s, Vector2(0.0, 11.5) * s, body, 3.6 * s, true)
	game.draw_line(Vector2(-7.0, 1.5) * s, Vector2(7.0, 1.5) * s, outline, 5.4 * s, true)
	game.draw_line(Vector2(-7.0, 1.5) * s, Vector2(7.0, 1.5) * s, edge, 2.5 * s, true)
	var left_fluke = PackedVector2Array([
		Vector2(0.0, 9.0) * s, 
		Vector2(-9.0, 14.0) * s, 
		Vector2(-13.0, 7.2) * s, 
		Vector2(-9.4, 8.3) * s, 
		Vector2(-4.4, 5.7) * s
	])
	var right_fluke = PackedVector2Array([
		Vector2(0.0, 9.0) * s, 
		Vector2(9.0, 14.0) * s, 
		Vector2(13.0, 7.2) * s, 
		Vector2(9.4, 8.3) * s, 
		Vector2(4.4, 5.7) * s
	])
	game.draw_polyline(left_fluke, outline, 5.4 * s, true)
	game.draw_polyline(right_fluke, outline, 5.4 * s, true)
	game.draw_polyline(left_fluke, edge, 2.5 * s, true)
	game.draw_polyline(right_fluke, edge, 2.5 * s, true)
	game.draw_circle(Vector2.ZERO, 2.2 * s, core)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if energy > 0.0:
		var pulse = 0.5 + 0.5 * sin(game.time_alive * 14.0 + center.x * 0.01)
		game.draw_arc(center, (size * 0.58) + pulse * 3.0, game.time_alive * 6.0, game.time_alive * 6.0 + PI * 1.35, 22, Color(0.38, 1.0, 0.42, 0.34 * alpha * energy), 1.5)
		game.draw_circle(center + Vector2(cos(game.time_alive * 18.0), sin(game.time_alive * 13.0)) * size * 0.42, 2.0 * s, Color(0.76, 1.0, 0.48, 0.72 * alpha * energy))


static func _draw_secondary_ancorada(game: Node2D, secondary: Dictionary, camera: Vector2) -> void :
	var center_world: Vector2 = secondary.get("center", game.player_pos)
	var center: Vector2 = center_world - camera
	var radius: float = float(secondary.get("radius", game.ANCORADA_ULTIMATE_RADIUS))
	var charge: float = clampf(float(secondary.get("charge", 0.0)) / game.SECONDARY_ANCORADA_DURATION, 0.0, 1.0)
	var life_ratio: float = clampf(float(secondary.get("life", 0.0)) / maxf(0.01, float(secondary.get("max", game.SECONDARY_ANCORADA_DURATION))), 0.0, 1.0)
	var ring_alpha: float = 0.2 + 0.4 * life_ratio
	game.draw_arc(center, radius, 0.0, TAU, 80, Color(0.01, 0.04, 0.02, 0.72 * ring_alpha), 5.0)
	game.draw_arc(center, radius, 0.0, TAU, 80, Color(0.28, 1.0, 0.36, 0.86 * ring_alpha), 2.2)
	game.draw_arc(center, radius * (0.22 + 0.12 * sin(game.time_alive * 2.5 + charge * 3.0)), 0.0, TAU, 44, Color(0.7, 1.0, 0.44, 0.34 * life_ratio), 1.6)
	for i in range(16):
		var ang: float = game.time_alive * 0.48 + float(i) * TAU / 16.0
		var inner: Vector2 = center + Vector2.from_angle(ang) * (radius - 18.0)
		var outer: Vector2 = center + Vector2.from_angle(ang + 0.05) * (radius + 12.0)
		game.draw_line(inner, outer, Color(0.32, 1.0, 0.42, 0.13 * life_ratio), 1.2)
	var drops: Array = secondary.get("drops", [])
	for drop in drops:
		var fall: float = maxf(0.05, float(drop.get("fall", game.ANCORADA_ULTIMATE_FALL_TIME)))
		var p: float = clampf(float(drop.get("age", 0.0)) / fall, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - p, 2.2)
		var start: Vector2 = Vector2(drop.get("start", center_world)) - camera
		var target: Vector2 = Vector2(drop.get("target", center_world)) - camera
		var pos: Vector2 = start.lerp(target, eased)
		var drop_seed: float = float(drop.get("seed", 0.0))
		var drop_alpha: float = 1.0 if not bool(drop.get("hit", false)) else clampf(1.0 - (float(drop.get("age", 0.0)) - fall) / 0.42, 0.0, 1.0)
		for spark_i in range(5):
			var spark_phase: float = drop_seed + float(spark_i) * 1.9 + game.time_alive * (8.0 + float(spark_i))
			var offset: Vector2 = Vector2(sin(spark_phase) * (5.0 + float(spark_i)), - float(spark_i) * 8.0 - 12.0)
			game.draw_line(pos + offset, pos + offset + Vector2(sin(spark_phase * 0.7) * 4.0, -22.0), Color(0.38, 1.0, 0.36, 0.4 * drop_alpha), 1.6)
		game.draw_line(pos + Vector2(0.0, -46.0), pos + Vector2(0.0, -10.0), Color(0.22, 1.0, 0.38, 0.24 * drop_alpha), 5.0)
		game._draw_ancorada_anchor_icon(pos, 46.0, 0.0, drop_alpha, 1.0)
	var impacts: Array = secondary.get("impacts", [])
	for impact in impacts:
		var impact_pos: Vector2 = Vector2(impact.get("pos", center_world)) - camera
		var max_life: float = maxf(0.01, float(impact.get("max", 0.58)))
		var impact_progress: float = 1.0 - clampf(float(impact.get("life", 0.0)) / max_life, 0.0, 1.0)
		var impact_alpha: float = 1.0 - impact_progress
		var ripple_radius: float = 18.0 + float(impact.get("radius", game.ANCORADA_ULTIMATE_IMPACT_RADIUS)) * (0.48 + impact_progress * 0.72)
		game.draw_circle(impact_pos, ripple_radius * 0.95, Color(0.16, 1.0, 0.25, 0.1 * impact_alpha))
		game.draw_circle(impact_pos, 18.0 + 28.0 * impact_progress, Color(0.62, 1.0, 0.12, 0.32 * impact_alpha))
		game.draw_arc(impact_pos, ripple_radius, 0.0, TAU, 64, Color(0.0, 0.015, 0.0, 0.96 * impact_alpha), 10.0)
		game.draw_arc(impact_pos, ripple_radius, 0.0, TAU, 64, Color(0.88, 1.0, 0.16, 1.0 * impact_alpha), 4.8)
		game.draw_arc(impact_pos, ripple_radius * 0.68, 0.0, TAU, 52, Color(0.26, 1.0, 0.26, 0.94 * impact_alpha), 3.4)
		game.draw_arc(impact_pos, ripple_radius * 0.38, 0.0, TAU, 42, Color(0.96, 1.0, 0.54, 0.82 * impact_alpha), 2.4)
		for ray_i in range(8):
			var ray_angle: float = game.time_alive * 0.12 + float(ray_i) * TAU / 8.0
			var ray_a: Vector2 = impact_pos + Vector2.from_angle(ray_angle) * (ripple_radius * 0.28)
			var ray_b: Vector2 = impact_pos + Vector2.from_angle(ray_angle) * (ripple_radius * 0.92)
			game.draw_line(ray_a, ray_b, Color(0.44, 1.0, 0.36, 0.22 * impact_alpha), 1.8)


static func _draw_projectiles(game: Node2D, camera: Vector2) -> void :
	if not game.boss1_rewind_sequence.is_empty():
		return
	var all_bullets = game.bullets + game.remote_bullets
	for bullet in all_bullets:
		if not game._world_point_in_view(Vector2(bullet.get("pos", Vector2.ZERO)), camera, 150.0):
			continue
		var kind = String(bullet.get("kind", ""))
		var palette = game._projectile_palette(kind)
		var pos = bullet["pos"] - camera
		var dir: Vector2 = bullet["dir"]
		var side = dir.orthogonal().normalized()
		var age = float(bullet.get("age", 0.0))
		var phase = float(bullet.get("phase", 0.0))
		match kind:
			"shuriken_eclipsado", "eclipsada", "eclipsada_lua", "eclipsada_sol":
				var spin_angle: float = age * 28.0 + phase
				var shadow_trail = pos - dir * 18.0
				var shuriken_color: Color = palette["glow"]
				var edge_color = Color(1.0, 0.86, 0.38, 0.92) if kind == "eclipsada_sol" else Color(0.88, 0.72, 1.0, 0.92)
				game.draw_line(shadow_trail, pos, Color(shuriken_color.r, shuriken_color.g, shuriken_color.b, 0.45), 6.0)
				game.draw_line(shadow_trail, pos, Color(1.0, 0.95, 0.78, 0.85) if kind == "eclipsada_sol" else Color(0.85, 0.5, 1.0, 0.85), 2.0)
				game.draw_circle(pos, 14.0, Color(shuriken_color.r, shuriken_color.g, shuriken_color.b, 0.28))
				var star_pts = PackedVector2Array()
				for i in range(10):
					var a_rad = spin_angle + i * (TAU / 10.0)
					var r_dist = 16.0 if i % 2 == 0 else 5.5
					star_pts.append(pos + Vector2.from_angle(a_rad) * r_dist)
				game.draw_polygon(star_pts, PackedColorArray([Color(1.0, 0.66, 0.18) if kind == "eclipsada_sol" else Color(0.82, 0.42, 1.0)]))
				star_pts.append(star_pts[0])
				game.draw_polyline(star_pts, edge_color, 1.8, true)
				game.draw_circle(pos, 3.5, Color(1.0, 0.95, 0.65))
			"retornante":
				var state = String(bullet.get("state", "ida"))
				var c = Color(1.0, 0.42, 0.92) if state == "volta" else Color(0.64, 0.42, 1.0)
				var outer = 13.0 + sin(age * 16.0) * 2.0
				game.draw_circle(pos, 6.5, c)
				game.draw_arc(pos, outer, age * 7.0, age * 7.0 + PI * 1.55, 28, Color(c.r, c.g, c.b, 0.88), 2.2)
				game.draw_line(pos - dir * 10.0, pos + dir * 10.0, Color(1.0, 1.0, 1.0, 0.68), 1.2)
			"prismatica":
				var start = pos - dir * 30.0
				var end = pos + dir * 8.0
				game.draw_line(start, end, Color(1.0, 1.0, 1.0, 0.95), 2.2)
				game.draw_line(start, end, Color(0.32, 1.0, 0.96, 0.42), 7.0)
				var diamond = PackedVector2Array([
					pos + dir * 10.0, 
					pos + side * 7.0, 
					pos - dir * 10.0, 
					pos - side * 7.0
				])
				game.draw_polygon(diamond, PackedColorArray([Color(0.9, 1.0, 1.0, 0.96)]))
				game.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(1.0, 0.62, 0.86, 0.72), 1.5, true)
			"parasitica":
				var wobble = side * sin(age * 13.0 + phase) * 5.0
				var draw_pos = pos + wobble
				game.draw_circle(draw_pos, 9.0, palette["glow"])
				game.draw_circle(draw_pos, 5.2, palette["core"])
				for i in range(3):
					var ang = age * 7.0 + phase + i * TAU / 3.0
					game.draw_circle(draw_pos + Vector2.from_angle(ang) * 7.0, 2.2, Color(0.72, 1.0, 0.4, 0.82))
			"necronada_dust":
				var dust_alpha = clampf(float(bullet.get("life", 0.0)) / maxf(0.01, float(bullet.get("max_life", 0.8))), 0.0, 1.0)
				for i in range(10):
					var local: Vector2 = - dir * (float(i) * 5.0 + sin(age * 9.0 + float(i)) * 2.0) + side * sin(age * 11.0 + phase + float(i) * 0.7) * (4.0 + float(i) * 0.65)
					var grain_pos: Vector2 = pos + local
					var size = 4.5 + sin(age * 14.0 + float(i)) * 1.2
					game.draw_circle(grain_pos, size, Color(0.05, 0.025, 0.08, 0.4 * dust_alpha))
					game.draw_circle(grain_pos + dir * 1.5, maxf(1.5, size * 0.45), Color(0.66, 0.35, 1.0, 0.54 * dust_alpha))
				game.draw_arc(pos, 20.0 + sin(age * 16.0) * 3.0, phase + age * 5.0, phase + age * 5.0 + PI * 1.25, 24, Color(0.78, 0.58, 1.0, 0.62 * dust_alpha), 2.0)
			"gravitante":
				game.draw_circle(pos, 10.0, palette["glow"])
				game.draw_circle(pos, 4.5, palette["core"])
				var orb_ang = age * 9.0 + phase
				game.draw_arc(pos, 14.0, orb_ang, orb_ang + PI * 1.35, 24, Color(0.82, 0.88, 1.0, 0.82), 2)
				game.draw_circle(pos + Vector2.from_angle(orb_ang) * 12.0, 2.8, Color(0.86, 0.92, 1.0, 0.9))
			"bombastica":
				var fuse_tip: Vector2 = pos - dir * 15.0 + side * sin(age * 18.0 + phase) * 5.0
				var head: Vector2 = pos + dir * 9.0
				game.draw_line(fuse_tip, head, Color(0.18, 0.88, 1.0, 0.52), 3.2, true)
				game.draw_circle(head, 16.0, Color(1.0, 0.48, 0.08, 0.18))
				game.draw_circle(head, 10.0, Color(1.0, 0.42, 0.06, 0.92))
				game.draw_circle(head, 5.0, Color(1.0, 0.94, 0.48, 0.95))
				game.draw_arc(head, 16.0, age * 8.0, age * 8.0 + PI * 1.4, 28, Color(1.0, 0.84, 0.28, 0.76), 2.0)
				game.draw_circle(fuse_tip, 4.5 + sin(age * 24.0) * 1.5, Color(1.0, 0.96, 0.62, 0.9))
			"ancorada":
				var rot_angle = dir.angle() - PI * 0.5 + deg_to_rad(620.0 * age)
				game.draw_line(pos - dir * 20.0, pos - dir * 8.0, Color(0.24, 1.0, 0.38, 0.26), 5.0)
				game._draw_ancorada_anchor_icon(pos, 28.0, rot_angle, 1.0, 0.9)
			"eletrica", "eletrica_charged":
				var charge_mult = 1.45 if kind == "eletrica_charged" else 1.0
				var a = pos - dir * (16.0 * charge_mult)
				var b = pos - dir * (6.0 * charge_mult) + side * sin(age * 28.0 + phase) * 5.0 * charge_mult
				var c = pos + dir * (7.0 * charge_mult)
				game.draw_polyline(PackedVector2Array([a, b, c]), Color(0.86, 0.28, 1.0, 0.54), 7.0 * charge_mult, true)
				game.draw_polyline(PackedVector2Array([a, b, c]), Color(0.74, 1.0, 1.0, 0.96), 3.0 * charge_mult, true)
				game.draw_circle(pos, 7.0 * charge_mult, palette["glow"])
				game.draw_circle(pos, 3.8 * charge_mult, Color.WHITE)
				if kind == "eletrica_charged":
					game.draw_arc(pos, 18.0, 0, TAU, 28, Color(1.0, 1.0, 1.0, 0.68), 2)
			"petro":
				var body = PackedVector2Array([
					pos + dir * 9.0, 
					pos + side * 5.0, 
					pos - dir * 9.0, 
					pos - side * 5.0
				])
				game.draw_polygon(body, PackedColorArray([Color(0.24, 1.0, 1.0, 0.92)]))
				game.draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), Color.WHITE, 1.2, true)
			_:
				var c: Color = bullet["color"]
				game.draw_circle(pos, 7, c)
				c.a = 0.22
				game.draw_circle(pos, 15, c)
	for bullet in game.return_bullets:
		if not game._world_point_in_view(Vector2(bullet.get("pos", Vector2.ZERO)), camera, 150.0):
			continue
		var pos = bullet["pos"] - camera
		var dir = Vector2(bullet.get("dir", Vector2.RIGHT))
		var age = float(bullet.get("age", 0.0))
		var state = String(bullet.get("state", "volta" if bool(bullet.get("returning", false)) else "ida"))
		var c = game._manifestation_color()
		if state == "instavel":
			c = Color(1.0, 0.28, 0.76)
		elif state == "volta":
			c = Color(1.0, 0.42, 0.92)
		var boosted = float(bullet.get("paradox_until", 0.0)) > game.time_alive or state == "instavel"
		var core_radius = 13.0 if boosted else 6.5
		var outer = 34.0 + sin(age * 16.0) * 6.0 if boosted else (17.0 + sin(age * 16.0) * 3.0 if state == "instavel" else 13.0 + sin(age * 16.0) * 2.0)
		game.draw_circle(pos, core_radius, c)
		game.draw_arc(pos, outer, age * 7.0, age * 7.0 + PI * 1.55, 28, Color(c.r, c.g, c.b, 0.88), 2.2)
		game.draw_line(pos - dir * 10.0, pos + dir * 10.0, Color(1.0, 1.0, 1.0, 0.68), 1.2)
		if state == "instavel":
			game.draw_arc(pos, outer + 8.0, age * 4.5, age * 4.5 + PI * 1.15, 22, Color(1.0, 0.76, 0.92, 0.56), 1.6)
	for bullet in game.enemy_bullets:
		if not game._world_point_in_view(Vector2(bullet.get("pos", Vector2.ZERO)), camera, 180.0):
			continue
		if bullet.get("type") == "boss4_comet":
			var comet_pos: Vector2 = Vector2(bullet["pos"]) - camera
			var comet_dir: Vector2 = Vector2(bullet.get("dir", Vector2.LEFT)).normalized()
			var comet_side: Vector2 = comet_dir.orthogonal()
			var comet_phase: float = float(bullet.get("phase", 0.0))
			var comet_radius: float = game.BOSS4_COMET_RADIUS
			var tail = PackedVector2Array()
			for i in range(7):
				var tail_t: float = float(i) / 6.0
				var curve: float = sin(comet_phase * 0.7 + game.time_alive * 6.0 + tail_t * 5.0) * (1.0 - tail_t) * 12.0
				tail.append(comet_pos - comet_dir * (comet_radius * (0.3 + tail_t * 2.1)) + comet_side * curve)
			game.draw_polyline(tail, Color(0.2, 0.56, 1.0, 0.18), 18.0, true)
			game.draw_polyline(tail, Color(0.72, 0.9, 1.0, 0.62), 5.0, true)
			var rock = PackedVector2Array()
			for i in range(8):
				var rock_angle: float = float(i) * TAU / 8.0 + comet_phase * 0.08
				rock.append(comet_pos + Vector2.from_angle(rock_angle) * comet_radius * (0.82 + 0.16 * sin(comet_phase + i * 2.3)))
			game.draw_circle(comet_pos, comet_radius * 1.45, Color(0.16, 0.52, 1.0, 0.16))
			game.draw_colored_polygon(rock, Color(0.2, 0.18, 0.22, 0.98))
			var rock_outline: PackedVector2Array = rock.duplicate()
			rock_outline.append(rock[0])
			game.draw_polyline(rock_outline, Color(1.0, 0.7, 0.22, 0.96), 3.2, true)
			game.draw_circle(comet_pos - comet_dir * 7.0 - comet_side * 7.0, 7.0, Color(0.44, 0.76, 0.96, 0.72))
			game.draw_arc(comet_pos, comet_radius * 1.18, comet_phase, comet_phase + PI * 1.4, 32, Color(0.42, 0.92, 1.0, 0.78), 2.4)
		elif bullet.get("type") == "boss7_dive_fireball":
			var pos: Vector2 = Vector2(bullet["pos"]) - camera
			var dir: Vector2 = Vector2(bullet.get("dir", Vector2.DOWN)).normalized()
			var phase: float = float(bullet.get("phase", 0.0))
			var radius: float = float(bullet.get("radius", game.BOSS7_DIVE_FIREBALL_RADIUS))
			game.PhoenixFire.draw_projectile(game, pos, dir, radius, game.time_alive, phase, game._phase7_visual_budget_enabled())
		elif bullet.get("type") == "phase7_fireball":
			var pos: Vector2 = Vector2(bullet["pos"]) - camera
			var dir: Vector2 = Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
			game.PhoenixFire.draw_projectile(game, pos, dir, float(bullet.get("radius", 14.0)), game.time_alive, float(bullet.get("phase", 0.0)), game._phase7_visual_budget_enabled())
		elif bullet.get("type") == "pyro_wall_seed":
			var pos = Vector2(bullet["pos"]) - camera
			var dir = Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
			var side = dir.orthogonal()
			var flame = PackedVector2Array([pos + dir * 19.0, pos + side * 10.0, pos - dir * 14.0, pos - side * 10.0])
			game.draw_circle(pos, 22.0, Color(1.0, 0.1, 0.02, 0.2))
			game.draw_colored_polygon(flame, Color(1.0, 0.24, 0.04, 0.96))
			game.draw_polyline(PackedVector2Array([flame[0], flame[1], flame[2], flame[3], flame[0]]), Color(1.0, 0.86, 0.28, 0.95), 2.4, true)
		elif bullet.get("type") == "miasma_cheese_spit":
			var pos = Vector2(bullet["pos"]) - camera
			var cheese_tex: Texture2D = game.textures.get("boss3_cheese")
			game.draw_circle(pos, 31.0, Color(0.34, 0.48, 0.02, 0.38))
			game.draw_arc(pos, 30.0, 0.0, TAU, 30, Color(0.88, 1.0, 0.28, 0.94), 3.0)
			game._draw_entity_fit(cheese_tex, pos, Vector2(48, 42), Color(0.88, 1.0, 0.42))
		elif bullet.get("type") == "miasma_eel_spit":
			var pos = Vector2(bullet["pos"]) - camera
			var dir = Vector2(bullet.get("dir", Vector2.LEFT)).normalized()
			var side = dir.orthogonal()
			var phase = float(bullet.get("phase", 0.0))
			var glob = PackedVector2Array([
				pos + dir * 20.0, 
				pos + side * (11.0 + sin(phase) * 2.0), 
				pos - dir * 15.0, 
				pos - side * (10.0 + cos(phase) * 2.0)
			])
			game.draw_circle(pos, 30.0, Color(0.1, 0.78, 0.1, 0.22))
			game.draw_colored_polygon(glob, Color(0.28, 1.0, 0.16, 0.92))
			game.draw_polyline(PackedVector2Array([glob[0], glob[1], glob[2], glob[3], glob[0]]), Color(0.9, 1.0, 0.38, 0.92), 2.2, true)
			game.draw_arc(pos, 24.0, phase + game.time_alive * 6.0, phase + game.time_alive * 6.0 + PI * 1.4, 24, Color(0.64, 1.0, 0.2, 0.72), 2.0)
		elif bullet.get("type") == "pustula_fossil_spit":
			var pos = Vector2(bullet["pos"]) - camera
			var dir = Vector2(bullet.get("dir", Vector2.LEFT)).normalized()
			var side = dir.orthogonal()
			var phase = float(bullet.get("phase", 0.0))
			var glob = PackedVector2Array([
				pos + dir * 17.0, 
				pos + side * (9.0 + sin(phase) * 2.0), 
				pos - dir * 13.0, 
				pos - side * (8.0 + cos(phase) * 2.0)
			])
			game.draw_circle(pos, 22.0, Color(0.16, 0.22, 0.06, 0.28))
			game.draw_colored_polygon(glob, Color(0.58, 0.9, 0.16, 0.92))
			game.draw_polyline(PackedVector2Array([glob[0], glob[1], glob[2], glob[3], glob[0]]), Color(0.92, 1.0, 0.42, 0.88), 1.8, true)
			game.draw_line(pos - dir * 18.0, pos - dir * 34.0 + side * sin(phase * 1.7) * 4.0, Color(0.56, 0.78, 0.22, 0.45), 3.0, true)
		elif bullet.get("type") == "rat_flask" or bullet.get("type") == "rat_spit":
			var pos = Vector2(bullet["pos"]) - camera
			var tex: Texture2D = game.textures.get("boss3_flask")
			game.draw_circle(pos, 31.0, Color(0.14, 0.01, 0.24, 0.72))
			game.draw_arc(pos, 31.0, 0.0, TAU, 30, Color(0.92, 0.58, 1.0, 0.96), 3.2)
			game._draw_entity_fit(tex, pos, Vector2(48, 60), Color(0.72, 1.0, 0.3) if bullet.get("type") == "rat_spit" else Color.WHITE)
			game.draw_circle(pos, 34.0, Color(0.5, 0.88, 0.12, 0.14))
		elif bullet.get("type") == "rat_shot":
			var idx = int(float(bullet.get("phase", 0.0))) % 2
			var rat_tex: Texture2D = game.textures["enemy_phase_3_bullet"][idx]
			var pos = Vector2(bullet["pos"]) - camera
			game.draw_circle(pos, 25.0, Color(0.1, 0.01, 0.2, 0.76))
			game.draw_arc(pos, 25.0, 0.0, TAU, 28, Color(0.94, 0.64, 1.0, 0.98), 3.0)
			game._draw_entity_fit(rat_tex, pos, Vector2(52, 38), Color.WHITE)
		elif bullet.get("type") == "phase4_magic":
			var idx = int(float(bullet.get("phase", 0.0))) % 2
			var magic_frames: Array = game.textures.get("enemy_phase_4_bullet", [])
			var magic_tex: Texture2D = magic_frames[idx] if magic_frames.size() > idx else null
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			game.draw_circle(pos, 27.0, Color(0.52, 0.08, 0.94, 0.26))
			game.draw_arc(pos, 24.0, phase, phase + PI * 1.7, 28, Color(1.0, 0.7, 0.22, 0.92), 3.0)
			game._draw_entity_fit(magic_tex, pos, Vector2(42, 42), Color(0.92, 0.72, 1.0))
		elif bullet.get("type") == "umbra_plasma":
			var pos = Vector2(bullet["pos"]) - camera
			var dir = Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
			var side = dir.orthogonal()
			var phase = float(bullet.get("phase", 0.0))
			var core = PackedVector2Array([pos + dir * 22.0, pos + side * 10.0, pos - dir * 16.0, pos - side * 10.0])
			game.draw_circle(pos, 31.0, Color(0.05, 0.72, 0.18, 0.22))
			game.draw_colored_polygon(core, Color(0.25, 1.0, 0.34, 0.96))
			game.draw_polyline(PackedVector2Array([core[0], core[1], core[2], core[3], core[0]]), Color(0.86, 1.0, 0.74, 0.95), 2.2, true)
			game.draw_arc(pos, 30.0, phase + game.time_alive * 7.5, phase + game.time_alive * 7.5 + PI * 1.55, 32, Color(0.58, 1.0, 0.64, 0.8), 2.5)
		elif bullet.get("type") == "nexus_refracted":
			var pos = Vector2(bullet["pos"]) - camera
			var dir = Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
			var side = dir.orthogonal()
			var shard = PackedVector2Array([pos + dir * 18.0, pos + side * 8.0, pos - dir * 14.0, pos - side * 8.0])
			game.draw_circle(pos, 22.0, Color(0.18, 0.76, 1.0, 0.18))
			game.draw_colored_polygon(shard, Color(1.0, 0.26, 0.72, 0.92))
			game.draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(0.62, 1.0, 1.0, 0.94), 2.0, true)
		elif bullet.get("type") == "arauto_shot":
			var pos = Vector2(bullet["pos"]) - camera
			var dir = Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
			var side = dir.orthogonal()
			var phase = float(bullet.get("phase", 0.0))
			var core = PackedVector2Array([pos + dir * 20.0, pos + side * 8.0, pos - dir * 18.0, pos - side * 8.0])
			game.draw_circle(pos, 28.0, Color(0.7, 0.18, 1.0, 0.2))
			game.draw_colored_polygon(core, Color(0.82, 0.34, 1.0, 0.94))
			game.draw_polyline(PackedVector2Array([core[0], core[1], core[2], core[3], core[0]]), Color(0.72, 0.94, 1.0, 0.92), 2.2, true)
			game.draw_arc(pos, 28.0, phase + game.time_alive * 5.0, phase + game.time_alive * 5.0 + PI * 1.45, 32, Color(1.0, 0.72, 1.0, 0.76), 2.2)
		elif bullet.get("type") == "larapio_coin" or bullet.get("type") == "larapio_stone":
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			var is_coin = bullet.get("type") == "larapio_coin"
			if is_coin:
				var body = Color(1.0, 0.78, 0.14)
				var rim = Color(0.52, 0.28, 0.04)
				game.draw_circle(pos, 10.0, Color(body.r, body.g, body.b, 0.82))
				game.draw_arc(pos, 12.5, phase, phase + TAU * 0.92, 28, rim, 2.0)
				game.draw_line(pos + Vector2(cos(phase), sin(phase)) * -6.0, pos + Vector2(cos(phase), sin(phase)) * 6.0, Color(1.0, 1.0, 0.72, 0.75), 1.6)
			else:
				var spin: float = float(bullet.get("spin", 1.0))
				var angle: float = phase * (0.72 + absf(spin) * 0.42) * signf(spin if spin != 0.0 else 1.0)
				var forward: Vector2 = Vector2.from_angle(angle)
				var side: Vector2 = forward.orthogonal()
				var wobble: float = sin(phase * 1.8)
				var rock = PackedVector2Array([
					pos + forward * (15.0 + wobble * 2.0) - side * 2.0,
					pos + forward * 4.0 + side * (13.0 + cos(phase) * 2.0),
					pos - forward * (10.0 + sin(phase * 0.7) * 2.0) + side * 9.0,
					pos - forward * (15.0 + cos(phase * 1.1) * 2.0) - side * 4.0,
					pos - forward * 2.0 - side * (12.0 + wobble * 2.0)
				])
				var crack_col: Color = Color(0.72, 0.16, 1.0, 0.88).lerp(Color(1.0, 0.28, 0.72, 0.94), 0.5 + 0.5 * sin(phase * 2.3))
				game.draw_circle(pos, 20.0, Color(0.42, 0.14, 0.68, 0.2))
				game.draw_colored_polygon(rock, Color(0.54, 0.5, 0.56, 0.96))
				game.draw_polyline(PackedVector2Array([rock[0], rock[1], rock[2], rock[3], rock[4], rock[0]]), Color(0.06, 0.045, 0.065, 0.9), 2.2, true)
				game.draw_line(pos - forward * 9.0 - side * 4.0, pos + forward * 7.0 + side * 3.0, crack_col, 1.8, true)
				game.draw_line(pos - forward * 2.0 + side * 8.0, pos + forward * 4.0 + side * 1.0, crack_col, 1.4, true)
				game.draw_circle(pos + forward * 6.0 - side * 7.0, 2.5, Color(0.02, 0.015, 0.02, 0.92))
				game.draw_circle(pos - forward * 7.0 + side * 2.0, 2.0, Color(0.02, 0.015, 0.02, 0.86))
		elif bullet.get("type") == "atirador":
			var c = Color(0.65, 0.85, 1.0)
			game.draw_circle(bullet["pos"] - camera, 14, c)
			game.draw_circle(bullet["pos"] - camera, 24, Color(0.3, 0.7, 1.0, 0.3))
		elif bullet.get("type") == "boss_pressure_bubble":
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			var radius = float(bullet.get("radius", 18.0)) * (1.0 + sin(game.time_alive * 15.0 + phase) * 0.07)
			game.Boss1VFX.streak(game, pos - Vector2(bullet.get("dir", Vector2.LEFT)) * radius * 3.6, pos, Color(0.2, 0.86, 1.0, 0.62), radius * 0.8)
			game.Boss1VFX.bubble(game, pos, radius, game.time_alive + phase, game.Boss1VFX.CYAN, game._get_boss_wave_quality_profile() == "LOW")
		elif bullet.get("type") == "cout_attack_speed":
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			var radius = float(bullet.get("radius", 14.0))
			game.draw_circle(pos, radius + 12.0, Color(1.0, 0.52, 0.08, 0.18))
			game.draw_arc(pos, radius + 8.0, phase + game.time_alive * 8.0, phase + game.time_alive * 8.0 + PI * 1.65, 28, Color(1.0, 0.8, 0.22, 0.9), 3.0)
			game.draw_line(pos - Vector2(bullet.get("dir", Vector2.RIGHT)) * 16.0, pos + Vector2(bullet.get("dir", Vector2.RIGHT)) * 10.0, Color(1.0, 0.95, 0.7, 0.84), 3.0)
		elif bullet.get("type") == "reflected_player":
			var pos = Vector2(bullet["pos"]) - camera
			var phase = float(bullet.get("phase", 0.0))
			var radius = float(bullet.get("radius", 11.0))
			game.draw_circle(pos, radius + 12.0, Color(0.54, 0.92, 1.0, 0.18))
			game.draw_circle(pos, radius, Color(0.82, 1.0, 1.0, 0.42))
			game.draw_arc(pos, radius + 6.0, - phase - game.time_alive * 9.0, - phase - game.time_alive * 9.0 + TAU * 0.7, 24, Color(0.96, 1.0, 1.0, 0.94), 2.6)
		elif bullet.get("type") == "frost_shard":
			var pos: Vector2 = bullet["pos"] - camera
			var dir: Vector2 = bullet["dir"]
			game.draw_line(pos - dir * 44.0, pos, Color(0.04, 0.13, 0.24, 0.64), 9.0)
			game.draw_line(pos - dir * 34.0, pos, Color(0.35, 0.88, 1.0, 0.56), 4.0)
			game.Boss2VFX.crystal(game, pos, dir, 15.0)
		else:
			var t = 0.5 + sin(float(bullet["phase"])) * 0.5
			var c = Color(0.45 + t * 0.28, 0.42, 0.5 + t * 0.5)
			game.draw_circle(bullet["pos"] - camera, 9, c)
			game.draw_circle(bullet["pos"] - camera, 16, Color(0.54, 0.16, 0.9, 0.22))
	for orbital in game.orbitals:
		var anchor = Vector2(orbital.get("origin_pos", game.player_pos))
		if String(orbital.get("target_kind", "enemy")) == "enemy":
			var enemy = game._enemy_by_uid(int(orbital["enemy_uid"]))
			if enemy:
				anchor = Vector2(enemy["pos"])
		elif game.boss_active and game.boss_hp > 0.0:
			anchor = game.boss_pos
		var orbit_radius = 62.0 if String(orbital.get("target_kind", "enemy")) == "boss" else 42.0
		var p = anchor + Vector2.from_angle(float(orbital["angle"])) * orbit_radius
		if not game._world_point_in_view(p, camera, 120.0):
			continue
		game.draw_circle(p - camera, 8, Color(0.55, 0.82, 1.0))
		game.draw_arc(anchor - camera, orbit_radius, float(orbital["angle"]) - 0.7, float(orbital["angle"]) + 0.35, 18, Color(0.46, 0.78, 1.0, 0.42), 1.6)


static func _draw_miasma_eye_mask(game: Node2D, viewport: Vector2, openness: float) -> void :
	var curves = game._miasma_eye_curves(viewport, openness)
	var upper: PackedVector2Array = curves["upper"]
	var lower: PackedVector2Array = curves["lower"]
	var top = PackedVector2Array([Vector2(-30, -30), Vector2(viewport.x + 30, -30)])
	var bottom = PackedVector2Array([Vector2(-30, viewport.y + 30), Vector2(viewport.x + 30, viewport.y + 30)])
	for i in range(upper.size() - 1, -1, -1):
		top.append(upper[i])
	for i in range(lower.size() - 1, -1, -1):
		bottom.append(lower[i])
	game.draw_colored_polygon(top, Color(0.005, 0.008, 0.006, 0.965))
	game.draw_colored_polygon(bottom, Color(0.005, 0.008, 0.006, 0.965))
	for width in [86.0, 64.0, 44.0, 26.0, 12.0]:
		var alpha: float = lerp(0.055, 0.5, 1.0 - width / 86.0)
		game.draw_polyline(upper, Color(0.0, 0.0, 0.0, alpha), width, true)
		game.draw_polyline(lower, Color(0.0, 0.0, 0.0, alpha), width, true)
	for mist_pass in range(4):
		var mist = PackedVector2Array()
		var mirrored = PackedVector2Array()
		for i in range(upper.size()):
			var p = Vector2(upper[i])
			var wave = sin(float(i) * 0.64 + game.time_alive * 1.2 + mist_pass * 1.7) * (5.0 + mist_pass * 2.0)
			mist.append(p + Vector2(0.0, wave - mist_pass * 5.0))
			mirrored.append(Vector2(lower[i]) + Vector2(0.0, - wave + mist_pass * 5.0))
		game.draw_polyline(mist, Color(0.44, 0.62, 0.1, 0.1 - mist_pass * 0.014), 18.0 - mist_pass * 3.2, true)
		game.draw_polyline(mirrored, Color(0.44, 0.62, 0.1, 0.1 - mist_pass * 0.014), 18.0 - mist_pass * 3.2, true)
	game.draw_polyline(upper, Color(0.54, 0.72, 0.1, 0.18), 3.0, true)
	game.draw_polyline(lower, Color(0.54, 0.72, 0.1, 0.18), 3.0, true)


static func _draw_miasma_darkness_fog(game: Node2D, player_screen: Vector2, viewport: Vector2) -> void :
	var radius = game.BOSS3_MIASMA_DARK_RADIUS
	var left = maxf(0.0, player_screen.x - radius)
	var right = minf(viewport.x, player_screen.x + radius)
	var top = maxf(0.0, player_screen.y - radius)
	var bottom = minf(viewport.y, player_screen.y + radius)

	var dark_col = Color(0.01, 0.02, 0.01, 0.97)
	game.draw_rect(Rect2(0, 0, viewport.x, top), dark_col, true)
	game.draw_rect(Rect2(0, bottom, viewport.x, maxf(0.0, viewport.y - bottom)), dark_col, true)
	game.draw_rect(Rect2(0, top, left, maxf(0.0, bottom - top)), dark_col, true)
	game.draw_rect(Rect2(right, top, maxf(0.0, viewport.x - right), maxf(0.0, bottom - top)), dark_col, true)

	for i in range(24):
		var angle: float = float(i) * TAU / 24.0 + sin(game.time_alive * 0.3 + i) * 0.04
		var p = player_screen + Vector2.from_angle(angle) * radius
		var fog_size: float = 24.0 + 12.0 * sin(game.time_alive * 1.2 + float(i))
		game.draw_circle(p, fog_size, Color(0.01, 0.03, 0.01, 0.45))

	game.draw_arc(player_screen, radius, 0.0, TAU, 64, Color(0.28, 0.65, 0.18, 0.4), 2.5, true)


static func _draw_miasma_qte_cheese_gunk(game: Node2D, viewport: Vector2, openness: float) -> void :
	var curves = game._miasma_eye_curves(viewport, openness)
	var upper: PackedVector2Array = curves["upper"]
	var lower: PackedVector2Array = curves["lower"]
	var progress: float = float(game.boss3_miasma_qte_taps) / max(1.0, float(game.boss3_miasma_qte_required))
	var glue_strength: float = clamp(1.0 - progress, 0.12, 1.0)
	for width in [24.0, 13.0, 5.0]:
		var alpha: float = 0.06 + glue_strength * (0.12 if width > 20.0 else 0.24)
		game.draw_polyline(upper, Color(0.78, 0.48, 0.04, alpha), width, true)
		game.draw_polyline(lower, Color(0.58, 0.36, 0.02, alpha * 0.95), width, true)
	for i in range(11):
		var t: float = lerp(0.18, 0.82, float(i) / 10.0)
		var idx: int = clampi(int(t * float(upper.size() - 1)), 0, upper.size() - 1)
		var top_p = Vector2(upper[idx])
		var bottom_p = Vector2(lower[idx])
		var gap: float = max(1.0, bottom_p.y - top_p.y)
		var length_ratio: float = clamp(0.32 + glue_strength * 0.52 + sin(game.time_alive * 1.1 + i * 1.9) * 0.08, 0.18, 0.92)
		var end_p = top_p.lerp(bottom_p, length_ratio)
		var sag: float = sin(game.time_alive * 2.0 + i) * 7.0
		var strand = PackedVector2Array([top_p + Vector2(0, 3), top_p.lerp(end_p, 0.5) + Vector2(sag, 0), end_p])
		game.draw_polyline(strand, Color(0.64, 0.4, 0.02, 0.3 + glue_strength * 0.24), 8.0 + glue_strength * 5.0, true)
		game.draw_polyline(strand, Color(1.0, 0.82, 0.18, 0.26), 2.4, true)
		if gap > 22.0:
			var blob_p = end_p + Vector2(sin(game.time_alive * 1.8 + i) * 2.0, 4.0)
			game.draw_circle(blob_p, 6.0 + glue_strength * 6.0, Color(0.36, 0.23, 0.015, 0.52))
			game.draw_circle(blob_p, 4.0 + glue_strength * 4.5, Color(0.92, 0.58, 0.05, 0.72))
			game.draw_circle(blob_p + Vector2(-2, -2), 2.0 + glue_strength * 1.8, Color(1.0, 0.91, 0.32, 0.42))
	for i in range(24):
		var t2: float = lerp(0.06, 0.94, float(i) / 23.0)
		var idx2: int = clampi(int(t2 * float(upper.size() - 1)), 0, upper.size() - 1)
		var edge_p = Vector2(upper[idx2]) if i % 2 == 0 else Vector2(lower[idx2])
		var edge_sign = 1.0 if i % 2 == 0 else -1.0
		var crawl = edge_p + Vector2(sin(game.time_alive * 1.4 + i) * 7.0, edge_sign * (8.0 + sin(i * 0.8) * 5.0))
		game.draw_circle(crawl, 5.0 + glue_strength * 6.5, Color(0.42, 0.28, 0.02, 0.34))
		game.draw_circle(crawl + Vector2(-1.5, -1.5), 2.4 + glue_strength * 2.8, Color(0.98, 0.7, 0.1, 0.42))
	for i in range(8):
		var angle: float = i * TAU / 8.0 + game.time_alive * 0.35
		var p = viewport * 0.5 + Vector2.from_angle(angle) * (72.0 + sin(game.time_alive * 2.1 + i) * 12.0)
		game.draw_circle(p, 6.0 + glue_strength * 5.0, Color(0.54, 0.34, 0.02, 0.24 * glue_strength))


static func _draw_miasma_faith_link(game: Node2D, camera: Vector2) -> void :
	var player_screen: Vector2 = game.player_pos - camera + Vector2(0, -18.0 + sin(game.boss3_miasma_qte_elapsed * 4.0) * 9.0)
	var boss_screen: Vector2 = game.boss_pos - camera + Vector2(0, -58.0 + sin(game.boss3_miasma_qte_elapsed * 3.2 + 1.4) * 11.0)
	var dir: Vector2 = boss_screen - player_screen
	if dir.length() <= 1.0:
		return
	var side = dir.normalized().orthogonal()
	var strand_a = PackedVector2Array()
	var strand_b = PackedVector2Array()
	for i in range(24):
		var t: float = float(i) / 23.0
		var base = player_screen.lerp(boss_screen, t)
		var wave: float = sin(t * TAU * 3.0 + game.boss3_miasma_qte_elapsed * 5.0) * 14.0
		var pulse: float = sin(t * TAU * 7.0 - game.boss3_miasma_qte_elapsed * 8.0) * 5.0
		strand_a.append(base + side * (wave + pulse))
		strand_b.append(base - side * (wave * 0.62 - pulse))
	game.draw_polyline(strand_a, Color(0.0, 0.0, 0.0, 0.78), 14.0, true)
	game.draw_polyline(strand_b, Color(0.0, 0.0, 0.0, 0.7), 11.0, true)
	game.draw_polyline(strand_a, Color(0.92, 1.0, 0.16, 0.8), 5.0, true)
	game.draw_polyline(strand_b, Color(0.18, 1.0, 0.24, 0.64), 4.0, true)
	game.draw_polyline(strand_a, Color(1.0, 0.84, 0.05, 0.72), 1.6, true)
	for i in range(9):
		var t2: float = fposmod(game.boss3_miasma_qte_elapsed * 0.55 + i / 9.0, 1.0)
		var p = player_screen.lerp(boss_screen, t2) + side * sin(t2 * TAU * 3.0 + game.boss3_miasma_qte_elapsed * 5.0) * 14.0
		game.draw_circle(p, 5.5, Color(0.02, 0.02, 0.0, 0.55))
		game.draw_circle(p, 3.2, Color(1.0, 0.82, 0.06, 0.8))
	for anchor in [player_screen, boss_screen]:
		var lift: float = 1.0 + 0.08 * sin(game.boss3_miasma_qte_elapsed * 5.0 + anchor.x)
		game.draw_arc(anchor + Vector2(0, 30), 32.0 * lift, 0.0, TAU, 48, Color(0.86, 1.0, 0.16, 0.28), 4.0, true)
		game.draw_arc(anchor + Vector2(0, 42), 46.0 * lift, - game.boss3_miasma_qte_elapsed * 2.0, TAU - game.boss3_miasma_qte_elapsed * 2.0, 48, Color(0.1, 1.0, 0.3, 0.2), 3.0, true)


static func _draw_umbra_miasma_overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void :
	if not game._is_umbra_miasma_active():
		return
	var center: Vector2 = game.player_pos - camera
	var inner_r: float = 120.0 + sin(game.time_alive * 3.2) * 6.0


	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.07, 0.03, 0.32), true)


	for i in range(12):
		var ang: float = game.time_alive * 0.45 + float(i) * (TAU / 12.0)
		var dist: float = inner_r + 45.0 + sin(game.time_alive * 1.8 + float(i) * 1.3) * 22.0
		var mist_pos: Vector2 = center + Vector2.from_angle(ang) * dist
		var mist_radius: float = 34.0 + sin(game.time_alive * 2.2 + float(i)) * 10.0
		game.draw_circle(mist_pos, mist_radius, Color(0.04, 0.16, 0.06, 0.14))
		game.draw_circle(mist_pos + Vector2(sin(ang) * 6.0, cos(ang) * 6.0), mist_radius * 0.6, Color(0.14, 0.42, 0.12, 0.1))


	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 4.0)
	game.draw_arc(center, inner_r, 0.0, TAU, 72, Color(0.18, 0.52, 0.16, 0.35 + pulse * 0.15), 3.0, true)
	game.draw_arc(center, inner_r + 14.0, - game.time_alive * 0.8, TAU - game.time_alive * 0.8, 64, Color(0.38, 0.82, 0.26, 0.22 + pulse * 0.12), 1.5, true)
	game.draw_arc(center, inner_r - 12.0, game.time_alive * 1.1, game.time_alive * 1.1 + PI * 1.4, 48, Color(0.58, 0.95, 0.32, 0.28), 2.0, true)


	for i in range(20):
		var ang: float = game.time_alive * (0.8 + float(i % 5) * 0.2) + float(i) * (TAU / 20.0)
		var orbit_dist: float = inner_r * (0.35 + 0.58 * fposmod(float(i) * 0.17 + game.time_alive * 0.12, 1.0))
		var particle_pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * orbit_dist
		var spore_size: float = 3.0 + sin(game.time_alive * 3.0 + i) * 1.2
		game.draw_circle(particle_pos, spore_size * 2.0, Color(0.12, 0.45, 0.1, 0.3))
		game.draw_circle(particle_pos, spore_size, Color(0.48, 0.92, 0.28, 0.85))
		game.draw_circle(particle_pos + Vector2(-0.8, -0.8), spore_size * 0.4, Color(0.85, 1.0, 0.65, 0.95))


static func _draw_procedural_lightning_bolt(game: Node2D, from: Vector2, to_angle: float, max_dist: float, color: Color, thickness: float, b_seed: int) -> void :
	var l_rng = RandomNumberGenerator.new()
	l_rng.seed = b_seed
	var curr: Vector2 = from
	var main_dir: Vector2 = Vector2.from_angle(to_angle)
	var perp: Vector2 = main_dir.orthogonal()
	var dist_traveled: float = 0.0

	while dist_traveled < max_dist:
		var step_len: float = l_rng.randf_range(25.0, 60.0)
		dist_traveled += step_len
		var clamped_dist: float = minf(dist_traveled, max_dist)
		var jitter: float = l_rng.randf_range(-18.0, 18.0) + sin(game.time_alive * 25.0 + float(b_seed % 7)) * 10.0
		var nxt: Vector2 = from + main_dir * clamped_dist + perp * jitter
		game.draw_line(curr, nxt, color, thickness)

		if l_rng.randf() < 0.38 and dist_traveled < max_dist * 0.8:
			var branch_dir: Vector2 = (main_dir + perp * l_rng.randf_range(-0.8, 0.8)).normalized()
			var branch_end: Vector2 = nxt + branch_dir * l_rng.randf_range(30.0, 70.0)
			game.draw_line(nxt, branch_end, color * Color(1, 1, 1, 0.7), maxf(1.0, thickness - 1.5))

		curr = nxt


static func _draw_network_rewind_visuals(game: Node2D, camera: Vector2) -> void :
	for visual in game.net_remote_rewind_visuals:
		var duration = maxf(0.01, float(visual.get("duration", game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME)))
		var elapsed = float(visual.get("elapsed", 0.0))
		var progress = clampf(elapsed / duration, 0.0, 1.0)
		var fade = clampf(minf(progress * 4.0, float(visual.get("life", 0.0)) / duration * 3.0), 0.0, 1.0)
		var from_pos = Vector2(visual.get("from", Vector2.ZERO))
		var to_pos = Vector2(visual.get("to", from_pos))
		var boss_screen = Vector2(visual.get("boss_pos", game.boss_pos)) - camera
		var color = game._chrono_variant_color(int(visual.get("variant", 0)))
		var current = from_pos.lerp(to_pos, smoothstep(0.0, 1.0, progress))
		var from_screen = from_pos - camera
		var to_screen = to_pos - camera
		var current_screen = current - camera
		game.draw_line(from_screen, to_screen, Color(0.04, 0.11, 0.18, 0.46 * fade), 12.0, true)
		game.draw_line(from_screen, to_screen, Color(color.r, color.g, color.b, 0.62 * fade), 4.0, true)
		game.draw_line(boss_screen, current_screen, Color(0.32, 0.88, 1.0, 0.22 * fade), 2.0, true)
		for echo_index in range(5):
			var echo_t = clampf(progress - float(echo_index) * 0.1, 0.0, 1.0)
			var echo_pos = from_pos.lerp(to_pos, smoothstep(0.0, 1.0, echo_t)) - camera
			var alpha = (0.3 - float(echo_index) * 0.045) * fade
			game._draw_entity_fit(game._player_texture(), echo_pos, Vector2(74, 88), Color(0.42, 0.92, 1.0, alpha), game._should_flip_player_sprite())
		game.draw_circle(current_screen, 44.0 + sin(game.time_alive * 9.0) * 4.0, Color(color.r, color.g, color.b, 0.09 * fade))
		game.draw_arc(current_screen, 47.0, - game.time_alive * 3.0, TAU - game.time_alive * 3.0, 48, Color(color.r, color.g, color.b, 0.72 * fade), 3.0)
		game.draw_arc(current_screen, 58.0, game.time_alive * 2.0, TAU + game.time_alive * 2.0, 54, Color(0.82, 1.0, 1.0, 0.36 * fade), 2.0)
		game._draw_centered("REWIND", current_screen + Vector2(0, -64), 13, Color(0.82, 1.0, 1.0, 0.9 * fade))


static func _draw_teleport_preview(game: Node2D, viewport: Vector2, camera: Vector2) -> void :
	var dest = game._desktop_dash_target() if game.desktop_aim_action == "dash" else game._teleport_destination_from_drag(game.teleport_drag_screen, viewport)
	var a = game.player_pos - camera
	var b = dest - camera
	if game.manifestation_key == "lacerante":
		game.draw_line(a, b, Color(0.25, 0.95, 1.0, 0.72), 8)
		game.draw_line(a, b, Color(1.0, 0.14, 0.95, 0.42), 3)
	else:
		game.draw_arc(a, 18.0, - game.time_alive * 3.0, TAU - game.time_alive * 3.0, 36, Color(0.25, 0.95, 1.0, 0.44), 2.0)
	game.draw_circle(b, 28, Color(0.05, 0.85, 1.0, 0.22))
	game.draw_arc(b, 34, 0, TAU, 48, Color(0.8, 0.15, 1.0, 0.88), 4)
