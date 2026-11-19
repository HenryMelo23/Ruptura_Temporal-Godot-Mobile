extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.RuntimeAssetController.release_transient_gallery_assets(game)
	var resident_before := _resident_card_texture_count()
	var eligible := 0
	for card in game.CARDS:
		if game._card_available_for_reward(card, true, true):
			eligible += 1
	var started_usec := Time.get_ticks_usec()
	game._spawn_random_card_drops(game.player_pos + Vector2(420.0, 0.0), 4, 0)
	var elapsed_usec := Time.get_ticks_usec() - started_usec
	var resident_after_spawn := _resident_card_texture_count()
	var selected_count: int = game.arauto_card_drops.size()
	_check(resident_before == 0, "gallery release left card textures resident")
	_check(selected_count == 4, "expected four cold card drops")
	_check(eligible > selected_count, "fixture did not exercise a larger reward pool")
	_check(resident_after_spawn == 0, "drop spawn synchronously loaded selected card textures")
	var ready := false
	for _frame in range(300):
		game.RuntimeAssetController.poll_registered_textures(game, 1, 2)
		game._update_arauto_card_drops(0.0)
		if _resident_card_texture_count() >= selected_count:
			ready = true
			break
		await process_frame
	var resident_after_load := _resident_card_texture_count()
	_check(ready, "selected card textures did not finish asynchronous loading")
	_check(resident_after_load <= selected_count * 2, "asynchronous loading retained unrelated card textures")
	print("CARD_DROP_COLD_LOAD_%s eligible=%d selected=%d resident_before=%d resident_after_spawn=%d resident_after_load=%d spawn_usec=%d" % [
		"FAIL" if failed else "OK",
		eligible,
		selected_count,
		resident_before,
		resident_after_spawn,
		resident_after_load,
		elapsed_usec,
	])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _resident_card_texture_count() -> int:
	var result := 0
	for key in game.textures:
		if String(key).begins_with("card_"):
			result += 1
	return result


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("CARD_DROP_COLD_LOAD_FAIL " + message)
