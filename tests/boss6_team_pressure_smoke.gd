extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _target_peers(entries: Array) -> Array[int]:
	var peers: Array[int] = []
	for value in entries:
		var peer_id := int(Dictionary(value).get("target_peer", 0))
		if peer_id > 0 and not peers.has(peer_id):
			peers.append(peer_id)
	peers.sort()
	return peers


func _prepare_three_players() -> void:
	game._start_game()
	game.mode = "game"
	game.current_phase = 6
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 1000.0
	game.boss_hp = 220.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(430.0, 0.0)
	game.player_hp = game.player_hp_max
	game.is_multiplayer = true
	game.is_host = true
	game.net_players_by_peer = {
		2: {"has_snapshot": true, "alive": true, "dead": false, "eliminated": false, "hp": 100.0, "hp_max": 100.0, "pos": game.boss_pos + Vector2(-360.0, 210.0)},
		3: {"has_snapshot": true, "alive": true, "dead": false, "eliminated": false, "hp": 100.0, "hp_max": 100.0, "pos": game.boss_pos + Vector2(-310.0, -240.0)},
		4: {"has_snapshot": true, "alive": false, "dead": true, "eliminated": false, "hp": 0.0, "hp_max": 100.0, "pos": game.boss_pos + Vector2(0.0, 380.0)},
	}
	game.boss_attacks.clear()


func _run() -> void:
	await process_frame
	_prepare_three_players()
	var living_ids: Array[int] = []
	for target in game._combat_targets():
		living_ids.append(int(Dictionary(target).get("peer_id", 0)))
	living_ids.sort()
	_check(living_ids.size() == 3, "fixture did not expose exactly three living targets")
	_check(not living_ids.has(4), "dead player remained targetable")

	game._start_boss6_vertebral_scythes()
	var scythes: Dictionary = game.boss_attacks.back()
	var scythe_peers := _target_peers(Array(scythes.get("bones", [])))
	_check(scythe_peers == living_ids, "vertebral scythes did not split across every living player")
	_check(int(scythes.get("team_target_count", 0)) == 3, "scythe team target metadata is incomplete")
	_check(Array(scythes.get("bones", [])).size() <= 12, "scythe party budget exceeded the readable cap")

	game.boss_attacks.clear()
	game._start_boss6_acid_bloom(false)
	var bloom: Dictionary = game.boss_attacks.back()
	var bloom_peers := _target_peers(Array(bloom.get("spots", [])))
	_check(bloom_peers == living_ids, "acid bloom did not reserve a telegraph for every living player")
	_check(Array(bloom.get("spots", [])).size() <= game.BOSS6_POOL_MAX, "acid bloom exceeded the global pool cap")

	game.boss_attacks.clear()
	game._start_boss6_carnage_tide()
	game._update_boss_attacks(0.01)
	var tide: Dictionary = game.boss_attacks.back()
	var spawned_drops: Array = tide.get("drops", [])
	var tide_peers := _target_peers(spawned_drops)
	_check(tide_peers == living_ids, "carnage tide did not create a drop for every living player")
	_check(spawned_drops.size() == 3, "carnage tide created an unexpected party drop count")
	_check(int(tide.get("team_target_count", 0)) == 3, "carnage tide omitted authoritative team metadata")
	var visual_packet: Dictionary = game.boss_visual_sync_controller.pack(game)
	var replicated_attacks: Array = visual_packet.get("boss_attacks", [])
	_check(not replicated_attacks.is_empty(), "boss visual snapshot omitted carnage tide")
	if not replicated_attacks.is_empty():
		_check(_target_peers(Array(Dictionary(replicated_attacks.back()).get("drops", []))) == living_ids, "visual snapshot lost per-player drop targets")

	game.net_players_by_peer.clear()
	var solo_bones: Array = game.boss6_stage_controller.build_vertebral_scythes(0.8, false)
	_check(solo_bones.size() == 5, "solo scythe budget no longer matches the original opening stage")
	var solo_drops: Array = game.boss6_stage_controller.build_carnage_drop_batch()
	_check(solo_drops.size() == 1, "solo carnage tide should keep one drop per wave")

	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	if not failures.is_empty():
		for failure in failures:
			printerr("BOSS6_TEAM_PRESSURE_FAIL " + failure)
		quit(1)
		return
	print("BOSS6_TEAM_PRESSURE_OK abilities=3 living_targets=3 dead_excluded=true target_cap=3 solo_preserved=true")
	for _frame in range(4):
		await process_frame
	quit(0)
