extends RefCounted

var core: Node


func configure(p_core: Node) -> void:
	core = p_core


func _pick_initial_phase() -> int:
	var forced_phase: = _sanitize_forced_initial_phase(core.forced_initial_phase)
	if core.force_phase6_start and forced_phase == 0:
		forced_phase = 6
	if forced_phase > 0:
		return forced_phase
	if core.INITIAL_PHASE_ROLL_POOL.is_empty():
		return 1
	var bias_target: = _sanitize_initial_phase_bias_target(core.initial_phase_bias_target)
	if bias_target > 0 and core.rng.randf() <= clampf(core.initial_phase_bias_strength, 0.0, 1.0):
		return bias_target
	var index: int = core.rng.randi_range(0, core.INITIAL_PHASE_ROLL_POOL.size() - 1)
	return int(core.INITIAL_PHASE_ROLL_POOL[index])


func _sanitize_initial_phase_bias_target(phase: int) -> int:
	return phase if phase in core.INITIAL_PHASE_ROLL_POOL else 0


func _sanitize_forced_initial_phase(phase: int) -> int:
	return phase if phase >= 1 and phase <= 7 else 0


func _forced_initial_phase_label() -> String:
	var phase: = _sanitize_forced_initial_phase(core.forced_initial_phase)
	return "AUTO" if phase == 0 else "FASE %d" % phase


func _begin_initial_phase_tracking(phase: int) -> void:
	var initial_phase: = _sanitize_initial_phase_bias_target(phase)
	core.run_initial_phase = initial_phase
	core.run_phase6_completed = false
	_reset_dimension_route_state()
	core.initial_phase_current_run = initial_phase
	core.initial_phase_current_recorded = initial_phase == 0


func _reset_dimension_route_state() -> void:
	core.dimension_route_queue.clear()
	core.dimension_route_farm_cycles = 0
	core.dimension_route_completed_count = 0
	core.dimension_route_last_phase = 0
	core.run_extracted = false


func _set_initial_phase_bias(target_phase: int, strength: float, persist: = true) -> void:
	core.initial_phase_bias_target = _sanitize_initial_phase_bias_target(target_phase)
	core.initial_phase_bias_strength = clampf(strength, 0.0, 1.0) if core.initial_phase_bias_target > 0 else 0.0
	if persist:
		core._save_config()


func _record_initial_phase_attempt_before_new_run() -> void:
	if core.initial_phase_current_recorded:
		return
	var phase: = _sanitize_initial_phase_bias_target(core.initial_phase_current_run)
	if phase == 0:
		core.initial_phase_current_recorded = true
		return
	if core.run_finalized_result != "":
		core.initial_phase_current_recorded = true
		return
	if core.time_alive > 0.0 and core.time_alive <= core.INITIAL_PHASE_QUICK_EXIT_TIME and not core.boss_dead:
		_set_initial_phase_bias(phase, core.INITIAL_PHASE_QUICK_EXIT_BIAS)
	core.initial_phase_current_recorded = true


func _record_initial_phase_completed(phase: int) -> void:
	var completed_phase: = _sanitize_initial_phase_bias_target(phase)
	if completed_phase == 0 or completed_phase != _sanitize_initial_phase_bias_target(core.run_initial_phase):
		return
	var next_preferred: = 6 if completed_phase == 1 else 1
	_set_initial_phase_bias(next_preferred, core.INITIAL_PHASE_ALTERNATE_BIAS)
	core.initial_phase_current_recorded = true


func _core_next_phase_after_boss(phase: int) -> int:
	if phase == 6:
		_record_initial_phase_completed(phase)
		core.run_phase6_completed = true
		return 2
	if phase == 1:
		_record_initial_phase_completed(phase)
		return 2
	if phase == 2:
		return 3
	if phase == 3:
		return 4
	return 0


func _next_phase_after_boss(phase: int) -> int:
	var core_next: int = _core_next_phase_after_boss(phase)
	if core_next > 0:
		return core_next
	if not core.dimension_route_queue.is_empty():
		return int(core.dimension_route_queue[0])
	return 0


func _consume_next_phase_after_boss(phase: int) -> int:
	var core_next: int = _core_next_phase_after_boss(phase)
	if core_next > 0:
		return core_next
	if not core.dimension_route_queue.is_empty():
		return int(core.dimension_route_queue.pop_front())
	return 0


func _register_dimension_phase_completed(phase: int) -> void:
	if phase == core.DIMENSION_FINAL_PHASE:
		return
	core.dimension_route_completed_count += 1
	core.dimension_route_last_phase = phase


func _should_offer_dimension_choice_after_boss(phase: int) -> bool:
	if phase == core.DIMENSION_FINAL_PHASE:
		return false
	if phase == 4:
		return true
	return core.dimension_route_farm_cycles > 0 and core.dimension_route_queue.is_empty()


func _dimension_extraction_available() -> bool:
	return core.dimension_route_completed_count > 0 and core.dimension_route_completed_count % core.DIMENSION_EXTRACTION_INTERVAL == 0


func _roll_dimension_route(count: int, last_phase: int) -> Array[int]:
	var route: Array[int] = []
	var previous: int = last_phase
	for i in range(maxi(0, count)):
		var candidates: Array[int] = []
		for phase in core.DIMENSION_ROUTE_POOL:
			if phase == core.DIMENSION_FINAL_PHASE or phase == previous:
				continue
			candidates.append(phase)
		if candidates.is_empty():
			break
		var chosen: int = candidates[core.rng.randi_range(0, candidates.size() - 1)]
		route.append(chosen)
		previous = chosen
	return route


func _begin_farm_dimension_cycle() -> int:
	core.dimension_route_farm_cycles += 1
	var entry_phase: int = core.DIMENSION_FIRST_FARM_PHASE
	var tail_count: int = core.DIMENSION_FIRST_FARM_TAIL_COUNT
	if core.dimension_route_farm_cycles > 1:
		var rolled: Array[int] = _roll_dimension_route(1, core.current_phase)
		entry_phase = int(rolled[0]) if not rolled.is_empty() else core.DIMENSION_FIRST_FARM_PHASE
		tail_count = maxi(0, core.DIMENSION_REPEAT_FARM_TOTAL_COUNT - 1)
	core.dimension_route_queue = _roll_dimension_route(tail_count, entry_phase)
	return entry_phase


func _complete_dimension_extraction() -> void:
	core.phase_fragment.clear()
	core.run_extracted = true
	core._stop_battle_music_for_screen_transition()
	core._add_text("EXTRACAO TEMPORAL", core.player_pos + Vector2(0, -118), Color(0.88, 1.0, 0.92), 2.4, 30)
	core._add_text("LINHA DO TEMPO ROMPIDA", core.player_pos + Vector2(0, -154), Color(1.0, 0.65, 0.22), 2.8, 24)
	core._finalize_run_report("Extracao")
	core.mode = "victory"


func _phase1_is_after_phase6() -> bool:
	return core.current_phase == 1 and int(core.run_initial_phase) == 6 and bool(core.run_phase6_completed)


func _apply_initial_phase_setup(phase: int, multiplayer_enemy_hp_scale: float = 1.0) -> void:
	var scaled_enemy_hp: float = core.ENEMY_BASE_HP * (multiplayer_enemy_hp_scale if core.is_multiplayer else 1.0)
	core._reset_boss_party_scaling_context(phase)
	if phase == 7:
		core.enemy_base_hp = scaled_enemy_hp * 1.18
		core.enemy_speed_base = core.ENEMY_BASE_SPEED * 1.08
		core.boss_ready = false
		core.boss_hp_max = 0.0
		core.boss_hp = 0.0
		core.boss_name = "FENIX"
		core.boss_title_color = Color(1.0, 0.38, 0.18)
		core.next_larapio_spawn_time = INF
		core._spawn_enemy(core.ENEMY_CINERIDO, core._spawn_point_on_edge())
		core._add_text("CHEAT: FASE 7", core.player_pos + Vector2(0, -112), core.boss_title_color, 2.2, 28)
		return
	if phase == 6:
		core.enemy_base_hp = scaled_enemy_hp
		core.enemy_speed_base = core.ENEMY_BASE_SPEED
		core.boss_hp_max = core._boss_hp_for_phase(6)
		core.boss_hp = core.boss_hp_max
		core.boss_pos = Vector2(core.WORLD_SIZE.x + 220.0, core.WORLD_SIZE.y * 0.36)
		core.boss1_walk_previous_pos = core.boss_pos
		core.boss_name = "MATRIARCA DA CHAGA"
		core.boss_title_color = Color(1.0, 0.64, 0.18)
		core.next_larapio_spawn_time = INF
		core._spawn_enemy(core.ENEMY_LODARIO, core._spawn_point_on_edge())
		core._add_text("INICIO SORTEADO: FASE 6-1", core.player_pos + Vector2(0, -112), core.boss_title_color, 2.2, 28)
		return
	if phase == 5:
		core.enemy_base_hp = scaled_enemy_hp * 4.15
		core.enemy_speed_base = core.ENEMY_BASE_SPEED * 1.24
		core.boss_hp_max = core._boss_hp_for_phase(5)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "UMBRA"
		core.boss_title_color = Color(0.42, 1.0, 0.55)
		core.next_larapio_spawn_time = core.LARAPIO_SPAWN_TIME
		core._load_umbra_mobile_memory()
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._add_text("CHEAT: FASE 5", core.player_pos + Vector2(0, -112), core.boss_title_color, 2.2, 28)
		return
	if phase == 4:
		core.enemy_base_hp = scaled_enemy_hp * 2.75
		core.enemy_speed_base = core.ENEMY_BASE_SPEED * 1.18
		core.boss_hp_max = core._boss_hp_for_phase(4)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "NEXO DA RUPTURA"
		core.boss_title_color = Color(1.0, 0.76, 0.18)
		core.next_larapio_spawn_time = core.LARAPIO_SPAWN_TIME
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._add_text("CHEAT: FASE 4", core.player_pos + Vector2(0, -112), core.boss_title_color, 2.2, 28)
		return
	if phase == 3:
		core.enemy_base_hp = scaled_enemy_hp * 2.05
		core.enemy_speed_base = core.ENEMY_BASE_SPEED * 1.12
		core.boss_hp_max = core._boss_hp_for_phase(3)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "PAI-RATO"
		core.boss_title_color = Color(0.72, 0.92, 0.24)
		core.next_larapio_spawn_time = core.LARAPIO_SPAWN_TIME
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._add_text("CHEAT: FASE 3", core.player_pos + Vector2(0, -112), core.boss_title_color, 2.2, 28)
		return
	if phase == 2:
		core.enemy_base_hp = scaled_enemy_hp * 1.65
		core.enemy_speed_base = core.ENEMY_BASE_SPEED * 1.08
		core.boss_hp_max = core._boss_hp_for_phase(2)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "SENTINELA GLACIAL"
		core.boss_title_color = Color(0.5, 0.86, 1.0)
		core.next_larapio_spawn_time = core.LARAPIO_SPAWN_TIME
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._add_text("CHEAT: FASE 2", core.player_pos + Vector2(0, -112), core.boss_title_color, 2.2, 28)
		return
	core.enemy_base_hp = scaled_enemy_hp
	core.enemy_speed_base = core.ENEMY_BASE_SPEED
	core.boss_hp_max = core.BOSS_BASE_HP
	core.boss_hp = core.boss_hp_max
	core.boss_pos = Vector2(1240, 410)
	core.boss1_walk_previous_pos = core.boss_pos
	core.boss_name = "CARANGUEJO COSMICO GIGANTE"
	core.boss_title_color = Color(1.0, 0.52, 0.16)
	core.next_larapio_spawn_time = core.time_alive + core._larapio_spawn_delay()
	core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())


func _advance_to_phase(phase: int) -> void:
	var rain_should_become_snow = phase == 2 and core.boss1_rain_active and core.weather_kind == "rain"
	var carried_enemy_hp: float = max(float(core.enemy_base_hp), core.ENEMY_BASE_HP)
	var carried_enemy_speed: float = max(float(core.enemy_speed_base), core.ENEMY_BASE_SPEED)
	var previous_enemy_cap: int = core._enemy_limit()
	core.current_phase = phase
	core.pending_phase = 0
	core.phase_started_at = core.time_alive
	core.enemy_manager.prepare_phase_density_carry(previous_enemy_cap)
	if core.is_multiplayer and core._is_world_authority():
		core._confirm_card_unlock_progress_for_active_players("phase_reached", float(phase), true)
	else:
		core._set_card_unlock_progress_max("phase_reached", float(phase))
	if core.mode != "phase_transition":
		core.mode = "game"
	core._play_phase_music()
	if core.mode != "phase_transition":
		core.phase_transition_timer = 0.0
	core.phase_fragment.clear()
	core.player_pos = core.PLAYER_START
	core.petro_pos = core.player_pos + Vector2(-64, 32)
	core.spawn_timer = 0.0
	core.last_attack_time = -10.0
	core.last_skill_time = -10.0
	core.last_dash_time = -10.0
	core.last_secondary_time = -999.0
	core.last_damage_time = -10.0
	core.boss_wave_slow_timer = 0.0
	core.miasma_eel_slow_timer = 0.0
	core.miasma_eel_slow_stacks = 0
	core.pustule_spit_slow_timer = 0.0
	core.pustule_spit_slow_grace_timer = 0.0
	core.player_silence_timer = 0.0
	core.boss_parasite_seeds = 0
	core.boss_parasite_mark_time = 0.0
	core.retornante_memoria_pending = false
	core.damage_flash_timer = 0.0
	core.hud_feedback.reset(core)
	core.low_health_heartbeat_timer = 0.0
	core.low_health_heartbeat_double = false
	core.secondary_drain_flash_timer = 0.0
	core.screen_shake_timer = 0.0
	core.screen_shake_strength = 0.0
	core.lacerante_preparing = false
	core.lacerante_prepare_stage = 0
	core.lacerante_prepare_frame = 0
	core.lacerante_prepare_timer = 0.0
	core.lacerante_prepare_dir = core.last_facing if core.last_facing.length() > 0.05 else Vector2.RIGHT
	core.forced_shop_timer = -1.0
	core.forced_shop_triggered = false
	core.next_forced_shop_time = max(0.0, core.shop_auto_interval - core.shop_auto_elapsed) if core.shop_auto_enabled else INF
	core.shop_opening_timer = 0.0
	core.shop_opening_forced = false
	core.boss_ready = true
	core.boss_call_timer = -1.0
	core.boss_active = false
	core.boss_dead = false
	core._reset_boss_party_scaling_context(phase)
	core.boss_phase = 0.0
	core.boss_attack_timer = 0.0
	core.boss_entry_timer = 0.0
	core.boss_stage_timer = 0.0
	core.boss_stage_approaching = false
	core.boss_stage_60_done = false
	core.boss_stage_40_done = false
	core.boss_stage_30_done = false
	core.boss_attacks.clear()
	core.boss_transition_waves.clear()
	core._reset_boss1_rewind_state()
	core.boss_empurrou_player = false
	core.larapio_spawned = false
	core.next_larapio_spawn_time = core.LARAPIO_SPAWN_TIME
	core.alert_stalker_done = false
	core.alert_projector_done = false
	core.alert_crystal_done = false
	core.alert_agglomerator_done = false
	core.alert_curater_done = false
	core.event_alert_text = ""
	core.event_alert_timer = 0.0
	core.event_alert_seed = 0
	core.insane_echo_visuals.clear()
	core.rational_trail_points.clear()
	core.rational_trail_sample_timer = 0.0
	core.rational_dilation_flash = 0.0
	core._clear_attack_lock()
	core.enemies.clear()
	core.bullets.clear()
	core.remote_bullets.clear()
	core.enemy_bullets.clear()
	core.eletrica_waves.clear()
	core.eletrica_chains.clear()
	core.eletrica_recoil_velocity = Vector2.ZERO
	core.larapio_coin_drops.clear()
	core.shockwaves.clear()
	core.effects.clear()
	core.heal_orbs.clear()
	core.slashes.clear()
	core.anchors.clear()
	core.prisms.clear()
	core.orbitals.clear()
	core.gravitante_vfx_events.clear()
	core.seed_links.clear()
	core.parasite_spit_zones.clear()
	core.return_bullets.clear()
	core.manifestation_secondaries.clear()
	core._reset_advanced_manifestation_state()
	core._reset_arauto_state(true)
	core._reset_phase3_state()
	core._reset_phase4_state()
	core._reset_phase5_state()
	core._reset_phase6_state()
	if phase == 1:
		core._clear_environment_weather(true)
	elif rain_should_become_snow:
		core._convert_rain_to_snow()
	elif phase != 2:
		core._clear_environment_weather(true)
	if core.current_phase == 6:
		core.enemy_base_hp = max(carried_enemy_hp, core.ENEMY_BASE_HP)
		core.enemy_speed_base = max(carried_enemy_speed, core.ENEMY_BASE_SPEED)
		core.boss_hp_max = core._boss_hp_for_phase(6)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "MATRIARCA DA CHAGA"
		core.boss_title_color = Color(1.0, 0.64, 0.18)
		core._spawn_enemy(core.ENEMY_LODARIO, core._spawn_point_on_edge())
		core._spawn_enemy(core.ENEMY_LODARIO, core._spawn_point_on_edge())
		core._add_text("FASE 6: CHAGA DE AMBAR", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)
	elif core.current_phase == 7:
		core.enemy_base_hp = max(carried_enemy_hp, core.ENEMY_BASE_HP * 1.18)
		core.enemy_speed_base = max(carried_enemy_speed, core.ENEMY_BASE_SPEED * 1.08)
		core.boss_ready = false
		core.boss_hp_max = 0.0
		core.boss_hp = 0.0
		core.boss_name = "FENIX"
		core.boss_title_color = Color(1.0, 0.38, 0.18)
		core.next_larapio_spawn_time = INF
		core._spawn_enemy(core.ENEMY_CINERIDO, core._spawn_point_on_edge())
		core._spawn_enemy(core.ENEMY_CINERIDO, core._spawn_point_on_edge())
		core._add_text("FASE 7: CINZAS DA RUPTURA", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)
	elif core.current_phase == 5:
		core.enemy_base_hp = max(carried_enemy_hp, core.ENEMY_BASE_HP * 4.15)
		core.enemy_speed_base = max(carried_enemy_speed, core.ENEMY_BASE_SPEED * 1.24)
		core.boss_hp_max = core._boss_hp_for_phase(5)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "UMBRA"
		core.boss_title_color = Color(0.42, 1.0, 0.55)
		core._load_umbra_mobile_memory()
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._add_text("FASE 5: MENTE DA UMBRA", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)
	elif core.current_phase == 4:
		core.enemy_base_hp = max(carried_enemy_hp, core.ENEMY_BASE_HP * 2.75)
		core.enemy_speed_base = max(carried_enemy_speed, core.ENEMY_BASE_SPEED * 1.18)
		core.boss_hp_max = core._boss_hp_for_phase(4)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "NEXO DA RUPTURA"
		core.boss_title_color = Color(1.0, 0.76, 0.18)
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._spawn_enemy(core._choose_phase4_enemy_type(), core._spawn_point_on_edge())
		core._add_text("FASE 4: CORACAO DO NEXO", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)
	elif core.current_phase == 3:
		core.enemy_base_hp = max(carried_enemy_hp, core.ENEMY_BASE_HP * 2.05)
		core.enemy_speed_base = max(carried_enemy_speed, core.ENEMY_BASE_SPEED * 1.12)
		core.boss_hp_max = core._boss_hp_for_phase(3)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "PAI-RATO"
		core.boss_title_color = Color(0.72, 0.92, 0.24)
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._add_text("FASE 3: CATEDRAL DO ESGOTO", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)
	elif core.current_phase == 2:
		core.enemy_base_hp = max(carried_enemy_hp, core.ENEMY_BASE_HP * 1.65)
		core.enemy_speed_base = max(carried_enemy_speed, core.ENEMY_BASE_SPEED * 1.08)
		core.boss_hp_max = core._boss_hp_for_phase(2)
		core.boss_hp = core.boss_hp_max
		core.boss_name = "SENTINELA GLACIAL"
		core.boss_title_color = Color(0.5, 0.86, 1.0)
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._add_text("FASE 2: FENDA GLACIAL", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)
	else:
		var secondary_phase1: = _phase1_is_after_phase6()
		core.enemy_base_hp = core.ENEMY_BASE_HP * (1.12 if secondary_phase1 else 1.0)
		core.enemy_speed_base = core.ENEMY_BASE_SPEED * (1.03 if secondary_phase1 else 1.0)
		core.boss_hp_max = core.BOSS_BASE_HP
		core.boss_hp = core.boss_hp_max
		core.boss_name = "CARANGUEJO COSMICO GIGANTE"
		core.boss_title_color = Color(1.0, 0.52, 0.16)
		core.next_larapio_spawn_time = core.time_alive + core._larapio_spawn_delay()
		core._spawn_enemy(core.ENEMY_COMMON, core._spawn_point_on_edge())
		core._add_text("FASE 1: RUINAS COSMICAS" if not secondary_phase1 else "FASE 1-2: RUINAS REABERTAS", core.player_pos + Vector2(0, -110), core.boss_title_color, 2.4, 30)


func _clear_phase_mp_request() -> void:
	core.phase_mp_request_timer = 0.0
	core.phase_mp_request_incoming = false
	core.phase_mp_request_outgoing = false
	core.phase_mp_target = 0
	core.phase_mp_action = "phase"
	core.phase_mp_vote_count = 0
	core.phase_mp_expected_count = 1
	core.buttons.erase("phase_mp_accept")


func _start_phase_mp_request_overlay(incoming: bool, target_phase: int, action: String = "phase", vote_count: int = 1, expected_count: int = 2) -> void:
	core.phase_mp_request_timer = core.PHASE_MP_REQUEST_TIME
	core.phase_mp_request_incoming = incoming
	core.phase_mp_request_outgoing = not incoming
	core.phase_mp_target = target_phase
	core.phase_mp_action = action
	core.phase_mp_vote_count = vote_count
	core.phase_mp_expected_count = maxi(1, expected_count)


func _phase_mp_request_visible() -> bool:
	return core.is_multiplayer and core.mode == "game" and core.phase_mp_request_timer > 0.0 and (core.phase_mp_request_incoming or core.phase_mp_request_outgoing)


func _update_phase_mp_request(delta: float) -> void:
	if not _phase_mp_request_visible():
		return
	core.phase_mp_request_timer = maxf(0.0, core.phase_mp_request_timer - delta)
	if core.phase_mp_request_timer <= 0.0:
		_clear_phase_mp_request()


func _request_phase_mp_consensus(target_phase: int, action: String = "phase") -> void:
	if target_phase <= 0 and action == "phase":
		return
	if core.phase_mp_request_outgoing and core.phase_mp_target == target_phase and core.phase_mp_action == action:
		return
	_start_phase_mp_request_overlay(false, target_phase, action, 1, core._active_run_player_count())
	if core._shop_rpc_available():
		core.rpc("_rpc_request_phase_transfer", target_phase, action)


func _accept_phase_mp_request() -> void:
	if not core.phase_mp_request_incoming:
		return
	var target_phase: int = core.phase_mp_target
	var action: String = core.phase_mp_action
	core.phase_mp_request_incoming = false
	core.phase_mp_request_outgoing = true
	if core._shop_rpc_available():
		core.rpc("_rpc_accept_phase_transfer", target_phase, action)


func _commit_phase_mp_transfer(target_phase: int, action: String = "phase") -> void:
	_clear_phase_mp_request()
	core.phase_fragment.clear()
	if action == "extract":
		_complete_dimension_extraction()
		return
	var next_phase: int = target_phase
	if action == "farm":
		next_phase = _begin_farm_dimension_cycle()
	if next_phase > 0:
		_start_phase_transition(next_phase)


func _update_phase_transition(delta: float) -> void:
	core.phase_transition_timer -= delta
	core._update_environment_weather(delta)
	core._update_effects(delta)
	if core.phase_transition_timer <= core.PHASE_TRANSITION_WIPE_TIME and core.pending_phase > 0:
		var target_phase: int = core.pending_phase
		core.pending_phase = 0
		_advance_to_phase(target_phase)
		core.mode = "phase_transition"
	elif core.phase_transition_timer <= 0.0:
		core.mode = "game"
		core._reset_phase_transition_nodes()


func _spawn_phase_fragment(pos: Vector2, next_phase: int) -> void:
	core.phase_fragment = {
		"pos": pos,
		"next_phase": next_phase,
		"pulse": 0.0,
		"life": 0.0
	}


func _spawn_phase_choice_portals(pos: Vector2) -> void:
	var center: Vector2 = pos.clamp(Vector2(180.0, 140.0), core.WORLD_SIZE - Vector2(180.0, 140.0))
	var farm_pos: Vector2 = (center + Vector2(-96.0, 18.0)).clamp(Vector2(90.0, 90.0), core.WORLD_SIZE - Vector2(90.0, 90.0))
	var umbra_pos: Vector2 = (center + Vector2(96.0, 18.0)).clamp(Vector2(90.0, 90.0), core.WORLD_SIZE - Vector2(90.0, 90.0))
	var choices: Array[Dictionary] = [
		{"pos": farm_pos, "next_phase": 0, "kind": "farm", "action": "farm", "label": ""},
		{"pos": umbra_pos, "next_phase": core.DIMENSION_FINAL_PHASE, "kind": "umbra", "action": "phase", "label": ""}
	]
	if _dimension_extraction_available():
		var extraction_pos: Vector2 = (center + Vector2(0.0, -92.0)).clamp(Vector2(90.0, 90.0), core.WORLD_SIZE - Vector2(90.0, 90.0))
		choices.append({"pos": extraction_pos, "next_phase": 0, "kind": "extract", "action": "extract", "label": "EXTRACAO"})
	core.phase_fragment = {
		"pos": center,
		"next_phase": 0,
		"pulse": 0.0,
		"life": 0.0,
		"choices": choices
	}
	core._add_text("DUAS ROTAS ABERTAS", center + Vector2(-132, -132), Color(0.62, 1.0, 0.92), 2.1, 25)


func _start_phase_transition(next_phase: int) -> void:
	core.pending_phase = next_phase
	core.mode = "phase_transition"
	core.phase_transition_timer = core.PHASE_TRANSITION_TIME
	core._add_text("FRATURA DIMENSIONAL", core.player_pos + Vector2(0, -120), Color(0.64, 0.92, 1.0), 1.8, 30)


func _update_phase_fragment(delta: float) -> void:
	if core.phase_fragment.is_empty():
		return
	core.phase_fragment["life"] = float(core.phase_fragment.get("life", 0.0)) + delta
	core.phase_fragment["pulse"] = float(core.phase_fragment.get("pulse", 0.0)) + delta * 4.0
	var choices: Array = Array(core.phase_fragment.get("choices", []))
	if not choices.is_empty():
		for choice in choices:
			var choice_pos: Vector2 = Vector2(choice.get("pos", core.phase_fragment.get("pos", core.player_pos)))
			if core.player_pos.distance_to(choice_pos) <= core.BOSS_FRAGMENT_PICKUP_RADIUS * 1.15:
				if core.is_multiplayer and not core._is_local_run_leader():
					var warn_cd: float = maxf(0.0, float(core.phase_fragment.get("leader_warn_cd", 0.0)) - delta)
					if warn_cd <= 0.0:
						core.phase_fragment["leader_warn_cd"] = 1.2
						core._add_text("LIDER DA RUN: %s" % core._run_leader_name(), choice_pos + Vector2(0, -86), Color(1.0, 0.86, 0.18), 0.95, 16)
					else:
						core.phase_fragment["leader_warn_cd"] = warn_cd
					return
				var action: String = String(choice.get("action", "phase"))
				var choice_phase: int = int(choice.get("next_phase", 0))
				if core.is_multiplayer:
					_request_phase_mp_consensus(choice_phase, action)
					return
				if action == "farm":
					choice_phase = _begin_farm_dimension_cycle()
				core.phase_fragment.clear()
				if action == "extract":
					_complete_dimension_extraction()
				elif choice_phase > 0:
					_start_phase_transition(choice_phase)
				return
		return
	var fragment_pos: Vector2 = Vector2(core.phase_fragment["pos"])
	if core.player_pos.distance_to(fragment_pos) <= core.BOSS_FRAGMENT_PICKUP_RADIUS:
		var next_phase = int(core.phase_fragment.get("next_phase", 0))
		if core.is_multiplayer:
			if not core._is_local_run_leader():
				core._add_text("APENAS O LIDER ATRAVESSA", fragment_pos + Vector2(0, -72), Color(1.0, 0.86, 0.18), 0.9, 16)
				return
			_request_phase_mp_consensus(next_phase, "phase")
			return
		core.phase_fragment.clear()
		if next_phase > 0:
			_start_phase_transition(next_phase)
