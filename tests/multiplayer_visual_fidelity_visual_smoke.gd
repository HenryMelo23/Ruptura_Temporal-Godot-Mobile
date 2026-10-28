extends SceneTree

const VisualSyncContract = preload("res://scripts/systems/online/runtime_visual_sync_contract.gd")
const OUT_DIR := "res://.codex"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_VISUAL_FIDELITY_FAIL " + message)
	quit(1)


func _manifest_index(key: String) -> int:
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == key:
			return index
	return -1


func _add_remote_cast(peer_id: int, key: String, origin: Vector2, target: Vector2, payload_extra: Dictionary, action: int = -1, sequence: int = 1, label: String = "") -> void:
	var index := _manifest_index(key)
	_check(index >= 0, "missing manifestation " + key)
	var resolved_action: int = game.NET_ABILITY_SKILL if action < 0 else action
	var visual_snapshot := VisualSyncContract.pack_player_visual(Vector2(0.25, -0.15), (target - origin).normalized(), resolved_action, 0.32, 0.4, sequence, 0)
	game._rpc_remote_player_state_light(peer_id, origin, 100, 100, false, index, 0, game.NET_ANIM_FIRE, 1, false, 18, false, label if label != "" else "QA %d" % peer_id, key, visual_snapshot)
	var payload := {
		"schema": VisualSyncContract.ABILITY_VISUAL_SCHEMA,
		"event_id": "%d:%d" % [peer_id, sequence],
		"manifestation_key": key,
		"seed": peer_id * 137,
		"aim_dir": (target - origin).normalized(),
		"move_dir": Vector2(0.25, -0.15),
		"visual_kind": key,
		"canonical_state": payload_extra.get("canonical_state", {
			"manifestation_key": key,
			"evolution_ids": [],
			"source_time": game.time_alive
		})
	}
	for payload_key in payload_extra.keys():
		if payload_key == "canonical_state":
			continue
		payload[payload_key] = payload_extra[payload_key]
	game._rpc_ability_visual(peer_id, sequence, resolved_action, 0, origin, target, 1.8, 0.0, payload, 18)
	_check(not game.net_ability_visuals.is_empty(), "visual missing for " + key)
	game.net_ability_visuals[-1]["life"] = maxf(0.08, float(game.net_ability_visuals[-1].get("max", 1.8)) - 0.18)


func _canonical_fixture(key: String, action: int, origin: Vector2, target: Vector2) -> Dictionary:
	var state := {"manifestation_key": key, "evolution_ids": [], "source_time": game.time_alive}
	if action == game.NET_ABILITY_ATTACK:
		match key:
			"lacerante": state["slashes"] = [{"a": origin, "b": target, "life": 0.8, "max": 0.8, "color": Color.RED, "width": 42.0, "kind": "lacerante_attack"}]
			"acorrentada":
				state["acorrentada_tension"] = 30.0
				state["acorrentada_visuals"] = []
				state["acorrentada_worn_chains"] = [{"index": 0, "attack_motion": {"stage": 1, "elapsed": 0.18}, "physics": {"a": origin, "b": target, "points": [origin, origin.lerp(target, 0.33) + Vector2(0, -22), origin.lerp(target, 0.66) + Vector2(0, 18), target]}}]
			"eclipsada": state["eclipsada_vfx"] = [{"kind": "q_dash", "origin": origin, "target": target, "dir": (target - origin).normalized(), "life": 0.7, "max": 0.8, "color": Color(0.58, 0.42, 1.0)}]
		return state
	if action == game.NET_ABILITY_SECONDARY:
		var secondary_kind := "eclipsada_sol" if key == "eclipsada" else key
		state["secondary"] = {"kind": secondary_kind, "life": 3.2, "max": 4.0, "active_time": 0.8, "center": origin, "pos": origin, "radius": 145.0, "seed": 91, "phase": 0.4, "angle": 0.7, "targets": [], "cuts": [], "ghosts": [], "zaps": [], "final_frame": 1}
		return state
	if action == game.NET_ABILITY_TELEPORT:
		var teleport_kind := "eclipsada_lua_tp" if key == "eclipsada" else key
		state["tp_effects"] = [{"kind": teleport_kind, "life": 0.65, "max": 0.8, "a": origin, "b": target, "color": Color(0.4, 0.86, 1.0)}]
		if key == "lacerante":
			state["slashes"] = [{"a": origin, "b": target, "life": 0.65, "max": 0.8, "color": Color(1.0, 0.08, 0.18), "width": 42.0, "kind": "lacerante_tp"}]
		return state
	match key:
		"eletrica": state["eletrica_waves"] = [{"pos": target, "dir": (target - origin).normalized(), "age": 0.22, "life": 0.6, "max": 0.8, "phase": 0.2}]
		"lacerante": state["slashes"] = [{"center": origin, "radius": 128.0, "life": 0.6, "max": 0.8, "rotations": 3.0, "color": Color.RED, "width": 86.0, "kind": "lacerante_spin"}]
		"prismatica": state["prisms"] = [{"pos": target, "life": 1.0, "max_life": 1.2, "radius": 42.0}]
		"retornante": state["return_bullets"] = [{"pos": target, "origin": origin, "dir": (target - origin).normalized(), "life": 1.0, "max_life": 1.2, "age": 0.2, "kind": "retornante"}]
		"parasitica": state["parasite_spit_zones"] = [{"state": "flying", "origin": origin, "target": target, "age": 0.22, "travel": 0.6, "life": 1.0, "max": 1.2, "phase": 0.3}]
		"gravitante": state["gravitante_vfx_events"] = [{"kind": "gravity_q", "pos": target, "points": [origin, origin.lerp(target, 0.5)], "life": 0.45, "max": 0.55}]
		"ancorada": state["anchors"] = [{"pos": target, "link_from": origin, "source": "ancorada_hab1", "life": 1.0, "max": 1.2}]
		"cartografica":
			state["cartographic_route_timer"] = 1.0
			state["cartographic_trace_flash"] = 0.2
			state["cartographic_complete_map_timer"] = 1.0
			state["cartographic_coords"] = [{"pos": origin, "life": 1.0, "max": 1.2, "slot": 0}, {"pos": target, "life": 1.0, "max": 1.2, "slot": 1}]
		"mnesica": state["shockwaves"] = [{"pos": target, "radius": 72.0, "life": 0.6, "max": 0.8, "visual_only": true}]
		"ressonante": state["shockwaves"] = [{"pos": origin, "radius": 180.0, "life": 0.8, "max_life": 1.2, "kind": "sinfonia_silencio"}]
		"contratual": state["contractual_notifications"] = [{"pos": target, "life": 1.0, "max": 1.2, "phase": 0.4}]
		"acorrentada": state["acorrentada_links"] = [{"kind": "anchor", "target": {}, "anchor": target, "life": 1.0, "max": 1.2, "hit_cd": {}}]
		"eclipsada": state["eclipsada_vfx"] = [{"kind": "q_dash", "origin": origin, "target": target, "dir": (target - origin).normalized(), "life": 0.6, "max": 0.8, "color": Color(0.58, 0.42, 1.0)}]
		"bombastica": state["bombastica_bombs"] = [{"id": 1, "kind": "q_bomb", "pos": target, "target": target, "state": "armed", "age": 0.2, "travel": 0.3, "fuse": 1.0, "fuse_total": 1.2, "radius": 110.0, "phase": 0.2, "exploded": false}]
		"necronada":
			state["necronada_vfx"] = [{"kind": "rose_summon_ring", "pos": target, "radius": 96.0, "life": 0.6, "max": 0.8}]
			state["necronada_vestiges"] = []
			state["necronada_remnants"] = []
			state["necronada_requiem"] = {}
	return state


func _prepare_manifestation_gallery(key: String, manifest_index: int) -> void:
	game.net_ability_visuals.clear()
	game.net_ability_seen.clear()
	game.net_players_by_peer.clear()
	game.remote_bullets.clear()
	var actions := [
		[game.NET_ABILITY_SKILL, Vector2(250, 230), Vector2(430, 230), "Q"],
		[game.NET_ABILITY_SECONDARY, Vector2(910, 230), Vector2(910, 230), "E"],
		[game.NET_ABILITY_TELEPORT, Vector2(250, 565), Vector2(470, 565), "TP"]
	]
	for action_index in range(actions.size()):
		var entry: Array = actions[action_index]
		var action: int = int(entry[0])
		var origin: Vector2 = entry[1]
		var target: Vector2 = entry[2]
		_add_remote_cast(100 + action_index, key, origin, target, {"canonical_state": _canonical_fixture(key, action, origin, target)}, action, action_index + 1, "%s %s" % [key.to_upper(), String(entry[3])])
	var attack_origin := Vector2(920, 565)
	var attack_target := Vector2(1120, 565)
	if key in ["lacerante", "acorrentada", "eclipsada"]:
		_add_remote_cast(103, key, attack_origin, attack_target, {"canonical_state": _canonical_fixture(key, game.NET_ABILITY_ATTACK, attack_origin, attack_target)}, game.NET_ABILITY_ATTACK, 4, "%s ATK" % key.to_upper())
	else:
		var player_visual := VisualSyncContract.pack_player_visual(Vector2.ZERO, Vector2.RIGHT, game.NET_ABILITY_ATTACK, 0.22, 0.4, 4, 0)
		game._rpc_remote_player_state_light(103, attack_origin, 100, 100, false, manifest_index, 0, game.NET_ANIM_FIRE, 2, false, 18, false, "%s ATK" % key.to_upper(), key, player_visual)
		game.remote_bullets.append({"source": 103, "uid": "gallery:%s" % key, "pos": attack_target, "dir": Vector2.RIGHT, "speed": 0.0, "life": 1.0, "max_life": 1.0, "age": 0.25, "phase": float(manifest_index), "kind": key, "pierce": key in ["prismatica", "retornante"], "hits": {}, "color": Color.WHITE})


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.is_multiplayer = true
	game.online_connected = true
	game.qa_streaming_enabled = false
	game.gfx_screen_shake = false
	game.time_alive = 42.0
	game.player_pos = Vector2(800, 450)
	game.enemies.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.net_ability_visuals.clear()
	game.net_players_by_peer.clear()
	game.set_process(false)
	game.set_physics_process(false)
	game.preview_capture_mode = true

	_add_remote_cast(42, "gravitante", Vector2(520, 320), Vector2(650, 275), {
		"canonical_state": {
			"manifestation_key": "gravitante",
			"evolution_ids": ["gravitante_ev2_shared_singularity"],
			"source_time": 42.0,
			"gravitante_vfx_events": [{"kind": "gravity_q", "pos": Vector2(650, 275), "points": [Vector2(590, 220), Vector2(700, 300)], "life": 0.55, "max": 0.55}]
		}
	})
	_add_remote_cast(43, "cartografica", Vector2(920, 300), Vector2(1040, 355), {
		"canonical_state": {
			"manifestation_key": "cartografica",
			"evolution_ids": [],
			"source_time": 42.0,
			"cartographic_route_timer": 3.0,
			"cartographic_trace_flash": 0.2,
			"cartographic_complete_map_timer": 2.0,
			"cartographic_coords": [
				{"pos": Vector2(880, 350), "life": 4.0, "max": 4.0, "phase": 0.2, "slot": 0},
				{"pos": Vector2(990, 225), "life": 4.0, "max": 4.0, "phase": 1.3, "slot": 1},
				{"pos": Vector2(1110, 360), "life": 4.0, "max": 4.0, "phase": 2.4, "slot": 2}
			]
		}
	})
	_add_remote_cast(44, "contratual", Vector2(540, 610), Vector2(700, 570), {
		"canonical_state": {
			"manifestation_key": "contratual",
			"evolution_ids": [],
			"source_time": 42.0,
			"contractual_notifications": [{"pos": Vector2(540, 610), "life": 3.0, "max": 3.0, "phase": 0.7}],
			"enemy_markers": [{"uid": 4401, "pos": Vector2(700, 570), "hp": 100.0, "contract_clause": "agressao", "contract_infractions": 2, "contract_flash": 0.4}]
		}
	})
	_add_remote_cast(45, "necronada", Vector2(985, 590), Vector2(1080, 540), {
		"canonical_state": {
			"manifestation_key": "necronada",
			"evolution_ids": [],
			"source_time": 42.0,
			"necronada_vestiges": [],
			"necronada_remnants": [
				{"id": 1, "enemy_type": game.ENEMY_COMMON, "profile": {"color": Color(0.48, 0.82, 1.0)}, "pos": Vector2(1040, 520), "target_pos": Vector2(1080, 540), "hp": 80.0, "max_hp": 80.0, "summon": 0.0, "phase": 0.2, "facing_dir": Vector2.LEFT},
				{"id": 2, "enemy_type": game.ENEMY_STALKER, "profile": {"color": Color(0.64, 0.44, 1.0)}, "pos": Vector2(1110, 605), "target_pos": Vector2(1080, 540), "hp": 80.0, "max_hp": 80.0, "summon": 0.0, "phase": 1.4, "facing_dir": Vector2.LEFT}
			],
			"necronada_vfx": [{"kind": "rose_summon_ring", "pos": Vector2(1080, 540), "radius": 100.0, "life": 0.7, "max": 0.7}],
			"necronada_requiem": {}
		}
	})
	var henry_visual_snapshot := VisualSyncContract.pack_player_visual(Vector2(0.5, 0.0), Vector2.RIGHT, -1, 0.0, 0.5, 5, 0)
	game._rpc_remote_player_state_light(46, Vector2(360, 520), 125, 125, false, 0, 100, game.NET_ANIM_IDLE, 0, false, 18, false, "HENRY REMOTO", "barometrico", henry_visual_snapshot)
	_check(int(Dictionary(game.net_players_by_peer.get(46, {})).get("manifestation", -1)) == game.HENRY_SELECTION_INDEX, "Henry remote identity was not canonicalized")
	_check(game.net_players_by_peer.size() == 5, "remote players missing from presentation")
	_check(game.net_ability_visuals.size() == 4, "remote casts missing from presentation")

	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_check(await _capture("multiplayer_visual_fidelity_1280x720.png", Vector2i(1280, 720)), "desktop capture failed")
	game.gfx_low_resource = true
	_check(await _capture("multiplayer_visual_fidelity_low_960x540.png", Vector2i(960, 540)), "low-resource capture failed")
	game.gfx_low_resource = false
	var gallery_count := 0
	for manifest_index in range(game.MANIFESTATIONS.size()):
		var key := String(game.MANIFESTATIONS[manifest_index].get("key", ""))
		_prepare_manifestation_gallery(key, manifest_index)
		_check(game.net_players_by_peer.size() == 4, key + " gallery is missing a remote actor")
		_check(game.net_ability_visuals.size() == (4 if key in ["lacerante", "acorrentada", "eclipsada"] else 3), key + " gallery is missing a canonical action")
		_check(await _capture("multiplayer_manifestation_%02d_%s.png" % [manifest_index + 1, key], Vector2i(1280, 720)), key + " gallery capture failed")
		game.gfx_low_resource = true
		_check(await _capture("multiplayer_manifestation_low_%02d_%s.png" % [manifest_index + 1, key], Vector2i(960, 540)), key + " low-resource gallery capture failed")
		game.gfx_low_resource = false
		gallery_count += 1
	print("MULTIPLAYER_VISUAL_FIDELITY_VISUAL_OK peers=5 henry=aspect_preserved abilities=4 desktop=1280x720 low=960x540 manifestations=%d actions_per_manifestation=4 modes=2" % gallery_count)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	var test_audio_bus := AudioServer.get_bus_index(&"Boss1TimeStopMusic")
	if test_audio_bus >= 0:
		AudioServer.remove_bus(test_audio_bus)
	for _frame in range(6):
		await process_frame
	quit(0)


func _capture(file_name: String, capture_size: Vector2i) -> bool:
	root.mode = Window.MODE_WINDOWED
	root.borderless = true
	root.min_size = Vector2i.ZERO
	root.content_scale_size = capture_size
	root.size = capture_size
	for _frame in range(4):
		await process_frame
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != capture_size:
		return false
	return image.save_png(OUT_DIR.path_join(file_name)) == OK
