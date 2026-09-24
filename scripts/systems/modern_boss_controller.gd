extends Node
class_name ModernBossController

const PhoenixFire = preload("res://scripts/vfx/phoenix_fire.gd")

var game: Node = null


func bind_game(root: Node) -> void:
	game = root


func update_boss7_cooldowns(delta: float) -> void:
	for key in game.boss7_cooldowns.keys():
		game.boss7_cooldowns[key] = maxf(0.0, float(game.boss7_cooldowns.get(key, 0.0)) - delta)


func update_boss7_flight(delta: float) -> void:
	var target: Vector2 = game._boss_target_pos(true, 0.18)
	var to_target: Vector2 = target - game.boss_pos
	var dist: float = to_target.length()
	var desired := Vector2.ZERO
	if dist < 250.0:
		desired = -to_target.normalized() * 142.0
	elif dist > 390.0:
		desired = to_target.normalized() * 142.0
	else:
		desired = to_target.normalized().orthogonal() * (78.0 if int(game.time_alive * 0.2) % 2 == 0 else -78.0)
	game.boss7_velocity = game.boss7_velocity.move_toward(desired, 420.0 * delta)
	game.boss_pos = (game.boss_pos + game.boss7_velocity * delta).clamp(Vector2(100, 92), game.WORLD_SIZE - Vector2(100, 92))
	if game.boss7_velocity.length() > 8.0:
		game.boss7_attack_dir = game.boss7_velocity.normalized()


func update_boss7_state(delta: float) -> void:
	game.boss7_state_timer = maxf(0.0, game.boss7_state_timer - delta)
	update_boss7_flame_waves(delta)
	match game.boss7_state:
		game.BOSS7_STATE_FEATHER:
			if game.boss7_state_timer <= 0.0:
				fire_boss7_feathers()
				boss7_enter_recovery(0.36)
		game.BOSS7_STATE_WING:
			if game.boss7_state_timer <= 0.0:
				fire_boss7_wing_blast()
				boss7_enter_recovery(0.46)
		game.BOSS7_STATE_DIVE_PREP:
			game.boss_pos.y = move_toward(game.boss_pos.y, -180.0, 750.0 * delta)
			if game.boss7_state_timer <= 0.0:
				game.boss7_state = game.BOSS7_STATE_DIVE_WAIT
				game.boss7_state_timer = 0.8
		game.BOSS7_STATE_DIVE_WAIT:
			game.boss_pos.y = -180.0
			if game.boss7_state_timer <= 0.0:
				game.boss7_state = game.BOSS7_STATE_DIVE_MARK
				game.boss7_state_timer = 0.9
				var aim: Vector2 = game._boss_target_pos(true, 0.32)
				game.boss7_target_pos = aim.clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90))
		game.BOSS7_STATE_DIVE_MARK:
			game.boss_pos.y = -180.0
			if game.boss7_state_timer <= 0.0:
				if game.boss7_dive_fake_count < 3 and game.rng.randf() < 0.5:
					game.boss7_dive_fake_count += 1
					game.boss7_state = game.BOSS7_STATE_DIVE_FAKE
					game.boss7_state_timer = 2.0
					spawn_boss7_dive_fireball(game.boss7_target_pos)
				else:
					game.boss7_state = game.BOSS7_STATE_DIVE
					game.boss7_state_timer = 0.45
					game.boss_pos = game.boss7_target_pos - Vector2(380.0, 380.0)
					game.boss7_attack_dir = Vector2(1, 1).normalized()
		game.BOSS7_STATE_DIVE_FAKE:
			game.boss_pos.y = -180.0
			if game.boss7_state_timer <= 0.0:
				game.boss7_state = game.BOSS7_STATE_DIVE_MARK
				game.boss7_state_timer = 0.9
				var aim: Vector2 = game._boss_target_pos(true, 0.32)
				game.boss7_target_pos = aim.clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90))
		game.BOSS7_STATE_DIVE:
			var old_pos: Vector2 = game.boss_pos
			var speed: float = 1750.0 if game.boss7_reborn else 1550.0
			game.boss_pos = game.boss_pos.move_toward(game.boss7_target_pos, speed * delta)
			add_boss7_dive_trail(old_pos, game.boss_pos)
			if old_pos.distance_to(game.boss_pos) > 1.0:
				if game._distance_to_segment(game.player_pos, old_pos, game.boss_pos) <= game.BOSS7_DIVE_WIDTH * 0.5 and game._local_player_damageable_by_contact():
					game._damage_player(int(game.player_hp_max * (0.093 if game.boss7_reborn else 0.085) + (28 if game.boss7_reborn else 25)), "boss7_dive")
					game._apply_boss_burn(2)
					game.player_pos = game._clamp_player_world(game.player_pos + game._hostile_knockback(game.boss7_attack_dir * 185.0))
				game._damage_remote_player_on_segment(old_pos, game.boss_pos, game.BOSS7_DIVE_WIDTH * 0.5, int(game.net_player_hp_max * (0.093 if game.boss7_reborn else 0.085) + (28 if game.boss7_reborn else 25)), "boss7_dive", {}, "boss7_dive")
			if game.boss_pos.distance_to(game.boss7_target_pos) <= 12.0 or game.boss7_state_timer <= 0.0:
				game.boss_pos = game.boss7_target_pos
				game._boss_entry_impact_feedback(0.85)
				game._play_sfx("boss_impact", 0.03, 0.45, 1.25)
				spawn_boss7_flame_wave(game.boss7_target_pos, 250.0)
				boss7_enter_recovery(0.55)
		game.BOSS7_STATE_REBIRTH:
			var p: float = 1.0 - game.boss7_state_timer / maxf(0.01, game.BOSS7_REBIRTH_ANIM_TIME)
			game.boss_pos = game.boss7_core_pos + Vector2(0.0, -80.0 + 80.0 * game._ease_out_cubic(p))
			if game.boss7_state_timer <= 0.0:
				game.boss7_state = game.BOSS7_STATE_FLY
				game.boss_attack_timer = 0.45
		game.BOSS7_STATE_RECOVERY:
			if game.boss7_state_timer <= 0.0:
				game.boss7_state = game.BOSS7_STATE_FLY


func boss7_enter_recovery(time: float) -> void:
	game.boss7_state = game.BOSS7_STATE_RECOVERY
	game.boss7_state_timer = time
	game.boss_attack_timer = game._boss7_attack_delay()


func spawn_boss7_flame_wave(center: Vector2, max_radius: float = 250.0) -> void:
	var flames: Array = []
	var count: int = 24 if game._memory_saver_active() else (34 if game._runtime_visual_budget_active() else 72)
	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU + game.rng.randf_range(-0.05, 0.05)
		var layer: String = "yellow" if i % 3 == 0 else ("orange" if i % 3 == 1 else "red")
		var dist_mult: float = game.rng.randf_range(0.85, 1.0)
		var size: float = game.rng.randf_range(7.0, 14.0)
		flames.append({
			"angle": angle,
			"layer": layer,
			"dist_mult": dist_mult,
			"size": size,
			"offset": Vector2(game.rng.randf_range(-4, 4), game.rng.randf_range(-4, 4))
		})
	game.boss7_flame_waves.append({
		"pos": center,
		"radius": 0.0,
		"max_radius": max_radius,
		"expand_speed": 310.0,
		"life": 1.0,
		"flames": flames,
		"hit_player": false
	})


func boss7_dive_fireball_damage() -> int:
	return int(game.player_hp_max * game.BOSS7_DIVE_FIREBALL_DAMAGE_RATIO + game.BOSS7_DIVE_FIREBALL_DAMAGE_FLAT)


func spawn_boss7_dive_fireball(target: Vector2) -> void:
	var impact_pos: Vector2 = target.clamp(Vector2(90.0, 90.0), game.WORLD_SIZE - Vector2(90.0, 90.0))
	var spawn_pos: Vector2 = Vector2(impact_pos.x, -124.0)
	var dir: Vector2 = (impact_pos - spawn_pos).normalized()
	game.enemy_bullets.append({
		"pos": spawn_pos,
		"dir": dir,
		"life": 4.5,
		"damage": boss7_dive_fireball_damage(),
		"phase": game.rng.randf_range(0.0, TAU),
		"type": "boss7_dive_fireball",
		"speed_mult": game.BOSS7_DIVE_FIREBALL_SPEED / 210.0,
		"radius": game.BOSS7_DIVE_FIREBALL_RADIUS,
		"hit_radius": game.BOSS7_DIVE_FIREBALL_RADIUS,
		"impact_pos": impact_pos,
		"wave_radius": 250.0 * game.BOSS7_DIVE_FIREBALL_WAVE_RADIUS_MULT,
		"hit": {}
	})
	game._play_sfx("Frasco.mp3", 0.04, 0.56, 0.86 + game.rng.randf() * 0.16)


func update_boss7_dive_fireball_projectile(bullet: Dictionary, previous_pos: Vector2) -> void:
	var current_pos: Vector2 = Vector2(bullet.get("pos", previous_pos))
	var impact_pos: Vector2 = Vector2(bullet.get("impact_pos", game.boss7_target_pos))
	var hit_radius: float = float(bullet.get("hit_radius", game.BOSS7_DIVE_FIREBALL_RADIUS))
	var damage: int = int(bullet.get("damage", boss7_dive_fireball_damage()))
	if game._local_player_damageable_by_contact() and game._distance_to_segment(game.player_pos, previous_pos, current_pos) <= hit_radius:
		bullet["probability_near_miss_registered"] = true
		game._damage_player(damage, "boss7_dive_fireball")
		game._apply_boss_burn(4)
		game._spawn_radial_particles(game.player_pos, Color(1.0, 0.32, 0.08), 34)
		game._add_text("IMPACTO", game.player_pos + Vector2(0.0, -74.0), Color(1.0, 0.42, 0.1), 0.65, 22)
		bullet["life"] = 0.0
		return
	var hit_owner: Dictionary = bullet.get("hit", {})
	if game._damage_remote_player_on_segment(previous_pos, current_pos, hit_radius, damage, "boss7_dive_fireball", hit_owner, "dive_fireball"):
		bullet["hit"] = hit_owner
		bullet["life"] = 0.0
		return
	bullet["hit"] = hit_owner
	if game._distance_to_segment(impact_pos, previous_pos, current_pos) <= maxf(10.0, hit_radius * 0.45) or current_pos.y >= impact_pos.y:
		bullet["pos"] = impact_pos
		boss7_dive_fireball_ground_impact(bullet)
		bullet["life"] = 0.0


func boss7_dive_fireball_ground_impact(bullet: Dictionary) -> void:
	if bool(bullet.get("ground_exploded", false)):
		return
	bullet["ground_exploded"] = true
	var impact_pos: Vector2 = Vector2(bullet.get("impact_pos", bullet.get("pos", game.boss7_target_pos)))
	var wave_radius: float = float(bullet.get("wave_radius", 250.0 * game.BOSS7_DIVE_FIREBALL_WAVE_RADIUS_MULT))
	game._boss_entry_impact_feedback(0.72)
	game._play_sfx("boss_impact", 0.03, 0.5, 1.18)
	spawn_boss7_flame_wave(impact_pos, wave_radius)
	game._spawn_radial_particles(impact_pos, Color(1.0, 0.38, 0.06), 76)


func update_boss7_flame_waves(delta: float) -> void:
	for wave in game.boss7_flame_waves:
		wave["radius"] = float(wave.get("radius", 0.0)) + float(wave.get("expand_speed", 310.0)) * delta
		var radius: float = float(wave["radius"])
		var center: Vector2 = Vector2(wave["pos"])
		if not bool(wave.get("hit_player", false)):
			if game.player_pos.distance_to(center) <= radius + 22.0:
				wave["hit_player"] = true
				game._damage_player(int(game.player_hp_max * 0.088 + 26), "boss7_flame_wave")
				game._apply_boss_burn(2)
		game._damage_remote_player_in_radius(center, radius + 22.0, int(game.net_player_hp_max * 0.088 + 26), "boss7_flame_wave")
	game.boss7_flame_waves = game.boss7_flame_waves.filter(func(w): return float(w.get("radius", 0.0)) < float(w.get("max_radius", 250.0)))


func start_boss7_attack() -> void:
	var stage: int = game._boss7_stage()
	var candidates: Array = []
	candidates.append({"kind": game.BOSS7_ATTACK_FEATHER, "weight": 38.0 if stage == 1 else (25.0 if stage == 2 else 20.0)})
	candidates.append({"kind": game.BOSS7_ATTACK_WING, "weight": 27.0 if stage == 1 else (18.0 if stage == 2 else 12.0)})
	candidates.append({"kind": game.BOSS7_ATTACK_DIVE_TRAIL, "weight": 35.0 if stage == 1 else (27.0 if stage == 2 else 25.0)})
	candidates.append({"kind": game.BOSS7_ATTACK_SKY_FIREBALLS, "weight": 30.0 if stage == 1 else (35.0 if stage == 2 else 40.0)})
	candidates.append({"kind": game.BOSS7_ATTACK_WHIRLWIND, "weight": 20.0 if stage == 1 else (25.0 if stage == 2 else 30.0)})
	if stage >= 2:
		candidates.append({"kind": game.BOSS7_ATTACK_THERMAL, "weight": 18.0})
		candidates.append({"kind": game.BOSS7_ATTACK_ASH_RAIN, "weight": 12.0 if stage == 2 else 10.0})
	if stage >= 3:
		candidates.append({"kind": game.BOSS7_ATTACK_CROWN, "weight": 15.0})
	var available: Array = candidates.filter(func(item): return float(game.boss7_cooldowns.get(String(item.get("kind", "")), 0.0)) <= 0.0)
	if available.is_empty():
		game.boss_attack_timer = 0.25
		return
	var total := 0.0
	for item in available:
		total += float(item.get("weight", 0.0))
	var roll: float = game.rng.randf() * maxf(0.01, total)
	var selected: String = String(available[0].get("kind", game.BOSS7_ATTACK_FEATHER))
	for item in available:
		roll -= float(item.get("weight", 0.0))
		if roll <= 0.0:
			selected = String(item.get("kind", selected))
			break
	match selected:
		game.BOSS7_ATTACK_FEATHER:
			start_boss7_feather_volley()
		game.BOSS7_ATTACK_WING:
			start_boss7_wing_blast()
		game.BOSS7_ATTACK_DIVE_TRAIL:
			start_boss7_dive()
		game.BOSS7_ATTACK_SKY_FIREBALLS:
			start_boss7_sky_fireballs()
		game.BOSS7_ATTACK_WHIRLWIND:
			start_boss7_whirlwind()
		game.BOSS7_ATTACK_THERMAL:
			start_boss7_thermal()
		game.BOSS7_ATTACK_ASH_RAIN:
			start_boss7_ash_rain()
		game.BOSS7_ATTACK_CROWN:
			start_boss7_crown()


func start_boss7_feather_volley() -> void:
	game.boss7_state = game.BOSS7_STATE_FEATHER
	game.boss7_state_timer = game.BOSS7_FEATHER_WINDUP
	game.boss7_attack_dir = (game._boss_target_pos(true, 0.14) - game.boss_pos).normalized()
	if game.boss7_attack_dir.length() <= 0.05:
		game.boss7_attack_dir = Vector2.LEFT
	game.boss7_cooldowns[game.BOSS7_ATTACK_FEATHER] = 1.4


func fire_boss7_feathers() -> void:
	var stage: int = game._boss7_stage()
	var count := 7 if stage == 1 else (9 if stage == 2 else 11)
	var spread := deg_to_rad(66.0 if stage == 1 else (80.0 if stage == 2 else 92.0))
	var speed: float = game.BOSS7_FEATHER_REBORN_SPEED if game.boss7_reborn else game.BOSS7_FEATHER_SPEED
	for i in range(count):
		var ratio := 0.0 if count <= 1 else float(i) / float(count - 1)
		var dir: Vector2 = game.boss7_attack_dir.rotated(lerpf(-spread * 0.5, spread * 0.5, ratio)).normalized()
		game._add_boss_attack({"kind": game.BOSS7_ATTACK_FEATHER, "age": 0.0, "duration": 2.1, "pos": game.boss_pos + dir * 48.0, "prev": game.boss_pos + dir * 48.0, "dir": dir, "speed": speed, "hit": false, "phase": game.rng.randf_range(0.0, TAU)})
	game._play_sfx("boss_impact", 0.014, 0.48, 1.18)


func start_boss7_wing_blast() -> void:
	game.boss7_state = game.BOSS7_STATE_WING
	game.boss7_state_timer = game.BOSS7_WING_WINDUP
	game.boss7_attack_dir = (game._boss_target_pos(true, 0.12) - game.boss_pos).normalized()
	if game.boss7_attack_dir.length() <= 0.05:
		game.boss7_attack_dir = Vector2.LEFT
	game.boss7_cooldowns[game.BOSS7_ATTACK_WING] = 2.4


func fire_boss7_wing_blast() -> void:
	game._add_boss_attack({"kind": game.BOSS7_ATTACK_WING, "age": 0.0, "duration": 1.2, "origin": game.boss_pos, "dir": game.boss7_attack_dir, "hit": false})
	game._spawn_radial_particles(game.boss_pos + game.boss7_attack_dir * 74.0, Color(1.0, 0.64, 0.16), 42)


func start_boss7_dive() -> void:
	game.boss7_state = game.BOSS7_STATE_DIVE_PREP
	game.boss7_state_timer = 1.0
	game.boss7_target_pos = (game._boss_target_pos(true, 0.32)).clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90))
	game.boss7_attack_dir = Vector2.UP
	game.boss7_dive_fake_count = 0
	game.boss7_cooldowns[game.BOSS7_ATTACK_DIVE_TRAIL] = 20.0


func add_boss7_dive_trail(a: Vector2, b: Vector2) -> void:
	game._add_boss_attack({"kind": game.BOSS7_ATTACK_DIVE_TRAIL, "age": 0.0, "duration": 3.8 if game.boss7_reborn else 3.2, "a": a, "b": b, "tick": 0.45, "hit": {}})


func start_boss7_thermal() -> void:
	var spots: Array = []
	var base_target: Vector2 = game._boss_target_pos(true, 0.18)
	spots.append(base_target.clamp(Vector2(80, 80), game.WORLD_SIZE - Vector2(80, 80)))
	var count := 4 if game.boss7_reborn else 3
	for i in range(count - 1):
		var offset: Vector2 = Vector2.from_angle(game.rng.randf_range(0.0, TAU)) * game.rng.randf_range(90.0, 180.0)
		spots.append((base_target + offset).clamp(Vector2(80, 80), game.WORLD_SIZE - Vector2(80, 80)))
	game._add_boss_attack({"kind": game.BOSS7_ATTACK_THERMAL, "age": 0.0, "duration": 1.25, "spots": spots, "hit": {}})
	game.boss7_cooldowns[game.BOSS7_ATTACK_THERMAL] = 3.4
	game.boss_attack_timer = game._boss7_attack_delay()


func start_boss7_ash_rain() -> void:
	game._add_boss_attack({"kind": game.BOSS7_ATTACK_ASH_RAIN, "age": 0.0, "duration": 3.6, "spawn_cd": 0.0, "spawned": 0, "drops": []})
	game.boss7_cooldowns[game.BOSS7_ATTACK_ASH_RAIN] = 5.2
	game.boss_attack_timer = game._boss7_attack_delay()


func start_boss7_crown() -> void:
	game._add_boss_attack({"kind": game.BOSS7_ATTACK_CROWN, "age": 0.0, "duration": 2.1, "hit": {}})
	game.boss7_cooldowns[game.BOSS7_ATTACK_CROWN] = game.BOSS7_CROWN_COOLDOWN
	game.boss_attack_timer = game._boss7_attack_delay()


func start_boss7_rebirth() -> void:
	game.boss7_ultimate_active = false
	game.boss7_ultimate_timer = 0.0
	game.boss7_ultimate_quadrants = [0, 0, 0, 0]
	game.boss7_core_active = true
	game.boss7_core_pos = game.boss_pos
	game.boss7_core_hp_max = maxf(1.0, game.boss7_original_hp_max * game.BOSS7_CORE_HP_RATIO)
	game.boss7_core_hp = game.boss7_core_hp_max
	game.boss7_core_damage = 0.0
	game.boss7_core_timer = game.BOSS7_ASH_CORE_TIME
	game.boss7_state = game.BOSS7_STATE_ASH_CORE
	game.boss_active = true
	game.boss_hp = 0.0
	game.boss_attacks.clear()
	game._spawn_radial_particles(game.boss7_core_pos, Color(1.0, 0.32, 0.08), 130)
	game._add_text("CORACAO DE CINZAS", game.boss7_core_pos + Vector2(0, -86), Color(1.0, 0.72, 0.22), 1.2, 24)


func update_boss7_core(delta: float) -> void:
	game.boss7_core_timer = maxf(0.0, game.boss7_core_timer - delta)
	game.boss_phase += delta * 5.0
	if game.boss7_core_timer <= 0.0:
		var damage_ratio := clampf(game.boss7_core_damage / maxf(1.0, game.boss7_core_hp_max), 0.0, 1.0)
		var rebirth_ratio := lerpf(game.BOSS7_REBIRTH_MAX_RATIO, game.BOSS7_REBIRTH_MIN_RATIO, damage_ratio)
		game.boss7_core_active = false
		game.boss7_reborn = true
		game.boss7_state = game.BOSS7_STATE_REBIRTH
		game.boss7_state_timer = game.BOSS7_REBIRTH_ANIM_TIME
		game.boss_pos = game.boss7_core_pos + Vector2(0.0, -80.0)
		game.boss_hp_max = maxf(1.0, game.boss7_original_hp_max)
		game.boss_hp = maxf(1.0, game.boss7_original_hp_max * rebirth_ratio)
		game._spawn_radial_particles(game.boss7_core_pos, Color(1.0, 0.48, 0.1), 150)
		game._add_text("RENASCIMENTO %.0f%%" % (rebirth_ratio * 100.0), game.boss7_core_pos + Vector2(0, -96), Color(1.0, 0.48, 0.12), 1.2, 25)


func start_boss7_whirlwind() -> void:
	game.boss7_whirlwind_active = true
	game.boss7_whirlwind_timer = 2.5
	game.boss7_whirlwind_angle = 0.0
	game.boss7_whirlwind_spawn_timer = 0.0
	game.boss7_whirlwind_shots_left = 60
	game.boss7_cooldowns[game.BOSS7_ATTACK_WHIRLWIND] = 40.0
	game.boss_attack_timer = game._boss7_attack_delay() + 2.5
	game._add_text("REDEMOINHO DE FOGO", game.boss_pos + Vector2(0, -110), Color(1.0, 0.4, 0.1), 1.2, 24)


func update_boss7_whirlwind(delta: float) -> void:
	if not game.boss7_whirlwind_active:
		return
	game.boss7_whirlwind_timer = maxf(0.0, game.boss7_whirlwind_timer - delta)
	game.boss7_whirlwind_spawn_timer -= delta
	if game.boss7_whirlwind_spawn_timer <= 0.0 and game.boss7_whirlwind_shots_left > 0:
		game.boss7_whirlwind_spawn_timer = 0.04
		game.boss7_whirlwind_shots_left -= 1
		game.boss7_whirlwind_angle += TAU / 60.0
		var dir: Vector2 = Vector2.from_angle(game.boss7_whirlwind_angle)
		var speed := 170.0
		game.enemy_bullets.append({
			"pos": game.boss_pos + dir * 30.0,
			"dir": dir,
			"life": 4.5,
			"damage": int(game.player_hp_max * 0.07 + 20.0),
			"phase": game.rng.randf_range(0.0, TAU),
			"type": "phase7_fireball",
			"speed_mult": speed / 210.0,
			"radius": 14.0
		})
		game._spawn_radial_particles(game.boss_pos + dir * 30.0, Color(1.0, 0.5, 0.1), 3)
	if game.boss7_whirlwind_timer <= 0.0 and game.boss7_whirlwind_shots_left <= 0:
		game.boss7_whirlwind_active = false


func start_boss7_sky_fireballs() -> void:
	game.boss7_cooldowns[game.BOSS7_ATTACK_SKY_FIREBALLS] = 9.0
	var count: int = 15 if game.boss7_reborn else 12
	var spots: Array = []
	var base_target: Vector2 = game._boss_target_pos(true, 0.2)
	spots.append(base_target.clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90)))
	for i in range(count - 1):
		var offset: Vector2 = Vector2.from_angle(game.rng.randf_range(0.0, TAU)) * game.rng.randf_range(80.0, 220.0)
		spots.append((base_target + offset).clamp(Vector2(90, 90), game.WORLD_SIZE - Vector2(90, 90)))
	game._add_boss_attack({
		"kind": game.BOSS7_ATTACK_SKY_FIREBALLS,
		"age": 0.0,
		"duration": 2.2,
		"warning": 0.85,
		"spots": spots,
		"hit": {}
	})
	game.boss_attack_timer = game._boss7_attack_delay()
	game._add_text("CHUVA DE FOGO", game.boss_pos + Vector2(0, -90), Color(1.0, 0.6, 0.1), 1.0, 20)


func check_boss7_ultimate(_delta: float) -> void:
	if game.boss7_ultimate_active or game.boss7_ultimate_used or not game._is_world_authority():
		return
	if game.current_phase == 7 and game.boss_hp > 0.0 and game.boss_hp / maxf(1.0, game.boss_hp_max) <= 0.30 and game.boss_active and not game.boss_dead and not game.boss7_core_active:
		game.boss7_ultimate_active = true
		game.boss7_ultimate_used = true
		game.boss7_ultimate_timer = PhoenixFire.DURATION
		game.boss7_ultimate_tick_timer = 0.6
		refresh_boss7_ultimate_quadrants()
		game._add_text("AQUECIMENTO GLOBAL!", game.boss_pos + Vector2(0, -130), Color(1.0, 0.2, 0.0), 2.0, 32)
		game._vibrate(250, 0.8)


func update_boss7_ultimate(delta: float) -> void:
	if not game.boss7_ultimate_active:
		return
	game.boss7_ultimate_timer = maxf(0.0, game.boss7_ultimate_timer - delta)
	if game.boss7_ultimate_timer <= 0.0 or game.current_phase != 7 or not game.boss_active or game.boss_dead or game.boss7_core_active:
		game.boss7_ultimate_active = false
		game.boss7_ultimate_timer = 0.0
		game.boss7_ultimate_quadrants = [0, 0, 0, 0]
		return
	refresh_boss7_ultimate_quadrants()
	if not game._is_world_authority():
		return
	game.boss7_ultimate_tick_timer -= delta
	if game.boss7_ultimate_tick_timer > 0.0:
		return
	game.boss7_ultimate_tick_timer = 0.6
	var elapsed: float = PhoenixFire.DURATION - game.boss7_ultimate_timer
	if PhoenixFire.dangerous(game.player_pos, game.WORLD_SIZE, elapsed) and game._local_player_damageable_by_contact():
		game._damage_player(int(game.player_hp_max * 0.025 + 10), "boss7_global_warming")
		game._apply_boss_burn(1)
	if game._remote_player_damage_ready():
		for peer_id in game._targetable_remote_peer_ids():
			var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
			if PhoenixFire.dangerous(Vector2(state.get("pos", Vector2(-10000, -10000))), game.WORLD_SIZE, elapsed):
				game._send_peer_damage(peer_id, int(float(state.get("hp_max", game.player_hp_max)) * 0.025 + 10), "boss7_global_warming")


func refresh_boss7_ultimate_quadrants() -> void:
	game.boss7_ultimate_quadrants.resize(4)
	for quadrant in range(4):
		game.boss7_ultimate_quadrants[quadrant] = PhoenixFire.phase(PhoenixFire.DURATION - game.boss7_ultimate_timer, quadrant) if game.boss7_ultimate_active else 0


func update_boss6_timers(delta: float) -> void:
	game.boss6_carapace_timer = maxf(0.0, game.boss6_carapace_timer - delta)
	if game.boss6_carapace_timer <= 0.0:
		game.boss6_carapace_plates.clear()
	game.boss6_vulnerability_timer = maxf(0.0, game.boss6_vulnerability_timer - delta)
	game.boss6_core_exposed_timer = maxf(0.0, game.boss6_core_exposed_timer - delta)
	game.boss6_fossil_era_timer = maxf(0.0, game.boss6_fossil_era_timer - delta)
	game.boss6_miasma_ult_cooldown = maxf(0.0, game.boss6_miasma_ult_cooldown - delta)
	game.boss6_miasma_slow_timer = maxf(0.0, game.boss6_miasma_slow_timer - delta)
	if game.boss6_miasma_slow_timer <= 0.0:
		game.boss6_miasma_slow_stacks = 0
		game.boss6_miasma_slow_tick = 0.0
	game.boss6_carnage_slow_timer = maxf(0.0, game.boss6_carnage_slow_timer - delta)

	if not game.boss6_fossil_echo.is_empty():
		game.boss6_fossil_echo["timer"] = maxf(0.0, float(game.boss6_fossil_echo.get("timer", 0.0)) - delta)
		if float(game.boss6_fossil_echo["timer"]) <= 0.0:
			game.boss6_fossil_echo.clear()
	game.boss6_fossil_echo_slow_timer = maxf(0.0, game.boss6_fossil_echo_slow_timer - delta)

	if game.boss6_necro_erosion_active:
		game.boss6_necro_erosion_timer = maxf(0.0, game.boss6_necro_erosion_timer - delta)
		if game.boss6_necro_erosion_timer <= 0.0:
			game.boss6_necro_erosion_active = false

	game.boss6_history_sample_timer -= delta
	if game.boss6_history_sample_timer <= 0.0:
		game.boss6_history_sample_timer = 0.15
		game.boss6_player_history.append({"time": game.time_alive, "pos": game.player_pos})
		if game.boss6_player_history.size() > 40:
			game.boss6_player_history.pop_front()

	if game._is_player_calcified():
		game.boss6_necro_erosion_damage_timer -= delta
		if game.boss6_necro_erosion_damage_timer <= 0.0:
			game.boss6_necro_erosion_damage_timer = 0.75
			game._damage_player(int(game.player_hp_max * 0.025 + 5), "boss6_necro_erosion_burn")

	for key in game.boss6_ability_cooldowns.keys():
		game.boss6_ability_cooldowns[key] = maxf(0.0, float(game.boss6_ability_cooldowns[key]) - delta)
	game._update_boss6_miasma_ultimate(delta)
	game._update_boss6_lodarian_pools(delta)
	game._update_boss6_rib_prison(delta)
	if game.boss6_core_exposed_timer > 0.0:
		game.boss6_core_pulse_timer -= delta
		if game.boss6_core_pulse_timer <= 0.0:
			game.boss6_core_pulse_timer = 1.6
			game._boss6_core_proximity_pulse()
