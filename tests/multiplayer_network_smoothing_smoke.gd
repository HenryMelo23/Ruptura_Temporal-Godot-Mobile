extends SceneTree

const Boss3AnimationPresentation = preload("res://scripts/presentation/boss3_animation_presentation.gd")
const EntitiesPresentation = preload("res://scripts/presentation/entities_presentation.gd")
const ManifestationVisualSnapshot = preload("res://scripts/systems/online/runtime_manifestation_visual_snapshot.gd")
const VisualSyncContract = preload("res://scripts/systems/online/runtime_visual_sync_contract.gd")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _canonical_fixture(game: Node, key: String, action: int, origin: Vector2, target: Vector2) -> Dictionary:
	var state := {"manifestation_key": key, "evolution_ids": [], "source_time": 18.0}
	if action == game.NET_ABILITY_ATTACK:
		match key:
			"lacerante":
				state["slashes"] = [{"a": origin, "b": target, "life": 0.7, "max": 0.7, "color": Color.RED, "width": 42.0, "kind": "lacerante_attack"}]
			"acorrentada":
				state["acorrentada_tension"] = 30.0
				state["acorrentada_visuals"] = []
				state["acorrentada_worn_chains"] = [{
					"index": 0,
					"attack_motion": {"stage": 1, "elapsed": 0.12},
					"physics": {"a": origin, "b": target, "points": [
						origin, origin.lerp(target, 0.33) + Vector2(0, -18),
						origin.lerp(target, 0.66) + Vector2(0, 14), target
					]}
				}]
			"eclipsada":
				state["eclipsada_vfx"] = [{"kind": "q_dash", "origin": origin, "target": target, "dir": (target - origin).normalized(), "life": 0.7, "max": 0.7, "color": Color(0.58, 0.42, 1.0)}]
		return state
	if action == game.NET_ABILITY_SECONDARY:
		state["secondary"] = {"kind": key, "life": 1.2, "max": 1.2, "center": target, "seed": 91, "targets": [], "cuts": [], "ghosts": [], "zaps": []}
		return state
	if action == game.NET_ABILITY_TELEPORT:
		var teleport_kind := "eclipsada_lua_tp" if key == "eclipsada" else key
		state["tp_effects"] = [{"kind": teleport_kind, "life": 0.8, "max": 0.8, "a": origin, "b": target, "color": Color(0.4, 0.86, 1.0)}]
		if key == "lacerante":
			state["slashes"] = [{"a": origin, "b": target, "life": 0.8, "max": 0.8, "color": Color(1.0, 0.08, 0.18), "width": 42.0, "kind": "lacerante_tp"}]
		return state
	match key:
		"eletrica": state["eletrica_waves"] = [{"pos": origin, "dir": (target - origin).normalized(), "age": 0.0, "life": 0.7, "max": 0.7, "phase": 0.2}]
		"lacerante": state["slashes"] = [{"center": origin, "radius": 128.0, "life": 0.7, "max": 0.7, "rotations": 3.0, "color": Color.RED, "width": 86.0, "kind": "lacerante_spin"}]
		"prismatica": state["prisms"] = [{"pos": target, "life": 1.2, "max_life": 1.2, "radius": 42.0}]
		"retornante": state["return_bullets"] = [{"pos": target, "origin": origin, "dir": (target - origin).normalized(), "life": 1.2, "kind": "retornante"}]
		"parasitica": state["parasite_spit_zones"] = [{"state": "flying", "origin": origin, "target": target, "age": 0.1, "travel": 0.6, "life": 1.2, "max": 1.2, "phase": 0.3}]
		"gravitante": state["gravitante_vfx_events"] = [{"kind": "gravity_q", "pos": target, "points": [origin, origin.lerp(target, 0.5)], "life": 0.55, "max": 0.55}]
		"ancorada": state["anchors"] = [{"pos": target, "link_from": origin, "source": "ancorada_hab1", "life": 1.2, "max": 1.2}]
		"cartografica":
			state["cartographic_route_timer"] = 1.0
			state["cartographic_trace_flash"] = 0.2
			state["cartographic_complete_map_timer"] = 1.0
			state["cartographic_coords"] = [{"pos": origin, "life": 1.2, "max": 1.2, "slot": 0}, {"pos": target, "life": 1.2, "max": 1.2, "slot": 1}]
		"mnesica": state["shockwaves"] = [{"pos": target, "radius": 72.0, "life": 0.7, "max": 0.7, "visual_only": true}]
		"ressonante": state["shockwaves"] = [{"pos": origin, "radius": 180.0, "life": 0.9, "max_life": 1.2, "kind": "sinfonia_silencio"}]
		"contratual": state["contractual_notifications"] = [{"pos": target, "life": 1.2, "max": 1.2, "phase": 0.4}]
		"acorrentada": state["acorrentada_links"] = [{"kind": "anchor", "target": {}, "anchor": target, "life": 1.2, "max": 1.2, "hit_cd": {}}]
		"eclipsada": state["eclipsada_vfx"] = [{"kind": "q_dash", "origin": origin, "target": target, "dir": (target - origin).normalized(), "life": 0.7, "max": 0.7, "color": Color(0.58, 0.42, 1.0)}]
		"bombastica": state["bombastica_bombs"] = [{"id": 1, "kind": "q_bomb", "pos": target, "target": target, "state": "armed", "age": 0.0, "travel": 0.3, "fuse": 1.2, "fuse_total": 1.2, "radius": 110.0, "phase": 0.2, "exploded": false}]
		"necronada":
			state["necronada_vfx"] = [{"kind": "rose_summon_ring", "pos": target, "radius": 96.0, "life": 0.7, "max": 0.7}]
			state["necronada_vestiges"] = []
			state["necronada_remnants"] = []
			state["necronada_requiem"] = {}
	return state


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host_game = load("res://scenes/Main.tscn").instantiate()
	var client_game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host_game)
	root.add_child(client_game)
	host_game.is_multiplayer = true
	host_game.online_room_owner = true
	client_game.is_multiplayer = true
	client_game.online_room_owner = false

	host_game.enemies = [{
		"uid": 7001,
		"type": host_game.ENEMY_COMMON,
		"pos": Vector2(100, 200),
		"hp": 100.0,
		"max_hp": 100.0,
		"phase": 0.0,
		"eletrica_static_stacks": 2,
		"eletrica_static_timer": 2.4,
		"eletrica_static_last_source": "skill_e",
		"last_move_dir": Vector2.RIGHT
	}]
	host_game.enemy_bullets = [{
		"pos": Vector2(160, 240),
		"dir": Vector2.RIGHT,
		"life": 4.0,
		"damage": 20.0,
		"type": "atirador",
		"radius": 24.0,
		"phase": 0.0,
		"speed_mult": 1.0
	}]
	host_game.boss_pos = Vector2(300, 280)
	host_game.current_phase = 2
	host_game.boss_active = true
	host_game.boss_hp = 1000.0
	host_game.boss_hp_max = 1400.0
	host_game.boss_phase = 1.0
	host_game.boss_eletrica_static_stacks = 2
	host_game.boss_eletrica_static_timer = 2.2
	host_game.boss_eletrica_static_last_source = "skill_q"
	host_game.boss_attacks = [{"kind": "bubble", "age": 0.20, "duration": 1.0, "target": Vector2(340, 280)}]
	host_game.boss2_state = host_game.BOSS2_STATE_FLASH_FREEZE
	host_game.boss2_anim_frame = 2
	host_game.boss2_ice_shards = [{"pos": Vector2(310, 280), "vel": Vector2(40, -20), "life": 0.6, "max": 0.8, "size": 8.0, "phase": 0.2}]
	host_game.boss2_snow_zones = [{"pos": Vector2(330, 300), "radius": 120.0, "life": 1.4, "max": 1.8, "phase": 0.4}]
	host_game.boss2_ultimate_timer = 12.0
	host_game.boss2_ultimate_center = Vector2(340, 300)
	host_game.boss3_miasma_variant = 4
	host_game.boss3_miasma_timer = 7.5
	host_game.boss3_miasma_qte_required = 18
	host_game.boss3_miasma_qte_taps = 6
	host_game.boss3_faith_link_timer = 2.0
	host_game.phase4_enemy_hazards = [{"kind": "boss4_pulse", "pos": Vector2(360, 320), "age": 0.10, "life": 1.0, "max": 1.0, "radius": 180.0}]
	host_game.current_music = "Fases1.mp3"
	client_game._apply_remote_world_snapshot(
		host_game._pack_net_enemies(),
		host_game._pack_net_boss(),
		host_game._pack_net_enemy_bullets()
	)
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(Vector2(client_game.enemies[0]["pos"]).is_equal_approx(Vector2(100, 200)), "initial enemy snapshot did not snap into place")
	_check(int(client_game.enemies[0].get("eletrica_static_stacks", 0)) == 2, "electric static stacks were not synchronized to replica")
	_check(is_equal_approx(float(client_game.enemies[0].get("eletrica_static_timer", 0.0)), 2.4), "electric static timer was not synchronized to replica")
	_check(String(client_game.enemies[0].get("eletrica_static_last_source", "")) == "skill_e", "electric static source was not synchronized to replica")
	_check(client_game.current_music == host_game.current_music, "replica did not adopt the authority music track")
	var synced_music: String = client_game.current_music
	client_game._play_phase_music_random(client_game.current_phase)
	_check(client_game.current_music == synced_music, "replica selected a different phase track locally")
	_check(client_game.boss_active, "boss active state was not synchronized to replica")
	_check(client_game.boss_eletrica_static_stacks == 2 and is_equal_approx(client_game.boss_eletrica_static_timer, 2.2), "boss electric static state was not synchronized to replica")
	_check(client_game.current_phase == 2, "boss phase index was not synchronized to replica")
	_check(is_equal_approx(client_game.boss_hp_max, 1400.0), "boss max HP was not synchronized to replica")
	_check(client_game.boss_attacks.size() == 1 and String(client_game.boss_attacks[0].get("kind", "")) == "bubble", "boss attack visuals were not synchronized to replica")
	_check(client_game.boss2_state == host_game.BOSS2_STATE_FLASH_FREEZE and client_game.boss2_anim_frame == 2, "boss2 animation state was not synchronized to replica")
	_check(client_game.boss2_ice_shards.size() == 1 and client_game.boss2_snow_zones.size() == 1, "boss2 ice visuals were not synchronized to replica")
	_check(is_equal_approx(client_game.boss2_ultimate_timer, 12.0) and client_game.boss2_ultimate_center == Vector2(340, 300), "boss2 ultimate visual state was not synchronized")
	host_game.current_phase = 3
	host_game.boss3_facing_dir = 1.0
	host_game.boss3_is_moving = true
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(client_game.boss3_miasma_variant == 4 and client_game.boss3_miasma_qte_required == 18 and client_game.boss3_miasma_qte_taps == 6, "boss3 miasma QTE visuals were not synchronized to replica")
	_check(is_equal_approx(client_game.boss3_faith_link_timer, 2.0), "boss3 faith link visual timer was not synchronized")
	_check(is_equal_approx(client_game.boss3_facing_dir, 1.0), "boss3 facing was not synchronized to replica")
	client_game.current_phase = 3
	client_game.boss_active = true
	client_game.boss_dead = false
	client_game.boss3_miasma_variant = 0
	client_game.boss3_miasma_timer = 0.0
	client_game.boss3_faith_link_timer = 0.0
	client_game.boss3_is_moving = true
	client_game.boss3_hit_animation_timer = 0.0
	Boss3AnimationPresentation.trigger_hit(client_game, 35.0, "network_snapshot")
	_check(client_game.boss3_hit_animation_timer == 0.0, "replica movement damage replaced walk with a static hit pose")
	_check(client_game.boss3_hit_feedback_timer > 0.0, "replica movement damage lost non-blocking feedback")
	host_game.current_phase = 4
	host_game.boss4_attack_pose_timer = 0.42
	host_game.boss4_anim_time = 3.25
	host_game.boss4_prison = {"pos": Vector2(410, 315), "phase": 0.4, "fragments": 3}
	host_game.boss4_clone = {"pos": Vector2(520, 330), "hp": 180.0}
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(client_game.phase4_enemy_hazards.size() == 1, "boss/environment hazards were not synchronized to replica")
	_check(is_equal_approx(client_game.boss4_attack_pose_timer, 0.42) and is_equal_approx(client_game.boss4_anim_time, 3.25), "boss4 sprite animation state was not synchronized")
	_check(not client_game.boss4_prison.is_empty() and not client_game.boss4_clone.is_empty(), "boss4 world mechanics were not synchronized")
	host_game.current_phase = 5
	host_game.boss5_current_action = "SIFAO"
	host_game.boss5_dimension = "necro"
	host_game.boss5_mental_state = "CACANDO"
	host_game.boss5_siphon_timer = 1.75
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(client_game.boss5_current_action == "SIFAO" and client_game.boss5_dimension == "necro", "boss5 action/dimension state was not synchronized")
	_check(client_game.boss5_mental_state == "CACANDO" and is_equal_approx(client_game.boss5_siphon_timer, 1.75), "boss5 visual pose state was not synchronized")
	host_game.current_phase = 6
	host_game.boss6_fossil_echo = {"pos": Vector2(440, 330), "timer": 2.0, "hp": 200.0, "hp_max": 280.0}
	host_game.boss6_necro_erosion_active = true
	host_game.boss6_necro_erosion_radius = 420.0
	host_game.boss6_necro_erosion_timer = 3.0
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(not client_game.boss6_fossil_echo.is_empty() and client_game.boss6_necro_erosion_active, "boss6 auxiliary visuals were not synchronized")
	_check(is_equal_approx(client_game.boss6_necro_erosion_radius, 420.0), "boss6 erosion geometry diverged")
	host_game.current_phase = 7
	host_game.boss7_state = host_game.BOSS7_STATE_DIVE
	host_game.boss7_state_timer = 0.65
	host_game.boss7_target_pos = Vector2(620, 360)
	host_game.boss7_reborn = true
	host_game.boss7_flame_waves = [{"pos": Vector2(400, 320), "radius": 120.0, "max_radius": 260.0, "flames": []}]
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(client_game.boss7_state == host_game.BOSS7_STATE_DIVE and is_equal_approx(client_game.boss7_state_timer, 0.65), "boss7 dive animation state was not synchronized")
	_check(client_game.boss7_reborn and client_game.boss7_flame_waves.size() == 1, "boss7 rebirth/flame visuals were not synchronized")
	host_game.current_phase = 2
	client_game._apply_remote_boss_snapshot(host_game._pack_net_boss(), Time.get_ticks_msec())

	await create_timer(0.06).timeout
	host_game.enemies[0]["pos"] = Vector2(220, 200)
	host_game.enemy_bullets[0]["pos"] = Vector2(310, 240)
	host_game.boss_pos = Vector2(420, 280)
	client_game._apply_remote_world_snapshot(
		host_game._pack_net_enemies(),
		host_game._pack_net_boss(),
		host_game._pack_net_enemy_bullets()
	)
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())

	_check(Vector2(client_game.enemies[0]["pos"]).x < 120.0, "enemy position jumped directly to the newest packet")
	_check(Vector2(client_game.enemy_bullets[0]["pos"]).x < 180.0, "bullet position jumped directly to the newest packet")
	_check(client_game.boss_pos.x < 320.0, "boss position jumped directly to the newest packet")
	client_game._update_network_interpolation(1.0 / 60.0)
	var enemy_after_one_frame := Vector2(client_game.enemies[0]["pos"]).x
	_check(enemy_after_one_frame > 100.0 and enemy_after_one_frame < 220.0, "enemy was not smoothly advanced between snapshots")

	var electric_index: int = -1
	for manifest_index in range(host_game.MANIFESTATIONS.size()):
		if String(host_game.MANIFESTATIONS[manifest_index].get("key", "")) == "eletrica":
			electric_index = manifest_index
			break
	_check(electric_index >= 0, "electric manifestation index was not found")
	host_game.manifestation_key = "gravitante"
	host_game.net_players_by_peer[42] = {"manifestation": electric_index, "pos": Vector2(500, 300), "hp": 100, "hp_max": 100, "dead": false}
	var remote_electric_target: Dictionary = {
		"uid": 7020, "type": host_game.ENEMY_COMMON, "pos": Vector2(260, 200),
		"hp": 1000.0, "max_hp": 1000.0, "phase": 0.0
	}
	host_game.enemies.append(remote_electric_target)
	host_game._damage_enemy(remote_electric_target, 10.0, "eletrica", false, false, Vector2(220, 200), "atk", 42)
	_check(int(remote_electric_target.get("eletrica_static_stacks", 0)) == 1, "remote electric player did not create the first static stack on authority")
	host_game._damage_enemy(remote_electric_target, 10.0, "tesla", false, false, Vector2(220, 200), "skill_e", 42)
	_check(int(remote_electric_target.get("eletrica_static_stacks", 0)) == 2, "remote electric player did not stack a second damage source on authority")

	host_game.current_phase = 6
	client_game.current_phase = 6
	host_game.enemies = [{
		"uid": 7601, "type": host_game.ENEMY_LODARIO, "pos": Vector2(385.4, 310),
		"hp": 500.0, "max_hp": 500.0, "phase": 1.0,
		"facing_dir": Vector2.RIGHT, "last_move_dir": Vector2.RIGHT,
		"lodario_jump_progress": 0.35, "lodario_hop_arc": 24.0,
		"lodario_jump_from": Vector2(360, 310), "lodario_jump_to": Vector2(450, 310),
		"lodario_jump_duration": 0.55, "lodario_lunge_active": true
	}]
	client_game.enemies.clear()
	client_game._apply_remote_enemy_snapshot(host_game._pack_net_enemies(), Time.get_ticks_msec())
	var remote_lodario: Dictionary = client_game.enemies[0]
	_check(float(remote_lodario.get("lodario_jump_progress", 0.0)) > 0.0, "Lodario airborne state was not synchronized")
	_check(float(remote_lodario.get("lodario_hop_arc", 0.0)) > 0.0, "Lodario jump arc was not synchronized")
	_check(bool(remote_lodario.get("lodario_lunge_active", false)), "Lodario lunge pose was not synchronized")
	var lodario_start: Vector2 = Vector2(remote_lodario["pos"])
	await create_timer(0.03).timeout
	client_game._update_network_interpolation(1.0 / 60.0)
	var lodario_after: Vector2 = Vector2(remote_lodario["pos"])
	_check(lodario_after.x > lodario_start.x and lodario_after.x < Vector2(remote_lodario["lodario_jump_to"]).x, "Lodario replica did not advance smoothly along the authoritative jump")
	_check(client_game._enemy_texture(remote_lodario) == client_game._texture_frame("enemy_phase_6_lodario", 1), "Lodario replica did not switch to its airborne sprite")
	host_game.current_phase = 2
	client_game.current_phase = 2

	client_game._accept_remote_player_position(42, Vector2(500, 300))
	await create_timer(0.04).timeout
	client_game._accept_remote_player_position(42, Vector2(560, 300))
	_check(client_game.net_player_render_pos.x < 520.0, "remote player jumped directly to snapshot")
	client_game._update_network_interpolation(1.0 / 60.0)
	_check(client_game.net_player_render_pos.x > 500.0 and client_game.net_player_render_pos.x < 560.0, "remote player interpolation did not advance smoothly")
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 90, 100, false, 1, 2, client_game.NET_ANIM_FIRE, 1, true, 12)
	_check(client_game.net_player_anim_state == client_game.NET_ANIM_FIRE, "remote animation state was not preserved")
	_check(client_game.net_player_frame_idx == 1 and client_game.net_player_flip_h, "remote animation frame/facing was not preserved")
	_check(is_equal_approx(client_game.net_player_hp, 90.0) and is_equal_approx(client_game.net_player_hp_max, 100.0), "remote player health was not preserved for ally HUD")
	_check(is_equal_approx(client_game._remote_player_health_ratio(client_game.net_players_by_peer[42]), 0.9), "ally health bar ratio did not match remote HP")
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 90, 100, false, 0, 2, client_game.NET_ANIM_FIRE, 1, true, 12, false, "MOBILE", "lacerante")
	_check(String(client_game.net_players_by_peer[42].get("manifestation_key", "")) == "lacerante", "stable manifestation key was lost in mobile snapshot")
	_check(client_game._net_player_texture_for_state(client_game.NET_ANIM_FIRE, 1, 0, "lacerante") == Array(client_game.textures.get("player_lacerante_attack_network", []))[1], "mobile replica used the wrong manifestation sprite")
	var visual_snapshot := VisualSyncContract.pack_player_visual(Vector2(-0.6, 0.8), Vector2(0.25, -0.75), client_game.NET_ABILITY_SKILL, 0.12, 1.0, 17, 3)
	_check(visual_snapshot.size() == VisualSyncContract.PLAYER_VISUAL_STRIDE, "player visual snapshot changed its fixed stride")
	client_game._rpc_remote_player_state_light(42, Vector2(565, 298), 90, 100, false, 0, 2, client_game.NET_ANIM_FIRE, 1, true, 12, false, "MOBILE", "lacerante", visual_snapshot)
	var visual_state: Dictionary = client_game.net_players_by_peer[42]
	_check(Vector2(visual_state.get("input_move", Vector2.ZERO)).is_equal_approx(Vector2(-0.6, 0.8)), "remote movement intent was not preserved")
	_check(Vector2(visual_state.get("aim_dir", Vector2.ZERO)).is_equal_approx(Vector2(0.25, -0.75).normalized()), "remote aim direction was not preserved")
	_check(int(visual_state.get("visual_action", -1)) == client_game.NET_ABILITY_SKILL, "remote ability pose was not preserved")
	_check(int(visual_state.get("visual_action_sequence", -1)) == 17 and int(visual_state.get("visual_flags", -1)) == 3, "remote visual sequence/flags were not preserved")
	var invalid_visual_snapshot := visual_snapshot.duplicate()
	invalid_visual_snapshot[0] = 999.0
	_check(not bool(VisualSyncContract.unpack_player_visual(invalid_visual_snapshot).get("valid", false)), "incompatible player visual schema was accepted")
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 0, 100, true, 1, 2, client_game.NET_ANIM_DAMAGE, 0, false, 12)
	_check(is_equal_approx(client_game._remote_player_health_ratio(client_game.net_players_by_peer[42]), 0.0), "dead ally health bar should be empty")
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 90, 100, false, 1, 2, client_game.NET_ANIM_FIRE, 1, true, 12)

	# Isolate projectile fidelity from a capsule event that may start while this
	# long-running integration fixture loads assets in the background.
	client_game.bargain_capsule.clear()
	client_game.arauto.clear()
	client_game.boss_active = false
	client_game.boss_hp = 0.0
	client_game.enemies = [{"uid": 9901, "type": client_game.ENEMY_COMMON, "pos": Vector2(820, 360), "hp": 100.0, "max_hp": 100.0, "phase": 0.0, "bit": 0, "last_move_dir": Vector2.ZERO}]
	client_game.remote_bullets = [{
		"source": 42,
		"uid": "42:1",
		"pos": Vector2(780, 360),
		"dir": Vector2.RIGHT,
		"speed": 200.0,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"kind": "eletrica",
		"pierce": false,
		"hits": {},
		"color": Color.CYAN
	}]
	client_game._update_remote_bullets(0.20)
	_check(client_game.remote_bullets.is_empty(), "non-piercing remote projectile crossed an enemy instead of ending on impact")
	client_game.remote_bullets = [{
		"source": 42,
		"uid": "42:2",
		"pos": Vector2(820, 360),
		"dir": Vector2.RIGHT,
		"speed": 0.0,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"kind": "prismatica",
		"pierce": true,
		"hits": {},
		"color": Color.CYAN
	}]
	client_game._update_remote_bullets(0.01)
	_check(not client_game.remote_bullets.is_empty() and int(client_game.remote_bullets[0].get("enemy_hits_count", 0)) == 1, "piercing remote projectile did not register its impact/ricochet")
	client_game.remote_bullets = [{
		"source": 42, "uid": "42:return", "pos": Vector2(560, 360), "dir": Vector2.RIGHT,
		"speed": 300.0, "life": 6.0, "max_life": 6.0, "age": 0.0, "phase": 0.0,
		"trail_cd": 0.0, "kind": "retornante", "motion_mode": "returning", "state": "ida",
		"pierce": true, "hits": {}, "color": Color.MAGENTA
	}]
	client_game.net_player_render_pos = Vector2(560, 360)
	client_game._update_remote_bullets(0.60)
	_check(not client_game.remote_bullets.is_empty() and String(client_game.remote_bullets[0].get("state", "")) == "volta", "returning projectile did not reproduce ida/volta trajectory")
	_check(not client_game.effects.is_empty(), "remote projectile did not emit its local visual trail")

	client_game.net_player_peer_id = 42
	client_game.net_player_render_pos = Vector2(560, 300)
	client_game._rpc_ability_visual(42, 1, client_game.NET_ABILITY_SKILL, 1, Vector2(560, 300), Vector2(700, 300), 0.8, 0.0, {"seed": 11, "rotations": 3.0}, 4)
	client_game._rpc_ability_visual(42, 2, client_game.NET_ABILITY_SECONDARY, 0, Vector2(560, 300), Vector2(560, 300), 2.0, 0.0, {"seed": 12, "center": Vector2(560, 300)}, 4)
	var patched_state := _canonical_fixture(client_game, "eletrica", client_game.NET_ABILITY_SECONDARY, Vector2(560, 300), Vector2(560, 300))
	patched_state["secondary"]["charge"] = 0.75
	client_game._rpc_ability_visual_patch(42, 2, 0.5, {"canonical_state": patched_state, "manifestation_key": "eletrica"})
	var patched_visual: Dictionary = client_game.net_ability_visuals[-1]
	_check(int(patched_visual.get("canonical_patch_count", 0)) == 1, "canonical ability-state patch was not applied")
	_check(is_equal_approx(float(Dictionary(Dictionary(patched_visual.get("canonical_state", {})).get("secondary", {})).get("charge", 0.0)), 0.75), "canonical ability-state patch lost the real local animation state")
	client_game._rpc_ability_visual(42, 3, client_game.NET_ABILITY_TELEPORT, 2, Vector2(560, 300), Vector2(760, 300), 0.55, 0.0, {"seed": 13}, 4)
	client_game.mode = "game"
	client_game.queue_redraw()
	await process_frame
	await process_frame
	_check(client_game.net_ability_visuals.size() == 3, "Q/E/TP remote visuals failed during rendered frames")
	_check(bool(client_game.net_ability_visuals[1].get("network_replica", false)), "secondary visual did not use a local effect replica")

	var prismatica_index := -1
	for i in range(client_game.MANIFESTATIONS.size()):
		if String(client_game.MANIFESTATIONS[i].get("key", "")) == "prismatica":
			prismatica_index = i
			break
	_check(prismatica_index >= 0, "prismatica manifestation index was not found")
	var prismatica_secondary := {
		"kind": "prismatica", "life": client_game.SECONDARY_PRISMATICA_DURATION,
		"max": client_game.SECONDARY_PRISMATICA_DURATION, "active_time": 0.5,
		"center": Vector2(560, 300), "angle": 0.0, "final_frame": 1,
		"targets": [], "cuts": [], "ghosts": [], "zaps": []
	}
	client_game._rpc_ability_visual(42, 4, client_game.NET_ABILITY_SECONDARY, prismatica_index, Vector2(560, 300), Vector2(560, 300), client_game.SECONDARY_PRISMATICA_DURATION, 0.0, {
		"schema": VisualSyncContract.ABILITY_VISUAL_SCHEMA,
		"manifestation_key": "prismatica",
		"seed": 77,
		"center": Vector2(560, 300),
		"final_frame": 1,
		"canonical_state": {
			"manifestation_key": "prismatica", "evolution_ids": [],
			"source_time": client_game.time_alive, "secondary": prismatica_secondary
		}
	}, 4)
	_check(client_game.net_ability_visuals.size() == 4, "prismatica remote ultimate visual was not created")
	var prismatica_visual: Dictionary = client_game.net_ability_visuals[-1]
	_check(String(prismatica_visual.get("kind", "")) == "prismatica", "prismatica ultimate did not initialize as local replica kind")
	_check(int(prismatica_visual.get("final_frame", -1)) == 1, "prismatica final frame was not preserved from network payload")
	client_game.net_player_render_pos = Vector2(620, 340)
	client_game.net_players_by_peer[42]["render_pos"] = Vector2(620, 340)
	client_game._update_network_ability_replica(prismatica_visual, 1.0 / 60.0)
	_check(Vector2(prismatica_visual.get("center", Vector2.ZERO)).is_equal_approx(Vector2(620, 340)), "prismatica remote ultimate did not follow remote player position")
	var remote_prismatica_secondary := EntitiesPresentation._remote_prismatica_secondary(client_game, 42)
	_check(String(remote_prismatica_secondary.get("kind", "")) == "prismatica", "remote prismatica player lost the canonical dance state")
	_check(client_game._prismatica_ultimate_frame_texture(remote_prismatica_secondary) != null, "remote prismatica player did not resolve a real local dance frame")

	var saved_secondaries: Array = client_game.manifestation_secondaries
	client_game.manifestation_secondaries = [{"kind": "eclipsada_sol", "life": 2.4, "max": 3.0, "center": Vector2(620, 340)}]
	var eclipsada_sol_snapshot := ManifestationVisualSnapshot.capture(client_game, client_game.NET_ABILITY_SECONDARY, "eclipsada")
	_check(String(Dictionary(eclipsada_sol_snapshot.get("secondary", {})).get("kind", "")) == "eclipsada_sol", "eclipsada solar form was omitted from the canonical visual snapshot")
	client_game.manifestation_secondaries = [{"kind": "eclipsada_lua_eclipse", "life": 2.4, "max": 3.0, "center": Vector2(620, 340)}]
	var eclipsada_lua_snapshot := ManifestationVisualSnapshot.capture(client_game, client_game.NET_ABILITY_SECONDARY, "eclipsada")
	_check(String(Dictionary(eclipsada_lua_snapshot.get("secondary", {})).get("kind", "")) == "eclipsada_lua_eclipse", "eclipsada lunar form was omitted from the canonical visual snapshot")
	client_game.manifestation_secondaries = saved_secondaries

	client_game.net_ability_visuals.clear()
	client_game.net_ability_seen.clear()
	var visual_sequence := 100
	var expected_visuals := 0
	var maximum_manifest_event_bytes := 0
	for manifest_index in range(client_game.MANIFESTATIONS.size()):
		var manifest_key := String(client_game.MANIFESTATIONS[manifest_index].get("key", ""))
		for action in [client_game.NET_ABILITY_SKILL, client_game.NET_ABILITY_SECONDARY, client_game.NET_ABILITY_TELEPORT]:
			var event_id := "42:%d" % visual_sequence
			var manifest_payload := {
				"schema": VisualSyncContract.ABILITY_VISUAL_SCHEMA,
				"event_id": event_id,
				"manifestation_key": manifest_key,
				"seed": visual_sequence * 17,
				"aim_dir": Vector2.RIGHT,
				"move_dir": Vector2(0.35, -0.2),
				"center": Vector2(640, 340),
				"visual_kind": manifest_key,
				"canonical_state": _canonical_fixture(client_game, manifest_key, action, Vector2(560, 340), Vector2(730, 340))
			}
			match manifest_key:
				"gravitante": manifest_payload["marked_points"] = [Vector2(610, 270), Vector2(690, 335)]
				"ancorada": manifest_payload["anchor_points"] = [Vector2(580, 380), Vector2(730, 350)]
				"cartografica": manifest_payload["route_points"] = [Vector2(540, 330), Vector2(650, 265), Vector2(760, 350)]
				"necronada":
					manifest_payload["remnant_positions"] = [Vector2(620, 320), Vector2(705, 355)]
					manifest_payload["remnant_types"] = [client_game.ENEMY_COMMON, client_game.ENEMY_STALKER]
			var clean_manifest_payload := VisualSyncContract.sanitize_ability_payload(manifest_payload)
			var manifest_event_bytes := VisualSyncContract.ability_event_bytes([42, visual_sequence, action, manifest_index, Vector2(560, 340), Vector2(730, 340), 1.2, 0.0, clean_manifest_payload, 8])
			maximum_manifest_event_bytes = maxi(maximum_manifest_event_bytes, manifest_event_bytes)
			_check(manifest_event_bytes <= VisualSyncContract.ABILITY_VISUAL_MAX_BYTES, "%s action %d canonical event exceeded packet budget: %d" % [manifest_key, action, manifest_event_bytes])
			client_game._rpc_ability_visual(42, visual_sequence, action, 0, Vector2(560, 340), Vector2(730, 340), 1.2, 0.0, manifest_payload, 8)
			expected_visuals += 1
			_check(client_game.net_ability_visuals.size() == expected_visuals, "%s action %d visual was not accepted" % [manifest_key, action])
			var manifest_visual: Dictionary = client_game.net_ability_visuals[-1]
			_check(String(manifest_visual.get("kind", "")) == manifest_key, "%s action %d used fallback manifestation index" % [manifest_key, action])
			_check(String(manifest_visual.get("event_id", "")) == event_id, "%s action %d lost stable event identity" % [manifest_key, action])
			_check(int(manifest_visual.get("schema", 0)) == VisualSyncContract.ABILITY_VISUAL_SCHEMA, "%s action %d lost canonical schema" % [manifest_key, action])
			_check(manifest_visual.get("canonical_state", null) is Dictionary and not Dictionary(manifest_visual.get("canonical_state", {})).is_empty(), "%s action %d fell back to simplified renderer" % [manifest_key, action])
			client_game.queue_redraw()
			await process_frame
			visual_sequence += 1
	var visuals_before_duplicate: int = client_game.net_ability_visuals.size()
	var duplicate_key: String = String(client_game.MANIFESTATIONS[-1].get("key", ""))
	client_game._rpc_ability_visual(42, visual_sequence - 1, client_game.NET_ABILITY_SKILL, 0, Vector2(560, 340), Vector2(730, 340), 1.2, 0.0, {"schema": VisualSyncContract.ABILITY_VISUAL_SCHEMA, "event_id": "duplicate", "manifestation_key": duplicate_key}, 8)
	_check(client_game.net_ability_visuals.size() == visuals_before_duplicate, "duplicate ability event was rendered twice")
	_check(visuals_before_duplicate == client_game.MANIFESTATIONS.size() * 3, "not all manifestation Q/E/TP visuals were reconstructed")

	# Projectile attacks use the shared remote projectile stream; melee attacks
	# use canonical ability events because their local animation is not a bullet.
	client_game.remote_bullets.clear()
	for manifest_index in range(client_game.MANIFESTATIONS.size()):
		var manifest_key := String(client_game.MANIFESTATIONS[manifest_index].get("key", ""))
		client_game.remote_bullets.append({
			"source": 42, "uid": "attack:%s" % manifest_key,
			"pos": Vector2(520 + manifest_index * 8, 420), "dir": Vector2.RIGHT,
			"speed": 0.0, "life": 1.0, "max_life": 1.0, "age": 0.18,
			"phase": float(manifest_index), "kind": manifest_key,
			"pierce": manifest_key in ["prismatica", "retornante"], "hits": {},
			"color": Color.WHITE
		})
	_check(client_game.remote_bullets.size() == client_game.MANIFESTATIONS.size(), "not all manifestation projectile attacks reached the shared remote renderer")
	for melee_key in ["lacerante", "acorrentada", "eclipsada"]:
		var melee_index := -1
		for index in range(client_game.MANIFESTATIONS.size()):
			if String(client_game.MANIFESTATIONS[index].get("key", "")) == melee_key:
				melee_index = index
				break
		_check(melee_index >= 0, "missing melee manifestation " + melee_key)
		var melee_payload := {
			"schema": VisualSyncContract.ABILITY_VISUAL_SCHEMA,
			"event_id": "42:%d" % visual_sequence,
			"manifestation_key": melee_key,
			"seed": visual_sequence,
			"canonical_state": _canonical_fixture(client_game, melee_key, client_game.NET_ABILITY_ATTACK, Vector2(560, 420), Vector2(760, 420))
		}
		client_game._rpc_ability_visual(42, visual_sequence, client_game.NET_ABILITY_ATTACK, melee_index, Vector2(560, 420), Vector2(760, 420), 0.7, 1.0, melee_payload, 8)
		var melee_visual: Dictionary = client_game.net_ability_visuals[-1]
		_check(int(melee_visual.get("action", -1)) == client_game.NET_ABILITY_ATTACK, melee_key + " attack did not reach the canonical renderer")
		if melee_key == "acorrentada":
			_check(not Array(Dictionary(melee_visual.get("canonical_state", {})).get("acorrentada_worn_chains", [])).is_empty(), "acorrentada attack lost its exact physical-chain snapshot")
		visual_sequence += 1
	client_game.queue_redraw()
	await process_frame

	host_game.current_phase = 2
	var core_payload_bytes := var_to_bytes([
		host_game._pack_net_enemies(),
		host_game._pack_net_boss(),
		host_game._pack_net_enemy_bullets()
	]).size()
	var visual_packet: Dictionary = host_game._pack_net_boss_visuals()
	var visual_payload_bytes := var_to_bytes(visual_packet).size()
	var encoded_visual_payload: PackedByteArray = host_game.RTWorldSnapshotChunkerScript.encode_variant(visual_packet)
	var visual_wire_chunks: Array = host_game.RTWorldSnapshotChunkerScript.split(encoded_visual_payload, host_game.NET_WORLD_CHUNK_PAYLOAD_BYTES)
	_check(core_payload_bytes < 1200, "compact one-entity core snapshot exceeded expected budget")
	for visual_chunk in visual_wire_chunks:
		_check(var_to_bytes([1, 0, visual_wire_chunks.size(), visual_chunk]).size() < 1392, "boss visual wire chunk exceeded ENet MTU budget")
	print("MULTIPLAYER_NETWORK_SMOOTHING_SMOKE_OK core_bytes=%d visual_bytes=%d visual_chunks=%d ability_max_bytes=%d enemy_step=%.2f" % [core_payload_bytes, visual_payload_bytes, visual_wire_chunks.size(), maximum_manifest_event_bytes, enemy_after_one_frame - 100.0])

	for game in [host_game, client_game]:
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		root.remove_child(game)
		game.free()
	for i in range(4):
		await process_frame
	quit(0)
