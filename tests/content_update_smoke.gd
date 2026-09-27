extends SceneTree

const CONTENT_BYTES := "RUPTURA_CONTENT_SMOKE"
const CONTENT_SHA256 := "da7a040e6cdf8ec8ba06fe084ec21a910f72244938eecf1b6551b4606d6ab79d"
const CONTENT_SIGNATURE := "hmOTMMhU66G1C+DBjkOzgNgMF5uGdXPUxfzqdj93F0VjtdQCitGg6zZ9QA98ASPZ/cpFNXltMlUNncTRsip9HvdG/8ZgucLFy4WjMhbGk+0JGaCc9l2PMsk5XPp2vJbkJv9DI3SoaFUl3603vmo4UPi1m3/oIc/7QbpbWR9lLW0e239N/f15peTNhWyPG9aIc7xcX7XIW3zTiXYBQUILwygeX0zaXAV06bKz4Uv2YEnb7we4QLyyz76Jo1YSS71wKi1wlyxmH1A2ncDpnIp0XIjA3Mb2LxtpPU+uzHJmmEDlwX+fupjjJJbss8C7kLoqDgeHSC7Hnatp2Y4puAKfsAw4BusOgzEbptKmHhnPd5iftWKCQZ/gEguXcBY/xAj2j2VOG1oDV0sMRpSTwg8t1NtehRBgtXgPqda1+I32qGrq/ggQLdH6/8QjPCNjvSL+SFma/VIqHyasljXgliGtet2sha/2UZyUNNG86/2hndsdhkv1t6BZzu+vsjjyrDDF"

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
			"required_game_version_code": game.GAME_VERSION_CODE,
			"platform": OS.get_name().to_lower(),
			"signature": CONTENT_SIGNATURE
		}]
	}
	var normalized: Dictionary = game._normalize_content_update_manifest(payload)
	_check(bool(normalized.get("ok", false)), "valid content manifest was rejected")
	var wrong_base: Dictionary = payload.duplicate(true)
	wrong_base.packs[0].required_game_version_code = game.GAME_VERSION_CODE - 1
	_check(not bool(game._normalize_content_update_manifest(wrong_base).get("ok", true)), "wrong base version accepted")
	var corrupted_sha: Dictionary = payload.duplicate(true)
	corrupted_sha.packs[0].sha256 = "0".repeat(64)
	_check(not bool(game._normalize_content_update_manifest(corrupted_sha).get("ok", true)), "corrupted SHA accepted")
	var invalid_signature: Dictionary = payload.duplicate(true)
	invalid_signature.packs[0].signature = "AA=="
	_check(not bool(game._normalize_content_update_manifest(invalid_signature).get("ok", true)), "invalid signature accepted")
	var unsigned: Dictionary = payload.duplicate(true)
	unsigned.packs[0].erase("signature")
	_check(not bool(game._normalize_content_update_manifest(unsigned).get("ok", true)), "unsigned pack accepted")
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
	_check(_failed_partial_download_does_not_activate(pack_path), "failed partial download activated or replaced final pack")
	_check(_resumed_partial_download_promotes(pack_path), "resumed partial download did not promote verified pack")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pack_path))
	print("CONTENT_UPDATE_OK manifest_validation=true sha256=true")
	if game.get_parent() != null:
		game.get_parent().remove_child(game)
	if game.has_method("_cleanup_runtime_resources"):
		game.call("_cleanup_runtime_resources")
	game.free()
	await process_frame
	await process_frame
	quit(0)


func _failed_partial_download_does_not_activate(pack_path: String) -> bool:
	var part_path: String = pack_path + ".part"
	var final_marker := "ACTIVE_OK"
	var final_file := FileAccess.open(pack_path, FileAccess.WRITE)
	if final_file == null:
		return false
	final_file.store_string(final_marker)
	final_file.close()
	var part_file := FileAccess.open(part_path, FileAccess.WRITE)
	if part_file == null:
		return false
	part_file.store_string("broken")
	part_file.close()
	game.content_update_download_path = pack_path
	game.content_update_download_part_path = part_path
	game.content_update_download_resume_path = part_path + ".resume"
	game.content_update_current_pack = {"size": CONTENT_BYTES.to_utf8_buffer().size(), "sha256": CONTENT_SHA256}
	game._finish_content_update_download()
	var preserved := FileAccess.get_file_as_string(pack_path) == final_marker
	if FileAccess.file_exists(part_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(part_path))
	return preserved and game.content_update_status == "error"


func _resumed_partial_download_promotes(pack_path: String) -> bool:
	if FileAccess.file_exists(pack_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(pack_path))
	var part_path: String = pack_path + ".part"
	var resume_path: String = part_path + ".resume"
	var split_at := 8
	var part_file := FileAccess.open(part_path, FileAccess.WRITE)
	if part_file == null:
		return false
	part_file.store_string(CONTENT_BYTES.substr(0, split_at))
	part_file.close()
	var resume_file := FileAccess.open(resume_path, FileAccess.WRITE)
	if resume_file == null:
		return false
	resume_file.store_string(CONTENT_BYTES.substr(split_at))
	resume_file.close()
	game.content_update_download_path = pack_path
	game.content_update_download_part_path = part_path
	game.content_update_download_resume_path = resume_path
	game.content_update_download_resume_offset = split_at
	game.content_update_current_pack = {"size": CONTENT_BYTES.to_utf8_buffer().size(), "sha256": CONTENT_SHA256}
	game.content_update_manifest = {"content_version": "resume-smoke", "content_version_code": 2, "packs": []}
	game.content_update_queue.clear()
	if not game._merge_content_update_download(206):
		return false
	game._finish_content_update_download()
	return FileAccess.file_exists(pack_path) and FileAccess.get_file_as_string(pack_path) == CONTENT_BYTES and game.content_update_status != "error"
