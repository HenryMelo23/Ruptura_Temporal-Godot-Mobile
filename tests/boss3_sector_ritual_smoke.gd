extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS3_SECTOR_RITUAL_FAIL " + message)
	quit(1)


func _prepare_boss() -> void:
	game._start_game()
	game._advance_to_phase(3)
	game.mode = "game"
	game.current_phase = 3
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8000.0
	game.boss_hp = 8000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(220, 0)
	game.player_hp = game.player_hp_max
	game.boss3_ritual_timer = 0.0
	game.boss3_miasma_timer = 0.0
	game.boss3_miasma_variant = 0
	game.boss_attacks.clear()
	game.enemy_bullets.clear()
	game.phase3_cheeses.clear()


func _set_party_size(size: int) -> void:
	game.is_multiplayer = size > 1
	game.online_connected = size > 1
	game.is_host = size > 1
	game.online_room_owner = size > 1
	game.online_lobby_active_player_count = size
	game.online_lobby_connected_count = size
	game.net_players_by_peer.clear()
	if size >= 2:
		game.net_players_by_peer[2] = {"pos": game.WORLD_SIZE * 0.5 + Vector2(-220, 0), "hp": 900, "hp_max": 900, "alive": true}
	if size >= 3:
		game.net_players_by_peer[3] = {"pos": game.WORLD_SIZE * 0.5 + Vector2(0, 220), "hp": 900, "hp_max": 900, "alive": true}
	game._reset_boss_party_scaling_context(3)


func _lane_pos(attack: Dictionary, lane: int) -> Vector2:
	var lanes: int = int(attack.get("lanes", game.BOSS3_SECTOR_RITUAL_LANES))
	var lane_width: float = TAU / float(lanes)
	var angle: float = -PI + lane_width * (float(lane) + 0.5)
	return Vector2(attack.get("center", game.WORLD_SIZE * 0.5)) + Vector2.from_angle(angle) * 300.0


func _run() -> void:
	await process_frame
	_prepare_boss()
	_set_party_size(1)
	game._start_boss3_sector_ritual()
	_check(game.boss_attacks.size() == 1, "solo ritual was not queued")
	var attack: Dictionary = game.boss_attacks[0]
	_check(String(attack.get("kind", "")) == "boss3_sector_ritual", "wrong attack kind")
	_check(int(attack.get("steps", 0)) == 3, "solo ritual should use 3 sectors")
	_check(float(attack.get("warning", 0.0)) >= 1.0, "ritual warning is too short")
	var safe_lane: int = game._boss3_sector_ritual_safe_lane(attack, 0)
	var danger_lane: int = (safe_lane + 1) % int(attack.get("lanes", 6))
	game.player_pos = _lane_pos(attack, safe_lane)
	_check(not game._boss3_sector_ritual_position_in_danger(game.player_pos, attack, 0), "safe lane is damaging")
	game.player_pos = _lane_pos(attack, danger_lane)
	_check(game._boss3_sector_ritual_position_in_danger(game.player_pos, attack, 0), "danger lane is safe")

	var hp_before: int = game.player_hp
	game._update_boss3_attacks(float(attack.get("warning", game.BOSS3_SECTOR_RITUAL_WARNING)) + 0.05)
	_check(game.player_hp < hp_before, "active ritual did not damage local player")
	var hp_after_first_hit: int = game.player_hp
	game._update_boss3_attacks(0.1)
	_check(game.player_hp == hp_after_first_hit, "ritual hit same player twice in one sector")
	game._clear_boss_runtime_hazards()
	_check(game.boss_attacks.is_empty(), "cleanup did not remove sector ritual")

	_prepare_boss()
	_set_party_size(2)
	game._start_boss3_sector_ritual()
	_check(int(game.boss_attacks[0].get("steps", 0)) == 4, "duo ritual should add one sector")
	_check(game._is_world_authority(), "duo host is not authoritative")
	game._clear_boss_runtime_hazards()

	_prepare_boss()
	_set_party_size(3)
	game._start_boss3_sector_ritual()
	_check(int(game.boss_attacks[0].get("steps", 0)) == 5, "trio ritual should cap at five sectors")
	_check(game.boss3_sector_ritual_cooldown > 0.0, "ritual cooldown was not reset")
	game._clear_boss_runtime_hazards()

	_prepare_boss()
	_set_party_size(1)
	game.boss3_sector_ritual_cooldown = 0.0
	game.boss3_miasma_cooldown = 999.0
	game.boss3_faith_test_cooldown = 999.0
	game.boss3_events = {"cheese85": true, "cheese60": true}
	game.boss_hp = game.boss_hp_max * 0.6
	game._update_boss_phase3(0.01)
	_check(game.boss_attacks.any(func(a): return String(a.get("kind", "")) == "boss3_sector_ritual"), "phase 3 update did not start ritual when off cooldown")
	game._clear_boss_runtime_hazards()

	print("BOSS3_SECTOR_RITUAL_SMOKE_OK steps=3/4/5 warning=%.2fs radius=%d clouds=false" % [game.BOSS3_SECTOR_RITUAL_WARNING, int(game.BOSS3_SECTOR_RITUAL_RADIUS)])
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
