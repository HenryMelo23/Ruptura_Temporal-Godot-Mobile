extends SceneTree

const UPDATE_BYTES := "RUPTURA_UPDATE_SMOKE"
const UPDATE_SHA256 := "1de07c535a00b4405330e33a2747dca7dff524f807b6ddd8e708f3199c3c8b91"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("APP_UPDATE_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var next_version_code := int(game.GAME_VERSION_CODE) + 1
	var payload := {
		"available": true,
		"version": "9.9.99",
		"version_code": next_version_code,
		"size": UPDATE_BYTES.to_utf8_buffer().size(),
		"sha256": UPDATE_SHA256,
		"notes": ["Atualizador smoke"],
		"mandatory": false,
		"apk_url": game.ONLINE_RELAY_BASE_URL + game.APP_UPDATE_DOWNLOAD_PREFIX + "ruptura_temporal_mobile_9.9.99.apk"
	}
	game._apply_app_update_manifest(payload)
	_check(game.app_update_popup_visible, "new version did not open the startup popup")
	_check(game.app_update_status == "available", "new version status is incorrect")
	_check(game._app_update_button_rects(Vector2(1280, 720)).size() == 2, "update choice does not expose update/later actions")

	var update_dir := ProjectSettings.globalize_path("user://updates")
	DirAccess.make_dir_recursive_absolute(update_dir)
	var update_path := "user://updates/app_update_smoke.apk"
	var file := FileAccess.open(update_path, FileAccess.WRITE)
	_check(file != null, "could not create the streamed update fixture")
	file.store_buffer(UPDATE_BYTES.to_utf8_buffer())
	file.close()
	var verified: Dictionary = game._verify_app_update_file(update_path, UPDATE_BYTES.to_utf8_buffer().size(), UPDATE_SHA256)
	_check(bool(verified.get("ok", false)), "valid streamed APK fixture failed SHA-256 verification")
	var rejected: Dictionary = game._verify_app_update_file(update_path, UPDATE_BYTES.to_utf8_buffer().size(), "0".repeat(64))
	_check(not bool(rejected.get("ok", true)), "invalid SHA-256 was accepted")

	game.app_update_popup_visible = false
	var current_payload: Dictionary = payload.duplicate(true)
	current_payload["version_code"] = game.GAME_VERSION_CODE
	game._apply_app_update_manifest(current_payload)
	_check(not game.app_update_popup_visible, "current version offered an unnecessary update")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(update_path))
	print("APP_UPDATE_SMOKE_OK popup=true streamed_file=true sha256=true current_version_ignored=true")
	quit(0)
