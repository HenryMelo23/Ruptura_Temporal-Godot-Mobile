extends SceneTree

const State = preload("res://scripts/systems/content_pack_state.gd")

func _initialize() -> void:
	assert(State.project_contract_valid())
	var base_code := State.base_version_code()
	assert(base_code == 24100)
	var prefix := "user://content_boot_smoke_" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(State.STORAGE))
	var source := prefix + ".txt"
	_write(source, "old")
	var base := PCKPacker.new()
	assert(base.pck_start(prefix + ".pck") == OK)
	assert(base.add_file("res://patch_probe.txt", source) == OK)
	assert(base.add_file("res://patch_removed.txt", source) == OK)
	assert(base.flush() == OK)
	assert(ProjectSettings.load_resource_pack(prefix + ".pck"))
	var filename := "boot_smoke_%d.pck" % OS.get_process_id()
	var patch_path := State.STORAGE.path_join(filename)
	var patch := PCKPacker.new()
	assert(patch.pck_start(patch_path) == OK)
	_write(source, "new")
	assert(patch.add_file("res://patch_probe.txt", source) == OK)
	assert(patch.add_file("res://patch_added.txt", source) == OK)
	assert(patch.add_file_removal("res://patch_removed.txt") == OK)
	_write(source, "extends RefCounted\nconst MARKER = %d\n" % base_code)
	assert(patch.add_file("res://patch_probe.gd", source) == OK)
	assert(patch.flush() == OK)
	var key := Crypto.new().generate_rsa(2048)
	assert(key.save(prefix + ".pem", true) == OK)
	var digest := FileAccess.get_sha256(patch_path)
	var entry := {
		"filename": filename, "sha256": digest,
		"signature": Marshalls.raw_to_base64(Crypto.new().sign(HashingContext.HASH_SHA256, digest.hex_decode(), key)),
		"size": FileAccess.open(patch_path, FileAccess.READ).get_length(),
		"required_game_version_code": base_code, "platform": OS.get_name().to_lower()
	}
	var state := {"content_version": "smoke", "content_version_code": 1, "packs": [entry]}
	_write(prefix + ".json", JSON.stringify(state))
	var tampered: Dictionary = entry.duplicate(true)
	tampered.sha256 = "0".repeat(64)
	assert(not State.authentic(tampered, prefix + ".pem"))
	var unsigned: Dictionary = entry.duplicate(true)
	unsigned.erase("signature")
	assert(not State.authentic(unsigned, prefix + ".pem"))
	var unsafe: Dictionary = entry.duplicate(true)
	unsafe.filename = "../escape.pck"
	assert(State.mount_installed(prefix + ".json", prefix + ".pem").is_empty() == false)
	var incompatible: Dictionary = entry.duplicate(true)
	incompatible.required_game_version_code = base_code - 1
	assert(not State.compatible(incompatible))
	var unsafe_state := {"content_version": "unsafe", "content_version_code": 1, "packs": [unsafe]}
	_write(prefix + "_unsafe.json", JSON.stringify(unsafe_state))
	assert(State.mount_installed(prefix + "_unsafe.json", prefix + ".pem").is_empty())
	assert(FileAccess.get_file_as_string("res://patch_probe.txt") == "new")
	assert(FileAccess.file_exists("res://patch_added.txt"))
	assert(not FileAccess.file_exists("res://patch_removed.txt"))
	assert(load("res://patch_probe.gd").MARKER == base_code)
	_check_no_stale_baselines()
	for path in [source, prefix + ".pck", prefix + ".pem", prefix + ".json", prefix + "_unsafe.json", patch_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CONTENT_PATCH_BOOT_OK signature=true add=true replace=true remove=true script=true")
	quit(0)

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(value)


func _check_no_stale_baselines() -> void:
	for path in [
		"res://scripts/systems/content_pack_state.gd",
		"res://tools/build_content_patch.ps1",
		"res://tools/publish_content_update.ps1",
		"res://server/content_update_smoke.js",
		"res://tests/content_update_smoke.gd",
		"res://tests/content_patch_boot_smoke.gd"
	]:
		var text := FileAccess.get_file_as_string(path)
		for prefix in [236, 238, 240]:
			assert(text.find(str(prefix * 100)) == -1)
