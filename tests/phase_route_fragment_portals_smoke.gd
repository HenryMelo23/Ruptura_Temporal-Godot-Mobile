extends SceneTree

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE_ROUTE_FRAGMENT_PORTALS_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game._start_game()
	game.run_initial_phase = 6
	game.run_phase6_completed = true
	game.current_phase = 1
	game.phase_started_at = game.PHASE1_REVIVATOR_UNLOCK_TIME + 120.0
	game.time_alive = game.phase_started_at
	game.enemies.clear()
	game.arauto.clear()
	game.arauto_spawned = false
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.next_larapio_spawn_time = game.time_alive + game._larapio_spawn_delay()
	_check(is_equal_approx(float(game.next_larapio_spawn_time - game.time_alive), float(game.PHASE1_SECONDARY_LARAPIO_SPAWN_TIME)), "secondary phase 1 Larapio delay mismatch")
	game.time_alive = game.phase_started_at + 30.0
	for i in range(24):
		_check(game._choose_enemy_type() != game.ENEMY_COUT_ATTACK_SPEED, "phase 1 after phase 6 should use local phase time, not global run time")
	var arauto_spawn_time: float = game._arauto_spawn_time()
	game.time_alive = game.phase_started_at + arauto_spawn_time
	game._try_spawn_arauto()
	_check(game.arauto.is_empty(), "Arauto should not spawn exactly at the active pacing threshold")
	game.time_alive = game.phase_started_at + arauto_spawn_time + 0.25
	game._try_spawn_arauto()
	_check(not game.arauto.is_empty(), "Arauto should spawn after the active phase 1 pacing threshold")

	game.arauto.clear()
	game.arauto_evolution_fragment.clear()
	game.manifest_evolution_fragment_claimed_this_run = false
	game.manifest_evolution_fragment_claim_count = 0
	game.manifest_evolution_fragment_claim_source = ""
	game._spawn_arauto_evolution_fragment(Vector2(420, 360), game.ARAUTO_VARIANT_AGUILHAO)
	_check(not game.arauto_evolution_fragment.is_empty(), "Aguilhao should drop jewel when no jewel was collected")
	game.arauto_evolution_fragment.clear()
	game._spawn_arauto_evolution_fragment(Vector2(440, 360), game.ARAUTO_VARIANT_CONDUTOR)
	_check(not game.arauto_evolution_fragment.is_empty(), "Arauto should still drop jewel if Aguilhao jewel was not collected")
	game._mark_manifest_evolution_fragment_collected(game.ARAUTO_VARIANT_AGUILHAO)
	game.arauto_evolution_fragment.clear()
	game._spawn_arauto_evolution_fragment(Vector2(460, 360), game.ARAUTO_VARIANT_CONDUTOR)
	_check(not game.arauto_evolution_fragment.is_empty(), "Arauto should provide the second evolution jewel")
	game._mark_manifest_evolution_fragment_collected(game.ARAUTO_VARIANT_CONDUTOR)
	game.arauto_evolution_fragment.clear()
	game._spawn_arauto_evolution_fragment(Vector2(480, 360), game.ARAUTO_VARIANT_CONDUTOR)
	_check(game.arauto_evolution_fragment.is_empty(), "Arauto should stop dropping jewels after both evolution choices")

	game.mode = "game"
	game.pending_phase = 0
	game.dimension_route_queue.clear()
	game.dimension_route_farm_cycles = 0
	game.dimension_route_completed_count = 3
	game._start_phase_transition(game.DIMENSION_FINAL_PHASE)
	_check(game.pending_phase == 0 and game.mode == "game", "Umbra was reachable before four completed maps")
	game.dimension_route_completed_count = 4
	game.current_phase = 4
	game.player_pos = Vector2(640, 420)
	game._spawn_phase_choice_portals(Vector2(640, 420))
	var choices: Array = Array(game.phase_fragment.get("choices", []))
	_check(choices.size() == 2, "fourth boss should create exactly two phase choice portals")
	_check(choices.any(func(choice): return String(choice.get("action", "")) == "farm" and String(choice.get("kind", "")) == "farm"), "red farm portal should start the farm route")
	_check(choices.any(func(choice): return int(choice.get("next_phase", 0)) == 5 and String(choice.get("kind", "")) == "umbra"), "green blue portal should route to Umbra phase 5")
	for choice in choices:
		if String(choice.get("action", "")) == "farm":
			game.player_pos = Vector2(choice["pos"])
			break
	game._update_phase_fragment(0.016)
	_check(int(game.pending_phase) in game.DIMENSION_ROUTE_POOL and int(game.pending_phase) != 5 and String(game.mode) == "phase_transition", "farm portal did not start a valid random map")
	_check(int(game.dimension_route_farm_cycles) == 1, "first farm portal should register one farm cycle")
	_check(Array(game.dimension_route_queue).size() == 3, "farm cycle should queue the remaining three maps")
	var farm_cycle: Dictionary = {int(game.pending_phase): true}
	for queued_value in game.dimension_route_queue:
		var queued_phase := int(queued_value)
		_check(queued_phase in game.DIMENSION_ROUTE_POOL and queued_phase != 5, "farm cycle selected a reserved phase")
		farm_cycle[queued_phase] = true
	_check(farm_cycle.size() == 4, "farm cycle repeated a map before its fourth boss")
	game.pending_phase = 0
	game.mode = "game"
	game._spawn_phase_choice_portals(Vector2(640, 420))
	choices = Array(game.phase_fragment.get("choices", []))
	for choice in choices:
		if int(choice.get("next_phase", 0)) == 5:
			game.player_pos = Vector2(choice["pos"])
			break
	game._update_phase_fragment(0.016)
	_check(int(game.pending_phase) == 5 and String(game.mode) == "phase_transition", "green blue portal did not start transition to phase 5")

	game.pending_phase = 0
	game.mode = "game"
	game.current_phase = 3
	game.dimension_route_queue.clear()
	game.dimension_route_farm_cycles = 1
	game.dimension_route_completed_count = 10
	game.player_pos = Vector2(640, 420)
	game._spawn_phase_choice_portals(Vector2(640, 420))
	choices = Array(game.phase_fragment.get("choices", []))
	_check(choices.size() == 2, "route should keep exactly farm and Umbra even after many cycles")
	_check(not choices.any(func(choice): return String(choice.get("action", "")) == "extract"), "legacy extraction portal returned to the two-choice contract")
	var base_hp := float(game.ENEMY_BASE_HP)
	var base_speed := float(game.ENEMY_BASE_SPEED)
	game.enemy_base_hp = base_hp
	game.enemy_speed_base = base_speed
	game.dimension_route_farm_cycles = 0
	game._advance_to_phase(1)
	var first_cycle_hp := float(game.enemy_base_hp)
	var first_cycle_speed := float(game.enemy_speed_base)
	game.enemy_base_hp = base_hp
	game.enemy_speed_base = base_speed
	game.dimension_route_farm_cycles = 1
	game._advance_to_phase(1)
	_check(float(game.enemy_base_hp) > first_cycle_hp and float(game.enemy_speed_base) > first_cycle_speed, "continued cycle did not increase enemy pressure")

	if failed:
		await _finish(1)
		return
	print("PHASE_ROUTE_FRAGMENT_PORTALS_OK route_cycle=4 unique_maps=true choices=farm_umbra extraction=false")
	await _finish(0)


func _finish(code: int) -> void:
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(code)
