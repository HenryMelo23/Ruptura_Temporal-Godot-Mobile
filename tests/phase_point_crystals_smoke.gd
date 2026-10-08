extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _crystals() -> Array:
	return game._phase_point_crystal_orbs()


func _crystal_value_sum(crystals: Array) -> int:
	var total := 0
	for crystal in crystals:
		total += int(crystal.get("score_value", 0))
	return total


func _assert_crystal_set(phase: int, card_cost: int) -> void:
	game.card_cost = card_cost
	game._spawn_phase_point_crystals_for_phase(phase)
	var crystals: Array = _crystals()
	_check(crystals.size() >= game.PHASE_POINT_CRYSTAL_MIN_COUNT, "phase %d spawned too few crystals" % phase)
	_check(crystals.size() <= game.PHASE_POINT_CRYSTAL_MAX_COUNT, "phase %d spawned too many crystals" % phase)
	var total: int = _crystal_value_sum(crystals)
	_check(total >= int(round(float(card_cost) * 0.20)), "phase %d reward below target: %d" % [phase, total])
	_check(total <= int(round(float(card_cost) * 0.30)), "phase %d reward above target: %d" % [phase, total])
	for crystal in crystals:
		var pos: Vector2 = Vector2(crystal.get("pos", Vector2.ZERO))
		_check(pos.x >= game.PHASE_POINT_CRYSTAL_MARGIN.x and pos.y >= game.PHASE_POINT_CRYSTAL_MARGIN.y, "phase %d crystal below playable margin" % phase)
		_check(pos.x <= game.WORLD_SIZE.x - game.PHASE_POINT_CRYSTAL_MARGIN.x and pos.y <= game.WORLD_SIZE.y - game.PHASE_POINT_CRYSTAL_MARGIN.y, "phase %d crystal above playable margin" % phase)
		_check(String(crystal.get("kind", "")) == game.PHASE_POINT_CRYSTAL_KIND, "phase %d crystal kind drifted" % phase)


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	_check(_crystals().size() >= game.PHASE_POINT_CRYSTAL_MIN_COUNT, "initial playable phase did not spawn crystals")
	game._cleanup_phase_point_crystals()

	for phase in range(1, 8):
		_assert_crystal_set(phase, 500)
		game._cleanup_phase_point_crystals()

	game.card_cost = 1000
	game._spawn_phase_point_crystals_for_phase(2)
	_check(_crystal_value_sum(_crystals()) == 250, "card-cost reference reward should track 25 percent")

	var before_count: int = _crystals().size()
	game.player_pos = Vector2(12.0, 12.0)
	game.mode = "game"
	game._update_heal_orbs(0.016)
	_check(_crystals().size() == before_count, "ignored crystals should not self-collect or stall")

	var first: Dictionary = _crystals()[0].duplicate(true)
	var value: int = int(first.get("score_value", 0))
	game.score = 0
	game.score_total = 0
	game.run_points_earned = 0
	game.player_pos = Vector2(first.get("pos", game.player_pos))
	game._update_heal_orbs(0.016)
	_check(game.score == value and game.run_points_earned == value, "solo crystal collection did not credit exactly once")
	game._apply_gameplay_orb_collect_local(first)
	_check(game.score == value and game.run_points_earned == value, "duplicate crystal collection credited twice")

	game._spawn_gameplay_orb("heal", game.PLAYER_START, {"fraction": 0.1}, 0, 12.0)
	game._spawn_phase_point_crystals_for_phase(3)
	game._cleanup_phase_point_crystals()
	_check(_crystals().is_empty(), "phase crystal cleanup left crystals behind")
	_check(not game.heal_orbs.filter(func(orb): return String(orb.get("kind", "heal")) == "heal").is_empty(), "phase crystal cleanup removed unrelated heal orb")
	game.heal_orbs.clear()

	game._spawn_phase_point_crystals_for_phase(4)
	game._start_phase_transition(5)
	_check(_crystals().is_empty(), "phase transition did not clean crystals")

	game.mode = "game"
	game.current_phase = 2
	game.boss_ready = true
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game._spawn_phase_point_crystals_for_phase(2)
	game._start_boss_call_local()
	_check(_crystals().is_empty(), "boss entry did not clean crystals")

	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.player_pos = Vector2(12.0, 12.0)
	game._spawn_phase_point_crystals_for_phase(6)
	var remote_crystal: Dictionary = _crystals()[0]
	game.net_players_by_peer[2] = {
		"has_snapshot": true,
		"alive": true,
		"dead": false,
		"eliminated": false,
		"hp": 100.0,
		"pos": Vector2(remote_crystal.get("pos", Vector2.ZERO))
	}
	_check(game._gameplay_orb_collecting_peer(remote_crystal) == 2, "host authority did not resolve remote crystal collector")
	game._confirm_gameplay_orb_removed(String(remote_crystal.get("uid", "")), "collected", 2, remote_crystal)
	_check(game._gameplay_orb_by_uid(String(remote_crystal.get("uid", ""))).is_empty(), "remote crystal collection did not remove once")

	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PHASE_POINT_CRYSTALS_SMOKE_OK count=4-6 reward=25pct bounds=true cleanup=true multiplayer_authority=true")
	quit(0 if failures.is_empty() else 1)
