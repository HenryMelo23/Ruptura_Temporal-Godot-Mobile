class_name RTBossVisualSyncController
extends RefCounted

const Boss1AnimationPresentation = preload("res://scripts/presentation/boss1_animation_presentation.gd")

## Owns world-visual packet serialization. The runtime keeps the RPC path and
## all mutable state so this controller cannot alter authority or gameplay.

func pack(game: Node) -> Dictionary:
	var packet: = {
		"henry_entrance": game.henry_incendiary_ability_controller.entrance_snapshot(),
		"boss_core": game._pack_net_boss(),
		"boss_name": game.boss_name,
		"boss_title_color": game.boss_title_color,
		"team_kills": game.enemies_killed,
		"boss_entry_timer": game.boss_entry_timer,
		"pacing_profile": game.run_pacing_profile,
		"run_leader_peer_id": game.run_leader_peer_id,
		"arauto": game.arauto.duplicate(true),
		"arauto_rays": game.arauto_rays.duplicate(true),
		"arauto_echo_breaks": game.arauto_echo_breaks.duplicate(true),
		"arauto_card_drops": game.arauto_card_drops.duplicate(true),
		"arauto_evolution_fragments": game.arauto_evolution_fragments.duplicate(true),
		"bargain_capsule": game.bargain_capsule.duplicate(true),
		"boss_attacks": game.boss_attacks.duplicate(true),
		"boss_transition_waves": game.boss_transition_waves.duplicate(true),
		"weather": game._pack_net_weather_visuals(),
		"runtime_event": game.runtime_event_director.active_snapshot(),
		"point_boost": game.point_boost_pickup_controller.active_snapshot()
	}
	if game.current_phase == 7:
		# One clock reproduces the whole heat field; flames stay local to each client.
		packet["b7_heat"] = game.boss7_ultimate_timer if game.boss7_ultimate_active else -1.0
	match game.current_phase:
		1:
			packet.merge({
				"boss1_attack_windup": game.boss1_attack_windup.duplicate(true),
				"boss1_time_wave": game.boss1_time_wave.duplicate(true),
				"boss1_absorb_timer": game.boss1_absorb_timer,
				"boss1_stage_timer": game.boss_stage_timer,
				"boss1_stage_duration": game.boss_stage_duration,
				"boss1_siege_tide_jump": {
					"event_id": game.boss1_siege_tide_jump_event_id,
					"timer": game.boss1_siege_tide_jump_timer,
					"duration": game.boss1_siege_tide_jump_duration
				},
				"boss1_rewind_sequence": {} if game.boss1_rewind_sequence.is_empty() else {
					"event_id": String(game.boss1_rewind_sequence.get("event_id", "")),
					"elapsed": float(game.boss1_rewind_sequence.get("elapsed", 0.0)),
					"variant": int(game.boss1_rewind_sequence.get("variant", 0))
				}
			})
		2:
			packet.merge({
				"phase2_fire_walls": game.phase2_fire_walls.duplicate(true),
				"boss2_ice_shards": game.boss2_ice_shards.duplicate(true),
				"boss2_snow_zones": game.boss2_snow_zones.duplicate(true),
				"boss2_frost_particles": game.boss2_frost_particles.duplicate(true),
				"b2": PackedFloat32Array([
					float(maxi(0, game.NET_BOSS2_STATES.find(game.boss2_state))),
					game.boss2_action_timer,
					game.boss2_target_position.x,
					game.boss2_target_position.y,
					float(maxi(0, game.NET_BOSS2_ATTACKS.find(game.boss2_last_attack))),
					float(game.boss2_repeat_count),
					game.boss2_facing_dir,
					game.boss2_walk_speed,
					game.boss2_anim_timer,
					float(game.boss2_anim_frame),
					game.boss2_breath_dir.x,
					game.boss2_breath_dir.y,
					game.boss2_ultimate_timer,
					game.boss2_ultimate_center.x,
					game.boss2_ultimate_center.y,
					game.boss2_ultimate_orbit_angle,
					game.boss2_ultimate_spit_timer,
					game.boss2_ultimate_hail_timer,
					game.boss2_ultimate_fan_timer,
					game.boss2_ultimate_blizzard_tick,
					game.boss2_ultimate_blizzard_exposure,
					game.boss2_ultimate_hit_gate,
					1.0 if game.boss2_ultimate_used else 0.0,
					game.boss2_ultimate_wind_active,
					game.boss2_ultimate_wind_timer,
					game.boss2_ultimate_wind_dir.x,
					game.boss2_ultimate_wind_dir.y
				])
			})
		3:
			packet.merge({
				"phase3_ritual_pulse": game.phase3_ritual_pulse_controller.active_snapshot(),
				"phase3_miasma_zones": game.phase3_miasma_zones.duplicate(true),
				"boss3_faith": game.boss3_faith,
				"boss3_stage": game.boss3_stage,
				"boss3_stun_timer": game.boss3_stun_timer,
				"boss3_ritual_timer": game.boss3_ritual_timer,
				"boss3_ritual_destroyed": game.boss3_ritual_destroyed,
				"boss3_consume_uid": game.boss3_consume_uid,
				"boss3_consume_timer": game.boss3_consume_timer,
				"boss3_is_moving": game.boss3_is_moving,
				"boss3_facing_dir": game.boss3_facing_dir,
				"boss3_miasma_timer": game.boss3_miasma_timer,
				"boss3_miasma_variant": game.boss3_miasma_variant,
				"boss3_miasma_target_peer_id": game.boss3_miasma_target_peer_id,
				"boss3_miasma_clone_timer": game.boss3_miasma_clone_timer,
				"boss3_miasma_clone_positions": game.boss3_miasma_clone_positions.duplicate(true),
				"boss3_miasma_clone_reveal_timer": game.boss3_miasma_clone_reveal_timer,
				"boss3_miasma_qte_required": game.boss3_miasma_qte_required,
				"boss3_miasma_qte_taps": game.boss3_miasma_qte_taps,
				"boss3_miasma_qte_time_left": game.boss3_miasma_qte_time_left,
				"boss3_miasma_qte_elapsed": game.boss3_miasma_qte_elapsed,
				"boss3_faith_test_active": game.boss3_faith_test_active,
				"boss3_faith_test_pulses_left": game.boss3_faith_test_pulses_left,
				"boss3_faith_test_pulse_timer": game.boss3_faith_test_pulse_timer,
				"boss3_faith_link_timer": game.boss3_faith_link_timer,
				"boss3_sector_ritual_cooldown": game.boss3_sector_ritual_cooldown,
				"boss3_sector_ritual_sequence": game.boss3_sector_ritual_sequence
			})
		4:
			packet["phase4_instability_pulse"] = game.phase4_instability_pulse_controller.active_snapshot()
			packet["phase4_enemy_hazards"] = game.phase4_enemy_hazards.duplicate(true)
			packet["boss4_attack_pose_timer"] = game.boss4_attack_pose_timer
			packet["boss4_anim_time"] = game.boss4_anim_time
			packet["boss4_instability"] = game.boss4_instability
			packet["boss4_gravity_timer"] = game.boss4_gravity_timer
			packet["boss4_gravity_dir"] = game.boss4_gravity_dir
			packet["boss4_vampire_timer"] = game.boss4_vampire_timer
			packet["boss4_prison"] = game.boss4_prison.duplicate(true)
			packet["boss4_clone"] = game.boss4_clone.duplicate(true)
			packet["boss4_strike_sequence"] = game.boss4_strike_sequence.duplicate(true)
			packet["boss4_rupture_anchors"] = game.boss4_rupture_anchors.duplicate(true)
			packet["boss4_secondary_active"] = game.boss4_secondary_active
			packet["boss4_secondary_elapsed"] = game.boss4_secondary_elapsed
			packet["boss4_ultimate_active"] = game.boss4_ultimate_active
			packet["boss4_ultimate_timer"] = game.boss4_ultimate_timer
			packet["boss4_meteorites"] = game.boss4_meteorites.duplicate(true)
			packet["boss4_meteor_damage_bonus"] = game.boss4_meteor_damage_bonus
			packet["boss4_controller"] = game.boss4_controller.snapshot()
			packet["boss4_ultimate_destroyed"] = game.boss4_ultimate_destroyed
			packet["boss4_stun_timer"] = game.boss4_stun_timer
			packet["boss4_vulnerable_timer"] = game.boss4_vulnerable_timer
			packet["boss4_hit_timer"] = game.boss4_hit_timer
			packet["boss4_ultimate_outcome"] = game.boss4_ultimate_outcome
			packet["boss4_ultimate_outcome_timer"] = game.boss4_ultimate_outcome_timer
		5:
			packet["phase5_hazards"] = game.phase5_hazards.duplicate(true)
			packet["phase5_telegraphs"] = game.phase5_telegraphs.duplicate(true)
			packet["boss5_current_action"] = game.boss5_current_action
			packet["boss5_dimension"] = game.boss5_dimension
			packet["boss5_mental_state"] = game.boss5_mental_state
			packet["boss5_siphon_timer"] = game.boss5_siphon_timer
			packet["umbra_decision"] = game.umbra_authority_controller.public_event()
		6:
			packet.merge({
				"phase6_pustule_pools": game.phase6_pustule_pools.duplicate(true),
				"amber_suturer_state": game.amber_suturer_state.duplicate(true),
				"amber_sutures": game.amber_sutures.duplicate(true),
				"amber_suturer_visual_events": game.amber_suturer_visual_events.duplicate(true),
				"boss6_lodarian_pools": game.boss6_lodarian_pools.duplicate(true),
				"boss6_state": game.boss6_state,
				"boss6_current_ability": game.boss6_current_ability,
				"boss6_carapace_plates": game.boss6_carapace_plates.duplicate(true),
				"boss6_carapace_timer": game.boss6_carapace_timer,
				"boss6_vulnerability_timer": game.boss6_vulnerability_timer,
				"boss6_core_exposed_timer": game.boss6_core_exposed_timer,
				"boss6_core_permanent_bonus": game.boss6_core_permanent_bonus,
				"boss6_special_event_id": game.boss6_special_event_id,
				"boss6_special_timer": game.boss6_special_timer,
				"boss6_organs": game.boss6_organs.duplicate(true),
				"boss6_final_mutation": game.boss6_final_mutation,
				"boss6_final_birth_timer": game.boss6_final_birth_timer,
				"boss6_fossil_era_timer": game.boss6_fossil_era_timer,
				"boss6_fossil_shield": game.boss6_fossil_shield,
				"boss6_rib_prison": game.boss6_rib_prison.duplicate(true),
				"boss6_tail_channels": game.boss6_tail_channels.duplicate(true),
				"boss6_reflux_objects": game.boss6_reflux_objects.duplicate(true),
				"boss6_cracked_heart": game.boss6_cracked_heart.duplicate(true),
				"boss6_shielded": game.boss6_shielded,
				"boss6_entry_particle_seed": game.boss6_entry_particle_seed,
				"boss6_relocating": game.boss6_relocating,
				"boss6_relocate_from": game.boss6_relocate_from,
				"boss6_relocate_to": game.boss6_relocate_to,
				"boss6_relocate_age": game.boss6_relocate_age,
				"boss6_relocate_duration": game.boss6_relocate_duration,
				"boss6_miasma_ult_timer": game.boss6_miasma_ult_timer,
				"boss6_miasma_ult_cooldown": game.boss6_miasma_ult_cooldown,
				"boss6_miasma_ult_angle": game.boss6_miasma_ult_angle,
				"boss6_miasma_ult_pustule_timer": game.boss6_miasma_ult_pustule_timer,
				"boss6_fossil_echo": game.boss6_fossil_echo.duplicate(true),
				"boss6_necro_erosion_active": game.boss6_necro_erosion_active,
				"boss6_necro_erosion_radius": game.boss6_necro_erosion_radius,
				"boss6_necro_erosion_timer": game.boss6_necro_erosion_timer
			})
		7:
			packet.merge({
				"boss7_state": game.boss7_state,
				"boss7_state_timer": game.boss7_state_timer,
				"boss7_target_pos": game.boss7_target_pos,
				"boss7_reborn": game.boss7_reborn,
				"boss7_core_active": game.boss7_core_active,
				"boss7_core_pos": game.boss7_core_pos,
				"boss7_core_hp": game.boss7_core_hp,
				"boss7_core_hp_max": game.boss7_core_hp_max,
				"boss7_core_timer": game.boss7_core_timer,
				"boss7_flame_waves": game.boss7_flame_waves.duplicate(true)
			})
	return packet



func apply(game: Node, snapshot_data) -> void:
	if not snapshot_data is Dictionary:
		return
	var data: Dictionary = snapshot_data
	if game._is_world_replica() and data.has("henry_entrance"):
		game.henry_incendiary_ability_controller.apply_entrance_snapshot(Dictionary(data["henry_entrance"]))
	if game._is_world_replica() and data.has("boss_core"):
		game._apply_remote_boss_snapshot(data.get("boss_core"), Time.get_ticks_msec())
		game.boss_name = String(data.get("boss_name", game.boss_name))
		var incoming_title_color = data.get("boss_title_color", game.boss_title_color)
		if incoming_title_color is Color:
			game.boss_title_color = incoming_title_color
	if game._is_world_replica() and data.has("team_kills"):
		game._apply_shared_kill_progress(maxi(0, int(data["team_kills"])))
	if game._is_world_replica() and data.has("runtime_event"):
		game.runtime_event_director.apply_remote_snapshot(Dictionary(data["runtime_event"]))
	if game._is_world_replica() and data.has("point_boost"):
		game.point_boost_pickup_controller.apply_remote_snapshot(Dictionary(data["point_boost"]))
	if game._is_world_replica() and data.has("pacing_profile"):
		game.run_pacing_profile = String(data.get("pacing_profile", game.run_pacing_profile))
	game.boss1_visual_snapshot_ms = Time.get_ticks_msec()
	# Entry simulation runs only on the host; replicas render its remaining time.
	var incoming_entry_timer: float = maxf(0.0, float(data.get("boss_entry_timer", 0.0)))
	if game._is_world_replica() and not game.boss1_entry_announce_sfx_played and incoming_entry_timer > 0.0 and incoming_entry_timer <= game.BOSS1_ENTRY_ANNOUNCE_SFX_LEAD:
		game.boss1_entry_announce_sfx_played = true
		game._play_sfx("boss1_entry_announce", 0.02, 0.86, 1.0)
	game.boss_entry_timer = incoming_entry_timer
	var heat_timer: float = clampf(float(data.get("b7_heat", -1.0)), -1.0, game.PhoenixFire.DURATION)
	game.boss7_ultimate_active = game.current_phase == 7 and heat_timer > 0.0
	game.boss7_ultimate_timer = maxf(0.0, heat_timer) if game.boss7_ultimate_active else 0.0
	game._refresh_boss7_ultimate_quadrants()
	game.run_leader_peer_id = int(data.get("run_leader_peer_id", game.run_leader_peer_id))
	var incoming_arauto = data.get("arauto", game.arauto)
	game.arauto = incoming_arauto.duplicate(true) if incoming_arauto is Dictionary else {}
	game.arauto_rays = Array(data.get("arauto_rays", game.arauto_rays)).duplicate(true)
	game.arauto_echo_breaks = Array(data.get("arauto_echo_breaks", game.arauto_echo_breaks)).duplicate(true)
	game.arauto_card_drops = Array(data.get("arauto_card_drops", game.arauto_card_drops)).duplicate(true)
	game.arauto_evolution_fragments = Array(data.get("arauto_evolution_fragments", game.arauto_evolution_fragments)).duplicate(true)
	if game._is_world_replica() and data.has("bargain_capsule"):
		var incoming_capsule = data.get("bargain_capsule", {})
		game.bargain_capsule = incoming_capsule.duplicate(true) if incoming_capsule is Dictionary else {}
	var incoming_boss_attacks := Array(data.get("boss_attacks", game.boss_attacks)).duplicate(true)
	if game._is_world_replica():
		game._apply_shared_boss_attack_visual_feedback(incoming_boss_attacks)
	game.boss_attacks = incoming_boss_attacks
	game.boss_transition_waves = Array(data.get("boss_transition_waves", game.boss_transition_waves)).duplicate(true)
	game._apply_remote_weather_visual_snapshot(data.get("weather", {}))
	var incoming_time_wave = data.get("boss1_time_wave", game.boss1_time_wave)
	game.boss1_time_wave = incoming_time_wave.duplicate(true) if incoming_time_wave is Dictionary else {}
	game.boss1_absorb_timer = float(data.get("boss1_absorb_timer", game.boss1_absorb_timer))
	if game.current_phase == 1:
		var incoming_windup = data.get("boss1_attack_windup", {})
		game.boss1_attack_windup = incoming_windup.duplicate(true) if incoming_windup is Dictionary else {}
		game.boss_stage_timer = float(data.get("boss1_stage_timer", game.boss_stage_timer))
		game.boss_stage_duration = float(data.get("boss1_stage_duration", game.boss_stage_duration))
		var incoming_tide_jump = data.get("boss1_siege_tide_jump", {})
		if data.has("boss1_siege_tide_jump") and incoming_tide_jump is Dictionary:
			var incoming_tide_event_id := String(incoming_tide_jump.get("event_id", ""))
			var incoming_tide_timer := maxf(0.0, float(incoming_tide_jump.get("timer", 0.0)))
			var incoming_tide_duration := maxf(0.0, float(incoming_tide_jump.get("duration", 0.0)))
			if incoming_tide_event_id.is_empty() or incoming_tide_timer <= 0.0 or incoming_tide_duration <= 0.0:
				Boss1AnimationPresentation.clear_siege_tide_jump(game)
			else:
				game.boss1_siege_tide_jump_event_id = incoming_tide_event_id
				game.boss1_siege_tide_jump_timer = incoming_tide_timer
				game.boss1_siege_tide_jump_duration = incoming_tide_duration
	var incoming_rewind = data.get("boss1_rewind_sequence", {})
	if incoming_rewind is Dictionary and game._is_world_replica():
		game._apply_boss1_rewind_sync(incoming_rewind)
	game.phase2_fire_walls = Array(data.get("phase2_fire_walls", game.phase2_fire_walls)).duplicate(true)
	game.boss2_ice_shards = Array(data.get("boss2_ice_shards", game.boss2_ice_shards)).duplicate(true)
	game.boss2_snow_zones = Array(data.get("boss2_snow_zones", game.boss2_snow_zones)).duplicate(true)
	game.boss2_frost_particles = Array(data.get("boss2_frost_particles", game.boss2_frost_particles)).duplicate(true)
	var boss2_compact = data.get("b2", PackedFloat32Array())
	if boss2_compact is PackedFloat32Array and boss2_compact.size() >= 27:
		var b2: PackedFloat32Array = boss2_compact
		game.boss2_state = String(game.NET_BOSS2_STATES[clampi(int(b2[0]), 0, game.NET_BOSS2_STATES.size() - 1)])
		game.boss2_action_timer = b2[1]
		game.boss2_target_position = Vector2(b2[2], b2[3])
		game.boss2_last_attack = String(game.NET_BOSS2_ATTACKS[clampi(int(b2[4]), 0, game.NET_BOSS2_ATTACKS.size() - 1)])
		game.boss2_repeat_count = int(b2[5])
		game.boss2_facing_dir = b2[6]
		game.boss2_walk_speed = b2[7]
		game.boss2_anim_timer = b2[8]
		game.boss2_anim_frame = int(b2[9])
		game.boss2_breath_dir = Vector2(b2[10], b2[11])
		game.boss2_ultimate_timer = b2[12]
		game.boss2_ultimate_center = Vector2(b2[13], b2[14])
		game.boss2_ultimate_orbit_angle = b2[15]
		game.boss2_ultimate_spit_timer = b2[16]
		game.boss2_ultimate_hail_timer = b2[17]
		game.boss2_ultimate_fan_timer = b2[18]
		game.boss2_ultimate_blizzard_tick = b2[19]
		game.boss2_ultimate_blizzard_exposure = b2[20]
		game.boss2_ultimate_hit_gate = b2[21]
		game.boss2_ultimate_used = b2[22] > 0.5
		game.boss2_ultimate_wind_active = b2[23]
		game.boss2_ultimate_wind_timer = b2[24]
		game.boss2_ultimate_wind_dir = Vector2(b2[25], b2[26])
	else:
		game.boss2_state = String(data.get("boss2_state", game.boss2_state))
		game.boss2_action_timer = float(data.get("boss2_action_timer", game.boss2_action_timer))
		game.boss2_target_position = Vector2(data.get("boss2_target_position", game.boss2_target_position))
		game.boss2_last_attack = String(data.get("boss2_last_attack", game.boss2_last_attack))
		game.boss2_repeat_count = int(data.get("boss2_repeat_count", game.boss2_repeat_count))
		game.boss2_facing_dir = float(data.get("boss2_facing_dir", game.boss2_facing_dir))
		game.boss2_walk_speed = float(data.get("boss2_walk_speed", game.boss2_walk_speed))
		game.boss2_anim_timer = float(data.get("boss2_anim_timer", game.boss2_anim_timer))
		game.boss2_anim_frame = int(data.get("boss2_anim_frame", game.boss2_anim_frame))
		game.boss2_breath_dir = Vector2(data.get("boss2_breath_dir", game.boss2_breath_dir))
		game.boss2_ultimate_timer = float(data.get("boss2_ultimate_timer", game.boss2_ultimate_timer))
		game.boss2_ultimate_center = Vector2(data.get("boss2_ultimate_center", game.boss2_ultimate_center))
		game.boss2_ultimate_orbit_angle = float(data.get("boss2_ultimate_orbit_angle", game.boss2_ultimate_orbit_angle))
		game.boss2_ultimate_spit_timer = float(data.get("boss2_ultimate_spit_timer", game.boss2_ultimate_spit_timer))
		game.boss2_ultimate_hail_timer = float(data.get("boss2_ultimate_hail_timer", game.boss2_ultimate_hail_timer))
		game.boss2_ultimate_fan_timer = float(data.get("boss2_ultimate_fan_timer", game.boss2_ultimate_fan_timer))
		game.boss2_ultimate_blizzard_tick = float(data.get("boss2_ultimate_blizzard_tick", game.boss2_ultimate_blizzard_tick))
		game.boss2_ultimate_blizzard_exposure = float(data.get("boss2_ultimate_blizzard_exposure", game.boss2_ultimate_blizzard_exposure))
		game.boss2_ultimate_hit_gate = float(data.get("boss2_ultimate_hit_gate", game.boss2_ultimate_hit_gate))
		game.boss2_ultimate_used = bool(data.get("boss2_ultimate_used", game.boss2_ultimate_used))
	game.phase3_miasma_zones = Array(data.get("phase3_miasma_zones", game.phase3_miasma_zones)).duplicate(true)
	if game.current_phase == 3 and game._is_world_replica() and data.has("phase3_ritual_pulse"):
		var ritual_snapshot = data.get("phase3_ritual_pulse", {})
		game.phase3_ritual_pulse_controller.apply_remote_snapshot(Dictionary(ritual_snapshot) if ritual_snapshot is Dictionary else {})
	game.boss3_faith = float(data.get("boss3_faith", game.boss3_faith))
	game.boss3_stage = int(data.get("boss3_stage", game.boss3_stage))
	game.boss3_stun_timer = float(data.get("boss3_stun_timer", game.boss3_stun_timer))
	game.boss3_ritual_timer = float(data.get("boss3_ritual_timer", game.boss3_ritual_timer))
	game.boss3_ritual_destroyed = int(data.get("boss3_ritual_destroyed", game.boss3_ritual_destroyed))
	game.boss3_consume_uid = int(data.get("boss3_consume_uid", game.boss3_consume_uid))
	game.boss3_consume_timer = float(data.get("boss3_consume_timer", game.boss3_consume_timer))
	game.boss3_is_moving = bool(data.get("boss3_is_moving", game.boss3_is_moving))
	game.boss3_facing_dir = float(data.get("boss3_facing_dir", game.boss3_facing_dir))
	game.boss3_miasma_timer = float(data.get("boss3_miasma_timer", game.boss3_miasma_timer))
	game.boss3_miasma_variant = game._coerce_boss3_miasma_variant(int(data.get("boss3_miasma_variant", game.boss3_miasma_variant)))
	game.boss3_miasma_target_peer_id = int(data.get("boss3_miasma_target_peer_id", game.boss3_miasma_target_peer_id))
	game.boss3_miasma_clone_timer = float(data.get("boss3_miasma_clone_timer", game.boss3_miasma_clone_timer))
	game.boss3_miasma_clone_positions = Array(data.get("boss3_miasma_clone_positions", game.boss3_miasma_clone_positions)).duplicate(true)
	game.boss3_miasma_clone_reveal_timer = float(data.get("boss3_miasma_clone_reveal_timer", game.boss3_miasma_clone_reveal_timer))
	game.boss3_miasma_qte_required = int(data.get("boss3_miasma_qte_required", game.boss3_miasma_qte_required))
	game.boss3_miasma_qte_taps = int(data.get("boss3_miasma_qte_taps", game.boss3_miasma_qte_taps))
	game.boss3_miasma_qte_time_left = float(data.get("boss3_miasma_qte_time_left", game.boss3_miasma_qte_time_left))
	game.boss3_miasma_qte_elapsed = float(data.get("boss3_miasma_qte_elapsed", game.boss3_miasma_qte_elapsed))
	game.boss3_faith_test_active = bool(data.get("boss3_faith_test_active", game.boss3_faith_test_active))
	game.boss3_faith_test_pulses_left = int(data.get("boss3_faith_test_pulses_left", game.boss3_faith_test_pulses_left))
	game.boss3_faith_test_pulse_timer = float(data.get("boss3_faith_test_pulse_timer", game.boss3_faith_test_pulse_timer))
	game.boss3_faith_link_timer = float(data.get("boss3_faith_link_timer", game.boss3_faith_link_timer))
	game.boss3_sector_ritual_cooldown = float(data.get("boss3_sector_ritual_cooldown", game.boss3_sector_ritual_cooldown))
	game.boss3_sector_ritual_sequence = int(data.get("boss3_sector_ritual_sequence", game.boss3_sector_ritual_sequence))
	game.phase6_pustule_pools = Array(data.get("phase6_pustule_pools", game.phase6_pustule_pools)).duplicate(true)
	if game.current_phase == 6 and game._is_world_replica():
		var incoming_suturer_state = data.get("amber_suturer_state", game.amber_suturer_state)
		game.amber_suturer_state = incoming_suturer_state.duplicate(true) if incoming_suturer_state is Dictionary else {}
		game.amber_sutures = Array(data.get("amber_sutures", game.amber_sutures)).duplicate(true)
		game.amber_suturer_visual_events = Array(data.get("amber_suturer_visual_events", game.amber_suturer_visual_events)).duplicate(true)
	game.boss6_lodarian_pools = Array(data.get("boss6_lodarian_pools", game.boss6_lodarian_pools)).duplicate(true)
	game.boss6_state = String(data.get("boss6_state", game.boss6_state))
	game.boss6_current_ability = String(data.get("boss6_current_ability", game.boss6_current_ability))
	game.boss6_carapace_plates = Array(data.get("boss6_carapace_plates", game.boss6_carapace_plates)).duplicate(true)
	game.boss6_carapace_timer = float(data.get("boss6_carapace_timer", game.boss6_carapace_timer))
	game.boss6_vulnerability_timer = float(data.get("boss6_vulnerability_timer", game.boss6_vulnerability_timer))
	game.boss6_core_exposed_timer = float(data.get("boss6_core_exposed_timer", game.boss6_core_exposed_timer))
	game.boss6_core_permanent_bonus = float(data.get("boss6_core_permanent_bonus", game.boss6_core_permanent_bonus))
	game.boss6_special_event_id = String(data.get("boss6_special_event_id", game.boss6_special_event_id))
	game.boss6_special_timer = float(data.get("boss6_special_timer", game.boss6_special_timer))
	game.boss6_organs = Array(data.get("boss6_organs", game.boss6_organs)).duplicate(true)
	game.boss6_final_mutation = String(data.get("boss6_final_mutation", game.boss6_final_mutation))
	game.boss6_final_birth_timer = float(data.get("boss6_final_birth_timer", game.boss6_final_birth_timer))
	game.boss6_fossil_era_timer = float(data.get("boss6_fossil_era_timer", game.boss6_fossil_era_timer))
	game.boss6_fossil_shield = float(data.get("boss6_fossil_shield", game.boss6_fossil_shield))
	var incoming_rib = data.get("boss6_rib_prison", game.boss6_rib_prison)
	game.boss6_rib_prison = incoming_rib.duplicate(true) if incoming_rib is Dictionary else {}
	game.boss6_tail_channels = Array(data.get("boss6_tail_channels", game.boss6_tail_channels)).duplicate(true)
	game.boss6_reflux_objects = Array(data.get("boss6_reflux_objects", game.boss6_reflux_objects)).duplicate(true)
	var incoming_cracked = data.get("boss6_cracked_heart", game.boss6_cracked_heart)
	game.boss6_cracked_heart = incoming_cracked.duplicate(true) if incoming_cracked is Dictionary else {}
	game.boss6_shielded = bool(data.get("boss6_shielded", game.boss6_shielded))
	var previous_entry_seed: int = game.boss6_entry_particle_seed
	game.boss6_relocating = bool(data.get("boss6_relocating", game.boss6_relocating))
	game.boss6_relocate_from = Vector2(data.get("boss6_relocate_from", game.boss6_relocate_from))
	game.boss6_relocate_to = Vector2(data.get("boss6_relocate_to", game.boss6_relocate_to))
	game.boss6_relocate_age = float(data.get("boss6_relocate_age", game.boss6_relocate_age))
	game.boss6_relocate_duration = float(data.get("boss6_relocate_duration", game.boss6_relocate_duration))
	if data.has("boss6_entry_particles"):
		# Backward-compatible reader for snapshots recorded before the seeded VFX contract.
		game.boss6_entry_particles = Array(data.get("boss6_entry_particles", [])).duplicate(true)
	elif data.has("boss6_entry_particle_seed"):
		var incoming_entry_seed: int = int(data.get("boss6_entry_particle_seed", -1))
		if incoming_entry_seed >= 0 and (incoming_entry_seed != previous_entry_seed or game.boss6_entry_particles.is_empty()):
			var entry_source: Vector2 = game.boss6_relocate_from if game.boss6_relocating else Vector2.ZERO
			game._spawn_boss6_entry_particles(game.boss6_relocate_to, entry_source, incoming_entry_seed)
	game.boss6_miasma_ult_timer = float(data.get("boss6_miasma_ult_timer", game.boss6_miasma_ult_timer))
	game.boss6_miasma_ult_cooldown = float(data.get("boss6_miasma_ult_cooldown", game.boss6_miasma_ult_cooldown))
	game.boss6_miasma_ult_angle = float(data.get("boss6_miasma_ult_angle", game.boss6_miasma_ult_angle))
	game.boss6_miasma_ult_pustule_timer = float(data.get("boss6_miasma_ult_pustule_timer", game.boss6_miasma_ult_pustule_timer))
	game.phase4_enemy_hazards = Array(data.get("phase4_enemy_hazards", game.phase4_enemy_hazards)).duplicate(true)
	if game.current_phase == 4 and game._is_world_replica() and data.has("phase4_instability_pulse"):
		var pulse_snapshot = data.get("phase4_instability_pulse", {})
		game.phase4_instability_pulse_controller.apply_remote_snapshot(Dictionary(pulse_snapshot) if pulse_snapshot is Dictionary else {})
	game.boss4_attack_pose_timer = float(data.get("boss4_attack_pose_timer", game.boss4_attack_pose_timer))
	game.boss4_anim_time = float(data.get("boss4_anim_time", game.boss4_anim_time))
	game.boss4_instability = float(data.get("boss4_instability", game.boss4_instability))
	game.boss4_gravity_timer = float(data.get("boss4_gravity_timer", game.boss4_gravity_timer))
	game.boss4_gravity_dir = Vector2(data.get("boss4_gravity_dir", game.boss4_gravity_dir))
	game.boss4_vampire_timer = float(data.get("boss4_vampire_timer", game.boss4_vampire_timer))
	var incoming_prison = data.get("boss4_prison", game.boss4_prison)
	game.boss4_prison = incoming_prison.duplicate(true) if incoming_prison is Dictionary else {}
	var incoming_clone = data.get("boss4_clone", game.boss4_clone)
	game.boss4_clone = incoming_clone.duplicate(true) if incoming_clone is Dictionary else {}
	var incoming_strike = data.get("boss4_strike_sequence", game.boss4_strike_sequence)
	game.boss4_strike_sequence = incoming_strike.duplicate(true) if incoming_strike is Dictionary else {}
	game.boss4_rupture_anchors = Array(data.get("boss4_rupture_anchors", game.boss4_rupture_anchors)).duplicate(true)
	game.boss4_secondary_active = bool(data.get("boss4_secondary_active", game.boss4_secondary_active))
	game.boss4_secondary_elapsed = float(data.get("boss4_secondary_elapsed", game.boss4_secondary_elapsed))
	game.boss4_ultimate_active = bool(data.get("boss4_ultimate_active", game.boss4_ultimate_active))
	game.boss4_ultimate_timer = float(data.get("boss4_ultimate_timer", game.boss4_ultimate_timer))
	game.boss4_meteorites = Array(data.get("boss4_meteorites", game.boss4_meteorites)).duplicate(true)
	game.boss4_meteor_damage_bonus = float(data.get("boss4_meteor_damage_bonus", game.boss4_meteor_damage_bonus))
	if game.current_phase == 4 and game._is_world_replica() and data.has("boss4_controller"):
		var controller_snapshot = data.get("boss4_controller", {})
		game.boss4_controller.apply_remote_snapshot(Dictionary(controller_snapshot) if controller_snapshot is Dictionary else {})
	game.boss4_ultimate_destroyed = int(data.get("boss4_ultimate_destroyed", game.boss4_ultimate_destroyed))
	game.boss4_stun_timer = float(data.get("boss4_stun_timer", game.boss4_stun_timer))
	game.boss4_vulnerable_timer = float(data.get("boss4_vulnerable_timer", game.boss4_vulnerable_timer))
	game.boss4_hit_timer = maxf(game.boss4_hit_timer, float(data.get("boss4_hit_timer", 0.0)))
	game.boss4_ultimate_outcome = String(data.get("boss4_ultimate_outcome", game.boss4_ultimate_outcome))
	game.boss4_ultimate_outcome_timer = maxf(game.boss4_ultimate_outcome_timer, float(data.get("boss4_ultimate_outcome_timer", 0.0)))
	game.phase5_hazards = Array(data.get("phase5_hazards", game.phase5_hazards)).duplicate(true)
	game.phase5_telegraphs = Array(data.get("phase5_telegraphs", game.phase5_telegraphs)).duplicate(true)
	game.boss5_current_action = String(data.get("boss5_current_action", game.boss5_current_action))
	game.boss5_dimension = String(data.get("boss5_dimension", game.boss5_dimension))
	game.boss5_mental_state = String(data.get("boss5_mental_state", game.boss5_mental_state))
	game.boss5_siphon_timer = float(data.get("boss5_siphon_timer", game.boss5_siphon_timer))
	if game.current_phase == 5 and game._is_world_replica() and data.has("umbra_decision"):
		var incoming_umbra_decision = data.get("umbra_decision", {})
		if game.umbra_authority_controller.accept_replica_event(incoming_umbra_decision):
			game.boss5_authoritative_decision = game.umbra_authority_controller.public_event()
			game.boss5_current_action = String(game.boss5_authoritative_decision.get("action", game.boss5_current_action))
	var incoming_fossil_echo = data.get("boss6_fossil_echo", game.boss6_fossil_echo)
	game.boss6_fossil_echo = incoming_fossil_echo.duplicate(true) if incoming_fossil_echo is Dictionary else {}
	game.boss6_necro_erosion_active = bool(data.get("boss6_necro_erosion_active", game.boss6_necro_erosion_active))
	game.boss6_necro_erosion_radius = float(data.get("boss6_necro_erosion_radius", game.boss6_necro_erosion_radius))
	game.boss6_necro_erosion_timer = float(data.get("boss6_necro_erosion_timer", game.boss6_necro_erosion_timer))
	game.boss7_state = String(data.get("boss7_state", game.boss7_state))
	game.boss7_state_timer = float(data.get("boss7_state_timer", game.boss7_state_timer))
	game.boss7_target_pos = Vector2(data.get("boss7_target_pos", game.boss7_target_pos))
	game.boss7_reborn = bool(data.get("boss7_reborn", game.boss7_reborn))
	game.boss7_core_active = bool(data.get("boss7_core_active", game.boss7_core_active))
	game.boss7_core_pos = Vector2(data.get("boss7_core_pos", game.boss7_core_pos))
	game.boss7_core_hp = float(data.get("boss7_core_hp", game.boss7_core_hp))
	game.boss7_core_hp_max = float(data.get("boss7_core_hp_max", game.boss7_core_hp_max))
	game.boss7_core_timer = float(data.get("boss7_core_timer", game.boss7_core_timer))
	game.boss7_flame_waves = Array(data.get("boss7_flame_waves", game.boss7_flame_waves)).duplicate(true)
	if not (boss2_compact is PackedFloat32Array and boss2_compact.size() >= 27):
		game.boss2_ultimate_wind_active = float(data.get("boss2_wind_active", game.boss2_ultimate_wind_active))
		game.boss2_ultimate_wind_timer = float(data.get("boss2_wind_timer", game.boss2_ultimate_wind_timer))
		game.boss2_ultimate_wind_dir = Vector2(data.get("boss2_wind_dir", game.boss2_ultimate_wind_dir))
