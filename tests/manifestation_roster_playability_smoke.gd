extends SceneTree

const MANIFESTATION_KEYS: Array[String] = ["eletrica", "lacerante", "prismatica", "parasitica", "gravitante"]
const SIMULATION_SECONDS: float = 30.0
const STEP: float = 1.0 / 60.0

var game: Node

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFESTATION_ROSTER_PLAYABILITY_FAIL " + message)
	_cleanup(1)

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	for key in MANIFESTATION_KEYS:
		var index: int = game._manifestation_index_for_key(key, -1)
		_check(index >= 0 and index < game.MANIFESTATIONS.size(), "missing=" + key)
		game.active_character_key = game.CHARACTER_GEOVANA
		game.selected_manifestation = index
		game.unlocked_manifestation_ids[key] = true
		game._start_game(false)
		_check(game.manifestation_key == key, "start_key=%s got=%s" % [key, game.manifestation_key])
		game.player_hp_max = 1000000.0
		game.player_hp = game.player_hp_max
		var steps: int = int(SIMULATION_SECONDS / STEP)
		for step_index in range(steps):
			game._update_game(STEP)
			if step_index % 120 == 0:
				await process_frame
		_check(game.time_alive >= SIMULATION_SECONDS - 0.1, "duration=%s time=%.2f" % [key, game.time_alive])
		print("MANIFESTATION_PLAYABILITY_30S_OK key=%s time=%.2f enemies=%d" % [key, game.time_alive, game.enemies.size()])

	print("MANIFESTATION_ROSTER_PLAYABILITY_SMOKE_OK manifests=5 seconds_each=30")
	_cleanup(0)

func _cleanup(code: int) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)
