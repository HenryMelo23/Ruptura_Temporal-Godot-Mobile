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
	game.time_alive = game.phase_started_at + game.ARAUTO_SPAWN_TIME
	game._try_spawn_arauto()
	_check(game.arauto.is_empty(), "Arauto should not spawn exactly at the 8 minute mark")
	game.time_alive = game.phase_started_at + game.ARAUTO_SPAWN_TIME + 0.25
	game._try_spawn_arauto()
	_check(not game.arauto.is_empty(), "Arauto should spawn after 8 minutes of phase 1")

	game.arauto.clear()
	game.arauto_evolution_fragment.clear()
	game.manifest_evolution_fragment_claimed_this_run = false
	game.manifest_evolution_fragment_claim_source = ""
	game._spawn_arauto_evolution_fragment(Vector2(420, 360), game.ARAUTO_VARIANT_AGUILHAO)
	_check(not game.arauto_evolution_fragment.is_empty(), "Aguilhao should drop jewel when no jewel was collected")
	game.arauto_evolution_fragment.clear()
	game._spawn_arauto_evolution_fragment(Vector2(440, 360), game.ARAUTO_VARIANT_CONDUTOR)
	_check(not game.arauto_evolution_fragment.is_empty(), "Arauto should still drop jewel if Aguilhao jewel was not collected")
	game._mark_manifest_evolution_fragment_collected(game.ARAUTO_VARIANT_AGUILHAO)
	game.arauto_evolution_fragment.clear()
	game._spawn_arauto_evolution_fragment(Vector2(460, 360), game.ARAUTO_VARIANT_CONDUTOR)
	_check(game.arauto_evolution_fragment.is_empty(), "Arauto should not drop jewel after Aguilhao jewel was collected")

	game.mode = "game"
	game.pending_phase = 0
	game.player_pos = Vector2(640, 420)
	game._spawn_phase_choice_portals(Vector2(640, 420))
	var choices: Array = Array(game.phase_fragment.get("choices", []))
	_check(choices.size() == 2, "boss 4 should create two phase choice portals")
	_check(choices.any(func(choice): return int(choice.get("next_phase", 0)) == 7 and String(choice.get("kind", "")) == "red"), "red portal should route to phase 7")
	_check(choices.any(func(choice): return int(choice.get("next_phase", 0)) == 5 and String(choice.get("kind", "")) == "umbra"), "green blue portal should route to Umbra phase 5")
	for choice in choices:
		if int(choice.get("next_phase", 0)) == 7:
			game.player_pos = Vector2(choice["pos"])
			break
	game._update_phase_fragment(0.016)
	_check(int(game.pending_phase) == 7 and String(game.mode) == "phase_transition", "red portal did not start transition to phase 7")
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

	if failed:
		await _finish(1)
		return
	print("PHASE_ROUTE_FRAGMENT_PORTALS_OK phase1_after6 arauto_clock unique_jewel boss4_choice_portals")
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
