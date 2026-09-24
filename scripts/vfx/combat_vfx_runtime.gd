extends RefCounted

# Host-owned state and compatibility wrappers are retained during extraction.


static func _particle_budget_available(game: Node2D) -> bool:
	return not game._runtime_visual_budget_active() or game.effects.size() < game._visual_effect_cap()


static func _runtime_visual_budget_active(game: Node2D) -> bool:
	return game.gfx_low_resource or game._memory_saver_active() or game.mobile_adaptive_visual_budget


static func _low_resource_cap(game: Node2D, default_cap: int, low_cap: int) -> int:
	if game._memory_saver_active():
		return mini(low_cap, int(ceil(float(low_cap) * 0.42)))
	if game.mobile_adaptive_visual_budget:
		return mini(low_cap, int(ceil(float(low_cap) * 0.62)))
	return low_cap if game.gfx_low_resource else default_cap


static func _visual_effect_cap(game: Node2D) -> int:
	return game.MEMORY_SAVER_EFFECT_CAP if game._memory_saver_active() else game.LOW_RESOURCE_EFFECT_CAP


static func _phase7_visual_budget_enabled(game: Node2D) -> bool:
	return game.current_phase == 7 and (game.gfx_low_resource or game._memory_saver_active() or game._is_mobile_runtime())


static func _phase7_ember_patch_cap(game: Node2D) -> int:
	if game._memory_saver_active():
		return game.PHASE7_EMBER_PATCH_MEMORY_CAP
	return game.PHASE7_EMBER_PATCH_LOW_CAP if game._phase7_visual_budget_enabled() else game.PHASE7_EMBER_PATCH_CAP


static func _screen_point_in_view(game: Node2D, screen_pos: Vector2, margin: float = 96.0) -> bool:
	var viewport: Vector2 = game.get_viewport_rect().size
	return screen_pos.x >= -margin and screen_pos.y >= -margin and screen_pos.x <= viewport.x + margin and screen_pos.y <= viewport.y + margin


static func _world_point_in_view(game: Node2D, world_pos: Vector2, camera: Vector2, margin: float = 96.0) -> bool:
	return game._screen_point_in_view(world_pos - camera, margin)


static func _trim_visual_effect_arrays(game: Node2D) -> void :
	if not game._runtime_visual_budget_active():
		return
	while game.effects.size() > game._visual_effect_cap():
		game.effects.pop_front()
	var slash_cap: = 18 if game._memory_saver_active() else 42
	while game.slashes.size() > slash_cap:
		game.slashes.pop_front()
	var frost_cap: = 28 if game._memory_saver_active() else 70
	while game.boss2_frost_particles.size() > frost_cap:
		game.boss2_frost_particles.pop_front()
	var phase7_patch_cap: int = game._phase7_ember_patch_cap()
	while game.phase7_ember_patches.size() > phase7_patch_cap:
		game.phase7_ember_patches.pop_front()
	while game.raindrops.size() > game._low_resource_cap(game.WEATHER_MAX_RAIN_DROPS, game.LOW_RESOURCE_RAIN_DROP_CAP):
		game.raindrops.pop_front()
	while game.snowflakes.size() > game._low_resource_cap(game.WEATHER_MAX_SNOW_FLAKES, game.LOW_RESOURCE_SNOW_FLAKE_CAP):
		game.snowflakes.pop_front()
	while game.puddles.size() > game._low_resource_cap(game.WEATHER_MAX_PUDDLES, game.LOW_RESOURCE_PUDDLE_CAP):
		game.puddles.pop_front()
	var splash_cap: int = 16 if game._memory_saver_active() else 26
	while game.rain_splashes.size() > splash_cap:
		game.rain_splashes.pop_front()
	var flame_wave_cap: int = 2 if game._memory_saver_active() else 4
	while game.boss7_flame_waves.size() > flame_wave_cap:
		game.boss7_flame_waves.pop_front()


static func _spawn_boss6_entry_particles(game: Node2D, target: Vector2, source: = Vector2.ZERO) -> void :
	game.boss6_entry_particles.clear()
	for i in range(game.BOSS6_ENTRY_PARTICLES):
		var edge: = posmod(i + game.rng.randi_range(0, 3), 4)
		var start: Vector2 = Vector2.ZERO
		match edge:
			0:
				start = Vector2(game.rng.randf_range(-140.0, game.WORLD_SIZE.x + 140.0), -120.0)
			1:
				start = Vector2(game.WORLD_SIZE.x + 140.0, game.rng.randf_range(-120.0, game.WORLD_SIZE.y + 120.0))
			2:
				start = Vector2(game.rng.randf_range(-140.0, game.WORLD_SIZE.x + 140.0), game.WORLD_SIZE.y + 120.0)
			_:
				start = Vector2(-140.0, game.rng.randf_range(-120.0, game.WORLD_SIZE.y + 120.0))
		if source != Vector2.ZERO:
			start = source + Vector2.from_angle(game.rng.randf_range(0.0, TAU)) * game.rng.randf_range(20.0, 220.0)
		game.boss6_entry_particles.append({
			"start": start, 
			"target": target + Vector2.from_angle(game.rng.randf_range(0.0, TAU)) * game.rng.randf_range(0.0, 74.0), 
			"delay": game.rng.randf_range(0.0, 0.7), 
			"duration": game.rng.randf_range(1.45, game.BOSS6_ENTRY_TIME), 
			"bend": game.rng.randf_range(-260.0, 260.0), 
			"size": game.rng.randf_range(1.4, 3.8), 
			"phase": game.rng.randf_range(0.0, TAU)
		})


static func _spawn_insane_echo_visual(game: Node2D, pos: Vector2, direction: Vector2) -> void :
	game.insane_echo_visuals.append({"pos": pos, "dir": direction.normalized(), "life": 0.72, "max": 0.72, "phase": game.rng.randf_range(0.0, TAU)})
	if game.insane_echo_visuals.size() > 10:
		game.insane_echo_visuals.pop_front()


static func _push_eclipsada_vfx(game: Node2D, visual: Dictionary) -> void :
	if not visual.has("life"):
		visual["life"] = 0.35
	if not visual.has("max"):
		visual["max"] = float(visual["life"])
	visual["color"] = visual.get("color", game._eclipsada_color())
	visual["seed"] = int(visual.get("seed", game.rng.randi()))
	game.eclipsada_vfx.append(visual)
	while game.eclipsada_vfx.size() > 72:
		game.eclipsada_vfx.pop_front()


static func _spawn_contract_break_vfx(game: Node2D, pos: Vector2, clause: String, infractions: int) -> void :
	game.contractual_vfx.append({
		"kind": "gavel", 
		"pos": pos, 
		"clause": clause, 
		"infractions": infractions, 
		"life": 0.62, 
		"max": 0.62, 
		"seed": game.rng.randi()
	})
	game._spawn_radial_particles(pos + Vector2(0, -42), game._contract_clause_color(clause), 8 + infractions * 3)


static func _spawn_tp_cut_visual(game: Node2D, pos: Vector2, cut_index: int) -> void :
	var angle: float = float(cut_index) * 2.399
	var direction: = Vector2.from_angle(angle)
	game.slashes.append({"a": pos - direction * 46.0, "b": pos + direction * 46.0, "life": 0.18, "max": 0.18, "color": Color(1.0, 0.02, 0.1), "width": 15.0})


static func _update_arauto_vfx(game: Node2D, delta: float) -> void :
	for ray in game.arauto_rays:
		ray["life"] = float(ray.get("life", 0.0)) - delta
	for fx in game.arauto_echo_breaks:
		fx["life"] = float(fx.get("life", 0.0)) - delta
	game.arauto_rays = game.arauto_rays.filter( func(ray): return float(ray.get("life", 0.0)) > 0.0)
	game.arauto_echo_breaks = game.arauto_echo_breaks.filter( func(fx): return float(fx.get("life", 0.0)) > 0.0)


static func _spawn_boss2_frost_particle(game: Node2D, pos: Vector2, dir: Vector2) -> void :
	var side = dir.orthogonal().normalized()
	game.boss2_frost_particles.append({
		"pos": pos + side * game.rng.randf_range(-26.0, 26.0), 
		"vel": dir * game.rng.randf_range(240.0, 390.0) + side * game.rng.randf_range(-70.0, 70.0), 
		"life": game.rng.randf_range(0.28, 0.58), 
		"max": 0.58, 
		"size": game.rng.randf_range(8.0, 18.0)
	})


static func _start_phase5_transmute_vfx(game: Node2D, old_dim: String, new_dim: String, dim_color: Color) -> void :
	var old_key: String = game._boss5_dimension_map_key(old_dim)
	var new_key: String = game._boss5_dimension_map_key(new_dim)
	var old_tex: Texture2D = game._get_texture(old_key)
	var new_tex: Texture2D = game._get_texture(new_key)
	if old_tex == null:
		old_tex = game._get_texture("map_phase_5")
	if new_tex == null:
		new_tex = game._get_texture("map_phase_5")

	game.phase5_transmute_active = true
	game.phase5_transmute_timer = 0.0
	game.phase5_transmute_duration = game.BOSS5_TRANSMUTE_VFX_DURATION
	game.phase5_transmute_center = game.player_pos
	game.phase5_transmute_old_tex = old_tex
	game.phase5_transmute_new_tex = new_tex
	game.phase5_transmute_color = dim_color
	game.phase5_transmute_particles.clear()

	for i in range(120):
		var ang: float = game.rng.randf_range(0.0, TAU)
		var speed: float = game.rng.randf_range(500.0, 950.0)
		var radius: float = game.rng.randf_range(2.0, 7.0)
		game.phase5_transmute_particles.append({
			"pos": game.boss_pos, 
			"vel": Vector2.from_angle(ang) * speed, 
			"size": radius, 
			"max_life": game.BOSS5_TRANSMUTE_VFX_DURATION, 
			"life": game.BOSS5_TRANSMUTE_VFX_DURATION
		})


static func _add_boss7_dive_trail(game: Node2D, a: Vector2, b: Vector2) -> void:
	game.modern_boss_controller.add_boss7_dive_trail(a, b)


static func _add_text(game: Node2D, text: String, pos: Vector2, color: Color, life: float, size: int) -> void :
	game.effects.append({"text": text, "pos": pos, "life": life, "max": life, "color": color, "size": size, "vel": Vector2(0, -24)})


static func _spawn_radial_particles(game: Node2D, pos: Vector2, color: Color, count: int) -> void :
	if not game.gfx_particles or not game._particle_budget_available():
		return
	var total: int = game._adaptive_particle_count(count)
	for i in range(total):
		game.effects.append({"text": "", "pos": pos, "life": game.rng.randf_range(0.25, 0.55), "max": 0.55, "color": color, "size": game.rng.randi_range(3, 7), "vel": Vector2.from_angle(game.rng.randf_range(0, TAU)) * game.rng.randf_range(40, 120)})


static func _spawn_bullet_hit_fragments(game: Node2D, pos: Vector2, bullet: Dictionary) -> void :
	if not game.gfx_particles or not game._particle_budget_available():
		return
	var color: Color = bullet.get("color", game._projectile_palette(String(bullet.get("kind", ""))).get("core", Color(0.36, 1.0, 0.94)))
	var dir: Vector2 = Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
	if dir.length() <= 0.05:
		dir = Vector2.RIGHT
	var total: int = game._adaptive_particle_count(20)
	for i in range(total):
		var spread: float = game.rng.randf_range(-1.8, 1.8)
		var shard_dir: Vector2 = dir.rotated(PI + spread).normalized()
		var speed: float = game.rng.randf_range(95.0, 245.0)
		game.effects.append({
			"kind": "bullet_fragment",
			"text": "",
			"pos": pos + shard_dir * game.rng.randf_range(2.0, 10.0),
			"life": game.rng.randf_range(0.24, 0.44),
			"max": 0.44,
			"color": color.lerp(Color.WHITE, game.rng.randf_range(0.1, 0.42)),
			"size": game.rng.randf_range(3.0, 7.0),
			"vel": shard_dir * speed + Vector2.from_angle(game.rng.randf_range(0.0, TAU)) * game.rng.randf_range(12.0, 48.0),
			"phase": game.rng.randf_range(0.0, TAU)
		})


static func _spawn_player_landing_smoke(game: Node2D, pos: Vector2) -> void:
	if not game.gfx_particles or not game._particle_budget_available():
		return
	var total: int = game._adaptive_particle_count(46)
	for i in range(total):
		var angle: float = float(i) * TAU / float(maxi(1, total)) + game.rng.randf_range(-0.12, 0.12)
		var dir: Vector2 = Vector2.from_angle(angle)
		var life: float = game.rng.randf_range(0.56, 0.92)
		game.effects.append({
			"kind": "landing_smoke",
			"text": "",
			"pos": pos + dir * game.rng.randf_range(10.0, 28.0),
			"life": life,
			"max": life,
			"color": Color(0.46 + game.rng.randf_range(-0.05, 0.06), 0.47 + game.rng.randf_range(-0.04, 0.06), 0.42 + game.rng.randf_range(-0.04, 0.06), 0.9),
			"size": game.rng.randf_range(14.0, 28.0),
			"vel": dir * game.rng.randf_range(92.0, 184.0) + Vector2(0.0, game.rng.randf_range(-10.0, 9.0)),
			"phase": game.rng.randf_range(0.0, TAU)
		})


static func _adaptive_particle_count(game: Node2D, count: int) -> int:
	if count <= 0:
		return 0
	if count == 1:
		return 1
	var enemy_count: int = game.enemies.size()
	var factor: = 1.0
	if enemy_count >= 22:
		factor = 0.34
	elif enemy_count >= 16:
		factor = 0.46
	elif enemy_count >= 11:
		factor = 0.62
	elif enemy_count >= 7:
		factor = 0.78
	if game._memory_saver_active():
		factor *= 0.22
	elif game.mobile_adaptive_visual_budget:
		factor *= 0.28
	elif game.gfx_low_resource:
		factor *= 0.45
	var min_count: int = 1 if game._runtime_visual_budget_active() else 2
	return clampi(int(ceil(float(count) * factor)), min_count, count)


static func _spawn_music_notes(game: Node2D, pos: Vector2, count: int) -> void :
	if not game.gfx_particles or not game._particle_budget_available(): return
	var notes = ["â™ª", "â™«", "â™¬", "â™©"]
	for i in range(game._adaptive_particle_count(count)):
		var note = notes[game.rng.randi() % notes.size()]
		var color = Color(1.0, 0.8 + game.rng.randf_range(-0.1, 0.2), 0.2 + game.rng.randf_range(0, 0.3))
		game.effects.append({
			"text": note, 
			"pos": pos + Vector2(game.rng.randf_range(-15, 15), game.rng.randf_range(-15, 15)), 
			"life": game.rng.randf_range(0.8, 1.2), 
			"max": 1.2, 
			"color": color, 
			"size": game.rng.randi_range(16, 24), 
			"vel": Vector2(game.rng.randf_range(-15, 15), game.rng.randf_range(-40, -20)), 
			"kind": "music_note", 
			"phase": game.rng.randf_range(0, TAU)
		})


static func _spawn_secondary_drain_sparks(game: Node2D, pos: Vector2) -> void :
	if not game.gfx_particles or not game._particle_budget_available():
		return
	for i in range(game._adaptive_particle_count(10)):
		var angle: float = - PI * 0.5 + game.rng.randf_range(-1.35, 1.35)
		game.effects.append({
			"text": "", 
			"pos": pos + Vector2(game.rng.randf_range(-26.0, 26.0), game.rng.randf_range(-34.0, 18.0)), 
			"life": game.rng.randf_range(0.16, 0.32), 
			"max": 0.32, 
			"color": Color(1.0, game.rng.randf_range(0.12, 0.34), 0.22, 0.96), 
			"size": game.rng.randi_range(3, 6), 
			"vel": Vector2.from_angle(angle) * game.rng.randf_range(85.0, 190.0)
		})


static func _enemy_shard_color(game: Node2D, enemy: Dictionary) -> Color:
	match String(enemy.get("type", game.ENEMY_COMMON)):
		game.ENEMY_AGGLOMERATOR:
			return Color(0.86, 0.78, 1.0)
		game.ENEMY_STALKER:
			return Color(0.42, 0.94, 1.0)
		game.ENEMY_PROJECTOR:
			return Color(0.84, 0.64, 1.0)
		game.ENEMY_CRYSTAL:
			return Color(0.22, 0.9, 1.0)
		game.ENEMY_CURATER:
			return Color(0.44, 1.0, 0.6)
		game.ENEMY_LARAPIO:
			return Color(0.92, 0.52, 1.0)
		game.ENEMY_ATIRADOR:
			return Color(0.74, 0.88, 1.0)
		game.ENEMY_KAMIKAZE:
			return Color(1.0, 0.52, 0.52)
		game.ENEMY_NEXUS_CARTOGRAPHER:
			return Color(1.0, 0.3, 0.78)
		game.ENEMY_NEXUS_CHRONOPHAGE:
			return Color(1.0, 0.72, 0.18)
		game.ENEMY_NEXUS_REFRACTOR:
			return Color(0.28, 0.9, 1.0)
		game.ENEMY_NEXUS_WEAVER:
			return Color(0.24, 1.0, 0.66)
		game.ENEMY_NEXUS_ECHO:
			return Color(1.0, 0.3, 0.7)
	return Color(0.76, 0.88, 1.0)


static func _spawn_enemy_desfragmentation(game: Node2D, pos: Vector2, color: Color, count: int) -> void :
	if not game.gfx_particles or not game._particle_budget_available():
		return
	var total = int(clamp(game._adaptive_particle_count(count), 6, 28))
	for i in range(total):
		var angle = game.rng.randf_range(0.0, TAU)
		var speed = game.rng.randf_range(90.0, 250.0)
		var size = game.rng.randf_range(4.0, 10.0)
		game.effects.append({
			"kind": "enemy_shard", 
			"text": "", 
			"pos": pos + Vector2.from_angle(angle) * game.rng.randf_range(6.0, 20.0), 
			"life": game.rng.randf_range(0.85, 1.25), 
			"max": 1.25, 
			"color": Color(color.r, color.g, color.b, 1.0), 
			"size": size, 
			"vel": Vector2.from_angle(angle) * speed, 
			"speed": speed, 
			"home_speed": game.rng.randf_range(360.0, 560.0), 
			"delay": game.rng.randf_range(0.05, 0.18), 
			"phase": game.rng.randf_range(0.0, TAU), 
			"spin": game.rng.randf_range(5.0, 11.0)
		})


static func _projectile_palette(game: Node2D, kind: String) -> Dictionary:
	match kind:
		"eletrica":
			return {"core": Color(0.76, 1.0, 1.0), "glow": Color(0.1, 0.95, 1.0, 0.92), "trail": Color(0.82, 0.22, 1.0, 0.46), "size": 8.0, "trail_size": 7.0}
		"eletrica_charged":
			return {"core": Color(1.0, 1.0, 1.0), "glow": Color(0.18, 1.0, 1.0, 1.0), "trail": Color(0.92, 0.32, 1.0, 0.62), "size": 11.0, "trail_size": 10.0}
		"prismatica":
			return {"core": Color(1.0, 1.0, 1.0), "glow": Color(0.36, 1.0, 0.96, 0.95), "trail": Color(1.0, 0.42, 0.78, 0.44), "size": 7.0, "trail_size": 6.0}
		"parasitica":
			return {"core": Color(0.8, 1.0, 0.54), "glow": Color(0.24, 0.95, 0.38, 0.9), "trail": Color(0.78, 1.0, 0.26, 0.42), "size": 8.0, "trail_size": 8.0}
		"gravitante":
			return {"core": Color(0.92, 0.98, 1.0), "glow": Color(0.5, 0.78, 1.0, 0.92), "trail": Color(0.74, 0.54, 1.0, 0.34), "size": 9.0, "trail_size": 9.0}
		"ancorada":
			return {"core": Color(1.0, 1.0, 1.0), "glow": Color(0.26, 0.96, 1.0, 0.9), "trail": Color(1.0, 0.78, 0.24, 0.38), "size": 8.0, "trail_size": 6.0}
		"cartografica":
			return {"core": Color(0.94, 1.0, 0.8), "glow": Color(0.3, 1.0, 0.78, 0.92), "trail": Color(1.0, 0.78, 0.24, 0.42), "size": 7.0, "trail_size": 6.0}
		"mnesica":
			return {"core": Color(1.0, 0.88, 1.0), "glow": Color(0.8, 0.5, 1.0, 0.9), "trail": Color(1.0, 0.42, 0.88, 0.38), "size": 7.0, "trail_size": 7.0}
		"ressonante":
			return {"core": Color(1.0, 0.96, 0.72), "glow": Color(1.0, 0.72, 0.18, 0.92), "trail": Color(0.34, 0.92, 1.0, 0.4), "size": 8.0, "trail_size": 7.0}
		"contratual":
			return {"core": Color(1.0, 0.96, 0.82), "glow": Color(1.0, 0.52, 0.2, 0.92), "trail": Color(1.0, 0.86, 0.42, 0.36), "size": 8.0, "trail_size": 6.0}
		"bombastica":
			return {"core": Color(1.0, 0.92, 0.46), "glow": Color(1.0, 0.46, 0.08, 0.94), "trail": Color(0.18, 0.88, 1.0, 0.36), "size": 9.0, "trail_size": 8.0}
		"retornante":
			return {"core": Color(1.0, 0.92, 1.0), "glow": Color(1.0, 0.34, 0.88, 0.94), "trail": Color(0.72, 0.42, 1.0, 0.38), "size": 8.0, "trail_size": 8.0}
		"necronada":
			return {"core": Color(0.92, 0.98, 1.0), "glow": Color(0.48, 0.34, 0.92, 0.94), "trail": Color(0.72, 0.96, 1.0, 0.38), "size": 8.0, "trail_size": 8.0}
		"necronada_dust":
			return {"core": Color(0.82, 0.7, 1.0), "glow": Color(0.35, 0.14, 0.58, 0.92), "trail": Color(0.06, 0.03, 0.1, 0.52), "size": 11.0, "trail_size": 14.0}
		"eclipsada_lua", "shuriken_eclipsado":
			return {"core": Color(0.92, 0.86, 1.0), "glow": Color(0.7, 0.36, 1.0, 0.94), "trail": Color(0.36, 0.72, 1.0, 0.38), "size": 8.0, "trail_size": 8.0}
		"eclipsada_sol":
			return {"core": Color(1.0, 0.96, 0.62), "glow": Color(1.0, 0.62, 0.16, 0.96), "trail": Color(1.0, 0.88, 0.3, 0.42), "size": 9.0, "trail_size": 9.0}
		"petro":
			return {"core": Color(0.82, 1.0, 1.0), "glow": Color(0.16, 0.92, 1.0, 0.88), "trail": Color(0.72, 1.0, 1.0, 0.38), "size": 6.0, "trail_size": 5.0}
	return {"core": Color.WHITE, "glow": Color(0.72, 0.92, 1.0, 0.9), "trail": Color(0.72, 0.92, 1.0, 0.35), "size": 7.0, "trail_size": 6.0}


static func _spawn_projectile_muzzle(game: Node2D, kind: String, pos: Vector2, dir: Vector2) -> void :
	var palette = game._projectile_palette(kind)
	var glow: Color = palette["glow"]
	var core: Color = palette["core"]
	var count = 7 if kind == "eletrica_charged" else 5
	game._spawn_radial_particles(pos, glow, count)
	var sparks: = 1 if game.gfx_low_resource else 3
	for i in range(sparks):
		if not game._particle_budget_available():
			break
		var spread = game.rng.randf_range(-0.42, 0.42)
		var spark_dir = dir.rotated(spread)
		game.effects.append({
			"kind": "trail", 
			"text": "", 
			"pos": pos + spark_dir * game.rng.randf_range(6.0, 12.0), 
			"life": game.rng.randf_range(0.12, 0.2), 
			"max": 0.2, 
			"color": Color(core.r, core.g, core.b, 0.95), 
			"size": game.rng.randf_range(6.0, 11.0), 
			"vel": spark_dir * game.rng.randf_range(120.0, 280.0)
		})


static func _emit_projectile_trail(game: Node2D, bullet: Dictionary) -> void :
	if game.gfx_low_resource and (game.effects.size() >= game.LOW_RESOURCE_EFFECT_CAP or game.rng.randf() < 0.45):
		return
	var palette = game._projectile_palette(String(bullet.get("kind", "")))
	var trail: Color = palette["trail"]
	var dir = Vector2(bullet.get("dir", Vector2.RIGHT))
	var side = dir.orthogonal().normalized()
	var drift = side * sin(float(bullet.get("age", 0.0)) * 18.0 + float(bullet.get("phase", 0.0))) * 6.0
	game.effects.append({
		"kind": "trail", 
		"text": "", 
		"pos": bullet["pos"] - dir * game.rng.randf_range(12.0, 22.0) + drift, 
		"life": game.rng.randf_range(0.12, 0.22), 
		"max": 0.22, 
		"color": trail, 
		"size": float(palette["trail_size"]) + game.rng.randf_range(-1.5, 1.5), 
		"vel": - dir * game.rng.randf_range(20.0, 55.0) + drift * 2.5
	})


static func _spawn_prismatica_ultimate_finish(game: Node2D, center: Vector2) -> void :
	if bool(game._active_prismatica_secondary().get("finish_burst_done", false)):
		return
	game._spawn_radial_particles(center, Color(0.72, 1.0, 0.98), 48)
	game._spawn_radial_particles(center, Color(1.0, 0.42, 0.92), 36)
	for ring_index in range(3):
		var life: = 0.32 + float(ring_index) * 0.09
		game.shockwaves.append({
			"pos": center, 
			"radius": 10.0 + float(ring_index) * 14.0, 
			"max": 118.0 + float(ring_index) * 54.0, 
			"life": life, 
			"max_life": life, 
			"damage": 0.0, 
			"hit": {}, 
			"visual_only": true, 
			"kind": "prismatica_finish"
		})
	for ray_index in range(20):
		var angle: float = float(ray_index) * TAU / 20.0 + game.rng.randf_range(-0.055, 0.055)
		var dir: = Vector2.from_angle(angle)
		var start: Vector2 = center + dir * game.rng.randf_range(8.0, 20.0)
		var finish: Vector2 = center + dir * game.rng.randf_range(84.0, 182.0)
		var hue: = fposmod(0.48 + float(ray_index) * 0.071 + game.rng.randf_range(-0.025, 0.025), 1.0)
		game.slashes.append({
			"a": start, 
			"b": finish, 
			"life": game.rng.randf_range(0.24, 0.44), 
			"max": 0.44, 
			"color": Color.from_hsv(hue, 0.72, 1.0, 0.88), 
			"width": game.rng.randf_range(4.0, 10.0)
		})
	for spark_index in range(28):
		var dir: = Vector2.from_angle(game.rng.randf_range(0.0, TAU))
		var hue: = fposmod(0.46 + game.rng.randf_range(0.0, 0.55), 1.0)
		game.effects.append({
			"text": "", 
			"pos": center + dir * game.rng.randf_range(4.0, 28.0), 
			"life": game.rng.randf_range(0.28, 0.62), 
			"max": 0.62, 
			"color": Color.from_hsv(hue, 0.62, 1.0, 0.98), 
			"size": game.rng.randi_range(4, 9), 
			"vel": dir * game.rng.randf_range(120.0, 260.0), 
			"kind": "spark"
		})


static func _spawn_ancorada_counterweight_vfx(game: Node2D, pos: Vector2, L: int) -> void :
	var vfx_scene: PackedScene = load("res://vfx/ancorada/AncoradaCounterweightVFX.tscn")
	if vfx_scene:
		var inst = vfx_scene.instantiate()
		game.add_child(inst)
		inst.global_position = pos
		var profile: String = game._get_boss_wave_quality_profile()
		inst.setup(L, profile, false)
