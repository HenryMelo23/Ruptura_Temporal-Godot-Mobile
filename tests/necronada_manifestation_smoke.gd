extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("NECRONADA_MANIFESTATION_SMOKE_FAIL " + message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _manifestation_index(key: String) -> int:
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == key:
			return i
	return -1


func _spawn_test_enemy(pos: Vector2, hp := 180.0, enemy_type := "") -> Dictionary:
	var type_to_spawn: String = enemy_type if enemy_type != "" else String(game.ENEMY_COMMON)
	game._spawn_enemy(type_to_spawn, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _make_vestige(enemy_type: String, pos: Vector2, depth := 1) -> Dictionary:
	return {
		"id": game.necronada_next_id,
		"enemy_type": enemy_type,
		"pos": pos,
		"life": 999999.0,
		"max": 999999.0,
		"depth": depth,
		"profile": game._necronada_profile(enemy_type),
		"phase": 0.0
	}


func _reset_necronada_runtime() -> void:
	game.enemies.clear()
	game.bullets.clear()
	game.necronada_vestiges.clear()
	game.necronada_ossuary.clear()
	game.necronada_remnants.clear()
	game.necronada_requiem.clear()
	game.necronada_pente_history.clear()
	game.necronada_vfx.clear()
	game.necronada_attack_counter = 0
	game.necronada_empowered_ready = false
	game.necronada_empower_until = 0.0
	game.necronada_empower_cooldown_until = 0.0
	game.necronada_horde_progress = 0
	game.necronada_boss_empower_rose_window = 0.0
	game.necronada_boss_empower_rose_hits = 0
	game.boss_active = false


func _run() -> void:
	await process_frame
	var index := _manifestation_index("necronada")
	_check(index >= 0, "Necronada was not registered in MANIFESTATIONS")
	_check(String(game.MANIFESTATIONS[index].get("icon", "")) == "res://assets/sprites/manifestacao-necronada.png", "Necronada icon uses wrong path")
	_check(ResourceLoader.exists("res://assets/sprites/manifestacao-necronada.png"), "Necronada icon is not packable")
	_check(game._manifest_select_item_texture(game.MANIFESTATIONS[index], false) != null, "Necronada icon did not load")

	game.selected_manifestation = index
	game.selected_aura = 0
	game._start_game()
	game.manifestation_key = "necronada"
	game.player_pos = Vector2(640, 360)
	game.player_damage = 120.0
	game.player_hp_max = 450
	game.player_hp = 300
	game.last_facing = Vector2.RIGHT
	game.attack_dragging = true
	game.attack_drag_direction = Vector2.RIGHT
	game.time_alive = 30.0
	game.last_attack_time = -999.0
	game.last_skill_time = -999.0
	game.last_secondary_time = -999.0
	_reset_necronada_runtime()

	_check(is_equal_approx(game._manifestation_base_damage(), game.PLAYER_BASE_DAMAGE * 0.84), "base damage is not normalized")
	_check(is_equal_approx(game._manifestation_attack_interval(), 0.64), "base cadence is not 0.64s")
	_check(float(game._ground_target_profile(false).get("radius", 0.0)) >= game.NECRONADA_ROSE_SUMMON_RADIUS, "HAB1 targeting radius is wrong")
	_check(float(game._ground_target_profile(true).get("radius", 0.0)) >= game.NECRONADA_ULTIMATE_RADIUS, "ultimate targeting radius is wrong")
	_check(is_equal_approx(float(game._secondary_skill_cooldown()), 10.0), "ultimate cooldown is not 10s")
	_check(game.NECRONADA_MAX_ACTIVE_REMNANTS == 7, "necro-ally active cap is not 7")
	_check(game.NECRONADA_ROSE_MAX == 7, "necro rose cap is not aligned with active cap")

	for i in range(game.NECRONADA_PASSIVE_ATTACKS):
		game._necronada_register_attack_passive()
	_check(game.player_hp > 300, "passive did not heal after 4 attacks")

	var enemy := _spawn_test_enemy(game.player_pos + Vector2(96, 0), 180.0)
	game._try_attack()
	_check(game.bullets.size() == 1, "ATK did not create projectile")
	_check(String(game.bullets[0].get("kind", "")) == "necronada", "ATK projectile has wrong kind")
	game._apply_bullet_effect(game.bullets[0], enemy)
	_check(bool(enemy.get("necronada_epitaph", false)), "ATK did not apply Epitaph")
	_check(int(enemy.get("necronada_epitaph_depth", 0)) == 1, "Epitaph depth did not start at 1")
	for i in range(4):
		game._apply_necronada_epitaph(enemy, Vector2(enemy["pos"]))
	_check(int(enemy.get("necronada_epitaph_depth", 0)) == 5, "Epitaph did not stack to 5")

	for i in range(game.NECRONADA_ROSE_MAX + 1):
		var dead := {
			"type": game.ENEMY_COMMON if i % 2 == 0 else game.ENEMY_PROJECTOR,
			"pos": game.player_pos + Vector2(36 + i * 18, 20),
			"hp": 0.0,
			"max_hp": 140.0,
			"killed_by_source": "player"
		}
		game._necronada_on_enemy_killed(dead)
	_check(game.necronada_vestiges.size() == game.NECRONADA_ROSE_MAX, "rose cap did not stay at max")
	_check(int(game.necronada_vestiges[0].get("id", 0)) == 1, "full rose capacity should not replace the oldest rose")
	_check(game.necronada_pente_history.has(game.ENEMY_COMMON), "common species was not remembered")
	_check(game.necronada_pente_history.has(game.ENEMY_PROJECTOR), "projector species was not remembered")
	var blocked_dead := {
		"type": game.ENEMY_COMMON,
		"pos": game.player_pos + Vector2(90, 30),
		"hp": 0.0,
		"max_hp": 140.0,
		"killed_by_source": "player"
	}
	game._necronada_on_enemy_killed(blocked_dead)
	_check(game.necronada_vestiges.size() == game.NECRONADA_ROSE_MAX, "rose dropped despite full summon capacity")

	game.necronada_vestiges.clear()
	game.necronada_vestiges.append(_make_vestige(game.ENEMY_COMMON, game.player_pos + Vector2(34, 0), 1))
	game.necronada_vestiges.append(_make_vestige(game.ENEMY_PROJECTOR, game.player_pos + Vector2(70, 0), 2))
	game.necronada_vestiges.append(_make_vestige(game.ENEMY_STALKER, game.player_pos + Vector2(118, 0), 3))
	game.necronada_vestiges.append(_make_vestige(game.ENEMY_COMMON, game.player_pos + Vector2(520, 0), 1))
	game._try_use_necronada_skill(game.player_pos)
	_check(game.necronada_remnants.size() == 3, "HAB1 did not summon all roses inside radius")
	_check(game.necronada_vestiges.size() == 1, "HAB1 consumed roses outside radius")
	_check(game.necronada_horde_progress == 3, "HAB1 did not add horde progress")
	var ranged_found := false
	for remnant in game.necronada_remnants:
		if String(remnant.get("enemy_type", "")) == game.ENEMY_PROJECTOR:
			ranged_found = bool(remnant.get("is_ranged", false))
	_check(ranged_found, "projector remnant was not configured as ranged")
	game.necronada_vestiges.clear()
	game.necronada_remnants.clear()
	for i in range(game.NECRONADA_MAX_ACTIVE_REMNANTS + 1):
		game.necronada_vestiges.append(_make_vestige(game.ENEMY_COMMON, game.player_pos + Vector2(24 + i * 6, 0), 1))
	game._try_use_necronada_skill(game.player_pos)
	_check(game.necronada_remnants.size() == game.NECRONADA_MAX_ACTIVE_REMNANTS, "HAB1 exceeded necro-ally cap")
	_check(game.necronada_vestiges.size() == 1, "HAB1 consumed rose that could not become an ally")
	game.necronada_remnants.clear()
	game.necronada_vestiges.clear()
	game._summon_necronada_remnant(game.player_pos + Vector2(46, 0), {
		"id": 1001,
		"enemy_type": game.ENEMY_COMMON,
		"profile": game._necronada_profile(game.ENEMY_COMMON),
		"depth": 1
	})
	game._summon_necronada_remnant(game.player_pos + Vector2(82, 0), {
		"id": 1002,
		"enemy_type": game.ENEMY_PROJECTOR,
		"profile": game._necronada_profile(game.ENEMY_PROJECTOR),
		"depth": 2
	})
	var common_profile_hp := clampf(float(game._necronada_profile(game.ENEMY_COMMON).get("hp", 0.45)), 0.30, 0.95)
	var expected_common_hp := maxf(24.0, game.player_hp_max * (0.42 + common_profile_hp * 0.42) * game.NECRONADA_REMNANT_HEALTH_MULT)
	_check(is_equal_approx(float(game.necronada_remnants[0].get("max_hp", 0.0)), expected_common_hp), "necro-ally max health was not reduced by 20%")

	game._try_arm_necronada_empower()
	_check(game.necronada_empowered_ready, "reinforcement did not arm")
	game.last_attack_time = -999.0
	game._try_attack()
	_check(not game.necronada_empowered_ready, "reinforced attack did not consume ready state")
	_check(game.necronada_empower_cooldown_until > game.time_alive, "reinforcement cooldown did not start after attack")
	_check(game.bullets.any(func(bullet): return String(bullet.get("kind", "")) == "necronada_dust"), "reinforced attack did not create necrotic dust")
	for remnant in game.necronada_remnants:
		_check(float(remnant.get("empower_timer", 0.0)) > 0.0, "reinforced attack did not buff all remnants")
		remnant["summon"] = 0.0
	var remnant_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	game._damage_remnants_in_area(Vector2(game.necronada_remnants[0].get("pos", game.player_pos)), 40.0, 80.0, "boss_necro_test")
	_check(float(game.necronada_remnants[0].get("hp", 0.0)) < remnant_hp_before, "boss area damage did not affect necro-allies")
	
	game.necronada_remnants[0]["hp"] = 220.0
	game.necronada_remnants[0]["max_hp"] = 220.0
	game.necronada_remnants[0]["summon"] = 0.0
	game.necronada_remnants[0]["pos"] = game.player_pos + Vector2(64, 0)
	var boss_radius_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	var boss_radius_hit := {}
	game._damage_remote_player_in_radius(Vector2(game.necronada_remnants[0].get("pos", game.player_pos)), 90.0, 120, "boss2_ice_pillar", boss_radius_hit, "ice_pillar_test")
	var boss_radius_hp_after := float(game.necronada_remnants[0].get("hp", 0.0))
	print("NECRONADA_NUMERIC boss_radius_remnant_hp %.2f -> %.2f" % [boss_radius_hp_before, boss_radius_hp_after])
	_check(boss_radius_hp_after < boss_radius_hp_before, "boss radius helper did not damage necro-ally")
	
	game.necronada_remnants[0]["hp"] = 220.0
	var boss_segment_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	var remnant_segment_pos := Vector2(game.necronada_remnants[0].get("pos", game.player_pos))
	var boss_segment_hit := {}
	game._damage_remote_player_on_segment(remnant_segment_pos - Vector2(120, 0), remnant_segment_pos + Vector2(120, 0), 42.0, 120, "boss4_column_test", boss_segment_hit, "segment_test")
	var boss_segment_hp_after := float(game.necronada_remnants[0].get("hp", 0.0))
	print("NECRONADA_NUMERIC boss_segment_remnant_hp %.2f -> %.2f" % [boss_segment_hp_before, boss_segment_hp_after])
	_check(boss_segment_hp_after < boss_segment_hp_before, "boss segment helper did not damage necro-ally")
	
	game.necronada_remnants[0]["hp"] = 220.0
	game.enemies.clear()
	game.arauto["active"] = false
	game.current_phase = 2
	game.boss_active = true
	game.boss_hp_max = 1200.0
	game.boss_hp = 900.0
	game.boss_pos = game.player_pos + Vector2(220, 0)
	game.boss2_ultimate_timer = 10.0
	game.boss2_ultimate_wind_active = 0.0
	game.boss2_ultimate_spit_timer = 2.0
	_check(not game._boss2_ultimate_boss_visible(), "boss2 should be hidden during calm blizzard window")
	_check(game._necronada_find_target(game.player_pos).is_empty(), "necro-ally targeted hidden boss2")
	game.necronada_remnants[0]["target_kind"] = "boss"
	_check(not game._necronada_target_alive(game.necronada_remnants[0]), "hidden boss2 remained alive as a necro target")
	game.boss2_ultimate_center = game.player_pos
	game.necronada_remnants[0]["pos"] = game.player_pos + Vector2(game.BOSS2_ULTIMATE_SAFE_RADIUS + 90.0, 0)
	game.boss2_ultimate_remnant_blizzard_tick = 0.01
	var blizzard_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	game._update_boss2_ultimate_blizzard_damage(0.02)
	var blizzard_hp_after := float(game.necronada_remnants[0].get("hp", 0.0))
	print("NECRONADA_NUMERIC boss2_blizzard_remnant_hp %.2f -> %.2f" % [blizzard_hp_before, blizzard_hp_after])
	_check(blizzard_hp_after < blizzard_hp_before, "boss2 blizzard did not damage necro-ally outside safe zone")
	game.current_phase = 1
	game.boss_active = false

	_check(float(game._necronada_profile(game.ENEMY_COMMON).get("range", 0.0)) >= game.NECRONADA_REMNANT_MELEE_RANGE_MIN, "common remnant range is still too short")
	_check(float(game._necronada_profile(game.ENEMY_PROJECTOR).get("range", 0.0)) >= game.NECRONADA_REMNANT_RANGED_RANGE_MIN, "ranged remnant range is still too short")
	game.enemies.clear()
	var melee_target := _spawn_test_enemy(game.player_pos + Vector2(115, 0), 360.0)
	var melee_hp_before := float(melee_target.get("hp", 0.0))
	game.necronada_remnants[0]["pos"] = game.player_pos
	game.necronada_remnants[0]["target_kind"] = "enemy"
	game.necronada_remnants[0]["target_uid"] = int(melee_target.get("uid", -1))
	game.necronada_remnants[0]["target_pos"] = Vector2(melee_target.get("pos", game.player_pos))
	game.necronada_remnants[0]["target_timer"] = 1.0
	game.necronada_remnants[0]["attack_cd"] = 0.0
	game._update_necronada_remnants(0.05)
	print("NECRONADA_NUMERIC melee_range_damage hp %.2f -> %.2f distance=115" % [melee_hp_before, float(melee_target.get("hp", 0.0))])
	_check(float(melee_target.get("hp", 0.0)) < melee_hp_before, "melee remnant did not attack at practical range")

	game.enemies.clear()
	var ranged_target := _spawn_test_enemy(game.player_pos + Vector2(315, 0), 360.0)
	var ranged_hp_before := float(ranged_target.get("hp", 0.0))
	game.necronada_remnants[1]["pos"] = game.player_pos
	game.necronada_remnants[1]["target_kind"] = "enemy"
	game.necronada_remnants[1]["target_uid"] = int(ranged_target.get("uid", -1))
	game.necronada_remnants[1]["target_pos"] = Vector2(ranged_target.get("pos", game.player_pos))
	game.necronada_remnants[1]["target_timer"] = 1.0
	game.necronada_remnants[1]["attack_cd"] = 0.0
	game._update_necronada_remnants(0.05)
	print("NECRONADA_NUMERIC ranged_range_damage hp %.2f -> %.2f distance=315" % [ranged_hp_before, float(ranged_target.get("hp", 0.0))])
	_check(float(ranged_target.get("hp", 0.0)) < ranged_hp_before, "ranged remnant did not attack at practical range")
	
	game.enemy_bullets.clear()
	game.necronada_remnants[0]["hp"] = 220.0
	game.necronada_remnants[0]["max_hp"] = 220.0
	game.necronada_remnants[0]["summon"] = 0.0
	game.necronada_remnants[0]["pos"] = game.player_pos + Vector2(96, 0)
	var bullet_remnant_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	game.enemy_bullets.append({
		"pos": Vector2(game.necronada_remnants[0].get("pos", game.player_pos)),
		"dir": Vector2.ZERO,
		"life": 1.0,
		"damage": 100.0,
		"phase": 0.0,
		"type": "boss_test_projectile",
		"hit_radius": 34.0,
		"speed_mult": 0.0
	})
	game._update_enemy_bullets(0.016)
	var bullet_remnant_hp_after := float(game.necronada_remnants[0].get("hp", 0.0))
	print("NECRONADA_NUMERIC bullet_remnant_hp %.2f -> %.2f bullets_left=%d" % [bullet_remnant_hp_before, bullet_remnant_hp_after, game.enemy_bullets.size()])
	_check(bullet_remnant_hp_after < bullet_remnant_hp_before, "real enemy bullet update did not damage necro-ally")
	_check(game.enemy_bullets.is_empty(), "enemy bullet was not consumed after hitting necro-ally")
	
	game.necronada_remnants[0]["hp"] = 220.0
	game.necronada_remnants[1]["hp"] = 220.0
	game.necronada_remnants[0]["summon"] = 0.0
	game.necronada_remnants[1]["summon"] = 0.0
	game.necronada_remnants[0]["pos"] = game.player_pos + Vector2(36, 0)
	game.necronada_remnants[1]["pos"] = game.player_pos + Vector2(520, 0)
	game.current_phase = 6
	game.boss_active = true
	game.boss_hp_max = 1600.0
	game.boss_hp = 1600.0
	var ultimate_near_hp_before := float(game.necronada_remnants[0].get("hp", 0.0))
	var ultimate_far_hp_before := float(game.necronada_remnants[1].get("hp", 0.0))
	game._damage_player(120, "boss6_reflux_wave")
	var ultimate_near_hp_after := float(game.necronada_remnants[0].get("hp", 0.0))
	var ultimate_far_hp_after := float(game.necronada_remnants[1].get("hp", 0.0))
	print("NECRONADA_NUMERIC boss_ultimate_remnants near %.2f -> %.2f far %.2f -> %.2f" % [ultimate_near_hp_before, ultimate_near_hp_after, ultimate_far_hp_before, ultimate_far_hp_after])
	_check(ultimate_near_hp_after < ultimate_near_hp_before, "boss ultimate did not damage near necro-ally")
	_check(ultimate_far_hp_after < ultimate_far_hp_before, "boss ultimate did not damage far necro-ally")

	var dust_target := _spawn_test_enemy(game.player_pos + Vector2(160, 0), 240.0)
	var dust_bullet: Dictionary = game.bullets.filter(func(bullet): return String(bullet.get("kind", "")) == "necronada_dust")[-1]
	dust_bullet["pos"] = Vector2(dust_target["pos"])
	game._apply_bullet_effect(dust_bullet, dust_target)
	_check(float(dust_target.get("evolution_slow", 0.0)) > 0.0, "reinforced dust did not slow enemy")
	_check(float(dust_target.get("necronada_crit_window", 0.0)) > 0.0, "reinforced dust did not mark enemy for crits")
	var roses_before_followup: int = game.necronada_vestiges.size()
	var normal_bullet := {
		"damage": game.player_damage * 0.40,
		"kind": "necronada",
		"pos": Vector2(dust_target["pos"]),
		"origin": game.player_pos,
		"source_category": "basic_attack",
		"always_crit": false
	}
	for i in range(game.NECRONADA_EMPOWER_ROSE_REQUIRED_HITS):
		game._apply_bullet_effect(normal_bullet.duplicate(true), dust_target)
	_check(game.necronada_vestiges.size() == roses_before_followup + 1, "reinforced target did not drop rose after four Necronada shots")
	
	game.boss_active = true
	game.boss_pos = game.player_pos + Vector2(145, 0)
	game.boss_hp_max = 1200.0
	game.boss_hp = 1200.0
	var boss_hp_before := float(game.boss_hp)
	var boss_remnant: Dictionary = game.necronada_remnants[0]
	boss_remnant["target_kind"] = "boss"
	boss_remnant["target_pos"] = game.boss_pos
	boss_remnant["pos"] = game.boss_pos + Vector2(-44, 0)
	boss_remnant["attack_cd"] = 0.0
	boss_remnant["target_timer"] = 0.0
	boss_remnant["summon"] = 0.0
	game.enemies.clear()
	game._update_necronada_remnants(0.20)
	var boss_hp_after := float(game.boss_hp)
	print("NECRONADA_NUMERIC remnant_boss_damage boss_hp %.2f -> %.2f" % [boss_hp_before, boss_hp_after])
	_check(float(game.boss_hp) < boss_hp_before, "necro-ally did not damage boss")
	
	game.necronada_boss_empower_rose_window = game.NECRONADA_EMPOWER_ROSE_WINDOW
	game.necronada_boss_empower_rose_hits = 0
	var boss_roses_before: int = game.necronada_vestiges.size()
	for i in range(game.NECRONADA_EMPOWER_ROSE_REQUIRED_HITS):
		game._necronada_register_boss_empower_followup_hit()
	_check(game.necronada_vestiges.size() == boss_roses_before + 1, "boss follow-up did not create a rose")
	
	var push_enemy := _spawn_test_enemy(game.player_pos + Vector2(120, 0), 300.0)
	var push_before := Vector2(push_enemy["pos"])
	var push_hp := float(push_enemy["hp"])
	game._apply_necronada_teleport_dust(game.player_pos, Vector2.RIGHT)
	_check(float(push_enemy["hp"]) < push_hp, "teleport dust did not damage enemy")
	_check(Vector2(push_enemy["pos"]).x > push_before.x, "teleport dust did not push enemy forward")

	_reset_necronada_runtime()
	var wave_enemy_near := _spawn_test_enemy(game.player_pos + Vector2(110, 0), 500.0)
	var wave_enemy_far := _spawn_test_enemy(game.player_pos + Vector2(390, 0), 500.0)
	var near_hp := float(wave_enemy_near.get("hp", 0.0))
	var far_hp := float(wave_enemy_far.get("hp", 0.0))
	game.necronada_horde_progress = game.NECRONADA_ULTIMATE_REQUIRED_REVIVES
	game.last_secondary_time = -999.0
	_check(game._cast_necronada_requiem(), "ultimate did not cast when horde progress was full")
	_check(game.necronada_horde_progress == 0, "ultimate did not spend 30 revives")
	_check(String(game.necronada_requiem.get("kind", "")) == "necrotic_wave", "ultimate did not create necrotic wave visual state")
	_check(float(wave_enemy_near.get("hp", 0.0)) < near_hp, "necrotic wave did not damage near enemy")
	_check(float(wave_enemy_far.get("hp", 0.0)) < far_hp, "necrotic wave did not damage far enemy")
	_check((near_hp - float(wave_enemy_near.get("hp", 0.0))) > (far_hp - float(wave_enemy_far.get("hp", 0.0))), "necrotic wave did not fall off with distance")
	_check(float(wave_enemy_near.get("necronada_crit_window", 0.0)) > 0.0, "necrotic wave did not mark near enemy")

	var details: Dictionary = game._manifestation_details("necronada")
	_check(String(details.get("funcao", "")).contains("Reconstrucao"), "catalog details missing Necronada identity")
	game._reset_advanced_manifestation_state()
	_check(game.necronada_vestiges.is_empty(), "reset did not clear roses")
	_check(game.necronada_remnants.is_empty(), "reset did not clear remnants")
	_check(game.necronada_horde_progress == 0, "reset did not clear horde progress")

	print("NECRONADA_MANIFESTATION_SMOKE_OK passive=true roses=true hab1=true empower=true ultimate=true reset=true")
	root.remove_child(game)
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	await process_frame
	quit(0)
