extends SceneTree

const State = preload("res://scripts/systems/content_pack_state.gd")

func _initialize() -> void:
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
	_write(source, "extends RefCounted\nconst MARKER = 23600\n")
	assert(patch.add_file("res://patch_probe.gd", source) == OK)
	assert(patch.flush() == OK)
	var key := Crypto.new().generate_rsa(2048)
	assert(key.save(prefix + ".pem", true) == OK)
	var digest := FileAccess.get_sha256(patch_path)
	var entry := {
		"filename": filename, "sha256": digest,
		"signature": Marshalls.raw_to_base64(Crypto.new().sign(HashingContext.HASH_SHA256, digest.hex_decode(), key)),
		"size": FileAccess.open(patch_path, FileAccess.READ).get_length(),
		"required_game_version_code": State.BASE_CODE, "platform": OS.get_name().to_lower()
	}
	var state := {"content_version": "smoke", "content_version_code": 1, "packs": [entry]}
	_write(prefix + ".json", JSON.stringify(state))
	var tampered: Dictionary = entry.duplicate(true)
	tampered.sha256 = "0".repeat(64)
	assert(not State.authentic(tampered, prefix + ".pem"))
	var incompatible: Dictionary = entry.duplicate(true)
	incompatible.required_game_version_code = 23500
	assert(not State.compatible(incompatible))
	assert(not State.mount_installed(prefix + ".json", prefix + ".pem").is_empty())
	assert(FileAccess.get_file_as_string("res://patch_probe.txt") == "new")
	assert(FileAccess.file_exists("res://patch_added.txt"))
	assert(not FileAccess.file_exists("res://patch_removed.txt"))
	assert(load("res://patch_probe.gd").MARKER == 23600)
	for path in [source, prefix + ".pck", prefix + ".pem", prefix + ".json", patch_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CONTENT_PATCH_BOOT_OK signature=true add=true replace=true remove=true script=true")
	quit(0)

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(value)
