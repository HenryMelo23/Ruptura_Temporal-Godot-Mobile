extends SceneTree

var scene: Node
var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	scene = load("res://debug/Phase5ApoloExhibition.tscn").instantiate()
	root.add_child(scene)
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("PHASE5_APOLO_EXHIBITION_FAIL " + message)
	_cleanup()
	quit(1)


func _assert_ok(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _run() -> void:
	await process_frame
	await process_frame
	game = scene.get("game")
	if game == null:
		game = scene.get_node_or_null("Phase5Main")
	_assert_ok(game != null, "main game was not created")
	_assert_ok(game.current_phase == 5, "expected phase 5")
	_assert_ok(game.boss_active and not game.boss_dead, "Umbra should be active")
	_assert_ok(game.apolo_phase5_exhibition_enabled, "Apolo control should be enabled")
	_assert_ok(game.enemies.is_empty(), "exhibition should be a clean Apolo vs Umbra fight")
	_assert_ok(not game.apolo_phase5_exhibition_arch.is_empty(), "Apolo architecture json was not loaded")
	_assert_ok(int(game.apolo_phase5_exhibition_arch.get("version", 0)) == 5, "unexpected Apolo architecture version")
	_assert_ok(not game.apolo_phase5_exhibition_card_memory.is_empty(), "Apolo card memory json was not loaded")

	var start_pos: Vector2 = game.player_pos
	var start_boss_hp: float = game.boss_hp
	for _i in range(240):
		game._update_game(1.0 / 60.0)
		await process_frame

	_assert_ok(game.apolo_phase5_exhibition_timer > 1.5, "Apolo thinking timer did not advance")
	_assert_ok(game.player_pos.distance_to(start_pos) > 12.0, "Apolo did not move the player")
	_assert_ok(game.apolo_phase5_exhibition_target != Vector2.ZERO, "Apolo did not choose a safe target")
	_assert_ok(game.apolo_phase5_exhibition_aim.length() > 0.05, "Apolo did not aim")
	_assert_ok(game.bullets.size() > 0 or game.boss_hp < start_boss_hp or game.apolo_phase5_exhibition_damage_done > 0.0, "Apolo did not attack through the player flow")

	game.phase5_hazards.clear()
	game._spawn_umbra_action("LASER_SOBRECARGA")
	var danger_at_player: float = game._apolo_phase5_danger_at(game.player_pos, 0.35)
	var next_target: Vector2 = game._apolo_phase5_find_safe_target()
	var danger_at_target: float = game._apolo_phase5_danger_at(next_target, 0.35)
	_assert_ok(danger_at_target <= danger_at_player or next_target.distance_to(game.player_pos) > 10.0, "Apolo did not react to overload laser space")

	print("PHASE5_APOLO_EXHIBITION_SMOKE_OK phase=5 clean=true apolo_memory=true movement=true aim=true attack=true laser_awareness=true")
	_cleanup()
	quit(0)


func _cleanup() -> void:
	if game != null and game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	if scene != null:
		if scene.get_parent() == root:
			root.remove_child(scene)
		scene.free()
	scene = null
	game = null
