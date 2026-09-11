extends SceneTree

const OUT_MANIFEST := "res://.codex/manifestation_catalog_lock_1280x720.png"
const OUT_SPECTRUM := "res://.codex/spectrum_catalog_lock_1280x720.png"
const OUT_NOTIFY := "res://.codex/manifest_spectrum_unlock_notification_1280x720.png"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_SPECTRUM_UNLOCK_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _prepare_clean_unlock_state() -> void:
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.unlocked_card_ids.clear()
	game.unlocked_manifestation_ids.clear()
	game.unlocked_spectrum_ids.clear()
	game.card_unlock_progress.clear()
	game.retornante_unlocked = false
	game._ensure_card_unlock_defaults()
	_check(game._manifestation_unlocked(0), "eletrica should be unlocked by default")
	_check(game._spectrum_unlocked(1), "impulsiva should be unlocked by default")
	_check(not game._manifestation_unlocked(1), "non-default manifestation should start locked")
	_check(not game._spectrum_unlocked(0), "non-default spectrum should start locked")


func _capture(path: String) -> void:
	for frame in range(12):
		game.queue_redraw()
		await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	var image: Image = viewport_texture.get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture")
	_check(image.save_png(path) == OK, "could not save " + path)
	image = null
	viewport_texture = null


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	_prepare_clean_unlock_state()

	game.mode = "catalog"
	game.catalog_tab = 0
	game.catalog_selected = 1
	game.catalog_scroll_index = 0
	game.catalog_detail_open = true
	var manifest_items: Array = game._catalog_items()
	_check(game._catalog_item_locked(manifest_items[1]), "locked manifestation should be hidden in catalog")
	_check(game._catalog_display_title(manifest_items[1]) == "???", "manifestation name leaked")
	_check(game._catalog_detail_mechanics(manifest_items[1]).find("OBJETIVO") >= 0, "manifestation objective missing")
	await _capture(OUT_MANIFEST)

	game.catalog_tab = 4
	game.catalog_selected = 0
	game.catalog_scroll_index = 0
	game.catalog_detail_open = true
	var spectrum_items: Array = game._catalog_items()
	_check(game._catalog_item_locked(spectrum_items[0]), "locked spectrum should be hidden in catalog")
	_check(game._catalog_display_title(spectrum_items[0]) == "???", "spectrum name leaked")
	_check(game._catalog_detail_mechanics(spectrum_items[0]).find("OBJETIVO") >= 0, "spectrum objective missing")
	await _capture(OUT_SPECTRUM)

	game.mode = "game"
	game.forced_initial_phase = 1
	game.force_phase6_start = false
	game._start_game()
	game.unlock_notifications.clear()
	_check(game._unlock_manifestation_by_key_state("lacerante", true), "could not unlock manifestation")
	_check(game._unlock_spectrum_by_key_state("racional", true), "could not unlock spectrum")
	_check(game.unlock_notifications.size() == 2, "unlock notifications were not queued")
	for i in range(game.unlock_notifications.size()):
		game.unlock_notifications[i]["age"] = 0.72
		game.unlock_notifications[i]["life"] = 5.28
	await _capture(OUT_NOTIFY)

	print("MANIFEST_SPECTRUM_UNLOCK_VISUAL_OK")
	print(ProjectSettings.globalize_path(OUT_MANIFEST))
	print(ProjectSettings.globalize_path(OUT_SPECTRUM))
	print(ProjectSettings.globalize_path(OUT_NOTIFY))
	root.remove_child(game)
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
