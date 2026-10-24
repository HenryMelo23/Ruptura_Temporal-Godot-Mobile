extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("ENEMY_POINT_PICKUP_FAIL " + message)


func _setup_solo() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.online_local_spectator = false
	game.is_dead = false
	game.player_hp = game.player_hp_max
	game.player_pos = Vector2(640.0, 360.0)
	game.score = 0
	game.score_total = 0
	game.run_points_earned = 0
	game.heal_orbs.clear()
	game.net_collected_gameplay_orb_ids.clear()
	game.cards_bought["orbita_coletora"] = 0


func _run_ground_and_chase() -> void:
	_setup_solo()
	var orb: Dictionary = game._spawn_enemy_point_drop(game.player_pos + Vector2(160.0, 0.0), 37)
	var ground_pos: Vector2 = orb["pos"]
	game._update_heal_orbs(0.5)
	_check(Vector2(orb["pos"]).is_equal_approx(ground_pos), "point moved before entering base collection radius")
	_check(game.score == 0, "point awarded score while still on the ground")
	orb["life"] = 0.01
	game._update_heal_orbs(1.0)
	_check(game.heal_orbs.has(orb), "enemy point expired instead of remaining on the ground")
	game.player_pos = ground_pos - Vector2(game.ENEMY_POINT_PICKUP_RADIUS - 4.0, 0.0)
	game._update_heal_orbs(0.05)
	_check(int(orb.get("magnet_peer_id", 0)) == game._mp_unique_id(), "point did not lock onto player inside collection radius")
	var speed_after_activation: float = float(orb.get("magnet_speed", 0.0))
	_check(speed_after_activation >= game.ENEMY_POINT_MAGNET_START_SPEED, "point did not start with magnet velocity")
	_check(game.score == 0, "point awarded before touching the player")
	for step in range(160):
		if game.heal_orbs.is_empty():
			break
		game.player_pos += Vector2(4.5, sin(float(step) * 0.25) * 1.5)
		game._update_heal_orbs(0.05)
	_check(game.heal_orbs.is_empty(), "accelerating point did not catch a moving player")
	_check(game.score == 37, "absorbed point did not award its value exactly once")
	_check(float(orb.get("magnet_speed", 0.0)) > speed_after_activation, "chasing point did not accelerate")


func _run_enemy_kill_creates_drop() -> void:
	_setup_solo()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(180.0, 0.0))
	var enemy: Dictionary = game.enemies.back()
	var expected_value: int = game._points_for_enemy(enemy)
	game._kill_enemy(enemy)
	var point_orbs: Array = game._enemy_point_orbs()
	_check(game.score == 0, "enemy kill still awarded points immediately")
	_check(point_orbs.size() == 1, "enemy kill did not leave one point drop on the ground")
	_check(int(point_orbs[0].get("score_value", 0)) == expected_value, "enemy point drop lost the kill reward value")
	game._spawn_enemy_point_drop(Vector2(point_orbs[0]["pos"]) + Vector2(8.0, 0.0), 7)
	_check(game._enemy_point_orbs().size() == 1, "nearby point drops were not coalesced")
	_check(int(point_orbs[0].get("score_value", 0)) == expected_value + 7, "coalescing nearby drops lost score value")


func _run_orbita_radius() -> void:
	_setup_solo()
	var orb: Dictionary = game._spawn_enemy_point_drop(game.player_pos + Vector2(140.0, 0.0), 11)
	game._update_heal_orbs(0.05)
	_check(int(orb.get("magnet_peer_id", 0)) == 0, "base radius attracted a point from too far away")
	game.cards_bought["orbita_coletora"] = 5
	game._update_heal_orbs(0.05)
	_check(int(orb.get("magnet_peer_id", 0)) == game._mp_unique_id(), "Orbita Coletora did not extend point attraction radius")


func _run_active_cap_merge() -> void:
	_setup_solo()
	for index in range(game.ENEMY_POINT_MAX_ACTIVE + 1):
		game._spawn_enemy_point_drop(Vector2(100.0 + float(index % 16) * 40.0, 100.0 + float(index / 16) * 28.0), 1)
	var point_orbs: Array = game._enemy_point_orbs()
	var total_value: int = 0
	for orb in point_orbs:
		total_value += int(orb.get("score_value", 0))
	_check(point_orbs.size() == game.ENEMY_POINT_MAX_ACTIVE, "active point safety cap was exceeded")
	_check(total_value == game.ENEMY_POINT_MAX_ACTIVE + 1, "cap merge lost point value")


func _run_multiplayer_authority() -> void:
	_setup_solo()
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.player_pos = Vector2(200.0, 200.0)
	game.net_players_by_peer = {42: {
		"pos": Vector2(760.0, 360.0),
		"render_pos": Vector2(760.0, 360.0),
		"hp": 400.0,
		"hp_max": 400.0,
		"alive": true,
		"dead": false,
		"eliminated": false,
		"has_snapshot": true
	}}
	game.net_decks_by_peer = {42: {"counts": {"orbita_coletora": 2}, "cinzas_bonuses": {}}}
	_check(game._neutral_pickup_radius_for_peer(72.0, 42) > 100.0, "remote Orbita Coletora radius was not read from the synced deck")
	var orb: Dictionary = game._spawn_enemy_point_drop(Vector2(760.0, 360.0), 23)
	var uid: String = String(orb.get("uid", ""))
	game._update_heal_orbs(0.016)
	_check(game.score == 23, "authority did not credit a point absorbed by the remote player")
	_check(game.heal_orbs.is_empty(), "authority did not remove remote-collected point")
	var score_after_collect: int = game.score
	game._rpc_request_gameplay_orb_collect(uid, 42)
	_check(game.score == score_after_collect, "duplicate remote request awarded the same point twice")


func _run() -> void:
	await process_frame
	_run_ground_and_chase()
	_run_enemy_kill_creates_drop()
	_run_orbita_radius()
	_run_active_cap_merge()
	_run_multiplayer_authority()
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	if not failed:
		print("ENEMY_POINT_PICKUP_SMOKE_OK ground=true chase=true acceleration=true orbita=true cap=true multiplayer_dedupe=true")
	quit(1 if failed else 0)
