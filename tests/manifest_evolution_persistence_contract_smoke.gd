extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_PERSISTENCE_FAIL " + message)
	_cleanup(1)


func _remove_save() -> void:
	if FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.INTERRUPTED_RUN_SAVE_PATH))


func _entry(stage: String, index: int) -> Dictionary:
	return Dictionary(game._manifest_evolution_entries("eletrica", stage)[index])


func _choose_pair() -> void:
	game.manifestation_key = "eletrica"
	game._reset_manifest_evolution_state()
	game.manifest_evolution_options = [_entry("ev1", 3)] # impact_link
	game._choose_manifest_evolution(0)
	game.manifest_evolution_options = [_entry("ev2", 1)] # skill_field
	game._choose_manifest_evolution(0)


func _assert_pair(label: String) -> void:
	var choices: Array = game._manifest_evolution_choices()
	_check(choices.size() == 2, label + " did not retain EV1+EV2")
	_check(String(choices[0].get("evolution", "")) == String(_entry("ev1", 3).get("id", "")), label + " restored wrong EV1")
	_check(String(choices[1].get("evolution", "")) == String(_entry("ev2", 1).get("id", "")), label + " restored wrong EV2")


func _cleanup(code: int) -> void:
	_remove_save()
	if game != null:
		game.mode = "menu"
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _run() -> void:
	_remove_save()
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.online_connected = false
	game.player_pos = Vector2(640, 360)
	_choose_pair()
	game._manifest_evolution_on_skill(game.player_pos + Vector2(40, 0))
	_assert_pair("selection")
	_check(Array(game.manifest_evolution_state.get("fields", [])).size() == 1, "skill field was not active before snapshot")

	game._save_interrupted_run(true)
	_check(FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "autosave did not persist evolution state")
	game._reset_manifest_evolution_state()
	_check(game._manifest_evolution_choices().is_empty(), "reset did not clear choices")
	_check(game._resume_interrupted_run(), "resume did not load saved evolution state")
	_assert_pair("resume")
	_check(Array(game.manifest_evolution_state.get("fields", [])).size() == 1, "resume lost active evolution field")
	_check(game.manifest_evolution_combat_event_seen.is_empty(), "resume restored transient event ledger")

	game._capture_retry_run_snapshot()
	game._reset_manifest_evolution_state()
	game.is_dead = true
	game.player_hp = 0.0
	game.mode = "game_over"
	_check(game._use_run_retry(), "retry did not restore a saved run")
	_assert_pair("retry")

	_remove_save()
	game.is_multiplayer = true
	game.mode = "game"
	game._save_interrupted_run(true)
	_check(not FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "multiplayer run persisted evolution state")
	print("MANIFEST_EVOLUTION_PERSISTENCE_OK selection=true resume=true retry=true multiplayer_block=true")
	_cleanup(0)
