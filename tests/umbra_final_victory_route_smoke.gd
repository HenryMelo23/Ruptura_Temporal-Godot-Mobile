extends SceneTree

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("UMBRA_FINAL_VICTORY_ROUTE_SMOKE_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_umbra_kill(route: Array) -> void:
	game.current_phase = game.DIMENSION_FINAL_PHASE
	game.mode = "game"
	game.is_dead = false
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 100.0
	game.boss_hp = 1.0
	game.boss_pos = Vector2(880, 420)
	game.boss5_siphon_timer = 0.0
	game.dimension_route_queue = route.duplicate()
	game.pending_phase = 6
	game.phase_transition_timer = 2.0
	game.phase_fragment = {
		"pos": Vector2(880, 420),
		"next_phase": 6,
		"life": 0.0,
		"pulse": 0.0
	}


func _run() -> void:
	await process_frame

	game._start_game()
	for route in [[6], [7, 4, 6], [6, 2, 7], [6, 6, 2], []]:
		game.dimension_route_queue = Array(route).duplicate()
		var before: Array = game.dimension_route_queue.duplicate()
		_check(game._next_phase_after_boss(game.DIMENSION_FINAL_PHASE) == 0, "final phase preview read a farming route")
		_check(game._consume_next_phase_after_boss(game.DIMENSION_FINAL_PHASE) == 0, "final phase consumed a farming route")
		_check(game.dimension_route_queue == before, "final phase mutated queue before victory was confirmed")

	game.rng.seed = 4519
	game._begin_initial_phase_tracking(1)
	var first_cycle: Array[int] = [1]
	for queued_phase in game.dimension_route_queue:
		first_cycle.append(int(queued_phase))
	var unique_first_cycle: Dictionary = {}
	for phase_value in first_cycle:
		unique_first_cycle[phase_value] = true
	_check(first_cycle.size() == 4 and unique_first_cycle.size() == 4, "initial route was not four unique maps")
	_check(first_cycle.all(func(value): return int(value) in game.DIMENSION_ROUTE_POOL and int(value) != game.DIMENSION_FINAL_PHASE), "initial route included a reserved map")
	for index in range(3):
		_check(game._consume_next_phase_after_boss(first_cycle[index]) == first_cycle[index + 1], "initial route queue was consumed out of order")
	game.dimension_route_queue.clear()
	game.dimension_route_farm_cycles = 0
	game.dimension_route_last_phase = first_cycle.back()
	var farm_entry: int = int(game._begin_farm_dimension_cycle())
	var farm_cycle: Array[int] = [farm_entry]
	for queued_phase in game.dimension_route_queue:
		farm_cycle.append(int(queued_phase))
	var unique_farm_cycle: Dictionary = {}
	for phase_value in farm_cycle:
		unique_farm_cycle[phase_value] = true
	_check(farm_cycle.size() == 4 and unique_farm_cycle.size() == 4, "farm cycle was not four unique maps")
	_check(farm_cycle.all(func(value): return int(value) in game.DIMENSION_ROUTE_POOL and int(value) != game.DIMENSION_FINAL_PHASE), "farm cycle selected a reserved phase")
	game.dimension_route_queue.clear()
	var repeated_entry: int = int(game._begin_farm_dimension_cycle())
	_check(repeated_entry in game.DIMENSION_ROUTE_POOL and game.dimension_route_queue.size() == 3, "repeated farm cycle did not create four maps")
	game.dimension_route_queue = [4, 6]
	_check(game._consume_next_phase_after_boss(7) == 4, "boss 7 did not consume the farming queue")
	_check(game.dimension_route_queue == [6], "boss 7 consumed more than one route entry")
	game.dimension_route_completed_count = 4
	game.dimension_route_queue.clear()
	_check(game._should_offer_dimension_choice_after_boss(3), "fourth completed map stopped offering route choice")

	game._start_game()
	game.current_phase = 4
	game.mode = "game"
	game.dimension_route_queue = [6, 2, 7]
	for attempt in range(game.RUN_RETRY_MAX_CHARGES):
		game.score = 10000
		game._capture_retry_run_snapshot()
		game.is_dead = true
		game.player_hp = 0.0
		game.mode = "game_over"
		_check(game._use_run_retry(), "retry %d failed" % [attempt + 1])
		_check(game.current_phase == 4, "retry %d changed the current phase" % [attempt + 1])
		_check(game.dimension_route_queue == [6, 2, 7], "retry %d lost the farming queue" % [attempt + 1])
	_check(not game._retry_available(), "a fourth retry was offered")

	_prepare_umbra_kill([6, 2, 7])
	var score_before: int = game.score
	var cores_before: int = game.persistent_spectral_coins
	game._damage_boss(999999.0, "smoke", false, false)
	_check(game.boss_dead and not game.boss_active, "Umbra did not enter the terminal dead state")
	_check(game.run_finalized_result == "Vitoria", "victory report was not finalized")
	_check(game.mode == "specter_upgrade" and game.specter_upgrade_previous_mode == "victory", "victory did not open the Specter upgrade")
	_check(game.pending_phase == 0 and is_zero_approx(game.phase_transition_timer), "stale phase transition survived victory")
	_check(game.phase_fragment.is_empty(), "a stale phase fragment survived victory")
	_check(game.dimension_route_queue.is_empty(), "farming queue was not cleared after confirmed victory")
	_check(game.score > score_before, "boss reward points were not granted")
	_check(game.persistent_spectral_coins > cores_before, "Spectral Core reward was not granted")
	_check(not game._retry_available(), "retry remained available after victory")

	var score_after: int = game.score
	var cores_after: int = game.persistent_spectral_coins
	var cards_after: int = game._deck_total_cards()
	game._damage_boss(999999.0, "late_duplicate", false, false)
	_check(game.score == score_after, "duplicate death callback granted points twice")
	_check(game.persistent_spectral_coins == cores_after, "duplicate death callback granted Spectral Cores twice")
	_check(game._deck_total_cards() == cards_after, "duplicate death callback granted cards twice")
	_check(game.run_finalized_result == "Vitoria" and game.mode == "specter_upgrade", "duplicate death callback left terminal victory")

	game._start_game()
	game.mode = "game"
	game.dimension_route_completed_count = game.DIMENSION_EXTRACTION_INTERVAL
	game._complete_dimension_extraction()
	_check(game.run_extracted, "voluntary extraction was not recorded")
	_check(game.run_finalized_result == "Extracao" and game.mode == "victory", "voluntary extraction no longer finishes through its own route")

	game._start_game()
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	_prepare_umbra_kill([7, 4, 6])
	_check(game._apply_final_phase_victory_from_authority(game.DIMENSION_FINAL_PHASE), "replica rejected the authoritative final event")
	_check(game.run_finalized_result == "Vitoria" and game.mode == "specter_upgrade", "replica did not observe terminal victory")
	_check(game.dimension_route_queue.is_empty() and game.pending_phase == 0 and game.phase_fragment.is_empty(), "replica retained route state after victory")
	_check(not game._apply_final_phase_victory_from_authority(game.DIMENSION_FINAL_PHASE), "replica accepted a duplicate final event")
	_check(not game._apply_final_phase_victory_from_authority(4), "replica accepted a non-final victory event")

	if failed:
		await _finish(1)
		return
	print("UMBRA_FINAL_VICTORY_ROUTE_SMOKE_OK route_cycles=4_unique retries=3 final=true idempotent=true extraction_api=true replica=true")
	await _finish(0)


func _finish(code: int) -> void:
	game.is_multiplayer = false
	game.mode = "menu"
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for _i in range(4):
		await process_frame
	quit(code)
