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
	game.app_update_check_in_flight = true
	game.app_update_checked = true
	game._on_app_update_check_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	_check(not game.app_update_check_in_flight, "failed update check remained in flight")
	_check(not game.app_update_checked, "failed update check was incorrectly marked complete")
	_check(game.app_update_check_timer == 2.0 and game.app_update_check_attempts == 1, "failed update check did not schedule the first retry")
	game.app_update_check_in_flight = true
	game._on_app_update_check_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify({"available": false}).to_utf8_buffer())
	_check(game.app_update_checked and game.app_update_check_attempts == 0, "successful no-update response did not complete the retry cycle")
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
	var preserved_part := "user://updates/ruptura_temporal_mobile_9.9.99.apk.part"
	stale_file = FileAccess.open(preserved_part, FileAccess.WRITE)
	_check(stale_file != null, "could not create resumable partial fixture")
	stale_file.store_string("PREFIX")
	stale_file.close()
	_check(game._cleanup_stale_app_update_files("", true) == 0, "startup cleanup removed or counted a resumable partial")
	_check(FileAccess.file_exists(preserved_part), "startup cleanup removed resumable progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(preserved_part))

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

	var full_bytes := UPDATE_BYTES.to_utf8_buffer()
	var split_at := 7
	var resume_part := "user://updates/app_update_resume.apk.part"
	var resume_tail := resume_part + ".resume"
	file = FileAccess.open(resume_part, FileAccess.WRITE)
	_check(file != null, "could not create resume prefix")
	file.store_buffer(full_bytes.slice(0, split_at))
	file.close()
	file = FileAccess.open(resume_tail, FileAccess.WRITE)
	_check(file != null, "could not create resume suffix")
	file.store_buffer(full_bytes.slice(split_at))
	file.close()
	game.app_update_download_part_path = resume_part
	game.app_update_download_resume_path = resume_tail
	game.app_update_download_resume_offset = split_at
	_check(game._merge_app_update_download(206), "HTTP 206 resume chunks were not merged")
	verified = game._verify_app_update_file(resume_part, full_bytes.size(), UPDATE_SHA256)
	_check(bool(verified.get("ok", false)), "resumed installer failed final SHA-256 verification")
	_check(not FileAccess.file_exists(resume_tail), "resume suffix survived a successful merge")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(resume_part))

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
	var platform_filename := "ruptura_temporal_mobile_9.9.100.apk"
	var expected_extension := ".apk"
	if game._app_update_platform() == "windows":
		platform_filename = "Ruptura_Temporal_9.9.100.exe"
		expected_extension = ".exe"
	elif game._app_update_platform() == "linux":
		platform_filename = "Ruptura_Temporal_9.9.100.x86_64"
		expected_extension = ".x86_64"
	var platform_payload := {
		"available": true,
		"version": "9.9.100",
		"version_code": next_version_code + 1,
		"size": UPDATE_BYTES.to_utf8_buffer().size(),
		"sha256": UPDATE_SHA256,
		"notes": ["Atualizador multiplataforma smoke"],
		"mandatory": false,
		"filename": platform_filename,
	}
	platform_payload[game._app_update_download_url_field()] = game.ONLINE_RELAY_BASE_URL + game._app_update_download_prefix() + platform_filename
	game._apply_app_update_manifest(platform_payload)
	_check(game.app_update_popup_visible, "platform update did not open the startup popup")
	_check(game._app_update_filename().ends_with(expected_extension), "platform update filename did not preserve its extension")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(update_path))
	print("APP_UPDATE_SMOKE_OK popup=true retry=true resume_206=true streamed_file=true sha256=true current_version_ignored=true platform=" + game._app_update_platform())
	game.queue_free()
	await process_frame
	game = null
	quit(0)
