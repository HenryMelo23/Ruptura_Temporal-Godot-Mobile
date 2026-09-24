extends RefCounted

# Draws through the main CanvasItem; state stays on the host during migration.


static func _draw_phase5_transmute_map_reveal(game: Node2D, map_texture: Texture2D, stage_rect: Rect2) -> void :
	var progress: float = clampf(game.phase5_transmute_timer / maxf(0.01, game.phase5_transmute_duration), 0.0, 1.0)
	var old_tex = game.phase5_transmute_old_tex if game.phase5_transmute_old_tex else map_texture
	var new_tex = game.phase5_transmute_new_tex if game.phase5_transmute_new_tex else map_texture
	game.draw_texture_rect(new_tex, stage_rect, false)
	if old_tex == null:
		return
	var tex_size: Vector2 = old_tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var slice_h = 24.0
	var frontier_base = stage_rect.position.x + stage_rect.size.x * progress
	var t = float(Time.get_ticks_msec()) * 0.001
	var row_count = int(ceil(stage_rect.size.y / slice_h))
	for row in range(row_count):
		var y = stage_rect.position.y + float(row) * slice_h
		var normalized_y = clampf((y - stage_rect.position.y) / maxf(1.0, stage_rect.size.y), 0.0, 1.0)
		var tear_noise = sin(normalized_y * 34.0 + t * 8.0) * 0.026
		tear_noise += sin(normalized_y * 91.0 + progress * 17.0) * 0.014
		tear_noise += sin(normalized_y * 173.0 - t * 4.0) * 0.008
		var frontier_x = clampf(frontier_base + tear_noise * stage_rect.size.x, stage_rect.position.x, stage_rect.end.x)
		var remaining_width = stage_rect.end.x - frontier_x
		if remaining_width <= 0.5:
			continue
		var dst_rect = Rect2(frontier_x, y, remaining_width, minf(slice_h, stage_rect.end.y - y))
		var src_x = ((frontier_x - stage_rect.position.x) / stage_rect.size.x) * tex_size.x
		var src_y = ((y - stage_rect.position.y) / stage_rect.size.y) * tex_size.y
		var src_w = (remaining_width / stage_rect.size.x) * tex_size.x
		var src_h = (dst_rect.size.y / stage_rect.size.y) * tex_size.y
		game.draw_texture_rect_region(old_tex, dst_rect, Rect2(src_x, src_y, src_w, src_h))
		if row % 2 == 0:
			var edge_a = 0.24 + 0.28 * sin(progress * PI)
			var edge_col = game.phase5_transmute_color.lightened(0.22)
			edge_col.a = edge_a
			game.draw_line(Vector2(frontier_x, y), Vector2(frontier_x + 12.0, y + dst_rect.size.y), Color(0.02, 0.0, 0.04, edge_a * 0.8), 4.0)
			game.draw_line(Vector2(frontier_x, y), Vector2(frontier_x + 12.0, y + dst_rect.size.y), edge_col, 2.0)
	var seam_x = clampf(frontier_base, stage_rect.position.x, stage_rect.end.x)
	var pulse = sin(progress * PI)
	for spark in range(24):
		var sy = stage_rect.position.y + fmod(float(spark) * 47.0 + t * 55.0, stage_rect.size.y)
		var sx = seam_x + sin(float(spark) * 3.71 + t * 7.0) * 28.0
		var s_col = game.phase5_transmute_color.lightened(0.35)
		s_col.a = 0.26 * pulse
		game.draw_rect(Rect2(Vector2(round(sx), round(sy)), Vector2(3, 3)), Color(0.02, 0.0, 0.04, s_col.a), true)
		game.draw_rect(Rect2(Vector2(round(sx) + 1.0, round(sy) + 1.0), Vector2(2, 2)), s_col, true)


static func _draw_boss4_lightning_link(game: Node2D, from_world: Vector2, to_world: Vector2, camera: Vector2, color: Color, thickness: float) -> void:
	var direction: Vector2 = to_world - from_world
	if direction.length() <= 0.01:
		return
	var side: Vector2 = direction.normalized().orthogonal()
	var points = PackedVector2Array()
	for i in range(9):
		var t: float = float(i) / 8.0
		var wobble: float = sin(game.time_alive * 19.0 + float(i) * 2.7) * 10.0 * sin(t * PI)
		points.append(from_world.lerp(to_world, t) + side * wobble - camera)
	game.draw_polyline(points, Color(0.18, 0.1, 0.02, 0.65), thickness + 6.0, true)
	game.draw_polyline(points, color, thickness, true)


static func _draw_boss7_flame_waves(game: Node2D, camera: Vector2) -> void:
	for wave in game.boss7_flame_waves:
		if not game._world_point_in_view(Vector2(wave.get("pos", Vector2.ZERO)), camera, float(wave.get("max_radius", 250.0)) + 120.0):
			continue
		var center: Vector2 = Vector2(wave["pos"]) - camera
		var r: float = float(wave.get("radius", 0.0))
		var max_r: float = maxf(1.0, float(wave.get("max_radius", 250.0)))
		var p: float = clampf(r / max_r, 0.0, 1.0)
		var base_alpha: float = (1.0 - p * 0.65)
		var flames: Array = wave.get("flames", [])
		for f in flames:
			var angle: float = float(f["angle"])
			var dist: float = r * float(f.get("dist_mult", 1.0))
			var p_pos: Vector2 = center + Vector2.from_angle(angle) * dist + Vector2(f.get("offset", Vector2.ZERO))
			var size: float = maxf(2.0, float(f.get("size", 10.0)) * (1.0 - p * 0.55))
			game.PhoenixFire.draw_flame(game, p_pos, size * 1.8, size * 3.4, game.time_alive, angle * 5.0, base_alpha, Vector2.UP, game._phase7_visual_budget_enabled())


static func _draw_boss7_ground_indicators(game: Node2D, camera: Vector2) -> void:
	if game.current_phase != 7:
		return
	if game.boss7_state == game.BOSS7_STATE_DIVE_MARK:
		var pos: Vector2 = game.boss7_target_pos - camera
		var p: float = clampf(1.0 - game.boss7_state_timer / 0.9, 0.0, 1.0)
		game.draw_circle(pos, 86.0, Color(1.0, 0.22, 0.05, 0.22 + p * 0.15))
		game.draw_arc(pos, 86.0, 0.0, TAU, 48, Color(1.0, 0.4, 0.08, 0.6), 2.0)
		game.draw_arc(pos, 86.0, -PI * 0.5, -PI * 0.5 + TAU * p, 48, Color(1.0, 0.88, 0.24, 0.95), 4.5)
		game.draw_line(pos + Vector2(-30, 0), pos + Vector2(30, 0), Color(1.0, 0.9, 0.3, 0.8), 2.0)
		game.draw_line(pos + Vector2(0, -30), pos + Vector2(0, 30), Color(1.0, 0.9, 0.3, 0.8), 2.0)
		game.draw_circle(pos, 12.0 * (1.0 - p * 0.5), Color(1.0, 0.95, 0.5, 0.9))

	for bullet in game.enemy_bullets:
		if String(bullet.get("type", "")) != "boss7_dive_fireball":
			continue
		var impact: Vector2 = Vector2(bullet.get("impact_pos", bullet.get("pos", game.boss7_target_pos))) - camera
		var world_pos: Vector2 = Vector2(bullet.get("pos", game.boss7_target_pos))
		var impact_world: Vector2 = Vector2(bullet.get("impact_pos", game.boss7_target_pos))
		var descent: float = clampf(1.0 - world_pos.distance_to(impact_world) / 520.0, 0.0, 1.0)
		var direct_r: float = game.BOSS7_DIVE_FIREBALL_RADIUS * (1.55 + descent * 0.2)
		var wave_r: float = float(bullet.get("wave_radius", 250.0 * game.BOSS7_DIVE_FIREBALL_WAVE_RADIUS_MULT))
		game.draw_circle(impact, direct_r + 20.0 * descent, Color(1.0, 0.12, 0.02, 0.12 + descent * 0.12))
		game.draw_arc(impact, direct_r, 0.0, TAU, 48, Color(1.0, 0.72, 0.16, 0.68 + descent * 0.18), 3.0, true)
		game.draw_arc(impact, wave_r, -game.time_alive * 2.5, TAU - game.time_alive * 2.5, 96, Color(1.0, 0.34, 0.04, 0.22 + descent * 0.14), 3.0, true)
		game.draw_line(impact + Vector2(-18.0, 0.0), impact + Vector2(18.0, 0.0), Color(1.0, 0.88, 0.32, 0.82), 2.0)
		game.draw_line(impact + Vector2(0.0, -18.0), impact + Vector2(0.0, 18.0), Color(1.0, 0.88, 0.32, 0.82), 2.0)

	for atk in game.boss_attacks:
		if atk.get("kind") == game.BOSS7_ATTACK_SKY_FIREBALLS:
			var spots: Array = atk.get("spots", [])
			var age: float = float(atk.get("age", 0.0))
			var warning: float = float(atk.get("warning", 0.85))
			if age < warning:
				var p: float = clampf(age / warning, 0.0, 1.0)
				for spot in spots:
					var spot_pos: Vector2 = Vector2(spot) - camera
					game.draw_circle(spot_pos, 42.0, Color(1.0, 0.18, 0.02, 0.25 * p))
					game.draw_arc(spot_pos, 42.0, 0.0, TAU, 32, Color(1.0, 0.55, 0.1, 0.85), 2.0)
					game.draw_circle(spot_pos, 42.0 * (1.0 - p), Color(1.0, 0.92, 0.28, 0.75))


static func _draw_phase_transition(game: Node2D, viewport: Vector2) -> void :
	game._draw_game(viewport)
	game._ensure_phase_transition_nodes()
	game.phase_transition_overlay_node.visible = true
	game.phase_transition_overlay_node.set_deferred("position", Vector2.ZERO)
	game.phase_transition_overlay_node.set_deferred("size", viewport)
	game.phase_transition_title_label.set_deferred("position", Vector2.ZERO)
	game.phase_transition_title_label.set_deferred("size", viewport)

	var target_phase: int = int(game.pending_phase if game.pending_phase > 0 else game.current_phase)
	var elapsed_time: float = clampf(game.PHASE_TRANSITION_TIME - game.phase_transition_timer, 0.0, game.PHASE_TRANSITION_TIME)

	var phase_names = {
		1: "RUÍNAS CÓSMICAS", 
		2: "ÁRTICO IMPERIAL", 
		3: "CATEDRAL DOS VERMES", 
		4: "CHARCO DOS SAPOS", 
		5: "COLISÃO DE MUNDOS", 
		6: "ABISMO FINAL", 
		7: "CINZAS DA RUPTURA"
	}
	var phase_shaders = {
		1: "res://shaders/transitions/star_dissolve.gdshader", 
		2: "res://shaders/transitions/blizzard_wipe.gdshader", 
		3: "res://shaders/transitions/slime_drip_melt.gdshader", 
		4: "res://shaders/transitions/black_hole_vortex.gdshader", 
		5: "res://shaders/transitions/energy_crack_shatter.gdshader", 
		6: "res://shaders/transitions/worm_devour.gdshader", 
		7: "res://shaders/transitions/slime_drip_melt.gdshader"
	}

	if elapsed_time < game.PHASE_TRANSITION_HOLD_TIME:
		game.phase_transition_title_label.visible = true
		game.phase_transition_title_label.text = String(phase_names.get(target_phase, "FASE %d" % target_phase)).to_upper()
		game.phase_transition_overlay_node.color = Color.BLACK
		game.phase_transition_overlay_node.material = null
	else:
		game.phase_transition_title_label.visible = false
		game.phase_transition_overlay_node.color = Color.WHITE
		var progress: float = clampf((elapsed_time - game.PHASE_TRANSITION_HOLD_TIME) / maxf(0.01, game.PHASE_TRANSITION_WIPE_TIME), 0.0, 1.0)
		var shader_path: String = String(phase_shaders.get(target_phase, phase_shaders[1]))
		var mat = game._get_phase_transition_material(shader_path)
		mat.set_shader_parameter("progress", progress)
		game.phase_transition_overlay_node.material = mat


static func _draw_catalog_phase_route(game: Node2D, items: Array, first_index: int, end_index: int, viewport: Vector2) -> void:
	var visible_centers: Dictionary = {}
	var visible_colors: Dictionary = {}
	for i in range(first_index, end_index):
		var item: Dictionary = Dictionary(items[i])
		var id = String(item.get("id", ""))
		if id == "":
			continue
		var rect = game._catalog_item_rect(i, first_index, viewport)
		visible_centers[id] = rect.get_center()
		visible_colors[id] = Color(item.get("color", Color(0.0, 1.0, 0.82)))
	for i in range(first_index, end_index):
		var item: Dictionary = Dictionary(items[i])
		var id = String(item.get("id", ""))
		if not visible_centers.has(id):
			continue
		var from: Vector2 = visible_centers[id]
		for next_id in Array(item.get("next_ids", [])):
			var target_id = String(next_id)
			if not visible_centers.has(target_id):
				continue
			var to: Vector2 = visible_centers[target_id]
			var accent: Color = visible_colors.get(id, Color(0.0, 1.0, 0.82))
			var pulse: float = 0.48 + 0.18 * sin(Time.get_ticks_msec() * 0.004 + float(i))
			game.draw_line(from, to, Color(accent.r, accent.g, accent.b, 0.28), 9.0, true)
			game.draw_line(from, to, Color(0.0, 1.0, 0.82, pulse), 2.4, true)
			var dir: Vector2 = (to - from).normalized()
			if dir.length() > 0.01:
				var mid: Vector2 = from.lerp(to, 0.58)
				game.draw_line(mid - dir.rotated(0.7) * 10.0, mid + dir * 17.0, Color(0.0, 1.0, 0.82, 0.72), 2.0, true)
				game.draw_line(mid - dir.rotated(-0.7) * 10.0, mid + dir * 17.0, Color(0.0, 1.0, 0.82, 0.72), 2.0, true)
	for id in visible_centers.keys():
		var center: Vector2 = visible_centers[id]
		var color: Color = visible_colors.get(id, Color(0.0, 1.0, 0.82))
		game.draw_circle(center, 8.0, Color(0.0, 0.0, 0.0, 0.62))
		game.draw_arc(center, 12.0, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.72), 2.0)


static func _draw_apolo_phase5_exhibition_world(game: Node2D, camera: Vector2) -> void:
	if not game._apolo_phase5_exhibition_active():
		return
	var target: Vector2 = game.apolo_phase5_exhibition_target - camera
	var player_screen: Vector2 = game.player_pos - camera
	var aim_end: Vector2 = player_screen + game.apolo_phase5_exhibition_aim.normalized() * 150.0
	game.draw_line(player_screen, aim_end, Color(0.2, 0.95, 1.0, 0.58), 2.0)
	game.draw_arc(target, 24.0, 0.0, TAU, 32, Color(0.2, 1.0, 0.62, 0.86), 2.0)
	game.draw_arc(target, 38.0, -game.time_alive * 2.2, -game.time_alive * 2.2 + PI * 1.15, 24, Color(1.0, 0.86, 0.24, 0.72), 2.0)
	game.draw_circle(target, 4.0, Color(0.75, 1.0, 0.82, 0.95))


static func _draw_apolo_phase5_exhibition_overlay(game: Node2D, viewport: Vector2) -> void:
	if not game.apolo_phase5_exhibition_enabled or game.current_phase != 5:
		return
	var width: float = minf(360.0, viewport.x - 32.0)
	var rect: Rect2 = Rect2(Vector2(18.0, 126.0), Vector2(width, 92.0))
	var accent: Color = Color(0.18, 1.0, 0.62, 0.92)
	game.draw_rect(rect, Color(0.015, 0.025, 0.02, 0.72), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.55), false, 2.0)
	var title: String = "APOLO VS UMBRA"
	var manifest_label: String = String(game.MANIFESTATIONS[game.selected_manifestation].get("name", game.manifestation_key)).to_upper()
	var arch_label: String = "ARQ " + str(game.apolo_phase5_exhibition_arch.get("version", "?")) + " H" + str(game.apolo_phase5_exhibition_arch.get("hidden", "?"))
	var damage_ratio: float = clampf(game.apolo_phase5_exhibition_damage_done / maxf(1.0, game.boss_hp_max), 0.0, 1.0)
	game.draw_string(game.font, rect.position + Vector2(14.0, 22.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, game._readable_text_size(13), Color(0.86, 1.0, 0.92, 0.95))
	game.draw_string(game.font, rect.position + Vector2(14.0, 44.0), "%s  %s" % [manifest_label, game.apolo_phase5_exhibition_state], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, game._readable_text_size(11), Color(0.7, 0.94, 1.0, 0.9))
	game.draw_string(game.font, rect.position + Vector2(14.0, 66.0), "DANO %.1f%%  HITS %d  %s" % [damage_ratio * 100.0, game.apolo_phase5_exhibition_hits_taken, arch_label], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, game._readable_text_size(11), Color(1.0, 0.86, 0.28, 0.9))
	var bar_rect: Rect2 = Rect2(rect.position + Vector2(14.0, 76.0), Vector2(rect.size.x - 28.0, 5.0))
	game.draw_rect(bar_rect, Color(0.08, 0.18, 0.14, 0.82), true)
	game.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * damage_ratio, bar_rect.size.y)), accent, true)


static func _draw_boss6_miasma_ultimate(game: Node2D, camera: Vector2) -> void :
	if not game._boss6_miasma_ultimate_active():
		return
	var center = game.WORLD_SIZE * 0.5 - camera
	var inner = game.BOSS6_MIASMA_ULT_INNER_RADIUS
	var outer = game._boss6_miasma_outer_radius()
	var pulse = 0.5 + sin(game.time_alive * 3.7) * 0.5


	game.draw_arc(center, inner, 0.0, TAU, 72, Color(0.22, 0.58, 0.2, 0.35 + pulse * 0.15), 3.0, true)
	game.draw_arc(center, outer, 0.0, TAU, 96, Color(0.35, 0.78, 0.25, 0.28 + pulse * 0.12), 3.0, true)

	for front_index in range(game.BOSS6_MIASMA_ULT_FRONT_COUNT):
		var front: float = game.boss6_miasma_ult_angle + float(front_index) * TAU / float(game.BOSS6_MIASMA_ULT_FRONT_COUNT)
		var start_angle = front - game.BOSS6_MIASMA_ULT_ARC
		var end_angle = front + game.BOSS6_MIASMA_ULT_ARC


		var strand = PackedVector2Array()
		for step in range(16):
			var t = float(step) / 15.0
			var ang = lerpf(start_angle, end_angle, t) + sin(game.time_alive * 1.8 + t * 4.0 + front_index) * 0.05
			var r = lerpf(inner + 15.0, outer - 15.0, t)
			strand.append(center + Vector2.from_angle(ang) * r)


		game.draw_polyline(strand, Color(0.08, 0.24, 0.1, 0.35), 16.0, true)
		game.draw_polyline(strand, Color(0.22, 0.64, 0.2, 0.45), 6.0, true)
		game.draw_polyline(strand, Color(0.62, 0.95, 0.35, 0.65 + pulse * 0.2), 2.2, true)


		for puff in range(8):
			var puff_t = float(puff) / 7.0
			var drift = fposmod(game.time_alive * 0.08 + front_index * 0.33 + puff_t * 0.4, 1.0)
			var puff_angle = lerpf(start_angle, end_angle, puff_t) + sin(game.time_alive * 1.4 + puff + front_index) * 0.04
			var puff_radius = lerpf(inner + 25.0, outer - 25.0, drift)
			var puff_pos = center + Vector2.from_angle(puff_angle) * puff_radius
			game.draw_circle(puff_pos, 8.0 + pulse * 3.0, Color(0.12, 0.42, 0.12, 0.25))
			game.draw_circle(puff_pos, 4.0 + pulse * 2.0, Color(0.48, 0.92, 0.28, 0.7))
			game.draw_circle(puff_pos + Vector2(-1, -1), 1.8, Color(0.85, 1.0, 0.6, 0.85))


static func _draw_boss6_rotating_barrier(game: Node2D, screen_pos: Vector2) -> void :
	if not game._boss6_miasma_ultimate_active():
		return
	var radius = game.BOSS6_BARRIER_RADIUS
	var gap_half = game.BOSS6_BARRIER_GAP_ARC
	for i in range(game.BOSS6_BARRIER_GAP_COUNT):
		var gap_center = game._boss6_barrier_gap_center(i)
		var next_gap = game._boss6_barrier_gap_center((i + 1) % game.BOSS6_BARRIER_GAP_COUNT)
		var start_angle = gap_center + gap_half
		var end_angle = next_gap - gap_half
		if end_angle <= start_angle:
			end_angle += TAU
		game.draw_arc(screen_pos, radius, start_angle, end_angle, 48, Color(0.42, 1.0, 0.18, 0.62), 8.0, true)
		game.draw_arc(screen_pos, radius + 13.0, start_angle + 0.04, end_angle - 0.04, 42, Color(0.78, 1.0, 0.36, 0.28), 3.0, true)
		var gap_tip = screen_pos + Vector2.from_angle(gap_center) * radius
		game.draw_circle(gap_tip, 11.0, Color(0.05, 0.16, 0.04, 0.56))
		game.draw_arc(screen_pos, radius - 26.0, gap_center - gap_half * 0.92, gap_center + gap_half * 0.92, 24, Color(0.14, 0.42, 0.1, 0.34), 2.0, true)


static func _draw_boss_world(game: Node2D, camera: Vector2) -> void :
	if not (game.boss_active and game.boss_hp > 0.0) and not (game.current_phase == 7 and game.boss7_core_active):
		return
	if game.current_phase == 7 and game.boss7_core_active:
		var core_frames: Array = game.textures.get("boss7_core", [])
		var core_tex: Texture2D = null
		if not core_frames.is_empty():
			core_tex = core_frames[int(game.boss_phase) % core_frames.size()]
		if core_tex != null:
			game._draw_dynamic_shadow_fit(core_tex, game.boss7_core_pos - camera + Vector2(0, 16), Vector2(92, 72), false, true, 0.34)
			game._draw_entity_fit(core_tex, game.boss7_core_pos - camera, Vector2(92, 82), Color(1.0, 0.86, 0.62), true)
		var core_pulse = 0.5 + 0.5 * sin(game.time_alive * 9.0)
		game.draw_circle(game.boss7_core_pos - camera, 54.0 + core_pulse * 6.0, Color(1.0, 0.32, 0.05, 0.12))
		game.draw_arc(game.boss7_core_pos - camera, 58.0 + core_pulse * 8.0, -game.time_alive * 2.0, TAU - game.time_alive * 2.0, 72, Color(1.0, 0.66, 0.16, 0.72), 3.0)
		game._draw_bar(game.boss7_core_pos - camera + Vector2(-70, -78), 140.0, game.boss7_core_hp / maxf(1.0, game.boss7_core_hp_max), Color(1.0, 0.52, 0.08))
		game._draw_centered("%.1fs" % game.boss7_core_timer, game.boss7_core_pos - camera + Vector2(0, -104), 18, Color(1.0, 0.86, 0.48))
		return
	var draw_boss_sprite: bool = not (game.current_phase == 2 and game.boss2_ultimate_timer > 0.0 and not game._boss2_ultimate_boss_visible())
	if game.current_phase == 6 and (game.boss_entry_timer > 0.0 or game.boss6_relocating):
		draw_boss_sprite = false
	if game.boss_entry_timer > 0.0 or (game.current_phase == 6 and game.boss6_relocating):
		game._draw_boss_entry(camera)
	if not draw_boss_sprite:
		return
	var boss_tex: Texture2D = game._boss_texture()
	var boss_draw_pos = game._boss_draw_position()
	var boss_draw_size = game._boss_draw_size()
	if game.current_phase == 2:
		game._draw_dynamic_shadow_fit(boss_tex, boss_draw_pos - camera + Vector2(0, 10), Vector2(122, 82), game.boss2_facing_dir < 0.0, true, 0.34)
	else:
		game._draw_dynamic_shadow_fit(boss_tex, game.boss_pos - camera, boss_draw_size, false, true, 0.44)
	var boss_modulate = Color.WHITE
	if game._attack_target_is_boss() and not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		game._draw_attack_target_marker(boss_draw_pos - camera + Vector2(0, 55), 64.0, game.locked_target_kind == "boss")
		boss_modulate = Color(1.0, 0.93, 0.48, 1.0)
	if game.current_phase == 2:
		game._draw_entity_fit_flipped(boss_tex, boss_draw_pos - camera, Vector2(184, 170), game.boss2_facing_dir < 0.0, boss_modulate, true)
	else:
		if game.current_phase == 7:
			game._draw_boss7_fire_aura(boss_tex, boss_draw_pos - camera, boss_draw_size)
		game._draw_entity_fit(boss_tex, boss_draw_pos - camera, boss_draw_size, boss_modulate, true)
	if game.current_phase == 6:
		game._draw_boss6_amber_heart(boss_draw_pos - camera, boss_draw_size)
		game._draw_boss6_smoke_shield(boss_draw_pos - camera, boss_draw_size)
		game._draw_boss6_rotating_barrier(boss_draw_pos - camera)
	if not game._boss3_miasma_hides_boss_bar() and not game._umbra_miasma_hides_boss_bar():
		var boss_bar_width = 168.0 if game.current_phase == 7 else (232.0 if game.current_phase == 6 else (220.0 if game.current_phase == 4 else (66.0 if game.current_phase == 5 else 148.0)))
		var bar_color = Color(1.0, 0.46, 0.08) if game.current_phase == 7 else (Color(1.0, 0.58, 0.16) if game.current_phase == 6 else (Color(0.24, 1.0, 0.42) if game.current_phase == 5 else (Color(1.0, 0.62, 0.08) if game.current_phase == 4 else Color(1.0, 0.12, 0.22))))
		game._draw_bar(boss_draw_pos - camera + Vector2( - boss_bar_width * 0.5, - boss_draw_size.y * 0.54), boss_bar_width, game.boss_hp / game.boss_hp_max, bar_color)
		if game.manifestation_key == "eletrica" and game.boss_eletrica_static_stacks > 0 and game.boss_eletrica_static_timer > 0.0:
			game._draw_eletrica_static_indicator(game, boss_draw_pos - camera + Vector2(0, - boss_draw_size.y * 0.54 - 12), game.boss_eletrica_static_stacks, game.boss_eletrica_static_timer, -1)


static func _draw_boss7_fire_aura(game: Node2D, texture: Texture2D, center: Vector2, size: Vector2) -> void:
	if texture == null:
		return
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 7.4)
	var dive_boost: float = 1.18 if game.boss7_state in [game.BOSS7_STATE_DIVE_PREP, game.BOSS7_STATE_DIVE_WAIT, game.BOSS7_STATE_DIVE_MARK, game.BOSS7_STATE_DIVE_FAKE, game.BOSS7_STATE_DIVE] else 1.0
	var reborn_boost: float = 1.18 if game.boss7_reborn else 1.0
	var layers: int = 2 if game._memory_saver_active() else 3
	for i in range(layers):
		var layer_f: float = float(i)
		var grow: float = (1.08 + layer_f * 0.055 + pulse * 0.026) * dive_boost
		var offset: Vector2 = Vector2(sin(game.time_alive * (2.1 + layer_f) + layer_f * 1.7) * 4.0, -7.0 - layer_f * 5.0 + cos(game.time_alive * (2.9 + layer_f)) * 2.0)
		var alpha: float = (0.2 - layer_f * 0.04) * reborn_boost
		var color: Color = Color(1.0, 0.32 + layer_f * 0.12, 0.04, alpha)
		game._draw_entity_fit(texture, center + offset, size * grow, color, true)
	var ember_count: int = 7 if not game._memory_saver_active() else 4
	for i in range(ember_count):
		var angle: float = game.time_alive * (1.8 + float(i) * 0.13) + float(i) * TAU / float(ember_count)
		var radius: Vector2 = Vector2(size.x * 0.32, size.y * 0.42)
		var ember_pos: Vector2 = center + Vector2(cos(angle) * radius.x, sin(angle * 1.25) * radius.y - size.y * 0.06)
		var ember_alpha: float = 0.32 + 0.24 * sin(game.time_alive * 8.0 + float(i))
		game.draw_circle(ember_pos, 2.4 + pulse * 1.8, Color(1.0, 0.52, 0.12, ember_alpha))


static func _draw_secondary_drain_border(game: Node2D, viewport: Vector2) -> void :
	var ratio: float = clamp(game.secondary_drain_flash_timer / 0.3, 0.0, 1.0)
	var pulse: float = 0.55 + sin(game.time_alive * 38.0) * 0.45
	var alpha: float = (0.2 + pulse * 0.18) * ratio
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.2, 0.0, 0.02, 0.1 * ratio), true)
	var thickness: float = 18.0 + 10.0 * pulse
	var red = Color(1.0, 0.04, 0.1, alpha + 0.1 * ratio)
	var blue = Color(0.35, 0.9, 1.0, alpha * 0.75)
	game.draw_rect(Rect2(0.0, 0.0, viewport.x, thickness), red, true)
	game.draw_rect(Rect2(0.0, viewport.y - thickness, viewport.x, thickness), red, true)
	game.draw_rect(Rect2(0.0, 0.0, thickness, viewport.y), red, true)
	game.draw_rect(Rect2(viewport.x - thickness, 0.0, thickness, viewport.y), red, true)
	for i in range(10):
		var t: float = fmod(game.time_alive * (1.2 + i * 0.04) + i * 0.137, 1.0)
		var edge = i % 4
		var from = Vector2.ZERO
		match edge:
			0:
				from = Vector2(t * viewport.x, thickness * 0.52)
			1:
				from = Vector2(viewport.x - thickness * 0.52, t * viewport.y)
			2:
				from = Vector2((1.0 - t) * viewport.x, viewport.y - thickness * 0.52)
			_:
				from = Vector2(thickness * 0.52, (1.0 - t) * viewport.y)
		var inward = (viewport * 0.5 - from).normalized()
		var mid = from + inward.rotated(sin(game.time_alive * 22.0 + i) * 0.35) * (24.0 + pulse * 16.0)
		var tip = from + inward * (44.0 + pulse * 22.0)
		game.draw_line(from, mid, red, 4.0)
		game.draw_line(mid, tip, blue, 2.0)


static func _draw_phase4_enemy_identity(game: Node2D, enemy: Dictionary, pos: Vector2, size: Vector2) -> void :
	var kind = String(enemy.get("type", ""))
	var pulse = 0.5 + 0.5 * sin(game.time_alive * 5.0 + int(enemy["uid"]) * 0.01)
	var casting = float(enemy.get("nexus_casting", 0.0)) > 0.0
	match kind:
		game.ENEMY_NEXUS_CARTOGRAPHER:
			game.draw_arc(pos, size.x * 0.48, game.time_alive, game.time_alive + PI * 1.55, 30, Color(1.0, 0.34, 0.82, 0.78), 2.5)
			for i in range(4):
				var angle: float = float(i) * PI * 0.5 + game.time_alive * 0.25
				game.draw_line(pos + Vector2.from_angle(angle) * 22.0, pos + Vector2.from_angle(angle + 0.52) * 38.0, Color(0.88, 0.58, 1.0, 0.68), 2.0)
		game.ENEMY_NEXUS_CHRONOPHAGE:
			game.draw_arc(pos, 44.0 + pulse * 5.0, - game.time_alive * 1.8, - game.time_alive * 1.8 + PI * 1.72, 34, Color(1.0, 0.76, 0.2, 0.88), 3.0)
			game.draw_line(pos, pos + Vector2.from_angle( - game.time_alive * 2.3) * 28.0, Color(1.0, 0.94, 0.62), 2.5)
			game.draw_circle(pos, 5.0, Color(0.24, 0.02, 0.18, 0.92))
		game.ENEMY_NEXUS_REFRACTOR:
			var diamond = PackedVector2Array([pos + Vector2(0, -42), pos + Vector2(32, 0), pos + Vector2(0, 42), pos + Vector2(-32, 0), pos + Vector2(0, -42)])
			game.draw_polyline(diamond, Color(0.42, 0.94, 1.0, 0.88), 3.0, true)
			game.draw_line(pos + Vector2(-34, 24), pos + Vector2(36, -26), Color(1.0, 0.28, 0.72, 0.72), 2.0, true)
		game.ENEMY_NEXUS_WEAVER:
			for i in range(6):
				var angle: float = float(i) * TAU / 6.0 + game.time_alive * 0.45
				var p = pos + Vector2.from_angle(angle) * (34.0 + pulse * 5.0)
				var direction = Vector2.from_angle(angle + 0.66)
				game.draw_line(p - direction * 8.0, p + direction * 8.0, Color(0.34, 1.0, 0.72, 0.84), 2.2, true)
		game.ENEMY_NEXUS_ECHO:
			for i in range(3):
				var offset = Vector2(-18.0 - i * 11.0, sin(game.time_alive * 8.0 + i) * 4.0)
				game.draw_circle(pos + offset, 24.0 - i * 4.0, Color(1.0, 0.22, 0.66, 0.12 - i * 0.025))
	if casting:
		game.draw_arc(pos, size.x * 0.58 + pulse * 7.0, 0.0, TAU, 42, Color(1.0, 0.92, 0.48, 0.82), 3.0)


static func _draw_phase_choice_portal(game: Node2D, choice: Dictionary, camera: Vector2, pulse_t: float, life: float) -> void:
	var kind: String = String(choice.get("kind", "red"))
	var label: String = String(choice.get("label", "PORTAL"))
	var pos: Vector2 = Vector2(choice.get("pos", game.phase_fragment.get("pos", game.player_pos))) - camera
	pos.y += sin(life * 2.2 + (1.6 if kind == "umbra" else 0.0)) * 5.0
	var pulse: float = 0.5 + 0.5 * sin(pulse_t * 2.0 + (0.8 if kind == "umbra" else 0.0))
	var primary: Color = Color(1.0, 0.13, 0.08, 0.92)
	var secondary: Color = Color(1.0, 0.62, 0.16, 0.84)
	var fill: Color = Color(0.34, 0.02, 0.02, 0.26)
	if kind == "farm":
		primary = Color(1.0, 0.16, 0.08, 0.92)
		secondary = Color(1.0, 0.58, 0.12, 0.84)
		fill = Color(0.35, 0.02, 0.02, 0.26)
	if kind == "umbra":
		primary = Color(0.14, 1.0, 0.78, 0.92)
		secondary = Color(0.12, 0.62, 1.0, 0.86)
		fill = Color(0.02, 0.18, 0.22, 0.28)
	elif kind == "extract":
		primary = Color(0.95, 1.0, 0.78, 0.94)
		secondary = Color(0.22, 1.0, 0.86, 0.88)
		fill = Color(0.18, 0.22, 0.08, 0.26)
	var radius: float = 42.0 + pulse * 7.0
	game.draw_set_transform(pos, sin(pulse_t * 0.7) * 0.05, Vector2(1.0, 0.46))
	game.draw_circle(Vector2.ZERO, radius * 1.35, Color(primary.r, primary.g, primary.b, 0.12))
	game.draw_circle(Vector2.ZERO, radius, fill)
	for i in range(4):
		var local_r: float = radius * (0.44 + float(i) * 0.14) + sin(pulse_t * 2.8 + float(i)) * 3.0
		var start: float = pulse_t * (0.34 + float(i) * 0.08) + float(i) * 0.9
		game.draw_arc(Vector2.ZERO, local_r, start, start + PI * 1.45, 72, primary if i % 2 == 0 else secondary, 2.2)
	for i in range(10):
		var ang: float = pulse_t * 1.7 + float(i) * TAU / 10.0
		var drop_pos: Vector2 = Vector2.from_angle(ang) * (radius * (0.72 + 0.22 * sin(pulse_t + float(i))))
		game.draw_circle(drop_pos, 2.2 + float(i % 3), secondary if i % 2 == 0 else primary)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if label != "":
		game._draw_centered(label, pos + Vector2(0, -64), 16, primary)
	game._draw_centered("ATRAVESSAR", pos + Vector2(0, 62), 12, Color(0.84, 0.94, 1.0, 0.88))


static func _draw_phase_fragment(game: Node2D, camera: Vector2) -> void :
	var choices: Array = Array(game.phase_fragment.get("choices", []))
	if not choices.is_empty():
		var pulse_t_choices: float = float(game.phase_fragment.get("pulse", 0.0))
		var life_choices: float = float(game.phase_fragment.get("life", 0.0))
		for choice in choices:
			game._draw_phase_choice_portal(choice, camera, pulse_t_choices, life_choices)
		game._draw_centered("ESCOLHA A PROXIMA RUPTURA", Vector2(640, 132), 18, Color(0.92, 0.98, 1.0, 0.96))
		return
	var pos: Vector2 = game.phase_fragment["pos"] - camera
	var pulse_t = float(game.phase_fragment.get("pulse", 0.0))
	var pulse = 0.5 + 0.5 * sin(pulse_t * 2.0)
	var hover = sin(float(game.phase_fragment.get("life", 0.0)) * 2.4) * 7.0
	pos.y += hover
	var outer_r = 38.0 + pulse * 10.0
	var inner_r = 20.0 + pulse * 5.0
	game.draw_circle(pos, outer_r * 1.2, Color(0.06, 0.0, 0.12, 0.28))
	game.draw_circle(pos, outer_r * 0.92, Color(0.45, 0.08, 1.0, 0.12 + pulse * 0.06))
	game.draw_arc(pos, outer_r + 12.0, 0, TAU, 72, Color(0.74, 0.34, 1.0, 0.92), 3)
	game.draw_arc(pos, outer_r * 0.78, 0, TAU, 64, Color(0.22, 0.92, 1.0, 0.82), 2)
	for i in range(6):
		var ang = pulse_t * 1.55 + i * TAU / 6.0
		var shard_pos = pos + Vector2.from_angle(ang) * (outer_r + 12.0 + sin(pulse_t * 3.0 + i) * 5.0)
		var shard_size = 7.0 + float(i % 2) * 2.0
		var shard_points = PackedVector2Array([
			shard_pos + Vector2(0, - shard_size), 
			shard_pos + Vector2(shard_size * 0.58, 0), 
			shard_pos + Vector2(0, shard_size), 
			shard_pos + Vector2( - shard_size * 0.58, 0)
		])
		game.draw_polygon(shard_points, PackedColorArray([Color(0.86, 0.94, 1.0, 0.82)]))
		game.draw_polyline(PackedVector2Array([shard_points[0], shard_points[1], shard_points[2], shard_points[3], shard_points[0]]), Color(0.3, 0.94, 1.0, 0.78), 1.5, true)
	var core_points = PackedVector2Array([
		pos + Vector2(0, - inner_r * 1.35), 
		pos + Vector2(inner_r * 0.58, - inner_r * 0.28), 
		pos + Vector2(inner_r * 0.74, inner_r * 0.48), 
		pos + Vector2(0, inner_r * 1.5), 
		pos + Vector2( - inner_r * 0.74, inner_r * 0.48), 
		pos + Vector2( - inner_r * 0.58, - inner_r * 0.28)
	])
	game.draw_polygon(core_points, PackedColorArray([Color(0.78, 0.9, 1.0, 0.92)]))
	game.draw_polyline(PackedVector2Array([core_points[0], core_points[1], core_points[2], core_points[3], core_points[4], core_points[5], core_points[0]]), Color(1.0, 1.0, 1.0, 0.92), 2.0, true)
	game.draw_circle(pos, inner_r * 0.48, Color(0.18, 0.95, 1.0, 0.86))
	game.draw_circle(pos, inner_r * 0.22, Color(1.0, 1.0, 1.0, 0.94))
	for i in range(4):
		var line_ang = pulse_t * 2.2 + i * PI * 0.5
		game.draw_line(pos + Vector2.from_angle(line_ang) * 8.0, pos + Vector2.from_angle(line_ang) * (outer_r + 4.0), Color(1.0, 1.0, 1.0, 0.54), 1.6)
	game._draw_centered("FRAGMENTO", pos + Vector2(0, -62), 18, Color(0.92, 0.98, 1.0))
	game._draw_centered("TOQUE PARA ATRAVESSAR", pos + Vector2(0, 68), 13, Color(0.58, 0.94, 1.0, 0.92))


static func _draw_phase6_pustule_pools(game: Node2D, camera: Vector2) -> void :
	for pool in game.boss6_lodarian_pools:
		var life = float(pool.get("life", 0.0))
		var max_life = maxf(0.01, float(pool.get("max", 4.0)))
		var fade = clampf(life / max_life, 0.0, 1.0)
		var center = Vector2(pool.get("pos", Vector2.ZERO)) - camera
		var radius = float(pool.get("radius", 78.0))
		var pool_kind = String(pool.get("kind", "lodarian"))
		var base_color = Color(0.58, 1.0, 0.2, 0.48 * fade)
		var fill_color = Color(0.22, 0.44, 0.07, 0.16 * fade)
		if pool_kind == "acid_bloom":
			base_color = Color(0.48, 1.0, 0.12, 0.54 * fade)
			fill_color = Color(0.1, 0.42, 0.05, 0.18 * fade)
		elif pool_kind == "carnage":
			base_color = Color(0.7, 1.0, 0.18, 0.58 * fade)
			fill_color = Color(0.3, 0.56, 0.04, 0.2 * fade)
		game.draw_circle(center, radius, fill_color)
		game.draw_circle(center, radius * 0.52, Color(base_color.r, base_color.g, base_color.b, 0.1 * fade))
		game.draw_arc(center, radius + sin(game.time_alive * 5.0 + float(pool.get("phase", 0.0))) * 5.0, - game.time_alive * 0.8, TAU - game.time_alive * 0.8, 76, base_color, 2.0)
		if pool_kind in ["acid_bloom", "carnage"]:
			for bubble_index in range(8):
				var angle: float = float(bubble_index) * TAU / 8.0 + game.time_alive * (0.38 + float(bubble_index % 3) * 0.08)
				var bubble_pos = center + Vector2.from_angle(angle) * radius * (0.2 + 0.58 * absf(sin(game.time_alive * 0.7 + float(bubble_index))))
				game.draw_circle(bubble_pos, 3.0 + float(bubble_index % 3), Color(0.8, 1.0, 0.28, 0.32 * fade))
	for pool in game.phase6_pustule_pools:
		var life = float(pool.get("life", 0.0))
		var max_life = maxf(0.01, float(pool.get("max", game.PUSTULE_POOL_DURATION)))
		var fade = clampf(life / max_life, 0.0, 1.0)
		var age = max_life - life
		var center = Vector2(pool.get("pos", Vector2.ZERO)) - camera
		var radius = float(pool.get("radius", game.PUSTULE_POOL_RADIUS))
		var phase = float(pool.get("phase", 0.0))
		var pulse = 0.5 + 0.5 * sin(game.time_alive * 5.6 + phase)
		game.draw_circle(center, radius, Color(0.12, 0.28, 0.04, 0.16 * fade))
		game.draw_circle(center, radius * 0.72, Color(0.34, 0.82, 0.12, 0.15 * fade))
		game.draw_arc(center, radius + pulse * 5.0, phase + game.time_alive * 0.42, phase + game.time_alive * 0.42 + TAU, 72, Color(0.62, 1.0, 0.18, 0.62 * fade), 2.4)
		game.draw_arc(center, radius * 0.55, - game.time_alive * 1.1, TAU - game.time_alive * 1.1, 44, Color(0.78, 1.0, 0.22, 0.18 * fade), 1.2)
		var fragments: Array = pool.get("fragments", [])
		for fragment in fragments:
			var delay = float(fragment.get("delay", 0.0))
			var progress = clampf((age - delay) / 0.72, 0.0, 1.0)
			if progress <= 0.0:
				continue
			var eased = 1.0 - pow(1.0 - progress, 2.5)
			var angle = float(fragment.get("angle", 0.0))
			var distance = float(fragment.get("distance", game.PUSTULE_FRAGMENT_MAX_DISTANCE))
			var wobble = Vector2.from_angle(angle + PI * 0.5) * sin(game.time_alive * 10.0 + float(fragment.get("phase", 0.0))) * 4.0 * (1.0 - progress)
			var drop = Vector2.from_angle(angle) * distance * eased + wobble
			var pos = center + drop + Vector2(0, sin(progress * PI) * -22.0)
			var size = float(fragment.get("size", 4.0)) * (1.1 - progress * 0.32)
			var shard_color = Color(0.62, 0.36, 0.14, 0.9 * fade).lerp(Color(0.48, 1.0, 0.14, 0.82 * fade), progress)
			game.draw_circle(pos, size + 2.0, Color(0.04, 0.1, 0.02, 0.28 * fade))
			game.draw_circle(pos, size, shard_color)
			if progress > 0.58:
				var puddle_pos = center + Vector2.from_angle(angle) * distance * minf(1.0, progress + 0.08)
				game.draw_circle(puddle_pos, size * (2.0 + progress), Color(0.36, 0.86, 0.08, 0.18 * fade))
				game.draw_line(pos, puddle_pos, Color(0.42, 0.92, 0.1, 0.34 * fade), maxf(1.0, size * 0.42))
	if game.phase6_pustule_pheromone_timer > 0.0 and game._local_counts_as_player() and game.player_hp > 0 and not game.is_dead:
		var pheromone_fade = clampf(game.phase6_pustule_pheromone_timer / maxf(0.01, game.BOSS6_PUSTULE_PHEROMONE_TIME), 0.0, 1.0)
		var pheromone_center: Vector2 = game.player_pos - camera
		var pheromone_radius = 42.0 + sin(game.time_alive * 7.0) * 3.0
		game.draw_circle(pheromone_center, pheromone_radius, Color(0.42, 0.92, 0.12, 0.055 * pheromone_fade))
		game.draw_arc(pheromone_center, pheromone_radius + 5.0, - game.time_alive * 2.3, TAU - game.time_alive * 2.3, 56, Color(0.74, 1.0, 0.22, 0.38 * pheromone_fade), 1.8)
		for i in range(6):
			var angle: float = game.time_alive * 1.7 + float(i) * TAU / 6.0
			var mote: Vector2 = pheromone_center + Vector2.from_angle(angle) * (pheromone_radius * 0.68 + sin(game.time_alive * 4.0 + float(i)) * 6.0)
			game.draw_circle(mote, 2.2, Color(0.72, 1.0, 0.22, 0.42 * pheromone_fade))


static func _draw_boss6_amber_heart(game: Node2D, center: Vector2, size: Vector2) -> void :
	var hp_ratio: float = game.boss_hp / max(1.0, game.boss_hp_max)
	if hp_ratio > 0.2:
		return
	var intensity: float = clamp(1.0 - hp_ratio / 0.2, 0.0, 1.0)
	var t: float = game.time_alive * (4.0 + intensity * 3.0)
	var heart: Vector2 = center + Vector2(0.0, - size.y * 0.09)
	var pulse: float = 1.0 + sin(t) * 0.1 + intensity * 0.18
	game.draw_circle(heart, 14.0 * pulse, Color(1.0, 0.48, 0.08, 0.24 + intensity * 0.18))
	game.draw_circle(heart, 8.0 * pulse, Color(1.0, 0.68, 0.18, 0.56 + intensity * 0.24))
	game.draw_arc(heart, 23.0 + sin(t * 1.3) * 4.0, t, t + PI * 1.42, 36, Color(1.0, 0.78, 0.24, 0.7), 2.6)
	game.draw_arc(heart, 35.0 + intensity * 10.0, - t * 0.72, - t * 0.72 + PI * 1.12, 42, Color(1.0, 0.24, 0.08, 0.34 + intensity * 0.22), 2.0)
	for i in range(6):
		var angle: float = t * 0.8 + float(i) * TAU / 6.0
		var start: Vector2 = heart + Vector2.from_angle(angle) * (18.0 + intensity * 5.0)
		var finish: Vector2 = heart + Vector2.from_angle(angle) * (34.0 + sin(t + float(i)) * 4.0 + intensity * 14.0)
		game.draw_line(start, finish, Color(1.0, 0.54, 0.12, 0.26 + intensity * 0.22), 1.8)


static func _draw_boss6_fossil_echo(game: Node2D, camera: Vector2) -> void :
	if game.boss6_fossil_echo.is_empty() or float(game.boss6_fossil_echo.get("timer", 0.0)) <= 0.0:
		return
	var pos: Vector2 = game.boss6_fossil_echo.get("pos", game.player_pos)
	var center: Vector2 = pos - camera
	var tex = game._player_texture()
	var profile: Dictionary = game._player_draw_profile()
	var echo_modulate: Color = Color(0.72, 0.48, 1.0, 0.65 + sin(game.time_alive * 8.0) * 0.12)
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 12.0)
	var hp_ratio: float = float(game.boss6_fossil_echo.get("hp", 280.0)) / float(game.boss6_fossil_echo.get("hp_max", 280.0))
	game.draw_circle(center, 38.0 + pulse * 6.0, Color(0.72, 0.48, 1.0, 0.08))
	game.draw_arc(center, 38.0 + pulse * 6.0, 0.0, TAU, 48, Color(0.85, 0.62, 1.0, 0.48), 2.2)
	game._draw_bar(center + Vector2(-30, -58), 60.0, hp_ratio, Color(0.72, 0.48, 1.0))
	if tex != null:
		var flip_h: bool = game._should_flip_player_sprite()
		if bool(profile.get("preserve_height", false)):
			game._draw_entity_by_height_rotated(tex, center + profile.get("offset", Vector2.ZERO), float(profile.get("height", game.PLAYER_DRAW_LACERAR_HEIGHT)), 0.0, echo_modulate, flip_h)
		elif bool(profile.get("fit_aspect", false)):
			game._draw_entity_fit_flipped(tex, center + profile.get("offset", Vector2.ZERO), profile.get("size", Vector2(64, 64)), flip_h, echo_modulate, true)
		else:
			game._draw_entity_stretched_rotated(tex, center + profile.get("offset", Vector2.ZERO), profile.get("size", Vector2(64, 64)), 0.0, echo_modulate, flip_h)


static func _draw_boss6_necro_erosion(game: Node2D, camera: Vector2) -> void :
	if game.current_phase != 6 or not game.boss6_necro_erosion_active or game.boss6_necro_erosion_timer <= 0.0:
		return
	var center: Vector2 = game.boss_pos - camera
	var radius: float = game.boss6_necro_erosion_radius
	var color: Color = Color(0.9, 0.15, 0.25, 0.52 + 0.18 * sin(game.time_alive * 9.0))
	game.draw_arc(center, radius, 0.0, TAU, 128, color, 4.0)
	game.draw_arc(center, radius + 15.0, 0.0, TAU, 128, Color(color.r, color.g, color.b, 0.22), 8.0)
	if game._is_player_calcified():
		var viewport_size: Vector2 = game.get_viewport_rect().size
		var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 12.0)
		game.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.9, 0.15, 0.25, 0.08 + pulse * 0.06), false, 12.0)
		game._draw_centered("CALCIFICADO - SAIA DO NEVOEIRO", Vector2(viewport_size.x * 0.5, viewport_size.y * 0.35), 24, Color(0.9, 0.15, 0.25))


static func _draw_phase5_transmute_particles(game: Node2D, camera: Vector2) -> void :
	if not game.phase5_transmute_active:
		return
	var count: int = game.phase5_transmute_particles.size()
	for i in range(count):
		var p: Dictionary = game.phase5_transmute_particles[i]
		var life_ratio: float = clampf(float(p["life"]) / maxf(0.01, float(p["max_life"])), 0.0, 1.0)
		var p_pos: Vector2 = Vector2(p["pos"]) - camera
		var p_size: float = float(p["size"]) * life_ratio
		var col: Color = game.phase5_transmute_color
		col.a = life_ratio * 0.8
		game.draw_circle(p_pos, p_size, col)
		game.draw_arc(p_pos, p_size * 1.3, 0.0, TAU, 12, Color(1.0, 1.0, 1.0, col.a * 0.5), 1.5)


static func _draw_boss3_miasma_clones(game: Node2D, camera: Vector2) -> void :
	if not game._boss3_miasma_active() or game.boss3_miasma_variant != 1:
		return
	var frames = game.textures.get("boss3", [])
	if not frames is Array or frames.is_empty():
		return
	var texture: Texture2D = frames[int(game.boss_phase) % frames.size()]
	var cycle: float = 1.0 - clamp(game.boss3_miasma_clone_timer / game.BOSS3_MIASMA_CLONE_SWAP, 0.0, 1.0)
	var base_alpha: float = 0.18 + sin(cycle * PI) * 0.72
	for i in range(game.boss3_miasma_clone_positions.size()):
		var world_pos = Vector2(game.boss3_miasma_clone_positions[i])
		var screen_pos = world_pos - camera
		var flicker: float = clamp(base_alpha + sin(game.time_alive * 9.0 + i * 1.8) * 0.1, 0.08, 0.88)
		game._draw_dynamic_shadow_fit(texture, screen_pos, Vector2(184, 170), false, true, 0.22 * flicker)
		game._draw_entity_fit(texture, screen_pos, Vector2(184, 170), Color(0.92, 1.0, 0.28, flicker), true)
		game.draw_arc(screen_pos, 70.0 + sin(game.time_alive * 4.0 + i) * 5.0, 0.0, TAU, 38, Color(0.78, 1.0, 0.16, 0.24 * flicker), 2.0)


static func _draw_boss3_miasma_clouds(game: Node2D, camera: Vector2) -> void :
	for cloud in game.boss3_miasma_clouds:
		var pos = Vector2(cloud.get("pos", game.boss_pos)) - camera
		var radius: float = float(cloud.get("radius", game.BOSS3_MIASMA_CLOUD_RADIUS))
		var life_ratio: float = clampf(float(cloud.get("life", 0.0)) / max(0.01, float(cloud.get("max", game.BOSS3_MIASMA_CLOUD_DURATION))), 0.0, 1.0)
		var phase: float = float(cloud.get("phase", 0.0))
		var pulse: float = 0.5 + 0.5 * sin(phase * 1.8)
		var alpha: float = (0.2 + life_ratio * 0.35)
		game.draw_circle(pos, radius * (0.95 + pulse * 0.1), Color(0.06, 0.22, 0.08, alpha * 0.35))
		game.draw_circle(pos, radius * 0.72, Color(0.14, 0.44, 0.16, alpha * 0.45))
		game.draw_circle(pos + Vector2(sin(phase) * 6.0, cos(phase * 0.7) * 4.0), radius * 0.45, Color(0.32, 0.78, 0.28, alpha * 0.5))
		game.draw_arc(pos, radius, 0.0, TAU, 48, Color(0.38, 0.84, 0.26, alpha * 0.55), 2.0, true)
		for i in range(4):
			var angle = phase + float(i) * TAU / 4.0
			var mote = pos + Vector2.from_angle(angle) * (radius * (0.3 + pulse * 0.2))
			game.draw_circle(mote, 3.5, Color(0.68, 0.98, 0.42, alpha * 0.75))


static func _draw_boss3_miasma_overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void :
	if not game._boss3_miasma_active():
		return
	var openness = 0.74
	if game.boss3_miasma_variant == 1:
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.72, 0.62, 0.02, 0.2), true)
	elif game.boss3_miasma_variant == 4:
		var progress: float = float(game.boss3_miasma_qte_taps) / max(1.0, float(game.boss3_miasma_qte_required))
		openness = lerp(0.035, 0.96, smoothstep(0.0, 1.0, progress))
		var elapsed: float = game.boss3_miasma_qte_elapsed
		var blink_phase: float = fmod(max(0.0, elapsed), 1.5)
		if blink_phase < 0.22:
			var blink: float = abs(blink_phase - 0.11) / 0.11
			openness *= clamp(blink, 0.04, 1.0)
	game._draw_miasma_eye_mask(viewport, openness)
	if game.boss3_miasma_variant == 2:
		var player_screen: Vector2 = game.player_pos - camera
		game._draw_miasma_darkness_fog(player_screen, viewport)
	if game.boss3_miasma_variant == 4:
		var center = viewport * 0.5
		var qte_progress: float = float(game.boss3_miasma_qte_taps) / max(1.0, float(game.boss3_miasma_qte_required))
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		var radius: float = 42.0 + pulse * 18.0 + qte_progress * 18.0
		game._draw_miasma_faith_link(camera)
		game._draw_miasma_qte_cheese_gunk(viewport, openness)
		game.draw_circle(center, radius - 4.0, Color(0.015, 0.025, 0.006, 0.82))
		game.draw_circle(center, radius, Color(0.64, 0.92, 0.1, 0.1 + pulse * 0.08))
		game.draw_arc(center, radius, - PI * 0.5, - PI * 0.5 + TAU * qte_progress, 64, Color(0.82, 1.0, 0.2, 0.96), 6.0, true)
		game.draw_arc(center, radius + 9.0, 0.0, TAU, 64, Color(0.74, 0.9, 0.14, 0.34 + pulse * 0.28), 2.0, true)
		game._draw_centered("ESPACO" if game._uses_desktop_ui() else "TOQUE", center + Vector2(0, 7), 18, Color(0.94, 1.0, 0.68))
		game._draw_centered("%d / %d" % [game.boss3_miasma_qte_taps, game.boss3_miasma_qte_required], center + Vector2(0, 88), 22, Color(0.88, 1.0, 0.34))
		if game.boss3_miasma_qte_time_left > 0.0:
			game._draw_centered("%.1fs" % game.boss3_miasma_qte_time_left, center + Vector2(0, 116), 18, Color(1.0, 0.46, 0.2))
		else:
			var overtime: float = max(0.0, game.boss3_miasma_qte_elapsed - game.BOSS3_MIASMA_QTE_DURATION)
			game._draw_centered("FE CORROMPIDA +%.0fs" % overtime, center + Vector2(0, 116), 18, Color(0.74, 1.0, 0.16))
		if game.boss3_miasma_tutorial_seen and game.boss3_miasma_qte_tutorial > 0.0:
			game._draw_centered(("APERTE ESPACO PARA ABRIR OS OLHOS" if game._uses_desktop_ui() else "APERTE COMO SE SUA VIDA DEPENDESSE"), center + Vector2(0, -112), 24, Color(1.0, 0.92, 0.3))
	else:
		game._draw_centered("MIASMA DA VIDA  %.0fs" % ceil(game.boss3_miasma_timer), Vector2(viewport.x * 0.5, 116), 18, Color(0.82, 1.0, 0.3, 0.92))


static func _draw_phase3_environment(game: Node2D, camera: Vector2) -> void :
	if game.current_phase != 3:
		return
	for zone in game.phase3_miasma_zones:
		var fade = clamp(float(zone["life"]) / max(0.01, float(zone["max"])), 0.0, 1.0)
		var p = Vector2(zone["pos"]) - camera
		var radius = float(zone["radius"])
		game.draw_circle(p, radius, Color(0.06, 0.22, 0.08, 0.18 * fade))
		game.draw_circle(p, radius * 0.65, Color(0.14, 0.44, 0.16, 0.22 * fade))
		game.draw_arc(p, radius, 0, TAU, 48, Color(0.38, 0.84, 0.26, 0.48 * fade), 2.0, true)
		for i in range(5):
			var ang = game.time_alive * 0.7 + float(zone["phase"]) + i * TAU / 5.0
			game.draw_circle(p + Vector2.from_angle(ang) * radius * 0.55, 3.5, Color(0.68, 0.98, 0.38, 0.65 * fade))
	for cheese in game.phase3_cheeses:
		var p = Vector2(cheese["pos"]) - camera
		var pulse = 1.0 + sin(game.time_alive * 7.0 + int(cheese["uid"]) % 5) * 0.08
		var tex: Texture2D = game.textures.get("boss3_cheese")
		game._draw_dynamic_shadow_fit(tex, p, Vector2(58, 48) * pulse, false, false, 0.38)
		game._draw_entity_fit(tex, p, Vector2(58, 48) * pulse, Color.WHITE)
		var cheese_selected = (game.attack_lock_selecting and game.attack_lock_candidate_kind == "cheese" and game.attack_lock_candidate_uid == int(cheese["uid"])) or (game.locked_target_kind == "cheese" and game.locked_target_uid == int(cheese["uid"]))
		if cheese_selected:
			game._draw_attack_target_marker(p + Vector2(0, 16), 30.0, game.locked_target_kind == "cheese")
		var c = Color(1.0, 0.88, 0.2) if bool(cheese["true"]) else Color(0.66, 1.0, 0.24)
		game.draw_arc(p, 35.0, 0, TAU, 32, Color(c.r, c.g, c.b, 0.76), 2.0)
		game._draw_bar(p + Vector2(-27, -38), 54, float(cheese["hp"]) / float(cheese["max_hp"]), c)
		if bool(cheese.get("ritual", false)):
			game._draw_centered("RITUAL", p + Vector2(0, -50), 13, Color(1.0, 0.42, 0.2))


static func _draw_phase4_environment(game: Node2D, camera: Vector2) -> void :
	if game.current_phase != 4:
		return
	var viewport = game.get_viewport_rect().size
	if game.boss4_instability > 0.0:
		var unstable_alpha = clampf(game.boss4_instability / 100.0, 0.0, 1.0)
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.42, 0.02, 0.64, 0.035 * unstable_alpha), true)
		for i in range(int(4 + unstable_alpha * 8.0)):
			var seed = float(i) * 41.7
			var a = Vector2(fposmod(seed * 5.0 + game.time_alive * 42.0, viewport.x), fposmod(seed * 2.7 + sin(game.time_alive + seed) * 90.0, viewport.y))
			var b = a + Vector2.from_angle(seed + game.time_alive * 0.8) * (42.0 + unstable_alpha * 82.0)
			game.draw_line(a, b, Color(0.86, 0.34, 1.0, 0.1 + unstable_alpha * 0.18), 1.4 + unstable_alpha * 1.8, true)
	game._draw_phase4_enemy_hazards(camera)
	game._draw_boss4_specials(camera)
	for zone in game.phase4_null_zones:
		var life_ratio: float = clamp(float(zone.get("life", 0.0)) / max(0.01, float(zone.get("max", game.BOSS4_NULL_ZONE_DURATION))), 0.0, 1.0)
		var pos = Vector2(zone["pos"]) - camera
		var radius = float(zone.get("radius", 92.0))
		var phase = float(zone.get("phase", 0.0))
		var vortex_frames: Array = game.textures.get("boss4_vortex", [])
		var vortex: Texture2D = vortex_frames[int(phase) % vortex_frames.size()] if not vortex_frames.is_empty() else null
		game.draw_circle(pos, radius * 1.18, Color(0.08, 0.0, 0.16, 0.24 * life_ratio))
		game._draw_entity_fit(vortex, pos, Vector2.ONE * radius * 2.25, Color(0.76, 0.58, 1.0, 0.82 * life_ratio))
		game.draw_arc(pos, radius, - phase, TAU - phase, 60, Color(0.92, 0.7, 1.0, 0.88 * life_ratio), 3.0)
		for i in range(8):
			var angle = phase * 0.7 + i * TAU / 8.0
			var outer = pos + Vector2.from_angle(angle) * radius * 1.15
			game.draw_line(outer, pos + Vector2.from_angle(angle + 0.38) * radius * 0.36, Color(0.76, 0.36, 1.0, 0.24 * life_ratio), 2.0)
	for planet in game.phase4_planets:
		var pos = Vector2(planet["pos"]) - camera
		var phase = float(planet.get("phase", 0.0))
		var frames: Array = game.textures.get("boss4_planet", [])
		var texture: Texture2D = frames[int(phase) % frames.size()] if not frames.is_empty() else null
		var pulse = 1.0 + sin(phase * 1.8) * 0.06
		game._draw_dynamic_shadow_fit(texture, pos + Vector2(0, 15), Vector2(104, 104) * pulse, false, true, 0.34)
		game.draw_circle(pos, 62.0, Color(0.72, 0.18, 1.0, 0.16))
		game._draw_entity_fit(texture, pos, Vector2(104, 104) * pulse, Color.WHITE, true)
		game.draw_arc(pos, 58.0 + sin(phase * 2.4) * 4.0, phase, phase + PI * 1.55, 42, Color(1.0, 0.74, 0.22, 0.86), 3.0)
		game._draw_bar(pos + Vector2(-45, -64), 90.0, float(planet.get("hp", 0.0)) / max(1.0, float(planet.get("max_hp", game.BOSS4_PLANET_HP))), Color(0.88, 0.34, 1.0))
	for meteor in game.boss4_meteorites:
		var meteor_world: Vector2 = Vector2(meteor.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(meteor_world, camera, 180.0):
			continue
		var pos: Vector2 = meteor_world - camera
		var phase: float = float(meteor.get("phase", 0.0))
		var radius: float = game.BOSS4_METEOR_RADIUS * (1.0 + 0.05 * sin(phase))
		var impact_progress: float = clampf(float(meteor.get("age", 0.0)) / maxf(0.1, float(meteor.get("warning", game.BOSS4_METEOR_WARNING))), 0.0, 1.0)
		if not bool(meteor.get("impacted", false)):
			game.draw_circle(pos, radius * (1.2 + impact_progress), Color(1.0, 0.54, 0.12, 0.2))
			game.draw_line(pos - Vector2(0, 240), pos, Color(1.0, 0.86, 0.36, 0.44), 8.0, true)
		else:
			var rock = PackedVector2Array()
			for i in range(9):
				var angle: float = float(i) * TAU / 9.0 + phase * 0.08
				rock.append(pos + Vector2.from_angle(angle) * radius * (0.84 + 0.18 * sin(phase + i * 1.9)))
			game.draw_circle(pos, radius * 1.32, Color(1.0, 0.32, 0.08, 0.16))
			game.draw_colored_polygon(rock, Color(0.22, 0.14, 0.16, 0.98))
			var rock_outline: PackedVector2Array = rock.duplicate()
			rock_outline.append(rock[0])
			game.draw_polyline(rock_outline, Color(1.0, 0.68, 0.22, 0.9), 3.0, true)
			for crater in range(3):
				var crater_pos: Vector2 = pos + Vector2.from_angle(phase + crater * 2.1) * radius * 0.42
				game.draw_circle(crater_pos, 7.0 + crater * 2.0, Color(0.06, 0.04, 0.08, 0.76))
			if bool(meteor.get("draining", false)):
				game._draw_boss4_lightning_link(game.boss_pos, meteor_world, camera, Color(1.0, 0.84, 0.24, 0.92), 3.0)
				game.draw_arc(pos, radius * 1.3, phase, phase + PI * 1.35, 36, Color(1.0, 0.2, 0.64, 0.8), 4.0)
			else:
				game.draw_arc(pos, radius * 1.24, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(meteor.get("ground_age", 0.0)) / game.BOSS4_METEOR_ARM_TIME, 0.0, 1.0), 42, Color(1.0, 0.76, 0.24, 0.92), 3.0)
			game._draw_bar(pos + Vector2(-radius, -radius - 18.0), radius * 2.0, float(meteor.get("hp", 0.0)) / maxf(1.0, float(meteor.get("max_hp", game.BOSS4_METEOR_HP))), Color(0.32, 0.9, 1.0) if not bool(meteor.get("draining", false)) else Color(1.0, 0.28, 0.58))


static func _draw_phase5_environment(game: Node2D, camera: Vector2) -> void :
	if game.current_phase != 5:
		return
	for tele in game.phase5_telegraphs:
		var to = Vector2(tele.get("to", game.boss_pos)) - camera
		var arrived = bool(tele.get("arrived", false))
		var c = Color(0.28, 1.0, 0.5, 0.85 if bool(tele.get("real", true)) else 0.35)

		if not arrived:
			var curr_pos = Vector2(tele.get("pos", game.boss_pos)) - camera
			var pulse = 0.5 + 0.5 * sin(game.time_alive * 12.0 + float(tele.get("phase", 0.0)))


			game.draw_circle(curr_pos, 18.0 + pulse * 6.0, Color(0.06, 0.28, 0.12, 0.35))
			game.draw_arc(curr_pos, 22.0 + pulse * 4.0, game.time_alive * 6.0, game.time_alive * 6.0 + PI * 1.4, 32, c, 2.5, true)
			game.draw_arc(curr_pos, 14.0 - pulse * 3.0, - game.time_alive * 8.0, - game.time_alive * 8.0 + PI * 1.2, 24, Color(0.72, 1.0, 0.45, 0.65), 2.0, true)


			game.draw_circle(curr_pos, 10.0, Color(0.12, 0.48, 0.18, 0.8))
			game.draw_circle(curr_pos, 6.0, Color(0.55, 1.0, 0.38, 0.95))
			game.draw_circle(curr_pos + Vector2(-1, -1), 2.5, Color(0.9, 1.0, 0.75, 0.95))


			game.draw_arc(to, 24.0 + pulse * 6.0, 0.0, TAU, 36, Color(c.r, c.g, c.b, 0.4), 1.8, true)
			game.draw_circle(to, 6.0, Color(c.r, c.g, c.b, 0.2))
		else:

			var p_life = float(tele.get("portal_life", 0.0))
			var p_max = maxf(0.01, float(tele.get("portal_max", 0.35)))
			var p_ratio = 1.0 - clampf(p_life / p_max, 0.0, 1.0)
			var portal_r = 16.0 + p_ratio * 48.0
			var alpha = clampf(1.0 - p_ratio, 0.0, 1.0)

			game.draw_circle(to, portal_r, Color(0.03, 0.12, 0.05, 0.5 * alpha))
			game.draw_arc(to, portal_r, p_ratio * TAU * 2.0, p_ratio * TAU * 2.0 + PI * 1.5, 48, Color(0.35, 1.0, 0.48, 0.85 * alpha), 4.0, true)
			game.draw_arc(to, portal_r * 0.65, - p_ratio * TAU * 2.5, - p_ratio * TAU * 2.5 + PI * 1.3, 36, Color(0.75, 1.0, 0.6, 0.7 * alpha), 2.5, true)
			game.draw_circle(to, portal_r * 0.3, Color(0.85, 1.0, 0.7, 0.9 * alpha))
	for hazard in game.phase5_hazards:
		var kind = String(hazard.get("kind", ""))
		match kind:
			"vortex":
				var pos = Vector2(hazard["pos"]) - camera
				var max_life = float(hazard.get("max", game.BOSS5_VORTEX_DURATION))
				var life = float(hazard.get("life", max_life))
				var elapsed = max_life - life
				var warning_dur = float(hazard.get("warning", game.BOSS5_VORTEX_WARNING))
				var radius_aviso = float(hazard.get("radius_aviso", 150.0))
				var radius_succao = float(hazard.get("radius_succao", 850.0))
				var radius_dano = float(hazard.get("radius_dano", 150.0))
				if elapsed < warning_dur:
					var prog: float = elapsed / maxf(0.01, warning_dur)
					var pulse_alpha: float = 0.2 + sin(game.time_alive * 10.0) * 0.1
					game.draw_circle(pos, radius_aviso, Color(0.54, 0.17, 0.89, pulse_alpha))
					game.draw_arc(pos, radius_aviso, 0, TAU, 64, Color(1.0, 0.0, 0.5, 0.85), 3.0)
					var ring_radius: float = radius_aviso * (1.0 - prog)
					if ring_radius > 2.0:
						game.draw_arc(pos, ring_radius, 0, TAU, 48, Color(1.0, 1.0, 1.0, 0.9), 2.0)
						game.draw_circle(pos, ring_radius, Color(1.0, 1.0, 1.0, 0.08 * prog))
				else:
					var fade: float = clampf(life / 0.5, 0.0, 1.0)
					var spin: float = game.time_alive * 2.5
					game.draw_arc(pos, radius_succao * 0.4, spin * 0.5, spin * 0.5 + TAU, 64, Color(0.4, 0.15, 0.7, 0.12 * fade), 1.5)
					for i in range(6):
						var r: float = radius_dano + (radius_succao * 0.35 - radius_dano) * (float(i) / 5.0)
						var angle_offset: float = spin * (1.2 + float(i) * 0.2)
						game.draw_arc(pos, r, angle_offset, angle_offset + TAU * 0.65, 48, Color(0.58, 0.2, 0.9, 0.35 * fade), 2.0)
						var inward_r: float = r * (1.0 - fmod(game.time_alive * 0.8 + float(i) * 0.15, 1.0))
						if inward_r > 10.0:
							game.draw_arc(pos, inward_r, - angle_offset, - angle_offset + PI * 0.5, 32, Color(0.35, 0.85, 1.0, 0.45 * fade), 1.5)
					game.draw_circle(pos, radius_dano, Color(0.18, 0.04, 0.32, 0.35 * fade))
					game.draw_arc(pos, radius_dano, - spin * 1.5, TAU - spin * 1.5, 64, Color(1.0, 0.1, 0.6, 0.9 * fade), 3.5)
					game.draw_circle(pos, 45.0, Color(0.05, 0.02, 0.1, 0.95 * fade))
					game.draw_circle(pos, 22.0, Color(0.0, 0.0, 0.0, 1.0 * fade))
					var core_pulse: float = 8.0 + sin(game.time_alive * 12.0) * 4.0
					game.draw_circle(pos, core_pulse, Color(0.4, 0.95, 1.0, 0.9 * fade))
					game.draw_arc(pos, 55.0, spin * 3.0, spin * 3.0 + PI * 1.2, 36, Color(0.3, 0.9, 1.0, 0.8 * fade), 2.5)
			"prison":
				var pos = Vector2(hazard["pos"]) - camera
				var max_life: float = float(hazard.get("max", game.BOSS5_PRISON_DURATION))
				var life: float = float(hazard.get("life", max_life))
				var elapsed: float = max_life - life
				var warning_dur: float = float(hazard.get("warning", game.BOSS5_PRISON_WARNING))
				var r_max: float = float(hazard.get("radius_max", 180.0))
				if elapsed < warning_dur:
					var prog: float = elapsed / maxf(0.01, warning_dur)
					var pulse_alpha: float = 0.22 + sin(game.time_alive * 9.0) * 0.1
					game.draw_circle(pos, r_max, Color(0.0, 0.47, 1.0, pulse_alpha))
					game.draw_arc(pos, r_max, 0, TAU, 64, Color(0.0, 1.0, 1.0, 0.85), 3.0)
					var ring_radius: float = r_max * (1.0 - prog)
					if ring_radius > 2.0:
						game.draw_arc(pos, ring_radius, 0, TAU, 48, Color(1.0, 1.0, 1.0, 0.95), 2.0)
						game.draw_circle(pos, ring_radius, Color(0.7, 0.95, 1.0, 0.12 * prog))
					for i in range(12):
						var flake_angle: float = float(i) * (TAU / 12.0) + game.time_alive * 0.6
						var flake_dist: float = r_max * (0.25 + 0.65 * fmod(game.time_alive * 0.35 + float(i) * 0.083, 1.0))
						var flake_pos: Vector2 = pos + Vector2(cos(flake_angle), sin(flake_angle)) * flake_dist
						game.draw_rect(Rect2(flake_pos - Vector2(2, 2), Vector2(4, 4)), Color(0.8, 0.95, 1.0, 0.8), true)
				else:
					var radius_atual: float = float(hazard.get("radius_atual", 45.0))
					var fade: float = clampf(life / 0.5, 0.0, 1.0)
					var spin: float = game.time_alive * 2.2
					game.draw_circle(pos, radius_atual, Color(0.05, 0.3, 0.8, 0.28 * fade))
					var r_core: float = radius_atual * 0.6 + sin(game.time_alive * 8.0) * 6.0
					game.draw_circle(pos, r_core, Color(0.0, 0.31, 1.0, 0.45 * fade))
					game.draw_circle(pos, r_core * 0.7, Color(0.0, 0.62, 1.0, 0.65 * fade))
					game.draw_circle(pos, r_core * 0.3, Color(0.58, 0.94, 1.0, 0.9 * fade))
					var num_segments: int = 20
					var step_ang: float = TAU / float(num_segments)
					for i in range(num_segments):
						var seg_ang: float = spin + float(i) * step_ang
						var seg_r: float = radius_atual + sin(game.time_alive * 12.0 + float(i)) * 3.0
						var seg_pos: Vector2 = pos + Vector2(cos(seg_ang), sin(seg_ang)) * seg_r
						game.draw_circle(seg_pos, 3.0, Color(0.78, 0.98, 1.0, 0.85 * fade))
					for i in range(16):
						var p_angle: float = - spin * 1.5 + float(i) * (TAU / 16.0)
						var p_r: float = radius_atual * (0.2 + 0.75 * fmod(game.time_alive * 0.5 + float(i) * 0.0625, 1.0))
						var p_pos: Vector2 = pos + Vector2(cos(p_angle), sin(p_angle)) * p_r
						if i % 3 == 0:
							game.draw_rect(Rect2(p_pos - Vector2(2, 2), Vector2(4, 4)), Color(1.0, 1.0, 1.0, 0.9 * fade), true)
						else:
							game.draw_rect(Rect2(p_pos - Vector2(3, 3), Vector2(6, 6)), Color(0.6, 0.92, 1.0, 0.85 * fade), true)
							game.draw_rect(Rect2(p_pos - Vector2(1, 4), Vector2(2, 8)), Color(1.0, 1.0, 1.0, 0.95 * fade), true)
			"miasma", "siphon":
				var pos = Vector2(hazard.get("pos", game.boss_pos)) - camera
				var radius = float(hazard.get("radius", 160.0))
				var color = Color(0.22, 1.0, 0.34, 0.18) if kind == "siphon" else Color(0.16, 0.92, 0.18, 0.16)
				game.draw_circle(pos, radius, color)
				game.draw_arc(pos, radius * (0.92 + sin(game.time_alive * 5.0) * 0.04), 0, TAU, 60, Color(0.34, 1.0, 0.44, 0.65), 3.0)
			"discharge":
				var start: Vector2 = Vector2(hazard.get("pos", game.boss_pos)) - camera
				var dir: Vector2 = Vector2(hazard.get("dir", Vector2.RIGHT)).normalized()
				var base_angle: float = dir.angle()
				var max_radius: float = float(hazard.get("radius", 380.0))
				var half_abertura: float = float(hazard.get("abertura", 0.9)) * 0.5
				var max_life: float = float(hazard.get("max", 2.4))
				var life: float = float(hazard.get("life", 0.0))
				var elapsed: float = max_life - life
				var warning_dur: float = float(hazard.get("warning", 0.6))
				var is_active: bool = elapsed >= warning_dur

				if not is_active:
					var pts: Array[Vector2] = [start]
					for k in range(16):
						var a: float = base_angle - half_abertura + (float(k) / 15.0) * (half_abertura * 2.0)
						pts.append(start + Vector2.from_angle(a) * max_radius)
					game.draw_polygon(pts, [Color(1.0, 0.8, 0.15, 0.18)])
					game.draw_arc(start, max_radius, base_angle - half_abertura, base_angle + half_abertura, 24, Color(1.0, 0.9, 0.25, 0.7), 3.0)
					game.draw_line(start, start + Vector2.from_angle(base_angle - half_abertura) * max_radius, Color(1.0, 0.9, 0.25, 0.6), 2.0)
					game.draw_line(start, start + Vector2.from_angle(base_angle + half_abertura) * max_radius, Color(1.0, 0.9, 0.25, 0.6), 2.0)
				else:
					var base_seed: int = int(hazard.get("seed", 12345)) + int(game.time_alive * 24.0)
					var colors: Array[Color] = [
						Color(1.0, 0.92, 0.2), 
						Color(0.75, 0.35, 1.0), 
						Color(1.0, 1.0, 1.0), 
						Color(1.0, 0.85, 0.1), 
						Color(0.65, 0.25, 0.95), 
						Color(1.0, 1.0, 1.0)
					]

					var fill_pts: Array[Vector2] = [start]
					for k in range(16):
						var a: float = base_angle - half_abertura + (float(k) / 15.0) * (half_abertura * 2.0)
						fill_pts.append(start + Vector2.from_angle(a) * max_radius)
					game.draw_polygon(fill_pts, [Color(0.55, 0.2, 0.9, 0.12)])

					for b in range(6):
						var t_angle: float = lerpf(base_angle - half_abertura + 0.04, base_angle + half_abertura - 0.04, float(b) / 5.0)
						var bolt_color: Color = colors[b % colors.size()]
						var thickness: float = 2.0 + float((b * 3 + int(game.time_alive * 10.0)) % 6)
						var bolt_seed: int = base_seed + b * 1337
						game._draw_procedural_lightning_bolt(start, t_angle, max_radius, bolt_color, thickness, bolt_seed)
			"thorns":
				var segs: Array = hazard.get("segments", [])
				var phase_str: String = String(hazard.get("phase", "crescimento"))
				var curr_w: float = float(hazard.get("current_width", 10.0))
				var growth_progress: float = clampf(float(hazard.get("growth_progress", 1.0)), 0.0, 1.0)

				for seg in segs:
					var world_a: Vector2 = Vector2(seg["a"])
					var world_b: Vector2 = Vector2(seg["b"])
					var world_tip: Vector2 = world_a.lerp(world_b, growth_progress)
					var a: Vector2 = world_a - camera
					var b: Vector2 = world_tip - camera
					var seg_vec: Vector2 = b - a
					var seg_len: float = seg_vec.length()
					if seg_len <= 1.0:
						continue
					var seg_dir: Vector2 = seg_vec.normalized()
					var perp: Vector2 = seg_dir.orthogonal()
					var num_seg: int = max(2, int(seg_len / 15.0))
					var points1: Array[Vector2] = []
					var points2: Array[Vector2] = []

					for i in range(num_seg + 1):
						var dist: float = minf(float(i) * 15.0, seg_len)
						var base_pt: Vector2 = a + seg_dir * dist
						var wave1: float = sin(float(i) * 0.5 + game.time_alive * 3.0) * (curr_w * 0.35)
						var wave2: float = cos(float(i) * 0.7 - game.time_alive * 2.0) * (curr_w * 0.35)
						points1.append(base_pt + perp * wave1)
						points2.append(base_pt + perp * wave2)

					for i in range(1, points1.size()):
						var fade: float = 1.0 - float(i) / float(num_seg)
						var vine_w: float = maxf(2.0, floor(curr_w * 0.15 * fade))
						game.draw_line(points1[i - 1] + Vector2(2.0, 2.0), points1[i] + Vector2(2.0, 2.0), Color(0.02, 0.04, 0.02, 0.92), vine_w + 2.0)
						game.draw_line(points1[i - 1], points1[i], Color(0.08, 0.30, 0.08, 0.98), vine_w + 1.0)
						game.draw_line(points2[i - 1], points2[i], Color(0.20, 0.48, 0.14, 0.94), maxf(1.5, vine_w))
						game.draw_line(points1[i - 1], points1[i], Color(0.40, 0.70, 0.24, 0.36), 1.5)

						if phase_str == "expansao":
							var hash_v: int = (i * 37) % 100
							if hash_v < 35:
								var side: float = 1.0 if hash_v < 17 else -1.0
								var thorn_angle: float = seg_dir.angle() + (PI / 2.5 * side)
								var thorn_size: float = 9.0 + curr_w * 0.20
								var thorn_base: Vector2 = points1[i]
								var tip: Vector2 = thorn_base + Vector2.from_angle(thorn_angle) * thorn_size
								var base1: Vector2 = thorn_base + Vector2.from_angle(thorn_angle + 1.2) * vine_w
								var base2: Vector2 = thorn_base + Vector2.from_angle(thorn_angle - 1.2) * vine_w
								game.draw_polygon([tip, base1, base2], [Color(0.82, 0.92, 0.52, 0.96)])
			"sopro_artico":
				var spears: Array = hazard.get("spears", [])
				for s_item in spears:
					if not s_item is Dictionary:
						continue
					var sp: Dictionary = s_item
					if bool(sp.get("hit", false)):
						continue
					var s_pos: Vector2 = Vector2(sp.get("pos", game.boss_pos)) - camera
					var s_ang: float = float(sp.get("angle", 0.0))
					var dir: Vector2 = Vector2.from_angle(s_ang)
					var perp: Vector2 = dir.orthogonal()
					var tip: Vector2 = s_pos + dir * 18.0
					var tail: Vector2 = s_pos - dir * 10.0
					var p1: Vector2 = tail + perp * 4.0
					var p2: Vector2 = tail - perp * 4.0
					game.draw_polygon([tip, p1, p2], [Color(0.35, 0.85, 1.0, 0.85)])
					game.draw_line(s_pos - dir * 8.0, tip, Color(1.0, 1.0, 1.0, 0.95), 2.0)
			"umbra_overload_laser":
				var start: Vector2 = (game.WORLD_SIZE * 0.5) - camera
				var fase_str: String = String(hazard.get("fase", "caminhando"))
				var curr_ang: float = float(hazard.get("angle", 0.0))
				var num_beams: int = int(hazard.get("num_beams", 2))

				if fase_str in ["esfera_carga_1", "esfera_recolher_1", "esfera_recolher_2"]:
					var st: float = float(hazard.get("stage_timer", 1.0))
					var r_sphere: float = 50.0 + sin(game.time_alive * 20.0) * 8.0
					if fase_str == "esfera_carga_1":
						r_sphere = lerpf(65.0, 25.0, clampf(st / 1.2, 0.0, 1.0))
					game.draw_circle(start, r_sphere, Color(0.95, 0.1, 0.15, 0.6))
					game.draw_arc(start, r_sphere + 8.0, 0, TAU, 48, Color(1.0, 0.8, 0.2, 0.85), 3.0)
				elif fase_str in ["laser_4_aviso", "laser_6_aviso"]:
					game.draw_circle(start, 35.0, Color(0.95, 0.1, 0.15, 0.4))
					var step_ang: float = TAU / float(num_beams)
					var warn_pulse: float = 0.4 + sin(game.time_alive * 25.0) * 0.35
					for b in range(num_beams):
						var b_ang: float = curr_ang + float(b) * step_ang
						var b_dir: Vector2 = Vector2.from_angle(b_ang)
						game.draw_line(start, start + b_dir * 1400.0, Color(1.0, 0.2, 0.15, warn_pulse), 3.0)
				elif fase_str in ["laser_2", "laser_4", "laser_6_ccw", "laser_6_cw"]:
					var width: float = 38.0 if num_beams == 2 else (32.0 if num_beams == 4 else 26.0)
					var step_ang: float = TAU / float(num_beams)

					game.draw_circle(start, 50.0 + sin(game.time_alive * 20.0) * 8.0, Color(1.0, 0.3, 0.1, 0.7))

					for b in range(num_beams):
						var b_ang: float = curr_ang + float(b) * step_ang
						var b_dir: Vector2 = Vector2.from_angle(b_ang)
						var end_pt: Vector2 = start + b_dir * 1400.0

						game.draw_line(start, end_pt, Color(0.4, 0.02, 0.05, 0.85), width)
						game.draw_line(start, end_pt, Color(0.95, 0.1, 0.15, 0.95), width * 0.6)
						game.draw_line(start, end_pt, Color(1.0, 0.5, 0.1, 0.95), width * 0.35)
						game.draw_line(start, end_pt, Color(1.0, 0.98, 0.92, 1.0), width * 0.15)

						for s in range(5):
							var t_spark: float = fmod(float(s) * 0.2 + game.time_alive * 3.0, 1.0)
							var spark_pos: Vector2 = start.lerp(end_pt, t_spark)
							var offset: Vector2 = b_dir.orthogonal() * (sin(game.time_alive * 30.0 + float(s) * 4.0) * width * 0.35)
							game.draw_circle(spark_pos + offset, 3.5, Color(1.0, 0.85, 0.2, 0.9))
	for rat in game.phase5_rats:
		var pos: Vector2 = Vector2(rat.get("pos", game.boss_pos)) - camera
		var life: float = float(rat.get("life", 5.0))
		var max_life: float = float(rat.get("max_life", 5.0))
		var is_flashing: bool = life <= 2.0 and fmod(game.time_alive * 12.0, 0.4) < 0.2
		var body_color: Color = Color(1.0, 0.2, 0.25, 0.95) if is_flashing else Color(0.18, 0.58, 0.95, 0.95)
		var outline_color: Color = Color(1.0, 0.7, 0.7, 0.95) if is_flashing else Color(0.6, 0.88, 1.0, 0.95)

		var pulse: float = 1.0 + sin(float(rat.get("phase", 0.0))) * 0.1

		game.draw_circle(pos + Vector2(0, 10), 14.0 * pulse, Color(0.0, 0.0, 0.0, 0.35))

		game.draw_circle(pos, 15.0 * pulse, body_color)
		game.draw_arc(pos, 15.0 * pulse, 0, TAU, 24, outline_color, 2.5)

		game.draw_circle(pos + Vector2(4, -3), 2.5, Color(1.0, 0.95, 0.8, 0.95))


		var bar_w: float = 24.0
		var bar_h: float = 4.0
		var bar_pos: Vector2 = pos + Vector2(-12.0, -22.0)
		game.draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.08, 0.08, 0.12, 0.75), true)
		var fill_w: float = bar_w * clampf(life / maxf(0.01, max_life), 0.0, 1.0)
		game.draw_rect(Rect2(bar_pos, Vector2(fill_w, bar_h)), Color(0.2, 0.8, 1.0, 0.9), true)
	if game.boss_active and game.boss_hp > 0.0:
		game._draw_centered("MENTE: %s" % game.boss5_mental_state, Vector2(game.get_viewport_rect().size.x * 0.5, 128.0), 17, Color(0.58, 1.0, 0.66, 0.92))


static func _draw_boss4_specials(game: Node2D, camera: Vector2) -> void :
	if game.boss4_gravity_timer > 0.0 and game.boss4_gravity_dir.length() > 0.01:
		var viewport: Vector2 = game.get_viewport_rect().size
		var dir: Vector2 = game.boss4_gravity_dir.normalized()
		var side: Vector2 = dir.orthogonal()
		for i in range(12):
			var lane: float = (float(i) - 5.5) * 72.0
			var center: Vector2 = viewport * 0.5 + side * lane
			game.draw_line(center - dir * 500.0, center + dir * 500.0, Color(0.42, 1.0, 0.82, 0.07), 10.0, true)
			var tip: Vector2 = center + dir * (80.0 + sin(game.time_alive * 4.0 + i) * 40.0)
			game.draw_polyline(PackedVector2Array([tip - dir * 26.0 + side * 14.0, tip, tip - dir * 26.0 - side * 14.0]), Color(0.6, 1.0, 0.88, 0.46), 2.0, false)
		game._draw_centered("GRAVIDADE %.0fs" % ceil(game.boss4_gravity_timer), Vector2(viewport.x * 0.5, 174.0), 16, Color(0.66, 1.0, 0.88, 0.9))
	if game.boss4_vampire_timer > 0.0 and game.petro_active:
		var p: Vector2 = game.petro_pos - camera
		var b: Vector2 = game.boss_pos - camera
		game.draw_line(p, b, Color(0.12, 0.0, 0.22, 0.48), 16.0, true)
		game.draw_line(p, b, Color(0.88, 0.2, 1.0, 0.8), 4.0, true)
		for i in range(5):
			var t = fposmod(game.time_alive * 0.85 + float(i) * 0.2, 1.0)
			game.draw_circle(p.lerp(b, t), 5.0 + sin(game.time_alive * 9.0 + i) * 2.0, Color(1.0, 0.54, 1.0, 0.76))
	if not game.boss4_prison.is_empty():
		var center = Vector2(game.boss4_prison.get("pos", game.player_pos)) - camera
		var phase = float(game.boss4_prison.get("phase", 0.0))
		var fragments = int(game.boss4_prison.get("fragments", 0))
		game.draw_circle(center, 82.0, Color(0.18, 0.0, 0.3, 0.22))
		game.draw_arc(center, 82.0, - phase, TAU - phase, 72, Color(0.9, 0.52, 1.0, 0.9), 3.2)
		for i in range(max(0, fragments)):
			var ang: float = phase + float(i) * TAU / max(1.0, float(fragments))
			var fp: Vector2 = center + Vector2.from_angle(ang) * 78.0
			game.draw_circle(fp, 10.0, Color(0.82, 0.58, 1.0, 0.84))
			game.draw_arc(fp, 15.0, - game.time_alive * 3.0, TAU - game.time_alive * 3.0, 24, Color(1.0, 0.82, 1.0, 0.86), 2.0)
	if not game.boss4_clone.is_empty():
		var pos = Vector2(game.boss4_clone.get("pos", game.player_pos)) - camera
		var tex = game._player_texture()
		game._draw_dynamic_shadow_fit(tex, pos + Vector2(0, 10), Vector2(82, 92), false, true, 0.28)
		game._draw_entity_fit(tex, pos, Vector2(82, 92), Color(0.36, 1.0, 0.9, 0.66), true)
		game._draw_bar(pos + Vector2(-40, -58), 80.0, clampf(float(game.boss4_clone.get("hp", 0.0)) / max(1.0, 260.0 + game.player_damage * 0.75), 0.0, 1.0), Color(0.28, 1.0, 0.88))
	if game.boss4_ultimate_active:
		game._draw_boss4_ultimate(camera)
	var viewport2 = game.get_viewport_rect().size
	var bar_w = 240.0
	var origin = Vector2(viewport2.x * 0.5 - bar_w * 0.5, 44.0)
	game.draw_rect(Rect2(origin - Vector2(4, 4), Vector2(bar_w + 8, 18)), Color(0.03, 0.0, 0.08, 0.56), true)
	game.draw_rect(Rect2(origin, Vector2(bar_w * clampf(game.boss4_instability / 100.0, 0.0, 1.0), 10.0)), Color(0.82, 0.24, 1.0, 0.82), true)
	game.draw_rect(Rect2(origin, Vector2(bar_w, 10.0)), Color(1.0, 0.7, 0.18, 0.72), false, 1.5)
	game._draw_centered("INSTABILIDADE DA RUPTURA %.0f%%" % game.boss4_instability, origin + Vector2(bar_w * 0.5, -11.0), 13, Color(1.0, 0.86, 0.42, 0.92))


static func _draw_boss4_ultimate(game: Node2D, camera: Vector2) -> void :
	var viewport = game.get_viewport_rect().size
	var center = game.WORLD_SIZE * 0.5 - camera
	var progress: float = 1.0 - game.boss4_ultimate_timer / max(0.01, game.BOSS4_ULTIMATE_DURATION)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.06, 0.2 + progress * 0.14), true)
	for i in range(8):
		var radius: float = 120.0 + progress * 420.0 + float(i) * 44.0 + sin(game.time_alive * 2.4 + i) * 12.0
		game.draw_arc(center, radius, - game.time_alive * (1.0 + i * 0.08), TAU - game.time_alive * (1.0 + i * 0.08), 128, Color(0.32, 1.0, 0.92, 0.24 - i * 0.018), 4.0)
		game.draw_arc(center, radius * 0.72, game.time_alive * (1.4 + i * 0.05), TAU + game.time_alive * (1.4 + i * 0.05), 96, Color(0.92, 0.24, 1.0, 0.18 - i * 0.012), 2.6)
	if game.boss4_gravity_dir.length() > 0.01:
		var dir = game.boss4_gravity_dir.normalized()
		for i in range(5):
			var p = center - dir * (220.0 + float(i) * 92.0) + dir.orthogonal() * sin(game.time_alive * 3.0 + float(i)) * 54.0
			game.draw_polyline(PackedVector2Array([p - dir * 22.0 + dir.orthogonal() * 14.0, p + dir * 18.0, p - dir * 22.0 - dir.orthogonal() * 14.0]), Color(0.7, 1.0, 0.9, 0.66), 3.0, false)
		game._draw_centered("GRAVIDADE: %s" % game._boss4_gravity_dir_label(dir), Vector2(viewport.x * 0.5, 122.0), 16, Color(0.7, 1.0, 0.9, 0.92))
	game._draw_centered("TEMPESTADE DE RAIOS %.0fs" % ceil(game.boss4_ultimate_timer), Vector2(viewport.x * 0.5, 92.0), 22, Color(1.0, 0.86, 0.28, 0.98))


static func _draw_phase4_enemy_hazards(game: Node2D, camera: Vector2) -> void :
	var viewport: Vector2 = game.get_viewport_rect().size
	for hazard in game.phase4_enemy_hazards:
		var kind = String(hazard.get("kind", ""))
		var age: float = float(hazard.get("age", 0.0))
		var fade: float = clampf(float(hazard.get("life", 0.0)) / max(0.01, float(hazard.get("max", 1.0))), 0.0, 1.0)
		match kind:
			"rift":
				var a: Vector2 = Vector2(hazard["a"]) - camera
				var b: Vector2 = Vector2(hazard["b"]) - camera
				var rift_warning = float(hazard.get("warning", game.PHASE4_RIFT_WARNING))
				var active = age >= rift_warning
				var color = Color(1.0, 0.18, 0.72, 0.92 * fade) if active else Color(0.76, 0.48, 1.0, 0.46)
				game.draw_line(a, b, Color(0.16, 0.0, 0.24, 0.62 * fade), 18.0 if active else 8.0, true)
				game.draw_line(a, b, color, 5.0 if active else 2.0, true)
				for i in range(9):
					var t = float(i) / 8.0
					var p = a.lerp(b, t) + (b - a).normalized().orthogonal() * sin(game.time_alive * 13.0 + i * 2.2) * (7.0 if active else 3.0)
					game.draw_circle(p, 3.5 if active else 2.0, color)
			"chrono":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard["radius"])
				var chrono_warning = float(hazard.get("warning", game.PHASE4_CHRONO_WARNING))
				var progress = clampf(age / maxf(0.01, chrono_warning), 0.0, 1.0)
				game.draw_circle(pos, radius * progress, Color(1.0, 0.54, 0.08, 0.06 + progress * 0.08))
				game.draw_arc(pos, radius * progress, 0.0, TAU, 64, Color(1.0, 0.78, 0.2, 0.82 * fade), 3.0)
				for i in range(8):
					var angle: float = - game.time_alive * 1.8 + float(i) * TAU / 8.0
					game.draw_line(pos + Vector2.from_angle(angle) * radius * progress * 0.74, pos + Vector2.from_angle(angle) * radius * progress, Color(1.0, 0.86, 0.38, 0.58 * fade), 2.0)
			"hostile_prism":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var size = 38.0 + sin(game.time_alive * 7.0 + float(hazard.get("phase", 0.0))) * 5.0
				var points = PackedVector2Array([pos + Vector2(0, - size), pos + Vector2(size * 0.72, 0), pos + Vector2(0, size), pos + Vector2( - size * 0.72, 0), pos + Vector2(0, - size)])
				game.draw_colored_polygon(PackedVector2Array([points[0], points[1], points[2], points[3]]), Color(0.12, 0.82, 1.0, 0.16 * fade))
				game.draw_polyline(points, Color(1.0, 0.3, 0.74, 0.9 * fade), 3.0, true)
				game.draw_arc(pos, size + 12.0, game.time_alive * 2.0, game.time_alive * 2.0 + PI * 1.5, 30, Color(0.38, 0.94, 1.0, 0.72 * fade), 2.0)
			"vector":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard["radius"])
				game.draw_circle(pos, radius, Color(0.08, 0.72, 0.52, 0.075 * fade))
				game.draw_arc(pos, radius, 0.0, TAU, 72, Color(0.24, 1.0, 0.72, 0.62 * fade), 2.0)
				for i in range(12):
					var angle: float = float(i) * TAU / 12.0 + game.time_alive * 0.22 * float(hazard.get("spin", 1.0))
					var p = pos + Vector2.from_angle(angle) * radius * 0.68
					var arrow = Vector2.from_angle(angle + deg_to_rad(38.0) * float(hazard.get("spin", 1.0)))
					game.draw_line(p - arrow * 10.0, p + arrow * 10.0, Color(0.54, 1.0, 0.82, 0.72 * fade), 2.4, true)
			"echo":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard["radius"])
				var warning: float = float(hazard["warning"])
				var progress = clampf(age / warning, 0.0, 1.0)
				game.draw_circle(pos, radius * progress, Color(1.0, 0.12, 0.56, 0.08 + progress * 0.1))
				game.draw_arc(pos, radius, - PI * 0.5, - PI * 0.5 + TAU * progress, 42, Color(1.0, 0.42, 0.76, 0.88 * fade), 3.0)
				if bool(hazard.get("triggered", false)):
					game.draw_circle(pos, radius * 1.16, Color(1.0, 0.72, 0.24, 0.26 * fade))
			"boss4_pulse":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard.get("radius", game.BOSS4_PULSE_RADIUS))
				var pulse_warning = float(hazard.get("warning", game.BOSS4_PULSE_WARNING))
				var progress = clampf(age / maxf(0.01, pulse_warning), 0.0, 1.0)
				game.draw_circle(pos, radius * progress, Color(1.0, 0.64, 0.14, 0.07))
				game.draw_arc(pos, radius * progress, 0.0, TAU, 96, Color(1.0, 0.72, 0.22, 0.88 * fade), 5.0)
				game.draw_arc(pos, radius * progress * 0.72, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 80, Color(0.76, 0.3, 1.0, 0.52 * fade), 3.0)
			"boss4_fissure":
				var a: Vector2 = Vector2(hazard["a"]) - camera
				var b: Vector2 = Vector2(hazard["b"]) - camera
				var fissure_warning = float(hazard.get("warning", game.PHASE4_RIFT_WARNING))
				var active = age >= fissure_warning
				var color = Color(1.0, 0.22, 0.72, 0.92 * fade) if active else Color(0.92, 0.66, 1.0, 0.44)
				game.draw_line(a, b, Color(0.1, 0.0, 0.2, 0.72 * fade), 20.0 if active else 8.0, true)
				game.draw_line(a, b, color, 5.5 if active else 2.2, true)
				if bool(hazard.get("teleport", false)):
					for i in range(5):
						var t = float(i) / 4.0
						game.draw_circle(a.lerp(b, t), 4.0 + sin(game.time_alive * 6.0 + i) * 1.6, Color(0.36, 1.0, 0.92, 0.72 * fade))
			"boss4_vector":
				var center: Vector2 = Vector2(hazard["pos"]) - camera
				var dir: Vector2 = Vector2(hazard["dir"]).normalized()
				var side = dir.orthogonal()
				var vector_warning = float(hazard.get("warning", game.BOSS4_VECTOR_WARNING))
				var active = age >= vector_warning
				var width = 22.0 if bool(hazard.get("elite", false)) else 16.0
				var a = center - dir * 760.0
				var b = center + dir * 760.0
				game.draw_line(a, b, Color(0.0, 0.08, 0.12, 0.62 * fade), width + 12.0, true)
				game.draw_line(a, b, Color(0.28, 1.0, 0.82, (0.84 if active else 0.38) * fade), width if active else 4.0, true)
				for i in range(7):
					var p = center + dir * (float(i) - 3.0) * 150.0
					game.draw_polyline(PackedVector2Array([p - dir * 24.0 + side * 14.0, p, p - dir * 24.0 - side * 14.0]), Color(1.0, 0.84, 0.28, 0.72 * fade), 2.0, false)
			"boss4_fragment":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard.get("radius", 58.0))
				var fragment_warning = float(hazard.get("warning", game.BOSS4_FRAGMENT_WARNING))
				var progress = clampf(age / maxf(0.01, fragment_warning), 0.0, 1.0)
				game.draw_circle(pos, radius, Color(1.0, 0.52, 0.18, 0.08 + progress * 0.1))
				game.draw_arc(pos, radius, - PI * 0.5, - PI * 0.5 + TAU * progress, 54, Color(1.0, 0.76, 0.24, 0.9 * fade), 3.0)
				if bool(hazard.get("triggered", false)):
					var fall = pos + Vector2(0, -220.0 * max(0.0, fade - 0.2))
					game.draw_line(fall, pos, Color(1.0, 0.84, 0.36, 0.58 * fade), 8.0, true)
					game.draw_circle(pos, radius * 0.72, Color(1.0, 0.66, 0.22, 0.24 * fade))
					if bool(hazard.get("barrier", false)):
						game.draw_rect(Rect2(pos - Vector2(radius * 0.62, radius * 0.32), Vector2(radius * 1.24, radius * 0.64)), Color(0.32, 0.18, 0.05, 0.46 * fade), true)
			"boss4_collapse":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard.get("radius", 110.0))
				game.draw_circle(pos, radius, Color(0.22, 0.0, 0.3, 0.18 * fade))
				for i in range(11):
					var angle = float(i) * TAU / 11.0 + sin(game.time_alive * 2.0 + i) * 0.18
					var inner = pos + Vector2.from_angle(angle) * radius * 0.15
					var outer = pos + Vector2.from_angle(angle + sin(i) * 0.16) * radius
					game.draw_line(inner, outer, Color(0.94, 0.34, 1.0, 0.3 * fade), 2.0 + fposmod(float(i), 3.0), true)
			"boss4_gravity_well":
				var pos: Vector2 = Vector2(hazard.get("pos", game.boss_pos)) - camera
				var radius: float = float(hazard.get("radius", game.BOSS4_GRAVITY_WELL_RADIUS))
				var warning: float = float(hazard.get("warning", game.BOSS4_GRAVITY_WELL_WARNING))
				var active = age >= warning
				var progress = clampf(age / maxf(0.01, warning), 0.0, 1.0)
				var vortex_alpha = (0.18 if active else 0.08 + progress * 0.08) * fade
				game.draw_circle(pos, radius * (0.5 + progress * 0.5), Color(0.08, 0.04, 0.2, vortex_alpha))
				game.draw_arc(pos, radius, game.time_alive * 2.4, TAU + game.time_alive * 2.4, 96, Color(0.46, 1.0, 0.9, (0.78 if active else 0.44) * fade), 4.0)
				game.draw_arc(pos, radius * 0.62, - game.time_alive * 3.2, TAU - game.time_alive * 3.2, 72, Color(1.0, 0.42, 1.0, (0.46 if active else 0.26) * fade), 3.0)
				for i in range(10):
					var angle: float = game.time_alive * (1.8 + float(i) * 0.06) + float(i) * TAU / 10.0 + float(hazard.get("phase", 0.0))
					var p = pos + Vector2.from_angle(angle) * radius * (0.24 + 0.55 * fposmod(float(i) * 0.17 + progress, 1.0))
					game.draw_circle(p, 3.5 + sin(game.time_alive * 5.0 + float(i)) * 1.0, Color(0.86, 1.0, 0.92, 0.56 * fade))
			"boss4_gravity_laser":
				var segment = game._boss4_gravity_laser_segment(hazard)
				var a: Vector2 = Vector2(segment[0]) - camera
				var b: Vector2 = Vector2(segment[1]) - camera
				var warning: float = float(hazard.get("warning", game.BOSS4_GRAVITY_LASER_WARNING))
				var progress = clampf(age / maxf(0.01, warning), 0.0, 1.0)
				var active = age >= warning
				var width: float = float(hazard.get("width", game.BOSS4_GRAVITY_LASER_WIDTH))
				var glow = width * (1.6 if active else 0.76)
				game.draw_line(a, b, Color(0.02, 0.0, 0.12, 0.7 * fade), glow + 12.0, true)
				game.draw_line(a, b, Color(0.86, 0.24, 1.0, (0.2 + progress * 0.22) * fade), glow, true)
				game.draw_line(a, b, Color(0.4, 1.0, 0.94, (0.42 if active else 0.26 + progress * 0.28) * fade), 4.0 + progress * 7.0, true)
				if active:
					game.draw_line(a, b, Color(1.0, 0.96, 0.62, 0.82 * fade), maxf(5.0, width * 0.34), true)
					for i in range(8):
						var p = a.lerp(b, fposmod(game.time_alive * 0.92 + float(i) * 0.13, 1.0))
						game.draw_circle(p, 3.0 + float(i % 3), Color(0.92, 1.0, 1.0, 0.62 * fade))
			"boss4_bubble":
				var bubble_world: Vector2 = Vector2(hazard.get("pos", hazard.get("start", game.player_pos)))
				var bubble_pos: Vector2 = bubble_world - camera
				var delay: float = float(hazard.get("delay", 0.0))
				var warning: float = float(hazard.get("warning", game.BOSS4_SECONDARY_WARNING))
				var bubble_age: float = age - delay
				var bubble_phase: float = float(hazard.get("phase", 0.0))
				if bubble_age < 0.0:
					var lane_start: Vector2 = Vector2(hazard.get("start", bubble_world)) - camera
					game.draw_line(lane_start - Vector2(26, 0), lane_start + Vector2(26, 0), Color(0.38, 0.86, 1.0, 0.24 * fade), 3.0, true)
				elif bubble_age < warning:
					var lane_start: Vector2 = Vector2(hazard.get("start", bubble_world)) - camera
					var lane_end: Vector2 = Vector2(hazard.get("end", bubble_world)) - camera
					var lane_progress: float = clampf(bubble_age / maxf(0.01, warning), 0.0, 1.0)
					var telegraph_pos: Vector2 = lane_start.lerp(lane_end, lane_progress)
					game.draw_arc(telegraph_pos, 34.0 + sin(game.time_alive * 16.0) * 4.0, 0.0, TAU, 28, Color(1.0, 0.34, 0.28, 0.8 * fade), 3.0)
					game._draw_centered("!", telegraph_pos, 26, Color(1.0, 0.78, 0.48, 0.92 * fade))
				else:
					game.draw_circle(bubble_pos, 38.0 + sin(game.time_alive * 8.0 + bubble_phase) * 3.0, Color(0.22, 0.74, 1.0, 0.16 * fade))
					game.draw_circle(bubble_pos, 27.0, Color(0.24, 0.72, 1.0, 0.72 * fade))
					game.draw_arc(bubble_pos, 30.0, bubble_phase, bubble_phase + PI * 1.45, 34, Color(0.86, 1.0, 1.0, 0.92 * fade), 3.0)
					game.draw_circle(bubble_pos - Vector2(8, 9), 7.0, Color(0.92, 1.0, 1.0, 0.56 * fade))
			"boss4_ultimate_ray":
				var ray_pos: Vector2 = Vector2(hazard.get("pos", game.player_pos)) - camera
				var ray_warning: float = float(hazard.get("warning", game.BOSS4_ULTIMATE_RAY_WARNING))
				var ray_active: bool = age >= ray_warning
				var ray_progress: float = clampf(age / maxf(0.01, ray_warning), 0.0, 1.0)
				if not ray_active:
					game.draw_circle(ray_pos, game.BOSS4_ULTIMATE_RAY_RADIUS * (0.82 + ray_progress * 0.24), Color(0.96, 0.08, 0.18, 0.18 * fade))
					game.draw_arc(ray_pos, game.BOSS4_ULTIMATE_RAY_RADIUS * (0.9 + ray_progress * 0.22), 0.0, TAU, 42, Color(1.0, 0.16, 0.2, 0.95 * fade), 4.0)
					game._draw_centered("!", ray_pos + Vector2(0, 8), 32, Color(1.0, 0.9, 0.72, 0.98 * fade))
				else:
					var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 18.0 + float(hazard.get("phase", 0.0)))
					game.draw_line(ray_pos + Vector2(0, -720), ray_pos, Color(1.0, 0.72, 0.12, 0.18 * fade), 26.0 + pulse * 10.0, true)
					game.draw_line(ray_pos + Vector2(0, -720), ray_pos, Color(1.0, 0.94, 0.38, 0.72 * fade), 7.0 + pulse * 4.0, true)
					game.draw_circle(ray_pos, game.BOSS4_ULTIMATE_RAY_RADIUS * (1.0 + pulse * 0.18), Color(1.0, 0.84, 0.2, 0.3 * fade))
			"boss4_meteor_shockwave":
				var shock_pos: Vector2 = Vector2(hazard.get("pos", game.player_pos)) - camera
				var shock_progress: float = clampf(age / maxf(0.01, float(hazard.get("max", 0.9))), 0.0, 1.0)
				game.draw_circle(shock_pos, game.BOSS4_METEOR_SHOCKWAVE_RADIUS * shock_progress, Color(1.0, 0.5, 0.12, 0.12 * fade))
				game.draw_arc(shock_pos, game.BOSS4_METEOR_SHOCKWAVE_RADIUS * (0.3 + 0.7 * shock_progress), 0.0, TAU, 54, Color(1.0, 0.78, 0.26, 0.84 * fade), 4.0)
			"boss4_column_barrage":
				var width: float = float(hazard.get("width", game.BOSS4_COLUMN_BARRAGE_WIDTH))
				var step: float = maxf(0.1, float(hazard.get("step", game.BOSS4_COLUMN_BARRAGE_STEP)))
				var columns: int = maxi(1, int(hazard.get("columns", 1)))
				var index: int = clampi(int(floor(age / step)), 0, columns - 1)
				var local_age: float = fposmod(age, step)
				var warning: float = float(hazard.get("warning", game.BOSS4_COLUMN_BARRAGE_WARNING))
				var active = local_age >= warning
				var x: float = float(hazard.get("start_x", game.WORLD_SIZE.x * 0.5)) - float(index) * width
				var top_left = Vector2(x - width * 0.5, 0.0) - camera
				var charge = clampf(local_age / maxf(0.01, warning), 0.0, 1.0)
				var blast = clampf((local_age - warning) / maxf(0.01, step - warning), 0.0, 1.0)
				var column_color = Color(1.0, 0.32, 0.08, (0.34 + 0.18 * sin(game.time_alive * 18.0)) * fade) if active else Color(1.0, 0.78, 0.16, (0.1 + charge * 0.18) * fade)
				game.draw_rect(Rect2(top_left, Vector2(width, game.WORLD_SIZE.y)), column_color, true)
				game.draw_rect(Rect2(top_left, Vector2(width, game.WORLD_SIZE.y)), Color(1.0, 0.86, 0.24, (0.7 + charge * 0.28) * fade), false, 3.0)
				game.draw_line(Vector2(x, 0.0) - camera, Vector2(x, game.WORLD_SIZE.y) - camera, Color(1.0, 0.96, 0.54, (0.32 + charge * 0.36) * fade), 3.0 + charge * 4.0, true)
				var cell_h = 64.0
				for y_index in range(int(ceil(game.WORLD_SIZE.y / cell_h))):
					var square_pos = Vector2(x - width * 0.5, float(y_index) * cell_h) - camera
					var pulse = 0.5 + 0.5 * sin(game.time_alive * 10.0 + float(y_index) * 0.8)
					var alpha = (0.32 + pulse * 0.42 + blast * 0.24) * fade if active else (0.08 + charge * 0.14) * fade
					game.draw_rect(Rect2(square_pos + Vector2(4, 3), Vector2(width - 8.0, cell_h - 6.0)), Color(1.0, 0.62, 0.1, alpha), false, 1.4)
					if active:
						var y_mid = square_pos.y + cell_h * 0.5
						game.draw_line(Vector2(square_pos.x + 10.0, y_mid), Vector2(square_pos.x + width - 10.0, y_mid), Color(1.0, 0.92, 0.38, 0.46 * fade), 2.3, true)
						game.draw_circle(Vector2(x, y_mid), 12.0 + pulse * 22.0, Color(1.0, 0.88, 0.36, (0.2 + blast * 0.22) * fade))
				if active:
					for spark in range(9):
						var y = fposmod(game.time_alive * 260.0 + float(spark) * 91.0, game.WORLD_SIZE.y) - camera.y
						var sx = x - camera.x + sin(game.time_alive * 4.0 + float(spark)) * width * 0.34
						game.draw_circle(Vector2(sx, y), 3.0 + float(spark % 3), Color(1.0, 0.95, 0.44, (0.46 + blast * 0.34) * fade))
				game._draw_centered("COLUNA %d" % (index + 1), Vector2(x, 72.0) - camera, 15, Color(1.0, 0.9, 0.42, 0.92 * fade))
			"boss4_column_laser":
				var origin: Vector2 = Vector2(hazard.get("origin", game.boss_pos)) - camera
				var target: Vector2 = Vector2(hazard.get("target", game.player_pos)) - camera
				var laser_warning: float = float(hazard.get("warning", game.BOSS4_COLUMN_LASER_WARNING))
				var charge = clampf(age / maxf(0.01, laser_warning), 0.0, 1.0)
				var dir: Vector2 = (target - origin).normalized()
				if dir.length() <= 0.01:
					dir = Vector2.LEFT
				var end = origin + dir * 1260.0
				game.draw_line(origin, end, Color(0.0, 0.16, 0.18, 0.64 * fade), 13.0 + charge * 5.0, true)
				game.draw_line(origin, end, Color(0.36, 1.0, 0.92, (0.32 + charge * 0.52) * fade), 2.4 + charge * 4.4, true)
				game.draw_arc(target, 34.0 + charge * 26.0, - PI * 0.5, - PI * 0.5 + TAU * charge, 48, Color(1.0, 0.8, 0.28, 0.88 * fade), 2.5)
				if bool(hazard.get("triggered", false)):
					game.draw_line(origin, end, Color(1.0, 0.94, 0.62, 0.95 * fade), 10.0, true)
			"boss4_drag_wave":
				var x: float = float(hazard.get("x", float(hazard.get("start_x", game.WORLD_SIZE.x + 80.0)) - float(hazard.get("speed", game.BOSS4_DRAG_WAVE_SPEED)) * age))
				var width: float = float(hazard.get("width", game.BOSS4_DRAG_WAVE_WIDTH))
				var rect = Rect2(Vector2(x - width * 0.5, 0.0) - camera, Vector2(width, game.WORLD_SIZE.y))
				var grabbed = bool(hazard.get("hit", false))
				game.draw_rect(rect, Color(0.22, 1.0, 0.74, (0.18 if grabbed else 0.1) * fade), true)
				game.draw_rect(rect, Color(0.54, 1.0, 0.86, (0.84 if grabbed else 0.58) * fade), false, 2.0)
				for y_index in range(8):
					var y = float(y_index) * game.WORLD_SIZE.y / 7.0 - camera.y
					var p = Vector2(x, y) - Vector2(camera.x, 0)
					game.draw_polyline(PackedVector2Array([p + Vector2(18, -10), p - Vector2(14, 0), p + Vector2(18, 10)]), Color(0.84, 1.0, 0.72, 0.7 * fade), 2.2, false)
				if grabbed:
					game._draw_centered("ARRASTO %.0fs" % ceil(float(hazard.get("drag_timer", 0.0))), Vector2(viewport.x * 0.5, 124.0), 17, Color(0.76, 1.0, 0.82, 0.92 * fade))
			"boss4_sonic_wave":
				var a: Vector2 = Vector2(hazard.get("a", game.boss_pos)) - camera
				var b: Vector2 = Vector2(hazard.get("b", game.boss_pos + Vector2.LEFT * 900.0)) - camera
				var sonic_warning: float = float(hazard.get("warning", game.BOSS4_SONIC_WARNING))
				var progress = clampf(age / maxf(0.01, sonic_warning), 0.0, 1.0)
				var sonic_width: float = float(hazard.get("width", game.BOSS4_SONIC_WIDTH))
				var dir: Vector2 = (b - a).normalized()
				if dir.length() <= 0.01:
					dir = Vector2.LEFT
				var side = dir.orthogonal()
				game.draw_line(a, b, Color(0.02, 0.04, 0.1, 0.74 * fade), sonic_width * 1.15, true)
				game.draw_line(a, b, Color(0.98, 0.18, 1.0, (0.3 + progress * 0.28) * fade), sonic_width * 0.72, true)
				game.draw_line(a, b, Color(0.18, 1.0, 1.0, (0.58 + progress * 0.3) * fade), 7.0 + progress * 8.0, true)
				game.draw_line(a + side * sonic_width * 0.52, b + side * sonic_width * 0.52, Color(1.0, 0.86, 0.28, 0.62 * fade), 2.8, true)
				game.draw_line(a - side * sonic_width * 0.52, b - side * sonic_width * 0.52, Color(1.0, 0.86, 0.28, 0.62 * fade), 2.8, true)
				for i in range(10):
					var offset = sin(game.time_alive * 9.0 + float(i)) * sonic_width * 0.34
					var t = float(i) / 9.0
					var p = a.lerp(b, t)
					game.draw_circle(p + side * offset, 7.0 + progress * 7.0, Color(0.9, 1.0, 1.0, 0.54 * fade))
					game.draw_arc(p, sonic_width * (0.24 + 0.22 * progress), - game.time_alive * 3.0 + float(i), TAU - game.time_alive * 3.0 + float(i), 24, Color(1.0, 0.26, 1.0, 0.34 * fade), 2.0)
				if bool(hazard.get("grabbed", false)):
					var player_screen: Vector2 = game.player_pos - camera
					for i in range(5):
						var wobble = Vector2(sin(game.time_alive * 8.0 + i) * 26.0, cos(game.time_alive * 5.0 + i) * 16.0)
						game.draw_line(game.boss_pos - camera + wobble * 0.2, player_screen + wobble, Color(0.58, 1.0, 0.96, 0.28 * fade), 2.4, true)
					game.draw_arc(player_screen, 52.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 52, Color(0.5, 1.0, 0.92, 0.72 * fade), 3.0)
			"safe_zone":
				var pos: Vector2 = Vector2(hazard["pos"]) - camera
				var radius: float = float(hazard.get("radius", 112.0))
				game.draw_circle(pos, radius, Color(0.34, 1.0, 0.72, 0.1 * fade))
				game.draw_arc(pos, radius, - game.time_alive, TAU - game.time_alive, 64, Color(0.56, 1.0, 0.86, 0.58 * fade), 2.4)


static func _draw_boss2_environment(game: Node2D, camera: Vector2) -> void :
	if game.current_phase != 2:
		return
	game._draw_boss2_ultimate_environment(camera)
	for zone in game.boss2_snow_zones:
		if not game._world_point_in_view(Vector2(zone.get("pos", Vector2.ZERO)), camera, float(zone.get("radius", 96.0)) + 90.0):
			continue
		var fade = clamp(float(zone.get("life", 0.0)) / max(0.01, float(zone.get("max", game.BOSS2_SLOW_ZONE_TIME))), 0.0, 1.0)
		var pos = Vector2(zone["pos"]) - camera
		var radius = float(zone["radius"])
		game.draw_circle(pos, radius, Color(0.62, 0.92, 1.0, 0.1 * fade))
		game.draw_arc(pos, radius, 0, TAU, 36, Color(0.02, 0.12, 0.22, 0.6 * fade), 5.0)
		game.draw_arc(pos, radius, 0, TAU, 36, Color(0.4, 0.85, 1.0, 0.62 * fade), 2.0)
		for i in range(5):
			var ang = float(zone.get("phase", 0.0)) + game.time_alive * 0.8 + i * TAU / 5.0
			game.draw_circle(pos + Vector2.from_angle(ang) * radius * 0.52, 2.4, Color(1.0, 1.0, 1.0, 0.46 * fade))
	for shard in game.boss2_ice_shards:
		if not game._world_point_in_view(Vector2(shard.get("pos", Vector2.ZERO)), camera, 120.0):
			continue
		var fade = clamp(float(shard.get("life", 0.0)) / max(0.01, float(shard.get("max", 1.2))), 0.0, 1.0)
		var pos = Vector2(shard["pos"]) - camera
		var angle = float(shard.get("angle", 0.0))
		var size = float(shard.get("size", 8.0)) * (0.7 + fade * 0.5)
		var tip = Vector2.from_angle(angle) * size * 1.45
		var side = Vector2.from_angle(angle + PI * 0.5) * size * 0.62
		var points = PackedVector2Array([pos + tip, pos + side, pos - tip, pos - side])
		game.draw_polygon(points, PackedColorArray([Color(0.72, 0.94, 1.0, 0.78 * fade)]))
		game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(1.0, 1.0, 1.0, 0.62 * fade), 1.2, true)
	var frost_drawn: int = 0
	var frost_draw_cap: int = 28 if game._memory_saver_active() else (52 if game._runtime_visual_budget_active() else 999999)
	for particle in game.boss2_frost_particles:
		if frost_drawn >= frost_draw_cap:
			break
		if not game._world_point_in_view(Vector2(particle.get("pos", Vector2.ZERO)), camera, 100.0):
			continue
		frost_drawn += 1
		var fade = clamp(float(particle.get("life", 0.0)) / max(0.01, float(particle.get("max", 0.58))), 0.0, 1.0)
		var pos = Vector2(particle["pos"]) - camera
		var radius = float(particle.get("size", 12.0)) * fade
		game.draw_circle(pos, radius, Color(0.74, 0.92, 1.0, 0.18 * fade))
		game.draw_circle(pos, radius * 0.42, Color(1.0, 1.0, 1.0, 0.6 * fade))
	game._draw_phase2_fire_walls(camera)


static func _draw_phase2_fire_walls(game: Node2D, camera: Vector2) -> void :
	for tile in game.phase2_fire_walls:
		if not game._world_point_in_view(Vector2(tile.get("pos", Vector2.ZERO)), camera, game.PYRO_WALL_TILE_SIZE + 90.0):
			continue
		var fade: float = clamp(float(tile.get("life", 0.0)) / min(1.2, float(tile.get("max", game.PYRO_WALL_DURATION))), 0.0, 1.0)
		var pos = Vector2(tile["pos"]) - camera
		var phase = float(tile.get("phase", 0.0))
		var rect = Rect2(pos - Vector2.ONE * game.PYRO_WALL_TILE_SIZE * 0.5, Vector2.ONE * game.PYRO_WALL_TILE_SIZE)
		game.draw_rect(rect, Color(0.28, 0.015, 0.01, 0.58 * fade), true)
		game.draw_rect(rect, Color(1.0, 0.22, 0.04, 0.82 * fade), false, 2.0)
		for i in range(3):
			var x = pos.x - 10.0 + i * 10.0
			var flame_h = 13.0 + sin(game.time_alive * 12.0 + phase + i * 1.7) * 5.0
			var flame = PackedVector2Array([Vector2(x - 5.0, pos.y + 12.0), Vector2(x, pos.y + 12.0 - flame_h), Vector2(x + 5.0, pos.y + 12.0)])
			game.draw_colored_polygon(flame, Color(1.0, 0.18 + i * 0.09, 0.02, 0.82 * fade))


static func _draw_phase7_ember_patches(game: Node2D, camera: Vector2) -> void:
	var lean_visuals: bool = game._phase7_visual_budget_enabled()
	var arc_segments: int = 22 if lean_visuals else 40
	var ember_count: int = 3 if lean_visuals else 5
	for patch in game.phase7_ember_patches:
		var world_pos: Vector2 = Vector2(patch.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world_pos, camera, game.PHASE7_DRAW_MARGIN):
			continue
		var life_ratio: float = clampf(float(patch.get("life", 0.0)) / maxf(0.01, float(patch.get("max", game.PHASE7_PANGOLIRO_EMBER_LIFE))), 0.0, 1.0)
		var age: float = float(patch.get("age", 0.0))
		var appear: float = clampf(age / maxf(0.01, game.PHASE7_PANGOLIRO_EMBER_DELAY), 0.0, 1.0)
		var fade: float = min(life_ratio, appear)
		var pos: Vector2 = world_pos - camera
		var phase: float = float(patch.get("phase", 0.0))
		var radius: float = game.PHASE7_PANGOLIRO_EMBER_RADIUS * (0.74 + 0.16 * sin(game.time_alive * 5.0 + phase))
		game.draw_circle(pos, radius, Color(0.22, 0.06, 0.015, 0.34 * fade))
		game.draw_circle(pos, radius * 0.62, Color(0.92, 0.2, 0.03, 0.14 * fade))
		game.draw_arc(pos, radius, game.time_alive * 1.8 + phase, game.time_alive * 1.8 + phase + PI * 1.35, arc_segments, Color(1.0, 0.5, 0.08, 0.66 * fade), 2.6)
		for i in range(ember_count):
			var a: float = phase + float(i) * TAU / maxf(1.0, float(ember_count)) + sin(game.time_alive * 2.4 + i) * 0.18
			var ember_pos: Vector2 = pos + Vector2.from_angle(a) * (radius * (0.2 + 0.12 * float(i)))
			game.draw_circle(ember_pos, 2.2 + float(i % 2), Color(1.0, 0.62, 0.12, 0.72 * fade))


static func _draw_phase7_enemy_vfx(game: Node2D, enemy: Dictionary, camera: Vector2, ground_pos: Vector2, draw_pos: Vector2, size: Vector2) -> void:
	if not game._world_point_in_view(Vector2(enemy.get("pos", ground_pos + camera)), camera, game.PHASE7_DRAW_MARGIN):
		return
	var lean_visuals: bool = game._phase7_visual_budget_enabled()
	var kind: String = String(enemy.get("type", ""))
	if kind == game.ENEMY_CINERIDO:
		var state: String = String(enemy.get("phase7_state", "walk"))
		if state == "windup" or state == "active":
			var dir: Vector2 = Vector2(enemy.get("phase7_target_dir", enemy.get("facing_dir", Vector2.LEFT))).normalized()
			var progress: float = clampf(float(enemy.get("phase7_timer", 0.0)) / game.PHASE7_CINERIDO_WINDUP, 0.0, 1.0)
			var origin: Vector2 = ground_pos + dir * 20.0
			var left: Vector2 = origin + dir.rotated(-game.PHASE7_CINERIDO_CONE_HALF_ANGLE) * (game.PHASE7_CINERIDO_CONE_RANGE * (0.55 + 0.45 * progress))
			var right: Vector2 = origin + dir.rotated(game.PHASE7_CINERIDO_CONE_HALF_ANGLE) * (game.PHASE7_CINERIDO_CONE_RANGE * (0.55 + 0.45 * progress))
			game.draw_colored_polygon(PackedVector2Array([origin, left, right]), Color(0.44, 0.17, 0.04, 0.22 + progress * 0.16))
			game.draw_line(origin, left, Color(1.0, 0.52, 0.16, 0.58), 2.0)
			game.draw_line(origin, right, Color(1.0, 0.52, 0.16, 0.58), 2.0)
	if kind == game.ENEMY_PANGOLIRO:
		var state_p: String = String(enemy.get("phase7_state", "walk"))
		var dir_p: Vector2 = Vector2(enemy.get("phase7_roll_dir", enemy.get("facing_dir", Vector2.LEFT))).normalized()
		if state_p == "align" or state_p == "windup":
			var telegraph_len: float = 118.0 + 72.0 * clampf(float(enemy.get("phase7_timer", 0.0)) / game.PHASE7_PANGOLIRO_WINDUP, 0.0, 1.0)
			game.draw_line(ground_pos + dir_p * 18.0, ground_pos + dir_p * telegraph_len, Color(1.0, 0.45, 0.08, 0.45), 5.0, true)
			game.draw_line(ground_pos + dir_p * 18.0, ground_pos + dir_p * telegraph_len, Color(0.28, 0.08, 0.02, 0.62), 2.0, true)
		elif state_p == "roll":
			game.draw_arc(ground_pos, size.x * 0.42, game.time_alive * 12.0, game.time_alive * 12.0 + PI * 1.55, 24 if lean_visuals else 36, Color(1.0, 0.48, 0.06, 0.82), 3.0)
	if kind == game.ENEMY_CORVOL:
		var target_world: Vector2 = Vector2(enemy.get("phase7_target", enemy.get("pos", Vector2.ZERO)))
		var target: Vector2 = target_world - camera
		var state_c: String = String(enemy.get("phase7_state", "orbit"))
		if (state_c == "prepare" or state_c == "ascend" or state_c == "dive") and game._world_point_in_view(target_world, camera, game.PHASE7_DRAW_MARGIN):
			var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 16.0)
			game.draw_circle(target, game.PHASE7_CORVOL_IMPACT_RADIUS, Color(0.22, 0.08, 0.02, 0.18))
			game.draw_arc(target, game.PHASE7_CORVOL_IMPACT_RADIUS + pulse * 5.0, -game.time_alive * 4.0, TAU - game.time_alive * 4.0, 28 if lean_visuals else 48, Color(1.0, 0.62, 0.22, 0.78), 2.0)
			game.draw_line(draw_pos, target, Color(0.9, 0.8, 0.62, 0.22), 1.5, true)


static func _draw_boss2_ultimate_environment(game: Node2D, camera: Vector2) -> void :
	if game.boss2_ultimate_timer <= 0.0:
		return
	var viewport: Vector2 = game.get_viewport_rect().size
	var center: Vector2 = game.boss2_ultimate_center - camera
	var safe_radius: float = game.BOSS2_ULTIMATE_SAFE_RADIUS
	var low: bool = game._memory_saver_active() or game._runtime_visual_budget_active() or game.gfx_low_resource
	var segments: int = 48 if low else 96
	# Put the storm outside the exact safe boundary, leaving combat readable inside.
	for ring in range(5 if low else 8):
		var radius: float = safe_radius + 30.0 + ring * 58.0
		var start: float = game.time_alive * (0.38 + ring * 0.035) + ring * 1.9
		game.draw_arc(center, radius, start, start + PI * 1.35, segments, Color(0.04, 0.14, 0.26, 0.28), 38.0)
		game.draw_arc(center, radius + 6.0, start, start + PI * 1.35, segments, Color(0.64, 0.85, 0.95, 0.3), 13.0)
		game.draw_arc(center, radius + 14.0, start + 0.4, start + PI, segments, Color(0.94, 1.0, 1.0, 0.34), 2.0)
	for i in range(65 if low else 150):
		var seed_value: float = float(i)
		var angle: float = game.time_alive * (1.15 + fposmod(seed_value * 0.13, 0.7)) + seed_value * 2.4
		var radius: float = safe_radius + 24.0 + fposmod(seed_value * 37.0, 570.0)
		var point: Vector2 = center + Vector2.from_angle(angle) * radius
		if not game._screen_point_in_view(point, 50.0):
			continue
		var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
		var length: float = 7.0 + fposmod(seed_value * 1.61, 16.0)
		game.draw_line(point - tangent * length, point, Color(0.8, 0.94, 1.0, 0.42), 2.0)
		game.draw_rect(Rect2(point.floor(), Vector2(2, 2)), Color(1.0, 1.0, 1.0, 0.72))
	game.Boss2VFX.rim(game, center, safe_radius, Color(0.5, 1.0, 0.88, 0.96), low)
	for i in range(24):
		var dir: Vector2 = Vector2.from_angle(i * TAU / 24.0)
		game.draw_line(center + dir * (safe_radius - 10.0), center + dir * (safe_radius - 18.0), Color(0.5, 1.0, 0.88, 0.72), 2.0)
	game._draw_boss2_ultimate_warning(camera)
	var banner = Rect2(Vector2(viewport.x * 0.5 - 145.0, 158.0), Vector2(290.0, 42.0))
	game.draw_rect(banner, Color(0.02, 0.06, 0.1, 0.88))
	game._draw_centered("NEVASCA %.0fs" % ceil(game.boss2_ultimate_timer), Vector2(viewport.x * 0.5, 175.0), 17, Color(0.9, 1.0, 1.0))
	game._draw_centered("PROTEJA-SE DENTRO DO ANEL", Vector2(viewport.x * 0.5, 192.0), 12, Color(0.5, 1.0, 0.88))


static func _draw_boss2_ultimate_warning(game: Node2D, camera: Vector2) -> void :
	var boss_screen: Vector2 = game.boss_pos - camera
	var ultimate_warning = game._telegraph_window(game.BOSS2_ULTIMATE_WARNING_TIME)
	if game.boss2_ultimate_spit_timer > 0.0 and game.boss2_ultimate_spit_timer <= ultimate_warning:
		var progress: float = 1.0 - game.boss2_ultimate_spit_timer / ultimate_warning
		var dir: Vector2 = (game.player_pos - game.boss_pos).normalized()
		if dir.length() <= 0.01:
			dir = Vector2.DOWN
		for offset in [-0.25, 0.0, 0.25]:
			var shot_dir: Vector2 = dir.rotated(offset)
			game.Boss2VFX.trajectory(game, boss_screen + shot_dir * 64.0, shot_dir, 620.0, game.time_alive, 0.5 + progress * 0.4)
		game.Boss2VFX.crystal(game, boss_screen + dir * 64.0, dir, 14.0 + progress * 10.0)
	if game.boss2_ultimate_fan_timer > 0.0 and game.boss2_ultimate_fan_timer <= ultimate_warning:
		var fan_origin: Vector2 = game.boss2_ultimate_center + Vector2.from_angle(game.boss2_ultimate_orbit_angle + PI * 0.45) * (game.BOSS2_ULTIMATE_SAFE_RADIUS + 250.0)
		fan_origin = fan_origin.clamp(Vector2(100, 100), game.WORLD_SIZE - Vector2(100, 100))
		var fan_dir: Vector2 = (game.player_pos - fan_origin).normalized()
		var screen_origin: Vector2 = fan_origin - camera
		for offset in [-0.52, -0.26, 0.0, 0.26, 0.52]:
			var ray: Vector2 = fan_dir.rotated(offset)
			game.Boss2VFX.trajectory(game, screen_origin, ray, 780.0, game.time_alive, 0.66)
	if game.boss2_ultimate_wind_active > 0.0:
		game._draw_boss2_wind_stream(camera, game.boss2_ultimate_wind_dir, game.boss2_ultimate_wind_active / game.BOSS2_ULTIMATE_WIND_DURATION, true)
	elif game.boss2_ultimate_wind_timer > 0.0 and game.boss2_ultimate_wind_timer <= ultimate_warning:
		var dir_warn: Vector2 = (game.WORLD_SIZE * 0.5 - game.player_pos).normalized()
		if dir_warn.length() <= 0.01:
			dir_warn = Vector2.RIGHT
		var progress_wind: float = 1.0 - game.boss2_ultimate_wind_timer / ultimate_warning
		game._draw_boss2_wind_stream(camera, dir_warn, progress_wind, false)


static func _draw_boss2_wind_stream(game: Node2D, camera: Vector2, dir: Vector2, intensity: float, active: bool) -> void :
	if dir.length() <= 0.01:
		return
	var center: Vector2 = game.player_pos - camera
	var side: Vector2 = dir.orthogonal()
	var base_alpha: float = 0.18 + intensity * 0.28
	var width: float = 68.0 if active else 42.0
	for i in range(9):
		var lane: float = float(i) - 4.0
		var offset: Vector2 = side * lane * 23.0
		var wobble: Vector2 = side * sin(game.time_alive * 8.0 + i) * 8.0
		var a: Vector2 = center - dir * (360.0 + i * 12.0) + offset + wobble
		var b: Vector2 = center + dir * (250.0 + intensity * 120.0) + offset - wobble
		game.draw_line(a, b, Color(0.66, 0.92, 1.0, base_alpha * (0.55 + i % 3 * 0.12)), max(2.0, width * (0.08 + intensity * 0.02)))
	if active:
		var resist_dir: Vector2 = - dir
		var arrow_center: Vector2 = center + resist_dir * 82.0
		var tip: Vector2 = arrow_center + resist_dir * 38.0
		var left: Vector2 = arrow_center - resist_dir * 22.0 + side * 22.0
		var right: Vector2 = arrow_center - resist_dir * 22.0 - side * 22.0
		game.draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([Color(0.18, 0.9, 1.0, 0.32 + intensity * 0.18)]))
		game._draw_centered("RESISTA", center + Vector2(0, -88), 15, Color(0.86, 1.0, 1.0, 0.88))
	else:
		game._draw_centered("VENTO", center - dir * 116.0 + Vector2(0, -54), 16, Color(0.86, 1.0, 1.0, 0.9))


static func _draw_boss6_particle_swarm(game: Node2D, camera: Vector2, progress: float, label: = true) -> void :
	progress = clampf(progress, 0.0, 1.0)
	var target_world: Vector2 = game.boss6_relocate_to if game.boss6_relocating else game.WORLD_SIZE * 0.5
	var target_screen: Vector2 = target_world - camera
	if game.boss6_entry_particles.is_empty():
		game.draw_circle(target_screen, 82.0 + progress * 36.0, Color(0.18, 0.42, 0.08, 0.18))
		game.draw_arc(target_screen, 96.0 + progress * 72.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 70, Color(0.62, 1.0, 0.24, 0.62), 4.0)
		if label:
			game._draw_centered("MATRIARCA DA CHAGA", target_screen + Vector2(0, -168), 31, Color(0.76, 1.0, 0.36, 0.95))
		return
	var stride = 2 if not game.gfx_low_resource else 5
	for i in range(0, game.boss6_entry_particles.size(), stride):
		var particle: Dictionary = game.boss6_entry_particles[i]
		var delay = float(particle.get("delay", 0.0)) / game.BOSS6_ENTRY_TIME
		var duration = maxf(0.08, float(particle.get("duration", game.BOSS6_ENTRY_TIME)) / game.BOSS6_ENTRY_TIME)
		var local = clampf((progress - delay) / duration, 0.0, 1.0)
		var eased = local * local * (3.0 - 2.0 * local)
		var start = Vector2(particle.get("start", game.boss6_relocate_from))
		var target = Vector2(particle.get("target", game.boss6_relocate_to))
		var pos = game._parasite_curve_point(start, target, eased, float(particle.get("bend", 0.0))) - camera
		var phase = float(particle.get("phase", 0.0))
		var size = float(particle.get("size", 2.0)) * (1.0 + sin(game.time_alive * 8.0 + phase) * 0.22)
		var alpha = clampf(sin(local * PI) * 0.88 + 0.12, 0.0, 0.95)
		var gray = Color(0.62, 0.64, 0.52, alpha * 0.76)
		var green = Color(0.38, 0.92, 0.2, alpha * 0.55)
		game.draw_circle(pos, size + 1.6, Color(0.03, 0.06, 0.02, alpha * 0.24))
		game.draw_circle(pos, size, gray if i % 4 != 0 else green)
	if progress > 0.72:
		var pulse = (progress - 0.72) / 0.28
		game.draw_circle(target_screen, 120.0 * pulse, Color(0.24, 0.72, 0.1, 0.13 * (1.0 - pulse)))
		game.draw_arc(target_screen, 72.0 + pulse * 88.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 72, Color(0.62, 1.0, 0.22, 0.62 * (1.0 - pulse * 0.3)), 4.0)
	if label:
		game._draw_centered("MATRIARCA DA CHAGA", target_screen + Vector2(0, -168), 31, Color(0.76, 1.0, 0.36, 0.95))


static func _draw_boss6_smoke_shield(game: Node2D, center: Vector2, size: Vector2) -> void :
	var has_carapace = not game.boss6_carapace_plates.is_empty()
	var has_fossil: bool = game.boss6_fossil_shield > 0.0
	var exposed = game.boss6_core_exposed_timer > 0.0 or game.boss6_vulnerability_timer > 0.0
	if not has_carapace and not has_fossil and not exposed and game.boss6_organs.is_empty():
		return
	var radius = maxf(size.x, size.y) * 0.62
	var pulse = 0.5 + 0.5 * sin(game.time_alive * 5.0)
	if has_carapace or has_fossil:
		var plate_count = game.boss6_carapace_plates.size()
		var color = Color(0.54, 1.0, 0.18, 0.58) if has_carapace else Color(0.68, 0.72, 0.5, 0.44)
		game.draw_circle(center, radius + 18.0, Color(0.08, 0.18, 0.05, 0.13))
		for i in range(maxi(1, plate_count)):
			var start = - PI * 0.5 + float(i) * TAU / maxf(1.0, float(maxi(1, plate_count)))
			game.draw_arc(center, radius + 12.0 + pulse * 5.0, start, start + TAU / maxf(1.0, float(maxi(1, plate_count))) * 0.74, 30, color, 5.0)
	if exposed:
		game.draw_circle(center, radius * 0.34 + pulse * 8.0, Color(1.0, 0.46, 0.12, 0.18))
		game.draw_arc(center, radius * 0.42 + pulse * 10.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 64, Color(1.0, 0.74, 0.24, 0.7), 3.0)
	for organ in game.boss6_organs:
		var organ_data: Dictionary = organ
		if not bool(organ_data.get("alive", true)):
			continue
		var organ_pos = Vector2(organ_data.get("pos", game.boss_pos)) - game._camera(game.get_viewport_rect().size)
		var organ_color = Color(0.58, 1.0, 0.18, 0.56)
		game.draw_circle(organ_pos, 24.0 + sin(game.time_alive * 5.0 + float(organ_data.get("pulse", 0.0))) * 4.0, Color(0.06, 0.16, 0.04, 0.42))
		game.draw_arc(organ_pos, 34.0, - game.time_alive, TAU - game.time_alive, 36, organ_color, 3.0)


static func _draw_boss_entry(game: Node2D, camera: Vector2) -> void :
	var target = game.WORLD_SIZE * 0.5 - camera
	if game.current_phase == 6:
		var progress6 = 0.0
		if game.boss6_relocating:
			progress6 = clampf(game.boss6_relocate_age / maxf(0.01, game.boss6_relocate_duration), 0.0, 1.0)
		else:
			progress6 = clampf(1.0 - game.boss_entry_timer / maxf(0.01, game.BOSS6_ENTRY_TIME), 0.0, 1.0)
		game._draw_boss6_particle_swarm(camera, progress6)
		return
	if game.current_phase == 5:
		var progress5: float = clamp(1.0 - game.boss_entry_timer / game.BOSS5_ENTRY_TIME, 0.0, 1.0)
		var anchor5 = Vector2(game.WORLD_SIZE.x * 0.68, game.WORLD_SIZE.y * 0.48) - camera
		game.draw_circle(anchor5, 90.0 + sin(game.time_alive * 6.0) * 8.0, Color(0.08, 0.28, 0.12, 0.24))
		game.draw_arc(anchor5, 128.0 * progress5, 0, TAU, 72, Color(0.3, 1.0, 0.52, 0.75), 5.0)
		game.draw_line(game.boss_pos - camera, anchor5, Color(0.2, 1.0, 0.44, 0.32), 18.0)
		game.draw_line(game.boss_pos - camera, anchor5, Color(0.86, 1.0, 0.74, 0.72), 3.0)
		game._draw_centered("UMBRA", anchor5 + Vector2(0, -128), 30, Color(0.56, 1.0, 0.68, 0.95))
		return
	if game.current_phase == 4:
		var progress4: float = clamp(1.0 - game.boss_entry_timer / game.BOSS4_ENTRY_TIME, 0.0, 1.0)
		var anchor: Vector2 = game.boss4_entry_target - camera
		for i in range(5):
			var radius = 54.0 + i * 31.0 + sin(game.time_alive * 5.0 + i) * 8.0
			game.draw_arc(anchor, radius, - game.time_alive * (0.7 + i * 0.08), TAU - game.time_alive * (0.7 + i * 0.08), 64, Color(1.0, 0.68 - i * 0.06, 0.14 + i * 0.12, (0.72 - i * 0.1) * (1.0 - progress4 * 0.35)), 3.0)
		game.draw_line(game.boss_pos - camera, anchor, Color(0.76, 0.34, 1.0, 0.32), 18.0)
		game.draw_line(game.boss_pos - camera, anchor, Color(1.0, 0.78, 0.24, 0.72), 3.0)
		game._draw_centered("NEXO DA RUPTURA", anchor + Vector2(0, -174), 32, Color(1.0, 0.82, 0.34))
		return
	if game.current_phase == 3:
		var progress3 = clamp(1.0 - game.boss_entry_timer / game.BOSS3_ENTRY_TIME, 0.0, 1.0)
		for i in range(3):
			var radius = 70.0 + i * 32.0 + progress3 * 120.0
			game.draw_arc(target, radius, 0, TAU, 64, Color(0.54, 0.92, 0.16, (1.0 - progress3) * (0.72 - i * 0.14)), 4.0)
		game._draw_centered("PAI-RATO", target + Vector2(0, -142), 34, Color(0.82, 1.0, 0.42))
		return
	if game.current_phase == 2:
		var progress2 = clamp(1.0 - game.boss_entry_timer / game.BOSS2_ENTRY_TIME, 0.0, 1.0)
		var boss_draw = game.boss_pos - camera
		if progress2 < 0.8:
			var crystal_h = 220.0
			var crystal_w = 120.0
			var points = PackedVector2Array([
				boss_draw + Vector2(0, - crystal_h * 0.52), 
				boss_draw + Vector2(crystal_w * 0.45, - crystal_h * 0.18), 
				boss_draw + Vector2(crystal_w * 0.34, crystal_h * 0.34), 
				boss_draw + Vector2(0, crystal_h * 0.52), 
				boss_draw + Vector2( - crystal_w * 0.34, crystal_h * 0.34), 
				boss_draw + Vector2( - crystal_w * 0.45, - crystal_h * 0.18)
			])
			game.draw_polygon(points, PackedColorArray([Color(0.46, 0.88, 1.0, 0.34)]))
			game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[0]]), Color(0.82, 0.96, 1.0, 0.92), 3.0, true)
			game.draw_line(points[0], points[3], Color(1.0, 1.0, 1.0, 0.58), 2.0)
		else:
			var impact = (progress2 - 0.8) / 0.2
			for i in range(3):
				game.draw_arc(target, 82.0 + impact * 520.0 + i * 32.0, 0, TAU, 96, Color(0.62, 0.92, 1.0, (1.0 - impact) * (0.7 - i * 0.16)), 4.0)
		if int(game.time_alive * 7.0) % 2 == 0:
			game._draw_centered("A NEVASCA EMITE UM GRITO", target + Vector2(0, -142), 30, Color(0.72, 0.96, 1.0))
		return
	var progress = 1.0 - game.boss_entry_timer / game.BOSS_ENTRY_TIME
	var radius = 115.0 * (1.0 + 0.1 * sin(game.time_alive * 10.0))
	game.draw_circle(target, radius, Color(0.08, 0.0, 0.16, 0.44))
	game.draw_arc(target, radius * 0.82, 0, TAU, 64, Color(0.62, 0.0, 1.0, 0.88), 5)
	game.draw_arc(target, radius * 0.52, 0, TAU, 64, Color(0.0, 0.8, 1.0, 0.82), 3)
	for i in range(8):
		var a = game.time_alive * 4.0 + i * TAU / 8.0
		game.draw_line(target + Vector2.from_angle(a) * radius * 0.25, target + Vector2.from_angle(a) * radius * 0.92, Color(1.0, 0.35, 1.0, 0.72), 4)
	if progress >= 0.8:
		var impact = (progress - 0.8) / 0.2
		game.draw_arc(target, 90 + impact * 600.0, 0, TAU, 96, Color(1.0, 1.0, 1.0, 1.0 - impact), 6)
		game.draw_arc(target, 70 + impact * 520.0, 0, TAU, 96, Color(0.0, 0.75, 1.0, 0.7 * (1.0 - impact)), 4)
	game._draw_centered("CARANGUEJO COSMICO GIGANTE", target + Vector2(0, -150), 34, Color.WHITE)


static func _draw_boss1_time_wave(game: Node2D, camera: Vector2) -> void :
	if game.boss1_time_wave.is_empty():
		return
	var center = Vector2(game.boss1_time_wave["origin"]) - camera
	var radius = float(game.boss1_time_wave["radius"])
	var returning = float(game.boss1_time_wave.get("direction", 1.0)) < 0.0
	var visual_age: float = float(game.boss1_time_wave.get("age", 0.0)) + game._boss1_visual_prediction()
	if float(game.boss1_time_wave.get("age", 0.0)) >= game.BOSS1_TIME_WAVE_WARNING:
		radius = clampf(radius + (-1.0 if returning else 1.0) * game.BOSS1_TIME_WAVE_SPEED * game._boss1_visual_prediction(), 34.0, float(game.boss1_time_wave.get("max_radius", radius)))
	var pulse = 0.5 + 0.5 * sin(visual_age * 11.0)
	var variant = int(game.boss1_time_wave.get("variant", 0))
	var variant_color = game._chrono_variant_color(variant)
	var primary = Color(1.0, 0.24, 0.66, 0.88) if returning else Color(variant_color.r, variant_color.g, variant_color.b, 0.88)
	game.Boss1VFX.chrono_wave(game, center, radius, visual_age, primary, game.BOSS1_TIME_WAVE_WIDTH, returning, game._get_boss_wave_quality_profile() == "LOW")
	match variant:
		1:
			game.draw_arc(center, max(24.0, radius - 44.0), PI * 0.15, PI * 1.15, 86, Color(1.0, 0.42, 0.86, 0.46), 5.0)
			game.draw_arc(center, radius + 44.0, PI * 1.15, PI * 2.15, 86, Color(1.0, 0.42, 0.86, 0.34), 4.0)
		2:
			for spiral in range(4):
				var a0 = float(game.boss1_time_wave.get("age", 0.0)) * 1.9 + spiral * TAU / 4.0
				game.draw_line(center + Vector2.from_angle(a0) * radius * 0.28, center + Vector2.from_angle(a0 + 0.75) * radius, Color(0.74, 0.52, 1.0, 0.38), 3.0)
		3:
			for shard in range(10):
				var a = shard * TAU / 10.0 + float(game.boss1_time_wave.get("age", 0.0)) * 0.42
				var p0 = center + Vector2.from_angle(a) * (radius - 18.0)
				var p1 = center + Vector2.from_angle(a + 0.08) * (radius + 26.0)
				game.draw_line(p0, p1, Color(1.0, 0.78, 0.3, 0.54), 3.0)
	for tick_index in range(24):
		var angle = tick_index * TAU / 24.0 + float(game.boss1_time_wave.get("age", 0.0)) * (-0.9 if returning else 0.9)
		var tick_length = 17.0 if tick_index % 3 == 0 else 9.0
		var inner = center + Vector2.from_angle(angle) * (radius - tick_length)
		var outer = center + Vector2.from_angle(angle) * (radius + tick_length * 0.35)
		game.draw_line(inner, outer, Color(primary.r, primary.g, primary.b, 0.82), 2.5 if tick_index % 3 == 0 else 1.4)
	game.draw_circle(center, 42.0 + pulse * 5.0, Color(0.04, 0.1, 0.18, 0.42))
	game.draw_arc(center, 44.0 + pulse * 5.0, 0.0, TAU, 40, primary, 3.0)
	var hand_angle = - PI * 0.5 + float(game.boss1_time_wave.get("age", 0.0)) * (-2.8 if returning else 2.8)
	game.draw_line(center, center + Vector2.from_angle(hand_angle) * 28.0, Color.WHITE, 3.0)
	game.draw_circle(center, 4.0, Color.WHITE)


static func _draw_boss1_rewind_world(game: Node2D, camera: Vector2) -> void :
	if game.boss1_rewind_sequence.is_empty() or game.boss1_rewind_history.is_empty():
		return
	var elapsed = float(game.boss1_rewind_sequence.get("elapsed", 0.0))
	var playback_start = game.BOSS1_CLOCK_TRAVEL_TIME
	var progress = clamp((elapsed - playback_start) / game.BOSS1_REWIND_PLAYBACK_TIME, 0.0, 1.0) if elapsed >= playback_start else 0.0
	var cursor = int(round(lerp(float(game.boss1_rewind_history.size() - 1), 0.0, progress)))
	var variant = int(game.boss1_rewind_sequence.get("variant", 0))
	var variant_color = game._chrono_variant_color(variant)
	var player_path = PackedVector2Array()
	var boss_path = PackedVector2Array()
	var step = max(1, int(ceil(float(cursor + 1) / 70.0)))
	for history_index in range(0, cursor + 1, step):
		var snapshot: Dictionary = game.boss1_rewind_history[history_index]
		player_path.append(Vector2(snapshot["player_pos"]) - camera)
		boss_path.append(Vector2(snapshot["boss_pos"]) - camera)
	if player_path.size() >= 2:
		game.draw_polyline(player_path, Color(0.02, 0.06, 0.12, 0.72), 9.0, true)
		game.draw_polyline(player_path, Color(0.16, 0.82, 1.0, 0.76), 5.0, true)
		game.draw_polyline(player_path, Color(0.88, 1.0, 1.0, 0.86), 1.6, true)
	if boss_path.size() >= 2:
		game.draw_polyline(boss_path, Color(0.02, 0.04, 0.1, 0.62), 9.0, true)
		game.draw_polyline(boss_path, Color(variant_color, 0.64), 4.0, true)
	for marker_index in range(0, player_path.size(), max(1, int(player_path.size() / 8.0))):
		game.draw_circle(player_path[marker_index], 4.0, Color(0.82, 1.0, 1.0, 0.72))
	for echo_offset in [5, 12, 22, 34]:
		var echo_index = min(game.boss1_rewind_history.size() - 1, cursor + echo_offset)
		if echo_index == cursor:
			continue
		var echo: Dictionary = game.boss1_rewind_history[echo_index]
		var alpha = max(0.06, 0.26 - float(echo_offset) * 0.0045)
		game._draw_entity_fit(game._player_texture(), Vector2(echo["player_pos"]) - camera, Vector2(74, 88), Color(0.42, 0.92, 1.0, alpha), game._should_flip_player_sprite())
		game._draw_entity_fit(game._boss_texture(), Vector2(echo["boss_pos"]) - camera, Vector2(184, 170), Color(variant_color.r, variant_color.g, variant_color.b, alpha * 0.86), true)
	for visual in game.boss1_rewind_visual_projectiles:
		var pos = Vector2(visual.get("pos", game.player_pos)) - camera
		var visual_kind = String(visual.get("visual", "player"))
		match visual_kind:
			"player":
				var palette = game._projectile_palette(String(visual.get("kind", "eletrica")))
				var direction = Vector2(visual.get("dir", Vector2.RIGHT)).normalized()
				game.draw_line(pos - direction * 18.0, pos + direction * 5.0, Color(palette["glow"].r, palette["glow"].g, palette["glow"].b, 0.82), 5.0)
				game.draw_circle(pos, 4.5, Color.WHITE)
			"returning":
				game.draw_circle(pos, 10.0, Color(0.84, 0.32, 1.0, 0.42))
				game.draw_arc(pos, 12.0, 0.0, TAU, 18, Color(1.0, 0.54, 0.96, 0.92), 2.4)
			"enemy":
				game.draw_circle(pos, 7.0, Color(1.0, 0.24, 0.52, 0.72))
				game.draw_arc(pos, 10.0, 0.0, TAU, 16, Color(0.64, 0.28, 1.0, 0.7), 2.0)
			"shockwave", "boss_wave":
				game.draw_arc(pos, float(visual.get("radius", 0.0)), 0.0, TAU, 64, Color(0.34, 0.92, 1.0, 0.56), 3.0)
			"prism":
				var diamond = PackedVector2Array([pos + Vector2(0, -16), pos + Vector2(16, 0), pos + Vector2(0, 16), pos + Vector2(-16, 0), pos + Vector2(0, -16)])
				game.draw_polyline(diamond, Color(0.42, 1.0, 0.94, 0.86), 3.0)


static func _draw_boss1_rewind_overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void :
	if game.boss1_rewind_sequence.is_empty():
		return
	var elapsed = float(game.boss1_rewind_sequence.get("elapsed", 0.0))
	var center_target = viewport * 0.5
	var travel_progress = clamp(elapsed / game.BOSS1_CLOCK_TRAVEL_TIME, 0.0, 1.0)
	var smooth_travel = smoothstep(0.0, 1.0, travel_progress)
	var clock_origin = game.boss_pos - camera + Vector2(0, -36)
	var clock_center = clock_origin.lerp(center_target, smooth_travel)
	var clock_scale = lerp(0.34, 1.0, smooth_travel)
	var turn_progress = clamp((elapsed - game.BOSS1_CLOCK_TRAVEL_TIME) / game.BOSS1_CLOCK_TURN_TIME, 0.0, 1.0)
	var variant = int(game.boss1_rewind_sequence.get("variant", 0))
	var variant_color = game._chrono_variant_color(variant)
	var overlay_alpha = 0.06 + 0.09 * smooth_travel
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.01, 0.04, 0.1, overlay_alpha), true)
	for scan_index in range(7):
		var scan_y = fposmod(elapsed * -180.0 + scan_index * viewport.y / 7.0, viewport.y)
		game.draw_line(Vector2(0, scan_y), Vector2(viewport.x, scan_y), Color(0.22, 0.86, 1.0, 0.06), 2.0)
	var radius = 106.0 * clock_scale
	game.Boss1VFX.clock_shell(game, clock_center, radius, elapsed, variant_color, game._get_boss_wave_quality_profile() == "LOW")
	game.draw_arc(clock_center, radius * 0.88, 0.0, TAU, 80, Color(1.0, 0.42, 0.78, 0.52), 2.0 * clock_scale)
	match variant:
		1:
			game.draw_arc(clock_center + Vector2( - radius * 0.16, 0), radius * 0.72, PI * 0.2, PI * 1.2, 54, Color(1.0, 0.48, 0.82, 0.34), 3.0)
			game.draw_arc(clock_center + Vector2(radius * 0.16, 0), radius * 0.72, PI * 1.2, PI * 2.2, 54, Color(0.42, 0.92, 1.0, 0.34), 3.0)
		2:
			for spiral in range(3):
				var spiral_angle = - turn_progress * TAU * 2.0 + spiral * TAU / 3.0
				game.draw_arc(clock_center, radius * (0.35 + spiral * 0.16), spiral_angle, spiral_angle + PI * 1.25, 42, Color(0.72, 0.52, 1.0, 0.3), 2.0)
		3:
			for fracture in range(8):
				var fracture_angle = fracture * TAU / 8.0 + turn_progress * 0.4
				game.draw_line(clock_center + Vector2.from_angle(fracture_angle) * radius * 0.3, clock_center + Vector2.from_angle(fracture_angle + 0.08) * radius * 0.78, Color(1.0, 0.78, 0.3, 0.34), 2.0)
	for tick_index in range(60):
		var angle = - PI * 0.5 + tick_index * TAU / 60.0
		var major = tick_index % 5 == 0
		var outer = clock_center + Vector2.from_angle(angle) * radius * 0.82
		var inner = clock_center + Vector2.from_angle(angle) * radius * (0.68 if major else 0.75)
		game.draw_line(inner, outer, Color(0.82, 0.98, 1.0, 0.92 if major else 0.54), (3.2 if major else 1.4) * clock_scale)
	var shown_minutes = lerp(10.0, 0.0, turn_progress)
	var minute_angle = - PI * 0.5 + shown_minutes * TAU / 60.0
	var hour_angle = - PI * 0.5 + (11.0 + shown_minutes / 60.0) * TAU / 12.0
	if turn_progress > 0.0 and turn_progress < 1.0:
		for trail_index in range(1, 5):
			var trail_minutes = min(10.0, shown_minutes + trail_index * 0.65)
			var trail_angle = - PI * 0.5 + trail_minutes * TAU / 60.0
			game.draw_line(clock_center, clock_center + Vector2.from_angle(trail_angle) * radius * 0.62, Color(0.32, 0.88, 1.0, 0.13), 3.0 * clock_scale)
	game.Boss1VFX.streak(game, clock_center, clock_center + Vector2.from_angle(hour_angle) * radius * 0.44, Color(1.0, 0.35, 0.72), 10.0 * clock_scale)
	game.Boss1VFX.streak(game, clock_center, clock_center + Vector2.from_angle(minute_angle) * radius * 0.64, Color(0.62, 0.98, 1.0), 7.0 * clock_scale)
	game.draw_circle(clock_center, 8.0 * clock_scale, Color.WHITE)
	var minute_label = int(round(shown_minutes))
	game._draw_centered("11:%02d PM" % minute_label, clock_center + Vector2(0, radius * 0.46), int(18 * clock_scale), Color(0.82, 0.98, 1.0))
	if elapsed < game.BOSS1_CLOCK_TRAVEL_TIME:
		game._draw_centered("CRONO-RUPTURA", clock_center + Vector2(0, radius + 34.0), 20, Color(0.42, 0.92, 1.0))
	elif turn_progress < 1.0:
		game._draw_centered("TEMPO -%.1fs" % (turn_progress * game.BOSS1_REWIND_SECONDS), clock_center + Vector2(0, radius + 40.0), 22, Color(1.0, 0.42, 0.76))
	else:
		game._draw_centered("LINHA RESTAURADA", clock_center + Vector2(0, radius + 40.0), 22, Color(0.48, 0.94, 1.0))


static func _draw_boss1_oceanic_slam_impact(game: Node2D, camera: Vector2) -> void :
	if not game.boss_active or game.current_phase != 1:
		return
	if game.boss_stage_timer <= 0.0 or game.boss_stage_timer > (game.BOSS_STAGE_JUMP_TIME - game.BOSS_STAGE_SLAM_TIME):
		return
	var time_since_slam: float = (game.BOSS_STAGE_JUMP_TIME - game.BOSS_STAGE_SLAM_TIME) - game.boss_stage_timer
	if time_since_slam > 0.85:
		return
	var center: Vector2 = game.boss_pos - camera
	var progress: float = clamp(time_since_slam / 0.85, 0.0, 1.0)
	var radius: float = lerpf(20.0, 280.0, progress)
	var alpha: float = (1.0 - progress) * 0.75
	var profile: String = game._get_boss_wave_quality_profile()

	game.Boss1VFX.arc(game, center, radius, 0.0, TAU, Color(0.28, 0.86, 1.0, alpha), 10.0 * (1.0 - progress) + 2.0, profile == "LOW")
	game.draw_arc(center, radius * 0.7, 0.0, TAU, 48, Color(0.08, 0.62, 0.92, alpha * 0.6), 8.0)
	game.draw_arc(center, radius, 0.0, TAU, 64, Color(0.32, 0.88, 1.0, alpha), 5.0)
	game.draw_arc(center, radius + 3.0, 0.0, TAU, 64, Color(0.9, 0.98, 1.0, alpha * 0.85), 2.0)

	if profile != "LOW":
		var ray_count: int = 12 if profile == "HIGH" else 8
		for i in range(ray_count):
			var ray_angle: float = float(i) * TAU / float(ray_count) + time_since_slam * 0.5
			var r_inner: Vector2 = center + Vector2.from_angle(ray_angle) * (radius * 0.4)
			var r_outer: Vector2 = center + Vector2.from_angle(ray_angle) * (radius * 1.1)
			game.draw_line(r_inner, r_outer, Color(0.5, 0.95, 1.0, alpha * 0.5), 2.0)


static func _draw_boss_wave_safe_sector(game: Node2D, center: Vector2, angle: float, size: float, radius: float, alpha: float, enraged: bool = false) -> void :
	var profile: String = game._get_boss_wave_quality_profile()
	var points = PackedVector2Array([center])
	var segments = 14
	for segment in range(segments + 1):
		var sector_angle = angle - size * 0.5 + size * float(segment) / float(segments)
		points.append(center + Vector2.from_angle(sector_angle) * radius)

	var fill_color: Color = Color(0.04, 0.78, 0.72, alpha) if not enraged else Color(0.02, 0.85, 0.82, alpha * 1.1)
	game.draw_polygon(points, PackedColorArray([fill_color]))

	var left = center + Vector2.from_angle(angle - size * 0.5) * radius
	var right = center + Vector2.from_angle(angle + size * 0.5) * radius
	var border_color: Color = Color(0.32, 1.0, 0.84, min(0.82, alpha * 2.6))
	game.draw_line(center, left, border_color, 2.2)
	game.draw_line(center, right, border_color, 2.2)

	if profile != "LOW" and alpha > 0.06:
		var line_step: float = 140.0
		var max_r: float = min(radius, 600.0)
		var step_r: float = 120.0
		while step_r < max_r:
			var arc_left: Vector2 = center + Vector2.from_angle(angle - size * 0.35) * step_r
			var arc_right: Vector2 = center + Vector2.from_angle(angle + size * 0.35) * step_r
			game.draw_line(arc_left, arc_right, Color(0.4, 0.98, 0.9, alpha * 0.45), 1.2)
			step_r += line_step


static func _draw_boss_wave_water_body(game: Node2D, center: Vector2, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void :
	var c_base: Color = Color(0.02, 0.22, 0.58, 0.52) if enraged else Color(0.04, 0.28, 0.68, 0.48)
	var c_core: Color = Color(0.0, 0.65, 0.92, 0.82) if enraged else Color(0.08, 0.58, 0.88, 0.78)
	var c_upper: Color = Color(0.45, 0.92, 1.0, 0.88) if enraged else Color(0.32, 0.84, 0.96, 0.82)

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)

		if game.current_phase == 1:
			game.Boss1VFX.arc(game, center, radius, a1, a2, c_core, width, profile == "LOW")
			continue
		game.draw_arc(center, radius, a1, a2, 58, c_base, width + 7.0)
		game.draw_arc(center, radius, a1, a2, 58, c_core, width + 1.0)

		if profile != "LOW":
			game.draw_arc(center, radius + width * 0.15, a1, a2, 58, c_upper, max(2.0, width * 0.4))


static func _draw_boss_wave_crest_and_foam(game: Node2D, center: Vector2, wave: Dictionary, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void :
	var age: float = float(wave.get("age", 0.0))
	var wave_idx: int = int(wave.get("idx", 0))

	var crest_color: Color = Color(0.94, 0.99, 1.0, 0.95)
	var undertone_color: Color = Color(0.45, 0.92, 1.0, 0.86) if enraged else Color(0.38, 0.88, 0.98, 0.80)

	var crest_r: float = radius + width * 0.45

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)

		if profile == "LOW":
			game.draw_arc(center, crest_r, a1, a2, 58, undertone_color, 4.0)
			game.draw_arc(center, crest_r + 1.0, a1, a2, 58, crest_color, 2.0)
		else:
			var segments: int = 42
			var arc_len: float = a2 - a1
			var pts_undertone: PackedVector2Array = PackedVector2Array()
			var pts_crest: PackedVector2Array = PackedVector2Array()

			for s in range(segments + 1):
				var frac: float = float(s) / float(segments)
				var angle: float = a1 + frac * arc_len
				var jitter: float = sin(angle * 16.0 + age * 14.0 + float(wave_idx) * 2.5) * (2.2 if enraged else 1.5)
				var cur_r: float = crest_r + jitter
				pts_crest.append(center + Vector2.from_angle(angle) * cur_r)
				pts_undertone.append(center + Vector2.from_angle(angle) * (cur_r - 1.5))

			if pts_undertone.size() > 1:
				game.draw_polyline(pts_undertone, undertone_color, 4.0, true)
			if pts_crest.size() > 1:
				game.draw_polyline(pts_crest, crest_color, 2.0, true)

		var foam_step: float = 0.08 if enraged else 0.12
		if profile == "LOW":
			foam_step = 0.24

		var angle_curr: float = a1
		var step_i: int = 0
		while angle_curr < a2:
			step_i += 1
			var foam_time: float = age * 2.4 if game.current_phase == 1 else floor(age * 8.0) * 0.3
			var h1: float = sin(float(wave_idx) * 17.3 + float(step_i) * 9.1 + foam_time)
			var h2: float = cos(float(step_i) * 13.7 + float(wave_idx) * 5.2)

			if h1 > (0.1 if profile == "HIGH" else 0.35):
				var f_angle: float = angle_curr + h2 * 0.03
				var f_dist: float = crest_r + h1 * (3.5 if enraged else 2.5)
				var foam_pos: Vector2 = center + Vector2.from_angle(f_angle) * f_dist
				var foam_size: float = 2.0 + abs(h2) * (2.4 if enraged else 1.8)
				var foam_col: Color = Color(0.96, 1.0, 1.0, 0.85 + h1 * 0.15) if h2 > 0.0 else Color(0.6, 0.95, 1.0, 0.78)

				game.draw_circle(foam_pos, foam_size, foam_col)

				if profile == "HIGH" and h1 > 0.65:
					var spray_pos: Vector2 = center + Vector2.from_angle(f_angle + 0.015) * (f_dist + 4.5)
					game.draw_circle(spray_pos, 1.2, Color(0.9, 0.98, 1.0, 0.7))

			angle_curr += foam_step


static func _draw_boss_wave_trail(game: Node2D, center: Vector2, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void :
	if profile == "LOW":
		return

	var trail_r: float = radius - width * 0.55
	var trail_width: float = width * 0.7
	var trail_color: Color = Color(0.02, 0.35, 0.75, 0.32) if not enraged else Color(0.01, 0.45, 0.85, 0.42)

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)
		game.draw_arc(center, trail_r, a1, a2, 48, trail_color, trail_width)


static func _draw_boss_attacks(game: Node2D, camera: Vector2) -> void :
	game._draw_boss1_time_wave(camera)
	game._draw_boss1_absorb(camera)
	game._draw_boss1_oceanic_slam_impact(camera)
	var profile: String = game._get_boss_wave_quality_profile()
	for wave_data in game.boss_transition_waves:
		var wave: Dictionary = wave_data
		if game.current_phase == 1 and game._is_world_replica():
			wave = wave.duplicate()
			var prediction: float = game._boss1_visual_prediction()
			var old_age: float = float(wave.get("age", 0.0))
			var moving_time: float = maxf(0.0, old_age + prediction - maxf(old_age, float(wave.get("warning", game.BOSS_STAGE_WAVE_WARNING))))
			wave["age"] = old_age + prediction
			wave["radius"] = float(wave.get("radius", 0.0)) + float(wave.get("speed", 0.0)) * moving_time
		var center = Vector2(wave["pos"]) - camera
		var enraged = bool(wave.get("enraged", false))
		if String(wave.get("kind", "")) == "dupla_abertura":
			var age = float(wave.get("age", 0.0))
			var warning = float(wave.get("warning", game.BOSS_STAGE_WAVE_WARNING))
			var opening = float(wave["open_angle"])
			var opening_size = float(wave["open_size"])
			var warning_progress = clamp(age / max(0.01, warning), 0.0, 1.0)
			var sector_alpha = (0.18 + warning_progress * 0.12) if age < warning else 0.08
			game._draw_boss_wave_safe_sector(center, opening, opening_size, 780.0, sector_alpha, enraged)
			game._draw_boss_wave_safe_sector(center, opening + PI, opening_size, 780.0, sector_alpha, enraged)
			if age < warning:
				game.draw_circle(center, 44.0 + warning_progress * 28.0, Color(0.08, 0.65, 0.92, 0.12 + warning_progress * 0.15))
				game.draw_arc(center, 48.0 + warning_progress * 30.0, 0.0, TAU, 52, Color(0.4, 0.95, 1.0, 0.8), 3.0)
				continue
			var radius = float(wave["radius"])
			var width = float(wave.get("width", 20.0))
			var half_gap = opening_size * 0.5
			var dangerous_arcs = [
				Vector2(opening + half_gap, opening + PI - half_gap), 
				Vector2(opening + PI + half_gap, opening + TAU - half_gap)
			]
			game._draw_boss_wave_trail(center, radius, dangerous_arcs, width, enraged, profile)
			game._draw_boss_wave_water_body(center, radius, dangerous_arcs, width, enraged, profile)
			game._draw_boss_wave_crest_and_foam(center, wave, radius, dangerous_arcs, width, enraged, profile)
			game._draw_boss_wave_gate_markers(center, radius, opening, opening_size, enraged)
			continue
		var start = float(wave.get("open_angle", 0.0)) + float(wave.get("open_size", 0.0)) * 0.5
		var end = start + TAU - float(wave.get("open_size", 0.0))
		var fallback_arcs = [Vector2(start, end)]
		var fallback_width = float(wave.get("width", 20.0))
		var fallback_radius = float(wave.get("radius", 0.0))
		game._draw_boss_wave_water_body(center, fallback_radius, fallback_arcs, fallback_width, enraged, profile)
		game._draw_boss_wave_crest_and_foam(center, wave, fallback_radius, fallback_arcs, fallback_width, enraged, profile)
	for attack in game.boss_attacks:
		var age = float(attack.get("age", 0.0))
		if age < 0.0:
			continue
		if game.current_phase == 1:
			age += game._boss1_visual_prediction()
			if game.Boss1VFX.attack(game, attack, game.boss_pos - camera, Vector2(attack.get("target", game.boss_pos)) - camera, game.time_alive, age, profile == "LOW"):
				continue
		var kind = String(attack["kind"])
		if kind.ends_with("_telegraph") and kind.begins_with("boss6_"):
			var target = Vector2(attack.get("target", game.boss_pos)) - camera
			var origin = Vector2(attack.get("origin", game.boss_pos)) - camera
			var duration = maxf(0.01, float(attack.get("duration", 1.0)))
			var p = clampf(age / duration, 0.0, 1.0)
			game.draw_line(origin, target, Color(0.64, 1.0, 0.2, 0.2 + p * 0.38), 3.0, true)
			game.draw_arc(target, 52.0 + p * 18.0, - game.time_alive * 2.0, TAU - game.time_alive * 2.0, 52, Color(0.72, 1.0, 0.24, 0.56), 2.4)
			game._draw_centered("CHAGA", target + Vector2(0, -62), 13, Color(0.82, 1.0, 0.34, 0.86))
			continue
		match kind:
			game.BOSS7_ATTACK_FEATHER:
				var pos7 = Vector2(attack.get("pos", game.boss_pos)) - camera
				var dir7 = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				game.PhoenixFire.draw_flame(game, pos7, 12.0, 39.0, game.time_alive, float(attack.get("phase", 0.0)), 0.76, -dir7, game._phase7_visual_budget_enabled())
				var side7 = dir7.orthogonal()
				var feather_tip = pos7 + dir7 * 14.0
				var feather_tail = pos7 - dir7 * 13.0
				game.draw_line(feather_tail - side7 * 3.0, feather_tip, Color(0.18, 0.04, 0.02, 0.78), 7.0, true)
				game.draw_line(feather_tail, feather_tip, Color(1.0, 0.52, 0.08, 0.92), 4.0, true)
				game.draw_line(feather_tail + side7 * 4.0, feather_tip - dir7 * 4.0, Color(1.0, 0.88, 0.28, 0.72), 2.0, true)
			game.BOSS7_ATTACK_WING:
				var origin7 = Vector2(attack.get("origin", game.boss_pos)) - camera
				var dir_wing = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				var p_wing = clampf(age / maxf(0.01, float(attack.get("duration", 1.0))), 0.0, 1.0)
				var facing7 = dir_wing.angle()
				var flame_count: int = 8 if game._phase7_visual_budget_enabled() else 16
				for flame_index in range(flame_count):
					var angle: float = lerpf(facing7 - game.BOSS7_WING_HALF_ANGLE, facing7 + game.BOSS7_WING_HALF_ANGLE, float(flame_index) / (flame_count - 1))
					var flame_pos: Vector2 = origin7 + Vector2.from_angle(angle) * game.BOSS7_WING_RANGE * (0.25 + p_wing * 0.7)
					game.PhoenixFire.draw_flame(game, flame_pos, 24.0, 52.0, game.time_alive, float(flame_index), 1.0 - p_wing * 0.8, Vector2.UP, game._phase7_visual_budget_enabled())
				game.draw_arc(origin7, game.BOSS7_WING_RANGE * (0.75 + p_wing * 0.25), facing7 - game.BOSS7_WING_HALF_ANGLE, facing7 + game.BOSS7_WING_HALF_ANGLE, 46, Color(1.0, 0.62, 0.12, 0.52 * (1.0 - p_wing * 0.4)), 14.0, true)
				game.draw_arc(origin7, game.BOSS7_WING_RANGE * 0.55, facing7 - game.BOSS7_WING_HALF_ANGLE * 0.72, facing7 + game.BOSS7_WING_HALF_ANGLE * 0.72, 38, Color(1.0, 0.94, 0.36, 0.42), 4.0, true)
			game.BOSS7_ATTACK_DIVE_TRAIL:
				var a7 = Vector2(attack.get("a", game.boss_pos)) - camera
				var b7 = Vector2(attack.get("b", game.boss_pos)) - camera
				var fade7 = 1.0 - clampf(age / maxf(0.01, float(attack.get("duration", 1.0))), 0.0, 1.0)
				game.PhoenixFire.draw_strip(game, a7, b7, 34.0, game.time_alive, fade7, game._phase7_visual_budget_enabled())
			game.BOSS7_ATTACK_THERMAL:
				var p_thermal = clampf(age / game.BOSS7_THERMAL_WARNING, 0.0, 1.0)
				for spot in Array(attack.get("spots", [])):
					var thermal_screen = Vector2(spot) - camera
					game.draw_circle(thermal_screen, game.BOSS7_THERMAL_RADIUS * (0.25 + p_thermal * 0.75), Color(1.0, 0.22, 0.04, 0.08 + p_thermal * 0.08))
					game.draw_arc(thermal_screen, game.BOSS7_THERMAL_RADIUS * (0.3 + p_thermal * 0.7), -game.time_alive * 3.0, TAU - game.time_alive * 3.0, 64, Color(1.0, 0.6, 0.12, 0.72), 3.0, true)
					if not bool(attack.get("fired", false)):
						game.draw_line(game.boss_pos - camera, thermal_screen, Color(1.0, 0.44, 0.08, 0.16 + p_thermal * 0.28), 3.0, true)
						game.PhoenixFire.draw_flame(game, thermal_screen, 16.0, 8.0 + 22.0 * p_thermal, game.time_alive, float(thermal_screen.x), 0.35 * p_thermal, Vector2.UP, true)
					else:
						var burst_fade: float = 1.0 - clampf((age - game.BOSS7_THERMAL_WARNING) / maxf(0.01, float(attack.get("duration", 1.25)) - game.BOSS7_THERMAL_WARNING), 0.0, 1.0)
						game.PhoenixFire.draw_burst(game, thermal_screen, game.BOSS7_THERMAL_RADIUS * 0.72, game.time_alive, burst_fade, game._phase7_visual_budget_enabled())
			game.BOSS7_ATTACK_ASH_RAIN:
				for drop in Array(attack.get("drops", [])):
					var drop_data: Dictionary = drop
					var ground = Vector2(drop_data.get("pos", game.player_pos)) - camera
					var drop_age = float(drop_data.get("age", 0.0))
					var warn = maxf(0.01, float(drop_data.get("warn", 0.52)))
					var p_drop = clampf(drop_age / warn, 0.0, 1.0)
					if not bool(drop_data.get("hit", false)):
						game.draw_circle(ground, 42.0 * (0.45 + p_drop * 0.55), Color(0.95, 0.38, 0.08, 0.1 + p_drop * 0.16))
						game.draw_arc(ground, 42.0, -game.time_alive * 2.8, TAU - game.time_alive * 2.8, 42, Color(1.0, 0.62, 0.16, 0.76), 2.0)
						var sky = ground + Vector2(0, -180.0 + p_drop * 180.0)
						game.PhoenixFire.draw_projectile(game, sky, Vector2.DOWN, 8.0 + p_drop * 4.0, game.time_alive, float(drop_data.get("phase", 0.0)), game._phase7_visual_budget_enabled())
					else:
						var fade_drop = 1.0 - clampf((drop_age - warn) / 0.52, 0.0, 1.0)
						game.draw_circle(ground, 38.0 + 16.0 * (1.0 - fade_drop), Color(0.38, 0.28, 0.22, 0.16 * fade_drop))
						game.PhoenixFire.draw_burst(game, ground, 35.0, game.time_alive, fade_drop, game._phase7_visual_budget_enabled())
			game.BOSS7_ATTACK_CROWN:
				var crown_alpha = 0.35 + 0.25 * sin(game.time_alive * 9.0)
				for lane in range(6):
					var angle7 = deg_to_rad(float(lane * 60))
					var fired = (lane % 2 == 0 and age >= 1.1) or (lane % 2 == 1 and age >= 1.58)
					var line_color = Color(1.0, 0.8, 0.18, 0.64 if fired else crown_alpha)
					var a_crown: Vector2 = game.boss_pos - Vector2.from_angle(angle7) * 360.0 - camera
					var b_crown: Vector2 = game.boss_pos + Vector2.from_angle(angle7) * 360.0 - camera
					game.draw_line(a_crown, b_crown, Color(0.24, 0.04, 0.01, 0.22), 64.0, true)
					game.draw_line(a_crown, b_crown, line_color, 8.0 if fired else 3.0, true)
					if fired:
						var fire_age: float = age - (1.1 if lane % 2 == 0 else 1.58)
						game.PhoenixFire.draw_strip(game, a_crown, b_crown, 26.0, game.time_alive, clampf(1.0 - fire_age / 0.6, 0.0, 1.0), game._phase7_visual_budget_enabled())
			game.BOSS6_ABILITY_ACID_BLOOM, game.BOSS6_ABILITY_INCUBATION:
				var warn_time = game.BOSS6_ACID_BLOOM_FALL_TIME if kind == game.BOSS6_ABILITY_ACID_BLOOM else 0.9
				var p = clampf(age / warn_time, 0.0, 1.0)
				for spot in Array(attack.get("spots", [])):
					var screen = Vector2(spot) - camera
					var color = Color(0.42, 1.0, 0.12, 0.7) if kind == game.BOSS6_ABILITY_ACID_BLOOM else Color(1.0, 0.62, 0.28, 0.64)
					var radius = game.BOSS6_ACID_BLOOM_RADIUS if kind == game.BOSS6_ABILITY_ACID_BLOOM else 42.0
					game.draw_circle(screen, radius * (0.18 + p * 0.82), Color(color.r, color.g, color.b, 0.05 + p * 0.1))
					game.draw_arc(screen, radius * (0.22 + p * 0.78), - game.time_alive * 2.2, TAU - game.time_alive * 2.2, 72, color, 2.4)
					if kind == game.BOSS6_ABILITY_ACID_BLOOM and not bool(attack.get("spawned", false)):
						var high: Vector2 = (game.boss_pos - camera) + Vector2(0, -170.0 - sin(p * PI) * 80.0)
						var spit_pos: Vector2 = high.lerp(screen, p)
						game.draw_line(game.boss_pos - camera, spit_pos, Color(0.42, 1.0, 0.12, 0.24), 3.0, true)
						game.draw_circle(spit_pos, 9.0 + p * 5.0, Color(0.58, 1.0, 0.16, 0.84))
			game.BOSS6_ABILITY_SCYTHES:
				var origin = Vector2(attack.get("origin", game.boss_pos))
				var duration = float(attack.get("duration", 2.85))
				for bone in attack.get("bones", []):
					var bone_dict: Dictionary = bone
					var pos = game._boss6_vertebral_scythe_pos(origin, bone_dict, age, duration) - camera
					var dir = Vector2(bone_dict.get("dir", Vector2.RIGHT)).normalized()
					if dir.length() <= 0.05:
						dir = Vector2.RIGHT
					var spin: float = game.time_alive * 10.0 + float(bone_dict.get("phase", 0.0))
					var bone_axis = dir.rotated(sin(spin) * 0.62)
					var side = bone_axis.orthogonal()
					var p0 = pos - bone_axis * 18.0
					var p1 = pos + bone_axis * 18.0
					game.draw_line(p0, p1, Color(0.1, 0.08, 0.05, 0.62), 10.0, true)
					game.draw_line(p0, p1, Color(0.78, 0.74, 0.58, 0.92), 5.0, true)
					game.draw_circle(p0 + side * 3.8, 4.4, Color(0.92, 0.86, 0.68, 0.88))
					game.draw_circle(p0 - side * 3.8, 4.4, Color(0.92, 0.86, 0.68, 0.88))
					game.draw_circle(p1 + side * 3.8, 4.0, Color(0.92, 0.86, 0.68, 0.88))
					game.draw_circle(p1 - side * 3.8, 4.0, Color(0.92, 0.86, 0.68, 0.88))
			game.BOSS6_ABILITY_CHASING_CRACK:
				for trail in Array(attack.get("trail", [])):
					var trail_data: Dictionary = trail
					var fade = clampf(float(trail_data.get("life", 0.0)) / maxf(0.01, float(trail_data.get("max", 0.72))), 0.0, 1.0)
					var pos = Vector2(trail_data.get("pos", game.boss_pos)) - camera
					game.draw_circle(pos, game.BOSS6_CHASING_CRACK_RADIUS * (0.78 + (1.0 - fade) * 0.28), Color(0.08, 0.36, 0.05, 0.1 * fade))
					game.draw_arc(pos, game.BOSS6_CHASING_CRACK_RADIUS * 0.78, game.time_alive * 1.4, game.time_alive * 1.4 + TAU, 50, Color(0.54, 1.0, 0.14, 0.42 * fade), 2.0)
				var current = Vector2(attack.get("pos", game.boss_pos)) - camera
				var pulse = 0.5 + 0.5 * sin(game.time_alive * 14.0 + float(attack.get("phase", 0.0)))
				game.draw_circle(current, game.BOSS6_CHASING_CRACK_RADIUS, Color(0.12, 0.46, 0.04, 0.18))
				game.draw_arc(current, game.BOSS6_CHASING_CRACK_RADIUS + pulse * 7.0, - game.time_alive * 3.6, TAU - game.time_alive * 3.6, 64, Color(0.66, 1.0, 0.18, 0.72), 3.0)
				game.draw_line(current + Vector2(-36, 0).rotated(game.time_alive), current + Vector2(36, 0).rotated(game.time_alive), Color(0.76, 1.0, 0.24, 0.66), 3.0, true)
			game.BOSS6_ABILITY_TAIL:
				for channel in Array(attack.get("channels", [])):
					var channel_data: Dictionary = channel
					var angle = float(channel_data.get("angle", 0.0))
					var start: Vector2 = game.boss_pos - camera
					var end: Vector2 = game.boss_pos + Vector2.from_angle(angle) * 980.0 - camera
					var active = bool(channel_data.get("fired", false))
					game.draw_line(start, end, Color(0.62, 1.0, 0.22, 0.22 if not active else 0.56), 18.0 if not active else 28.0, true)
					game.draw_line(start, end, Color(0.96, 1.0, 0.72, 0.7), 2.0, true)
			game.BOSS6_ABILITY_CARNAGE_TIDE:
				for drop in Array(attack.get("drops", [])):
					var drop_data: Dictionary = drop
					var fall = clampf(float(drop_data.get("fall", 0.0)) / maxf(0.01, float(drop_data.get("max", 0.68))), 0.0, 1.0)
					var ground = Vector2(drop_data.get("pos", game.player_pos)) - camera
					var high: Vector2 = (game.boss_pos - camera) + Vector2(0, -180.0)
					var pos: Vector2 = high.lerp(ground, 1.0 - fall)
					game.draw_line(high, pos, Color(0.62, 1.0, 0.16, 0.18 + 0.22 * (1.0 - fall)), 3.0, true)
					game.draw_circle(ground, game.BOSS6_CARNAGE_POOL_RADIUS * (0.3 + (1.0 - fall) * 0.7), Color(0.5, 1.0, 0.1, 0.09 + 0.08 * (1.0 - fall)))
					game.draw_circle(pos, 10.0 + (1.0 - fall) * 5.0, Color(0.58, 1.0, 0.16, 0.84))
			game.BOSS6_ABILITY_REFLUX:
				var p = clampf(age / 2.2, 0.0, 1.0)
				for object in Array(attack.get("objects", [])):
					var object_data: Dictionary = object
					var pos = Vector2(object_data.get("pos", game.boss_pos)).lerp(game.boss_pos, p) - camera
					game.draw_line(pos, game.boss_pos - camera, Color(0.42, 1.0, 0.18, 0.2 + p * 0.3), 3.0, true)
					game.draw_circle(pos, 7.0, Color(0.62, 1.0, 0.18, 0.6))
				game.draw_arc(game.boss_pos - camera, 70.0 + p * 160.0, - game.time_alive, TAU - game.time_alive, 90, Color(0.58, 1.0, 0.22, 0.42), 4.0)
			"boss6_cracked_heart_wave":
				var center = Vector2(attack.get("origin", game.boss_pos)) - camera
				var p = clampf(age / maxf(0.01, float(attack.get("duration", 1.35))), 0.0, 1.0)
				var radius = lerpf(40.0, 660.0, p)
				var opening = float(attack.get("opening", 0.0))
				var open_size = float(attack.get("open_size", 0.78))
				var start = opening + open_size
				game.draw_arc(center, radius, start, start + PI - open_size * 2.0, 96, Color(1.0, 0.28, 0.2, 0.7 * (1.0 - p * 0.2)), 9.0)
				game.draw_arc(center, radius, start + PI, start + TAU - open_size * 2.0, 96, Color(1.0, 0.28, 0.2, 0.7 * (1.0 - p * 0.2)), 9.0)
			"rat_rain":
				var safe = int(attack.get("safe", 0))
				for lane in range(4):
					var y = game.WORLD_SIZE.y * (0.18 + lane * 0.215) - camera.y
					var c = Color(0.48, 1.0, 0.2, 0.12) if lane == safe else Color(1.0, 0.3, 0.12, 0.22)
					game.draw_rect(Rect2( - camera.x, y - 34.0, game.WORLD_SIZE.x, 68.0), c, true)
					game.draw_line(Vector2( - camera.x, y), Vector2(game.WORLD_SIZE.x - camera.x, y), Color(c.r, c.g, c.b, 0.86), 2.0)
			"rat_spit":
				var dir = Vector2(attack.get("dir", Vector2.RIGHT))
				game.draw_line(game.boss_pos - camera, game.boss_pos - camera + dir * 620.0, Color(0.64, 1.0, 0.18, 0.72), 4.0)
			"miasma_cheese_spit":
				var dir = Vector2(attack.get("dir", Vector2.RIGHT)).normalized()
				var warning_progress: float = clamp(age / max(0.01, float(attack.get("warn", game.BOSS3_MIASMA_SPIT_WARNING))), 0.0, 1.0)
				var mouth: Vector2 = game.boss_pos - camera + dir * 52.0
				game.draw_circle(mouth, 12.0 + warning_progress * 20.0, Color(0.68, 0.9, 0.08, 0.12 + warning_progress * 0.2))
				game.draw_arc(mouth, 16.0 + warning_progress * 22.0, 0.0, TAU, 28, Color(0.9, 1.0, 0.3, 0.82), 3.0)
				game.draw_line(mouth, mouth + dir * (120.0 + warning_progress * 150.0), Color(0.78, 1.0, 0.22, 0.34 + warning_progress * 0.42), 3.0)
			"rat_tail":
				var pulse = clamp(age / 0.52, 0.0, 1.0)
				game.draw_circle(game.boss_pos - camera, 155.0, Color(1.0, 0.48, 0.12, 0.08 + pulse * 0.08))
				game.draw_arc(game.boss_pos - camera, 155.0, 0, TAU, 64, Color(1.0, 0.72, 0.22, 0.78), 4.0)
			"faith_pulse":
				var pos = Vector2(attack.get("pos", game.boss_pos)) - camera
				var dir = Vector2(attack.get("dir", Vector2.RIGHT)).normalized()
				var side = dir.orthogonal()
				var pulse = 0.5 + sin(game.time_alive * 18.0) * 0.5
				var facing = dir.angle()
				var arc_start = facing - PI * 0.25
				var arc_end = facing + PI * 0.25
				game.draw_arc(pos, 78.0 + pulse * 5.0, arc_start, arc_end, 20, Color(0.02, 0.0, 0.03, 0.58), 14.0, true)
				game.draw_arc(pos, 73.0 + pulse * 5.0, arc_start, arc_end, 20, Color(0.82, 1.0, 0.18, 0.76), 7.0, true)
				game.draw_arc(pos, 56.0 + pulse * 4.0, arc_start, arc_end, 18, Color(1.0, 0.88, 0.2, 0.84), 4.0, true)
				game.draw_arc(pos, 39.0 + pulse * 3.0, arc_start, arc_end, 16, Color(0.14, 0.96, 0.3, 0.66), 3.0, true)
				game.draw_line(pos, pos + dir * 78.0 + side * 54.0, Color(0.68, 1.0, 0.16, 0.24), 2.0)
				game.draw_line(pos, pos + dir * 78.0 - side * 54.0, Color(1.0, 0.86, 0.18, 0.24), 2.0)
				for i in range(4):
					var fork = pos - dir * (18.0 + i * 18.0) + side * sin(game.time_alive * 9.0 + i) * 18.0
					game.draw_line(fork, fork + dir * 32.0 + side * game.rng.randf_range(-7.0, 7.0), Color(0.12, 0.95, 0.34, 0.42), 1.6)
			"bubble":
				var progress = clamp(age / float(attack["duration"]), 0.0, 1.0)
				var r = 15.0
				var color = Color(0.0, 1.0, 0.8, 0.45)
				if progress < 0.25:
					r = 15.0 + sin(game.time_alive * 20.0) * 3.0
				elif progress < 0.5:
					r = 50.0 + sin(game.time_alive * 10.0) * 5.0
				elif progress < 0.75:
					r = 65.0 + sin(game.time_alive * 50.0) * 8.0
					color = Color(1.0, 0.0, 0.5, 0.48)
				else:
					r = 90.0 + (progress - 0.75) * 180.0
					color = Color(0.65, 0.15, 1.0, 0.35)
				var p = attack["target"] - camera
				game.draw_circle(p, r, Color(color.r, color.g, color.b, 0.12))
				game.draw_arc(p, r, 0, TAU, 64, color, 4)
				game.draw_line(game.boss_pos - camera, p, Color(0.0, 1.0, 0.8, 0.22), 2)
			"rain":
				var p = attack["target"] - camera
				var local = age
				if local < 2.2:
					var shadow_r = clamp(local / 2.2, 0.0, 1.0) * 35.0
					game.draw_circle(p, shadow_r, Color(0.0, 0.45, 1.0, 0.18))
					game.draw_arc(p, shadow_r, 0, TAU, 32, Color(0.0, 0.75, 1.0, 0.72), 2)
				else:
					game.draw_line(p + Vector2(0, -180 + (local - 2.2) * 360.0), p, Color(0.0, 0.78, 1.0, 0.88), 8)
					game.draw_circle(p, 28.0 + sin(game.time_alive * 16.0) * 4.0, Color(0.0, 0.55, 1.0, 0.22))
			"boiling_bubbles":
				for drop in attack.get("drops", []):
					var drop_age = float(drop.get("age", 0.0)) + (game._boss1_visual_prediction() if game.current_phase == 1 else 0.0)
					var launch = Vector2(drop.get("launch", game.boss_pos))
					var apex = Vector2(drop.get("apex", Vector2(launch.x, -120.0)))
					var target = Vector2(drop.get("target", game.player_pos))
					var phase = float(drop.get("phase", 0.0))
					var pos_world = launch
					var warning = clamp(drop_age / 1.36, 0.0, 1.0)
					var target_screen = target - camera
					var warn_r = 22.0 + warning * 42.0
					game.draw_circle(target_screen, warn_r, Color(0.12, 0.62, 1.0, 0.08 + warning * 0.1))
					game.draw_arc(target_screen, warn_r, 0.0, TAU, 42, Color(0.35, 0.92, 1.0, 0.58 + warning * 0.25), 2.2)
					if drop_age < 0.48:
						var up = smoothstep(0.0, 1.0, drop_age / 0.48)
						pos_world = launch.lerp(apex, up)
						game.draw_line(launch - camera, pos_world - camera, Color(0.28, 0.88, 1.0, 0.38), 5.0)
					elif drop_age < 1.18:
						pos_world = apex
						var glint = apex - camera + Vector2(sin(game.time_alive * 7.0 + phase) * 10.0, 0)
						game.draw_circle(glint, 13.0, Color(0.58, 1.0, 1.0, 0.58))
					else:
						var fall = clamp((drop_age - 1.18) / 0.45, 0.0, 1.0)
						pos_world = apex.lerp(target, fall)
						game.draw_line(pos_world - camera + Vector2(0, -42), target_screen, Color(0.3, 0.86, 1.0, 0.7), 7.0)
					var bubble_pos = pos_world - camera
					var wobble = 1.0 + sin(game.time_alive * 13.0 + phase) * 0.08
					game.Boss1VFX.bubble(game, bubble_pos, 18.0 * wobble, game.time_alive + phase, game.Boss1VFX.CYAN, profile == "LOW")
					if drop_age >= 1.58:
						var splash = clamp((drop_age - 1.58) / 0.42, 0.0, 1.0)
						game.draw_circle(target_screen, 28.0 + splash * 42.0, Color(0.18, 0.78, 1.0, 0.22 * (1.0 - splash)))
						for i in range(8):
							var a = phase + i * TAU / 8.0
							game.draw_line(target_screen, target_screen + Vector2.from_angle(a) * (22.0 + splash * 46.0), Color(0.7, 1.0, 1.0, 0.44 * (1.0 - splash)), 1.8)
			"pressure_bubbles":
				var dir = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				var origin = game.boss_pos - camera
				var pulse = 0.5 + sin(game.time_alive * 12.0) * 0.5
				for i in range(4):
					var p = origin + dir * (42.0 + i * 34.0)
					game.draw_circle(p, 10.0 + i * 3.0, Color(0.22, 0.84, 1.0, 0.08 + pulse * 0.06))
					game.draw_arc(p, 12.0 + i * 3.0, game.time_alive * 5.0, game.time_alive * 5.0 + PI * 1.2, 22, Color(0.88, 1.0, 1.0, 0.3 + pulse * 0.22), 1.7)
			"absorb_retaliation":
				var center = game.boss_pos - camera
				var fired_ratio = float(attack.get("fired", 0)) / max(1.0, float(attack.get("bursts", game.BOSS1_ABSORB_RETALIATE_BURSTS)))
				game.Boss1VFX.arc(game, center, 118.0 + sin(game.time_alive * 9.0) * 5.0, 0.0, TAU, Color(1.0, 0.62, 0.18, 0.94), 6.0, profile == "LOW")
				for spoke in range(8):
					var spoke_dir = Vector2.from_angle(game.time_alive * 1.7 + spoke * TAU / 8.0)
					game.draw_line(center + spoke_dir * 54.0, center + spoke_dir * (170.0 + fired_ratio * 80.0), Color(1.0, 0.82, 0.34, 0.13), 3.0)
			"tide":
				var tide_visual: Dictionary = attack.duplicate()
				tide_visual["age"] = age
				var line_pos = game._boss_tide_line(tide_visual)
				if bool(attack["horizontal"]):
					game.Boss1VFX.tide(game, Vector2(-camera.x, line_pos - camera.y), Vector2(game.WORLD_SIZE.x - camera.x, line_pos - camera.y), game.time_alive, profile == "LOW")
				else:
					game.Boss1VFX.tide(game, Vector2(line_pos - camera.x, -camera.y), Vector2(line_pos - camera.x, game.WORLD_SIZE.y - camera.y), game.time_alive, profile == "LOW")
			"sand":
				var p = attack["target"] - camera
				var r = 48.0 + sin(game.time_alive * 8.0) * 8.0
				game.draw_arc(p, r, 0, TAU, 48, Color(0.78, 0.64, 0.42, 0.72), 5)
				for i in range(8):
					game.draw_circle(p + Vector2.from_angle(game.time_alive * 5.0 + i) * (r * 0.65), 3, Color(0.9, 0.82, 0.62, 0.75))
			"pincer":
				var p = attack["target"] - camera
				var alpha = 0.32 if age < 1.55 else 0.76
				game.draw_line(Vector2(p.x, - camera.y), Vector2(p.x, game.WORLD_SIZE.y - camera.y), Color(1.0, 0.15, 0.55, alpha), 8)
				game.draw_line(Vector2( - camera.x, p.y), Vector2(game.WORLD_SIZE.x - camera.x, p.y), Color(1.0, 0.15, 0.55, alpha), 8)
			"rush":
				var dir = Vector2(attack.get("dir", Vector2.LEFT)).normalized()
				var state = String(attack.get("state", "telegraph"))
				var origin = game.boss_pos - camera
				if state == "telegraph":
					var flash = 0.45 + 0.55 * sin(game.time_alive * 16.0)
					var arrow_center = origin + dir * 118.0
					var side = dir.orthogonal()
					var tip = arrow_center + dir * 42.0
					var left = arrow_center - dir * 24.0 + side * 30.0
					var right = arrow_center - dir * 24.0 - side * 30.0
					game.draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([Color(1.0, 0.04, 0.02, 0.38 + flash * 0.32)]))
					game.draw_polyline(PackedVector2Array([left, tip, right]), Color(1.0, 0.88, 0.78, 0.72 + flash * 0.2), 4.0, false)
					game.draw_line(origin + dir * 38.0, origin + dir * 210.0, Color(1.0, 0.06, 0.02, 0.18 + flash * 0.2), 10.0)
				elif state == "dash":
					for trail_index in range(5):
						var side_offset: Vector2 = dir.orthogonal() * (trail_index - 2) * 28.0
						game.Boss1VFX.streak(game, origin - dir * (230.0 - abs(trail_index - 2) * 24.0) + side_offset, origin + dir * 48.0 + side_offset * 0.95, Color(1.0, 0.38, 0.1, 0.85 - abs(trail_index - 2) * 0.15), 13.0)
				elif state == "grab":
					game.draw_arc(origin, 82.0, 0.0, TAU, 54, Color(1.0, 0.3, 0.1, 0.78), 4.0)
				elif state == "throw":
					game.draw_line(game.player_pos - camera - dir * 90.0, game.player_pos - camera + dir * 20.0, Color(1.0, 0.66, 0.16, 0.62), 8.0)
			"blizzard", "frost_breath", "avalanche", "spin_spit_up", "glacial_stomp", "ice_prison", "flash_freeze", "shield", "ice_pillar":
				game.Boss2VFX.attack(game, attack, camera, profile == "LOW")


static func _draw_boss3_faith_link(game: Node2D, camera: Vector2) -> void :
	if game.current_phase != 3 or game.boss3_faith_link_timer <= 0.0:
		return
	var a = game.boss_pos - camera + Vector2(0, -8)
	var b = game.player_pos - camera + Vector2(0, -12)
	var dir = (b - a).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var side = dir.orthogonal()
	var points = PackedVector2Array()
	for i in range(9):
		var t = float(i) / 8.0
		var wobble = sin(game.time_alive * 10.0 + i * 1.7) * 18.0
		points.append(a.lerp(b, t) + side * wobble)
	game.draw_polyline(points, Color(0.02, 0.0, 0.03, 0.86), 13.0, false)
	game.draw_polyline(points, Color(0.94, 0.88, 0.16, 0.82), 6.0, false)
	game.draw_polyline(points, Color(0.3, 1.0, 0.24, 0.62), 2.4, false)
	game.draw_circle(a, 30.0 + sin(game.time_alive * 8.0) * 4.0, Color(0.74, 1.0, 0.16, 0.2))
	game.draw_circle(b, 26.0 + sin(game.time_alive * 8.0 + 1.0) * 4.0, Color(1.0, 0.86, 0.12, 0.2))


static func _draw_boss_mp_request(game: Node2D, viewport: Vector2) -> void :
	var panel_w: float = min(460.0, viewport.x * 0.86)
	var panel_h = 122.0 if game.boss_mp_request_incoming else 78.0
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, 146.0, panel_w, panel_h)
	var accent = Color(1.0, 0.52, 0.16) if game.boss_mp_request_incoming else Color(1.0, 0.82, 0.24)
	game._draw_holo_panel(panel, accent, true, 0.86)
	var remaining = int(ceil(max(0.0, game.boss_mp_request_timer)))
	var title = "PARCEIRO QUER CHAMAR O BOSS" if game.boss_mp_request_incoming else "CHAMADO DO BOSS ENVIADO"
	game._draw_centered(title, Vector2(panel.get_center().x, panel.position.y + 30.0), game._readable_text_size(15), accent)
	var status = "aguardando confirmacao %ds" % remaining
	if game.boss_mp_request_incoming:
		status = "clique ou enter/espaco em %ds" % remaining
	game._draw_centered(status.to_upper(), Vector2(panel.get_center().x, panel.position.y + 56.0), game._readable_text_size(12), Color(0.98, 0.94, 0.86))
	game.buttons.erase("boss_mp_accept")
	if game.boss_mp_request_incoming:
		game.buttons["boss_mp_accept"] = Rect2(panel.get_center().x - 94.0, panel.end.y - 42.0, 188.0, 32.0)
		game._draw_small_rect_button(game.buttons["boss_mp_accept"], "ACEITAR  ENTER", Color(0.22, 0.09, 0.03, 0.92), Color(1.0, 0.52, 0.16))


static func _draw_phase_mp_request(game: Node2D, viewport: Vector2) -> void :
	var panel_w: float = minf(500.0, viewport.x * 0.88)
	var panel_h: float = 126.0 if game.phase_mp_request_incoming else 84.0
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, 252.0, panel_w, panel_h)
	var accent = Color(0.0, 1.0, 0.82) if game.phase_mp_request_incoming else Color(1.0, 0.82, 0.24)
	game._draw_holo_panel(panel, accent, true, 0.86)
	var remaining: int = int(ceil(maxf(0.0, game.phase_mp_request_timer)))
	var action_label: String = "EXTRACAO" if game.phase_mp_action == "extract" else ("ROTA FARM" if game.phase_mp_action == "farm" else "FASE %d" % game.phase_mp_target)
	var title: String = "EQUIPE QUER TRANSFERIR: %s" % action_label if game.phase_mp_request_incoming else "PEDIDO DE TRANSFERENCIA ENVIADO"
	game._draw_centered(title, Vector2(panel.get_center().x, panel.position.y + 30.0), game._readable_text_size(15), accent)
	game._draw_centered("CONFIRMACOES %d/%d - %ds" % [game.phase_mp_vote_count, game.phase_mp_expected_count, remaining], Vector2(panel.get_center().x, panel.position.y + 58.0), game._readable_text_size(12), Color(0.98, 0.94, 0.86))
	game.buttons.erase("phase_mp_accept")
	if game.phase_mp_request_incoming:
		game.buttons["phase_mp_accept"] = game._phase_mp_accept_rect(viewport)
		game._draw_small_rect_button(game.buttons["phase_mp_accept"], "ACEITAR  ENTER", Color(0.03, 0.18, 0.14, 0.92), accent)


static func _draw_rain_puddles(game: Node2D, camera: Vector2) -> void :
	for puddle in game.puddles:
		if not game._world_point_in_view(Vector2(puddle.get("pos", Vector2.ZERO)), camera, float(puddle.get("r", game.WEATHER_PUDDLE_MAX_SIZE)) + 90.0):
			continue
		var life_alpha = clamp(float(puddle["life"]) / max(0.01, float(puddle["max_life"])), 0.0, 1.0)
		var grow_alpha = clamp(float(puddle.get("grow", 0.0)) / max(0.01, float(puddle.get("grow_time", 1.4))), 0.0, 1.0)
		var alpha = min(life_alpha, grow_alpha)
		var center = Vector2(puddle["pos"]) - camera
		var radius = float(puddle["r"])
		game.WeatherVFX.puddle(game, center, puddle, alpha)
		if game.player_pos.distance_to(Vector2(puddle["pos"])) <= radius:
			game.draw_arc(center, radius + 7.0, 0.0, TAU, 34, Color(0.7, 0.94, 1.0, 0.42), 1.8)


static func _draw_raindrops(game: Node2D, camera: Vector2) -> void :
	var draw_cap: int = game._low_resource_cap(game.WEATHER_MAX_RAIN_DROPS, game.LOW_RESOURCE_RAIN_DROP_CAP)
	var drawn: int = 0
	for drop in game.raindrops:
		if drawn >= draw_cap:
			break
		var ground = Vector2(drop["ground"])
		var pos = Vector2(ground.x, ground.y - float(drop["height"])) - camera
		if not game._screen_point_in_view(pos, 120.0):
			continue
		drawn += 1
		game.WeatherVFX.rain(game, pos, drop, game._rain_intensity())


static func _draw_rain_splashes(game: Node2D, camera: Vector2) -> void :
	var draw_cap: int = 16 if game._memory_saver_active() else (26 if game._runtime_visual_budget_active() else 90)
	var drawn: int = 0
	for splash in game.rain_splashes:
		if drawn >= draw_cap:
			break
		var center = Vector2(splash["pos"]) - camera
		if not game._screen_point_in_view(center, 96.0):
			continue
		drawn += 1
		game.WeatherVFX.splash(game, center, splash, camera)


static func _draw_snowflakes(game: Node2D, camera: Vector2) -> void :
	var draw_cap: int = game._low_resource_cap(game.WEATHER_MAX_SNOW_FLAKES, game.LOW_RESOURCE_SNOW_FLAKE_CAP)
	var drawn: int = 0
	for flake in game.snowflakes:
		if drawn >= draw_cap:
			break
		var pos = Vector2(flake["pos"]) - camera
		if not game._screen_point_in_view(pos, 120.0):
			continue
		drawn += 1
		game.WeatherVFX.snow(game, pos, flake, game.boss2_ultimate_timer > 0.0, game.gfx_low_resource or game._memory_saver_active())
