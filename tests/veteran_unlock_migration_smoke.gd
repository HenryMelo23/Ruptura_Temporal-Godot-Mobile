extends SceneTree

var game: Node
var failed: = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("VETERAN_UNLOCK_MIGRATION_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.unlocked_card_ids.clear()
	game.unlocked_manifestation_ids.clear()
	game.unlocked_spectrum_ids.clear()
	game.card_unlock_progress.clear()
	game.card_unlock_veteran_synced_version_code = 0
	game._ensure_card_unlock_defaults()

	_check(bool(game.unlocked_manifestation_ids.get("eletrica", false)), "eletrica default missing")
	_check(bool(game.unlocked_spectrum_ids.get("impulsiva", false)), "impulsiva default missing")
	_check(not bool(game.unlocked_manifestation_ids.get("lacerante", false)), "lacerante should start locked")
	_check(not bool(game.unlocked_spectrum_ids.get("racional", false)), "racional should start locked")

	var result: Dictionary = game._apply_veteran_unlock_payload({
		"ok": true,
		"version_code": int(game.GAME_VERSION_CODE),
		"manifestations": ["Lacerante", "prismatica", "forma_inexistente"],
		"specters": ["Racional", "Peregrina", "espectro_inexistente"]
	}, false)

	_check(int(result.get("manifestations", 0)) == 2, "unexpected manifestation unlock count")
	_check(int(result.get("specters", 0)) == 2, "unexpected specter unlock count")
	_check(bool(game.unlocked_manifestation_ids.get("lacerante", false)), "lacerante not restored")
	_check(bool(game.unlocked_manifestation_ids.get("prismatica", false)), "prismatica not restored")
	_check(not bool(game.unlocked_manifestation_ids.get("forma_inexistente", false)), "invalid manifestation restored")
	_check(bool(game.unlocked_spectrum_ids.get("racional", false)), "racional not restored")
	_check(bool(game.unlocked_spectrum_ids.get("peregrino", false)), "peregrino alias not restored")
	_check(not bool(game.unlocked_spectrum_ids.get("espectro_inexistente", false)), "invalid specter restored")
	_check(int(game.card_unlock_veteran_synced_version_code) >= int(game.GAME_VERSION_CODE), "sync version not stored")

	if failed:
		root.remove_child(game)
		game.queue_free()
		quit(1)
		return

	print("VETERAN_UNLOCK_MIGRATION_OK")
	root.remove_child(game)
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
