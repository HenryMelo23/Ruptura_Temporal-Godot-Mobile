extends SceneTree

const CONTENT_BYTES := "RUPTURA_CONTENT_SMOKE"
const CONTENT_SHA256 := "da7a040e6cdf8ec8ba06fe084ec21a910f72244938eecf1b6551b4606d6ab79d"

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("CONTENT_UPDATE_FAIL " + message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.content_update_version_code = 0
	var valid_url: String = game.ONLINE_RELAY_BASE_URL + game.CONTENT_UPDATE_DOWNLOAD_PREFIX + "ruptura_content_smoke.pck"
	var payload := {
		"available": true,
		"content_version": "smoke-1",
		"content_version_code": 1,
		"packs": [{
			"filename": "ruptura_content_smoke.pck",
			"download_url": valid_url,
			"size": CONTENT_BYTES.to_utf8_buffer().size(),
			"sha256": CONTENT_SHA256,
			"required_game_version_code": game.GAME_VERSION_CODE
		}]
	}
	var normalized: Dictionary = game._normalize_content_update_manifest(payload)
	_check(bool(normalized.get("ok", false)), "valid content manifest was rejected")
	_check(game._content_update_safe_filename("../escape.pck") == "", "path traversal filename was accepted")
	_check(game._content_update_safe_filename("bad.txt") == "", "non-pck filename was accepted")
	var invalid_payload: Dictionary = payload.duplicate(true)
	invalid_payload["packs"] = [Dictionary(payload["packs"][0]).merged({"download_url": "http://evil.invalid/file.pck"}, true)]
	_check(not bool(game._normalize_content_update_manifest(invalid_payload).get("ok", true)), "foreign content URL was accepted")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(game.CONTENT_UPDATE_STORAGE_DIR))
	var pack_path: String = game._content_update_pack_path("ruptura_content_smoke.pck")
	var file := FileAccess.open(pack_path, FileAccess.WRITE)
	_check(file != null, "could not create content pack fixture")
	file.store_buffer(CONTENT_BYTES.to_utf8_buffer())
	file.close()
	var verified: Dictionary = game._verify_update_file(pack_path, CONTENT_BYTES.to_utf8_buffer().size(), CONTENT_SHA256, "PCK")
	_check(bool(verified.get("ok", false)), "valid content pack fixture failed verification")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pack_path))
	print("CONTENT_UPDATE_OK manifest_validation=true sha256=true")
	game.queue_free()
	await process_frame
	quit(0)
