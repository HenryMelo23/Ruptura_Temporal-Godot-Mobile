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
	var update_url: String = game.ONLINE_RELAY_BASE_URL + game._app_update_download_prefix() + ("Ruptura_Temporal_9.9.99.exe" if game._app_update_platform() == "windows" else "ruptura_temporal_mobile_9.9.99.apk")
	var payload := {
		"available": true,
		"version": "9.9.99",
		"version_code": next_version_code,
		"size": UPDATE_BYTES.to_utf8_buffer().size(),
		"sha256": UPDATE_SHA256,
		"notes": ["Atualizador smoke"],
		"mandatory": false,
		"filename": update_url.get_file()
	}
	payload[game._app_update_download_url_field()] = update_url
	game._apply_app_update_manifest(payload)
	_check(game.app_update_popup_visible, "new version did not open the startup popup")
	_check(game.app_update_status == "available", "new version status is incorrect")
	_check(game._app_update_button_rects(Vector2(1280, 720)).size() == 2, "update choice does not expose update/later actions")
	game.app_update_selected = 1
	game.ui_input_block_until_msec = Time.get_ticks_msec() + 2000
	game._activate_app_update_selection()
	_check(not game.app_update_popup_visible, "optional update later action did not close the popup")
	_check(not game._ui_input_blocked(), "optional update later action kept the menu input blocked")
	game._apply_app_update_manifest(payload)
	_check(game.app_update_popup_visible, "new version did not reopen after optional dismissal")

	var update_dir := ProjectSettings.globalize_path("user://updates")
	DirAccess.make_dir_recursive_absolute(update_dir)
	var stale_apk := "user://updates/ruptura_temporal_mobile_0.0.1.apk"
	var stale_idsig := "user://updates/ruptura_temporal_mobile_0.0.1.apk.idsig"
	var stale_file := FileAccess.open(stale_apk, FileAccess.WRITE)
	_check(stale_file != null, "could not create stale APK fixture")
	stale_file.store_string("OLD_APK")
	stale_file.close()
	stale_file = FileAccess.open(stale_idsig, FileAccess.WRITE)
	_check(stale_file != null, "could not create stale IDSIG fixture")
	stale_file.store_string("OLD_IDSIG")
	stale_file.close()
	_check(game._cleanup_stale_app_update_files() == 2, "stale update cleanup did not remove old APK/IDSIG")
	_check(not FileAccess.file_exists(stale_apk), "old APK survived update cleanup")
	_check(not FileAccess.file_exists(stale_idsig), "old IDSIG survived update cleanup")

	var update_path := "user://updates/app_update_smoke.apk"
	var other_path := "user://updates/another_old_update.apk"
	var file := FileAccess.open(update_path, FileAccess.WRITE)
	_check(file != null, "could not create the streamed update fixture")
	file.store_buffer(UPDATE_BYTES.to_utf8_buffer())
	file.close()
	file = FileAccess.open(other_path, FileAccess.WRITE)
	_check(file != null, "could not create the removable stale update fixture")
	file.store_string("REMOVE_ME")
	file.close()
	_check(game._cleanup_stale_app_update_files(update_path) == 1, "cleanup with keep path removed the wrong number of files")
	_check(FileAccess.file_exists(update_path), "cleanup removed the active update download")
	_check(not FileAccess.file_exists(other_path), "cleanup kept a stale update beside the active download")
	var verified: Dictionary = game._verify_app_update_file(update_path, UPDATE_BYTES.to_utf8_buffer().size(), UPDATE_SHA256)
	_check(bool(verified.get("ok", false)), "valid streamed APK fixture failed SHA-256 verification")
	var rejected: Dictionary = game._verify_app_update_file(update_path, UPDATE_BYTES.to_utf8_buffer().size(), "0".repeat(64))
	_check(not bool(rejected.get("ok", true)), "invalid SHA-256 was accepted")

	game.app_update_popup_visible = false
	var current_payload: Dictionary = payload.duplicate(true)
	current_payload["version_code"] = game.GAME_VERSION_CODE
	game._apply_app_update_manifest(current_payload)
	_check(not game.app_update_popup_visible, "current version offered an unnecessary update")
	var published_payload := {
		"available": true,
		"version": "2.0.33",
		"version_code": 23300,
		"size": UPDATE_BYTES.to_utf8_buffer().size(),
		"sha256": UPDATE_SHA256,
		"notes": ["Versao publicada atual"],
		"mandatory": false,
		"filename": update_url.get_file()
	}
	published_payload[game._app_update_download_url_field()] = update_url
	game._apply_app_update_manifest(published_payload)
	_check(not game.app_update_popup_visible, "published 2.0.33 manifest still blocks the local 2.0.33 menu")
	game.app_update_popup_visible = false
	var original_platform: String = game.ui_platform_override
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	var windows_payload := {
		"available": true,
		"version": "9.9.100",
		"version_code": next_version_code + 1,
		"size": UPDATE_BYTES.to_utf8_buffer().size(),
		"sha256": UPDATE_SHA256,
		"notes": ["Atualizador Windows smoke"],
		"mandatory": false,
		"filename": "Ruptura_Temporal_9.9.100.exe",
		"exe_url": game.ONLINE_RELAY_BASE_URL + game.APP_UPDATE_WINDOWS_DOWNLOAD_PREFIX + "Ruptura_Temporal_9.9.100.exe"
	}
	game._apply_app_update_manifest(windows_payload)
	_check(game.app_update_popup_visible, "windows exe update did not open the startup popup")
	_check(game._app_update_filename().ends_with(".exe"), "windows update filename did not preserve exe")
	_check(game._app_update_file_label() == "EXE", "windows update label is not EXE")
	game.ui_platform_override = original_platform
	DirAccess.remove_absolute(ProjectSettings.globalize_path(update_path))
	print("APP_UPDATE_SMOKE_OK popup=true streamed_file=true sha256=true current_version_ignored=true windows=true")
	game.queue_free()
	await process_frame
	game = null
	quit(0)
