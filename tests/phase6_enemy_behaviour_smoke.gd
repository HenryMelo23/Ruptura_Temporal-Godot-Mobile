extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE6_ENEMY_BEHAVIOUR_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game.force_phase6_start = false
	game.gameplay_cheat_text = "FASE6"
	_check(game._try_unlock_retornante_cheat(), "FASE6 cheat was not accepted")
	_check(game.force_phase6_start, "FASE6 cheat did not enable forced start")
	game._start_game()
	_check(int(game.current_phase) == 6, "forced start did not enter phase 6")
	_check(game._current_map_texture() == game.textures["map_phase_6"], "phase 6 did not use the real map")
	_check(game.enemies.size() == 1, "phase 6-1 should start with one enemy")
	_check(String(game.enemies[0].get("type", "")) == game.ENEMY_LODARIO, "phase 6-1 should start with Lodario as its errante")
	_check(is_equal_approx(float(game.enemy_base_hp), float(game.ENEMY_BASE_HP)), "phase 6-1 should use phase 1 base hp")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(820, 420)
	game._spawn_enemy(game.ENEMY_LODARIO, Vector2(420, 420))
	var lodario: Dictionary = game.enemies.back()
	var start_x := Vector2(lodario["pos"]).x
	lodario["lodario_jump_timer"] = 0.0
	game._update_enemies(0.02)
	_check(float(lodario.get("lodario_jump_progress", 0.0)) > 0.0, "Lodario did not start a hop")
	game._update_enemies(game.LODARIO_HOP_DURATION + 0.05)
	_check(Vector2(lodario["pos"]).x > start_x, "Lodario did not hop toward the right-side player")
	_check(Vector2(lodario["pos"]).x <= start_x + game.LODARIO_HOP_DISTANCE + 2.0, "Lodario hop exceeded configured distance")
	_check(is_equal_approx(game.LODARIO_HOP_DISTANCE, 35.0), "Lodario base hop distance was not retuned")
	_check(is_equal_approx(game.LODARIO_HOP_INTERVAL, 0.7), "Lodario base hop interval was not retuned")
	_check(game._enemy_should_flip(lodario), "Lodario did not mirror while facing right")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(510, 420)
	game._spawn_enemy(game.ENEMY_LODARIO, Vector2(420, 420))
	var close_lodario: Dictionary = game.enemies.back()
	var close_start_x := Vector2(close_lodario["pos"]).x
	var expected_lodario_damage: float = (0.06 * float(game.player_hp_max) + float(game.enemy_close_damage)) * game.LODARIO_DAMAGE_BASE_MULT
	_check(float(close_lodario.get("damage", 0.0)) >= expected_lodario_damage - 0.01, "Lodario base damage was not raised")
	close_lodario["lodario_jump_timer"] = 0.0
	game._update_enemies(0.02)
	_check(bool(close_lodario.get("lodario_lunge_active", false)), "Lodario did not lunge when within 150px")
	_check(is_equal_approx(float(close_lodario.get("lodario_jump_duration", 0.0)), game.LODARIO_LUNGE_DURATION), "Lodario lunge did not use the faster displacement duration")
	_check(Vector2(close_lodario.get("lodario_jump_to", close_lodario["pos"])).x >= close_start_x + game.LODARIO_LUNGE_DISTANCE - 2.0, "Lodario lunge target did not advance 220px toward the player")
	game._update_enemies(game.LODARIO_LUNGE_DURATION + 0.04)
	_check(Vector2(close_lodario["pos"]).x >= close_start_x + 205.0, "Lodario lunge did not carry it close to the player")
	_check(float(close_lodario.get("lodario_lunge_cd", 0.0)) >= game.LODARIO_LUNGE_COOLDOWN - 0.1, "Lodario lunge cooldown did not start after landing")
	_check(is_equal_approx(game._lodario_hop_distance(close_lodario, 90.0, false), game.LODARIO_HOP_DISTANCE), "Lodario ignored lunge cooldown distance fallback")
	_check(is_equal_approx(game.LODARIO_LUNGE_TRIGGER_DISTANCE, 150.0), "Lodario lunge trigger distance changed")
	_check(is_equal_approx(game.LODARIO_LUNGE_DISTANCE, 220.0), "Lodario lunge distance changed")
	_check(is_equal_approx(game.LODARIO_LUNGE_DURATION, 0.44), "Lodario lunge air displacement speed was not reduced by 50%")
	_check(is_equal_approx(game.LODARIO_LUNGE_COOLDOWN, 20.0), "Lodario lunge cooldown changed")
	game.phase_started_at = 0.0
	game.time_alive = game.LODARIO_DAMAGE_RAMP_TIME
	_check(game._lodario_damage_scaling() > 1.15, "Lodario damage ramp did not scale over phase time")
	var lunge_hp := float(close_lodario["hp"])
	close_lodario["lodario_jump_progress"] = 0.5
	close_lodario["lodario_lunge_active"] = true
	game._damage_enemy(close_lodario, 100.0, "smoke", false, false)
	_check(lunge_hp - float(close_lodario["hp"]) <= 82.0, "Lodario lunge did not reduce incoming damage while airborne")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(360, 360)
	game._spawn_enemy(game.ENEMY_MIASMA_EEL, Vector2(980, 360))
	var eel: Dictionary = game.enemies.back()
	eel["shoot_cd"] = 0.0
	game._update_enemies(0.05)
	_check(game.enemy_bullets.any(func(b): return String(b.get("type", "")) == "miasma_eel_spit"), "Miasma Eel did not fire its slime")
	_check(float(eel.get("eel_attack_flash", 0.0)) > 0.0, "Miasma Eel did not enter attack frame window")
	game.miasma_eel_slow_timer = 0.0
	game.miasma_eel_slow_stacks = 0
	game._damage_player(1, "miasma_eel_spit")
	_check(game.miasma_eel_slow_stacks == 1, "Miasma slow did not stack on hit")
	_check(game._miasma_eel_slow_multiplier() < 1.0, "Miasma slow multiplier was not applied")

	game.enemies.clear()
	game.player_pos = Vector2(500, 420)
	game._spawn_enemy(game.ENEMY_CHRONAL_LEECH, Vector2(720, 420))
	var leech: Dictionary = game.enemies.back()
	var leech_frames: Array = game.textures.get("enemy_phase_6_sanguessuga_cronal", [])
	_check(leech_frames.size() >= 2 and leech_frames[0] != null and leech_frames[1] != null, "Chronal Leech frames were not loaded")
	_check(is_equal_approx(game.SANGUESSUGA_DETECTION_RADIUS, 200.0), "Chronal Leech attack radius was not retuned to 200px")
	_check(String(leech.get("leech_state", "")) == game.SANGUESSUGA_STATE_FALL_WARNING, "Chronal Leech did not start as fall warning")
	_check(game._enemy_texture(leech) == leech_frames[0], "Chronal Leech used attack frame before becoming active")
	game._update_enemies(game.SANGUESSUGA_FALL_WARNING_TIME + 0.02)
	_check(String(leech.get("leech_state", "")) == game.SANGUESSUGA_STATE_FALLING, "Chronal Leech did not enter falling state")
	_check(game._enemy_texture(leech) == leech_frames[0], "Chronal Leech used attack frame while falling")
	game._update_enemies(game.SANGUESSUGA_FALL_TIME_MAX + 0.03)
	_check(String(leech.get("leech_state", "")) == game.SANGUESSUGA_STATE_DORMANT, "Chronal Leech did not become dormant")
	_check(float(leech.get("leech_life", 0.0)) <= game.SANGUESSUGA_DORMANT_TIME, "Chronal Leech dormant timer invalid")
	game.player_pos = Vector2(leech["pos"]) + Vector2(190, 0)
	game._update_enemies(0.04)
	_check(String(leech.get("leech_state", "")) == game.SANGUESSUGA_STATE_TRIGGERED, "Chronal Leech did not trigger by proximity")
	_check(game._enemy_texture(leech) == leech_frames[0], "Chronal Leech used attack frame during warning trigger")
	game._update_enemies(game.SANGUESSUGA_TRIGGER_TIME + 0.04)
	_check(String(leech.get("leech_state", "")) == game.SANGUESSUGA_STATE_LEAPING, "Chronal Leech did not start one-shot leap")
	_check(game._enemy_texture(leech) == leech_frames[1], "Chronal Leech did not use attack frame while leaping")
	game.player_pos = Vector2(leech.get("leech_leap_to", leech["pos"]))
	game._update_enemies(game.SANGUESSUGA_LEAP_TIME_MAX + 0.08)
	_check(game.sanguessuga_parasite_timer > 0.0, "Chronal Leech hit did not apply parasitism")
	var parasite_timer_after_first := float(game.sanguessuga_parasite_timer)
	game._apply_sanguessuga_parasitism(game._sanguessuga_tick_damage())
	_check(game.sanguessuga_parasite_timer <= game.SANGUESSUGA_PARASITE_MAX_TIME, "Chronal Leech parasitism stacked past max duration")
	_check(game.sanguessuga_parasite_timer > parasite_timer_after_first, "second leech hit did not extend parasitism slightly")
	game.sanguessuga_parasite_timer = 0.0
	game.sanguessuga_bleed_tick_timer = 0.0

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_MIASMA_EEL, game.player_pos + Vector2(60, 0))
	eel = game.enemies.back()
	eel["pos"] = game.player_pos + Vector2(60, 0)
	eel["eel_relocate_timer"] = 0.0
	game._update_enemies(0.02)
	_check(float(eel.get("eel_relocating", 0.0)) > 0.0, "Miasma Eel did not start relocation when its cooldown expired")
	_check(Vector2(eel.get("eel_relocate_to", eel["pos"])).distance_to(game.player_pos) > game.MIASMA_EEL_SAFE_DISTANCE * 0.75, "Miasma Eel relocation target stayed too close")
	_check(float(eel.get("eel_relocate_duration", 0.0)) >= game.MIASMA_EEL_RELOCATE_MIN_DURATION, "Miasma Eel relocation duration was too short")
	_check(is_equal_approx(game.MIASMA_EEL_RELOCATE_COOLDOWN, 30.0), "Miasma Eel relocation cooldown is not locked to 30s")
	_check(Vector2(eel["pos"]).distance_to(Vector2(eel.get("eel_relocate_to", eel["pos"]))) > 20.0, "Miasma Eel teleported to relocation target")
	game._update_enemies(float(eel.get("eel_relocate_duration", 0.0)) + 0.1)
	_check(float(eel.get("eel_relocating", 0.0)) <= 0.0, "Miasma Eel did not finish relocation")
	_check(float(eel.get("eel_relocate_timer", 0.0)) >= 29.0, "Miasma Eel did not reset its 30s cooldown after arriving")
	eel["pos"] = game.player_pos + Vector2(40, 0)
	game._update_enemies(0.25)
	_check(float(eel.get("eel_relocating", 0.0)) <= 0.0, "Miasma Eel relocated early just because the player got close")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.phase6_pustule_pools.clear()
	for i in range(game._phase6_miasma_eel_cap()):
		game._spawn_enemy(game.ENEMY_MIASMA_EEL, Vector2(120 + i * 20, 120))
	_check(game._choose_phase6_enemy_type() != game.ENEMY_MIASMA_EEL, "Miasma Eel cap allowed too many eels")

	game.enemies.clear()
	game.phase6_pustule_pools.clear()
	game.player_pos = Vector2(640, 360)
	game._spawn_enemy(game.ENEMY_FOSSIL_PUSTULE, game.player_pos + Vector2(20, 0))
	game._update_enemies(0.02)
	_check(game.phase6_pustule_pools.size() == 1, "Fossil Pustule did not leave a liquid pool")
	_check(is_equal_approx(game.PUSTULE_EXPLODE_DISTANCE, 90.0), "Fossil Pustule explosion distance was not retuned")
	var pool: Dictionary = game.phase6_pustule_pools[0]
	_check(Array(pool.get("fragments", [])).size() == game.PUSTULE_FRAGMENT_COUNT, "Fossil Pustule did not create the requested fragment burst")
	game._spawn_enemy(game.ENEMY_LODARIO, Vector2(pool["pos"]) + Vector2(120, 0))
	var attracted_lodario: Dictionary = game.enemies.back()
	_check(game.phase6_pustule_pheromone_timer > 0.0, "Fossil Pustule did not contaminate player with pheromone")
	_check(is_equal_approx(game._lodario_hop_distance(attracted_lodario), game.LODARIO_PHEROMONE_HOP_DISTANCE), "Pheromone did not increase Lodario hop distance")
	_check(is_equal_approx(game._lodario_hop_interval(attracted_lodario), game.LODARIO_PHEROMONE_HOP_INTERVAL), "Pheromone did not increase Lodario hop cadence")
	_check(is_equal_approx(game.LODARIO_PHEROMONE_HOP_DISTANCE, 90.0), "Pheromone hop distance was not retuned")
	_check(is_equal_approx(game.LODARIO_PHEROMONE_HOP_INTERVAL, 0.55), "Pheromone hop interval was not retuned")
	_check(game._lodario_target_pos(attracted_lodario).distance_to(game.player_pos) < 1.0, "Pheromone did not make Lodario target the player instead of the explosion")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(760, 360)
	game._spawn_enemy(game.ENEMY_FOSSIL_PUSTULE, Vector2(360, 360))
	var shooting_pustule: Dictionary = game.enemies.back()
	shooting_pustule["pustule_mature_time"] = 0.0
	shooting_pustule["pustule_spit_cd"] = 0.0
	game._update_enemies(0.02)
	_check(game.enemy_bullets.size() == 1, "Fossil Pustule did not fire its slowing spit")
	_check(String(game.enemy_bullets[0].get("type", "")) == "pustula_fossil_spit", "Fossil Pustule spit used the wrong bullet type")
	_check(float(shooting_pustule.get("pustule_spit_cd", 0.0)) <= game.PUSTULE_SPIT_MAX_INTERVAL + 0.5, "Fossil Pustule close spit cooldown did not slow down")
	game.pustule_spit_slow_timer = 0.0
	game.pustule_spit_slow_grace_timer = 0.0
	game._damage_player(1, "pustula_fossil_spit")
	_check(game.pustule_spit_slow_timer > 0.0, "Fossil Pustule spit did not apply movement slow")
	game._damage_player(1, "pustula_fossil_spit")
	_check(game.pustule_spit_slow_timer <= game.PUSTULE_SPIT_SLOW_TIME, "Fossil Pustule spit slow stacked while active")
	game.pustule_spit_slow_timer = 0.0
	game.pustule_spit_slow_grace_timer = game.PUSTULE_SPIT_SLOW_GRACE
	game._damage_player(1, "pustula_fossil_spit")
	_check(game.pustule_spit_slow_timer <= 0.0, "Fossil Pustule spit ignored post-slow grace window")

	game.enemies.clear()
	game.phase_started_at = 0.0
	game.time_alive = game.PHASE1_STALKER_UNLOCK_TIME - 0.1
	_check(game._choose_phase6_enemy_type() == game.ENEMY_LODARIO, "phase 6-1 unlocked advanced enemies before the phase 1 stalker timing")
	game.time_alive = game.PHASE1_STALKER_UNLOCK_TIME + 0.1
	var early_kinds := {}
	for i in range(30):
		early_kinds[game._choose_phase6_enemy_type()] = true
	_check(not early_kinds.has(game.ENEMY_MIASMA_EEL), "phase 6-1 spawned eel before projector timing")
	_check(not early_kinds.has(game.ENEMY_FOSSIL_PUSTULE), "phase 6-1 spawned pustule before crystal timing")
	game.time_alive = game.PHASE1_PROJECTOR_UNLOCK_TIME + 0.1
	var mid_kinds := {}
	for i in range(60):
		mid_kinds[game._choose_phase6_enemy_type()] = true
	_check(not mid_kinds.has(game.ENEMY_FOSSIL_PUSTULE), "phase 6-1 spawned pustule before crystal timing")
	game.time_alive = game.PHASE1_SHIELD_CRYSTAL_UNLOCK_TIME + 0.1
	var late_kinds := {}
	for i in range(90):
		late_kinds[game._choose_phase6_enemy_type()] = true
	_check(late_kinds.has(game.ENEMY_FOSSIL_PUSTULE), "phase 6-1 did not unlock pustule on the crystal timing")

	game.enemies.clear()
	game.phase6_pustule_pools.clear()
	game.player_pos = Vector2(640, 360)
	game.current_phase = 6
	game.boss_active = true
	game.boss_dead = false
	game._spawn_enemy(game.ENEMY_FOSSIL_PUSTULE, game.player_pos + Vector2(20, 0))
	game._update_enemies(0.02)
	var hungry_lodarios := 0
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == game.ENEMY_LODARIO and bool(enemy.get("pustule_hungry", false)):
			hungry_lodarios += 1
	_check(game.phase6_pustule_pheromone_timer >= game.BOSS6_PUSTULE_PHEROMONE_TIME - 0.05, "Boss pustule did not extend pheromone to 7s")
	_check(hungry_lodarios == game.BOSS6_HUNGRY_LODARIO_COUNT, "Boss pustule hit did not spawn hungry Lodarios")

	game.enemies.clear()
	game.boss_attacks.clear()
	game.current_phase = 6
	game.boss_active = true
	game.boss_dead = false
	game.player_pos = Vector2(680, 380)
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.boss_hp_max = 1000.0
	game.boss_hp = 1000.0
	_check(not game.has_method("_spawn_boss6_parasite_worms"), "old Boss6 parasite worm spawner still exists")
	_check(not game.has_method("_start_boss6_parasite_ball"), "old Boss6 parasite ball ability still exists")
	game._damage_boss(100.0, "smoke", false, false)
	_check(game.boss_hp < 1000.0, "Boss6 became invulnerable without the old worm shield")
	var hp_after_plain_damage := float(game.boss_hp)
	_check(game.BOSS6_PUSTULE_MAX == 7, "Boss6 pustule cap was not raised to seven")
	game.enemies.clear()
	for i in range(game.BOSS6_PUSTULE_MAX - 1):
		game._spawn_boss6_pustule_at(Vector2(140 + i * 78, 180))
	game._start_boss6_incubation_pustules()
	_check(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == game.BOSS6_ABILITY_INCUBATION, "Boss6 incubation did not start near pustule cap")
	var incubation_spots: Array = game.boss_attacks[0].get("spots", [])
	_check(incubation_spots.size() == 1, "Boss6 incubation ignored remaining pustule capacity")
	game._update_boss_attacks(1.1)
	_check(game._boss6_pustule_count() == game.BOSS6_PUSTULE_MAX, "Boss6 incubation did not fill to the new seven pustule cap")
	game.boss_attacks.clear()
	game._start_boss6_carapace()
	_check(game.boss6_carapace_plates.size() == 3, "Boss6 carapace did not create three plates")
	game._damage_boss(100.0, "smoke", false, false)
	_check(game.boss_hp < hp_after_plain_damage, "Boss6 carapace blocked all damage instead of reducing")
	_check(game.boss6_carapace_plates.size() <= 3, "Boss6 carapace plate count became invalid")
	game.boss_attacks.clear()
	game.enemies.clear()
	game.boss6_lodarian_pools.clear()
	game._start_boss6_acid_bloom(true)
	_check(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == game.BOSS6_ABILITY_ACID_BLOOM, "Boss6 acid bloom did not start")
	game._update_boss_attacks(1.2)
	_check(game.enemies.is_empty(), "Boss6 acid bloom should not spawn leeches")
	_check(game.boss6_lodarian_pools.size() == game.BOSS6_ACID_BLOOM_COUNT, "Boss6 acid bloom did not create five puddles")
	var acid_positions: Array = []
	for acid_pool in game.boss6_lodarian_pools:
		_check(String(acid_pool.get("kind", "")) == "acid_bloom", "Boss6 acid bloom created a non-acid pool")
		_check(is_equal_approx(float(acid_pool.get("radius", 0.0)), game.BOSS6_ACID_BLOOM_RADIUS), "Boss6 acid bloom pool radius is incorrect")
		_check(float(acid_pool.get("life", 0.0)) > game.BOSS6_ACID_BLOOM_DURATION - 0.25, "Boss6 acid bloom pool duration is incorrect")
		acid_positions.append(Vector2(acid_pool.get("pos", Vector2.ZERO)))
	for i in range(acid_positions.size()):
		for j in range(i + 1, acid_positions.size()):
			_check(Vector2(acid_positions[i]).distance_to(Vector2(acid_positions[j])) >= 120.0, "Boss6 acid bloom did not spread puddles across the map")
	for i in range(game.BOSS6_LEECH_MAX + 4):
		game._spawn_boss6_leech_at(game.boss_pos + Vector2(140 + i * 12, 0))
	_check(game._boss6_active_leech_count() <= game.BOSS6_LEECH_MAX, "Boss6 leech global limit was not respected")
	game.boss_attacks.clear()
	game._start_boss6_chasing_crack()
	_check(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == game.BOSS6_ABILITY_CHASING_CRACK, "Boss6 chasing crack did not start")
	var crack_start := Vector2(game.boss_attacks[0].get("pos", Vector2.ZERO))
	game._update_boss_attacks(0.5)
	var crack_after := Vector2(game.boss_attacks[0].get("pos", Vector2.ZERO))
	_check(crack_after.distance_to(game.player_pos) < crack_start.distance_to(game.player_pos), "Boss6 chasing crack did not pursue the player")
	game.boss_attacks.clear()
	game.boss6_lodarian_pools.clear()
	game._start_boss6_carnage_tide()
	_check(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == game.BOSS6_ABILITY_CARNAGE_TIDE, "Boss6 carnage tide did not start")
	game._update_boss_attacks(0.75)
	_check(game.boss6_lodarian_pools.size() >= 1 and String(game.boss6_lodarian_pools[0].get("kind", "")) == "carnage", "Boss6 carnage tide did not create slowing slime")
	game.boss6_carnage_slow_timer = 0.0
	game._damage_player(1, "boss6_carnage_slime")
	_check(game.boss6_carnage_slow_timer >= game.BOSS6_CARNAGE_SLOW_TIME - 0.05, "Boss6 carnage slime did not apply the slow timer")
	_check(is_equal_approx(game._boss6_carnage_slow_multiplier(), game.BOSS6_CARNAGE_SLOW_MULT), "Boss6 carnage slow multiplier is incorrect")
	game.boss_attacks.clear()
	game._start_boss6_vertebral_scythes()
	_check(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == game.BOSS6_ABILITY_SCYTHES, "Boss6 vertebral scythes did not start")
	var bones: Array = game.boss_attacks[0].get("bones", [])
	_check(bones.size() == 5, "Boss6 early vertebral scythe count is incorrect")
	game.boss_attacks.clear()
	game.enemies.clear()
	game.boss_hp = game.boss_hp_max * 0.39
	game.boss6_miasma_ult_cooldown = 0.0
	var ult_def := {"id": game.BOSS6_ABILITY_MIASMA_ULTIMATE, "min_pct": 0.0, "max_pct": game.BOSS6_MIASMA_ULT_UNLOCK_PCT, "weight": 1.0, "cooldown": game.BOSS6_MIASMA_ULT_COOLDOWN}
	_check(game._boss6_ability_available(ult_def, 0), "Boss6 miasma ultimate was not available under 40 percent hp")
	game._start_boss6_miasma_ultimate()
	_check(game._boss6_miasma_ultimate_active(), "Boss6 miasma ultimate did not become active")
	_check(is_equal_approx(game.boss6_miasma_ult_timer, game.BOSS6_MIASMA_ULT_DURATION), "Boss6 miasma ultimate duration is incorrect")
	_check(is_equal_approx(game.boss6_miasma_ult_cooldown, game.BOSS6_MIASMA_ULT_COOLDOWN), "Boss6 miasma ultimate cooldown is incorrect")
	_check(not game._boss6_ability_available({"id": game.BOSS6_ABILITY_ACID_BLOOM, "min_pct": 0.0, "max_pct": 1.0, "weight": 1.0, "cooldown": 1.0}, 0), "Boss6 ultimate did not limit acid bloom")
	_check(game._boss6_ability_available({"id": game.BOSS6_ABILITY_SCYTHES, "min_pct": 0.0, "max_pct": 1.0, "weight": 1.0, "cooldown": 1.0}, 0), "Boss6 ultimate blocked precise bone attack")
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2.from_angle(game.boss6_miasma_ult_angle) * (game.BOSS6_MIASMA_ULT_INNER_RADIUS + 40.0)
	game._update_boss6_timers(0.45)
	_check(game.boss6_miasma_slow_stacks > 0, "Boss6 miasma ultimate did not stack slow when touching the player")
	_check(game._boss6_miasma_slow_multiplier() < 1.0, "Boss6 miasma slow multiplier was not applied")
	_check(game.enemies.filter(func(e): return String(e.get("type", "")) == game.ENEMY_FOSSIL_PUSTULE and bool(e.get("boss6_ult_pustule", false))).size() == game.BOSS6_MIASMA_ULT_PUSTULE_COUNT, "Boss6 ultimate did not spawn three rotating pustules")
	game.boss_hp = 500.0
	game.boss6_fossil_shield = 0.0
	game.boss6_carapace_plates.clear()
	game.boss6_miasma_ult_angle = 0.0
	var blocked_origin: Vector2 = game.boss_pos + Vector2.from_angle(game._boss6_barrier_gap_center(0) + game.BOSS6_BARRIER_GAP_ARC + 0.55) * 260.0
	game._damage_boss(100.0, "smoke", false, false, "", blocked_origin)
	_check(is_equal_approx(game.boss_hp, 500.0), "Boss6 miasma barrier did not block damage outside a gap")
	var open_origin: Vector2 = game.boss_pos + Vector2.from_angle(game._boss6_barrier_gap_center(0)) * 260.0
	game._damage_boss(100.0, "smoke", false, false, "", open_origin)
	_check(game.boss_hp < 500.0, "Boss6 miasma barrier blocked damage through a gap")
	game.boss6_miasma_ult_timer = 0.0
	game.boss6_miasma_slow_timer = 0.0
	game.boss6_miasma_slow_stacks = 0
	game.boss_attacks.clear()
	game._start_boss6_swarm_dissolution()
	_check(game.boss6_relocating, "Boss6 relocation did not start")
	_check(game.boss6_entry_particles.size() == game.BOSS6_ENTRY_PARTICLES, "Boss6 relocation did not create the requested particle swarm")

	game.gameplay_cheat_text = "FASE6"
	_check(game._try_unlock_retornante_cheat(), "FASE6 cheat did not toggle off")
	_check(not game.force_phase6_start, "FASE6 cheat did not disable forced start")

	print("PHASE6_ENEMY_BEHAVIOUR_SMOKE_OK cheat=true lodario_hop=35 pheromone_hop=90 eel_cd=30 phase6_1=true pustule_pool=true pustule_spit=true boss6_pustules=7 boss6=true")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
