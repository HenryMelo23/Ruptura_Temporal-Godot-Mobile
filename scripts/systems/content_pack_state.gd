extends RefCounted

const BASE_CONFIG := "res://assets/updates/content_base.json"
const STATE_PATH := "user://updates/content_state.json"
const STORAGE := "user://updates/content"
const PUBLIC_KEY := "res://assets/updates/content_public.pem"

static func base_contract(path: String = BASE_CONFIG) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Content update base contract missing: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Content update base contract is not valid JSON: " + path)
		return {}
	var contract: Dictionary = parsed
	var version := String(contract.get("base_version", ""))
	var code := int(contract.get("base_version_code", 0))
	if version == "" or code <= 0:
		push_error("Content update base contract is incomplete: " + path)
		return {}
	return {"base_version": version, "base_version_code": code}

static func base_version() -> String:
	return String(base_contract().get("base_version", ""))

static func base_version_code() -> int:
	return int(base_contract().get("base_version_code", 0))

static func project_contract_valid() -> bool:
	var contract := base_contract()
	if contract.is_empty():
		return false
	var configured_version := String(ProjectSettings.get_setting("application/config/version", ""))
	if configured_version != String(contract.get("base_version", "")):
		push_error("Project version %s does not match content base %s." % [configured_version, String(contract.get("base_version", ""))])
		return false
	return true

static func compatible(pack: Dictionary) -> bool:
	var contract := base_contract()
	if contract.is_empty():
		return false
	return int(pack.get("required_game_version_code", 0)) == int(contract.get("base_version_code", 0)) and String(pack.get("platform", "")) == OS.get_name().to_lower()

static func authentic(pack: Dictionary, public_key_path: String = PUBLIC_KEY) -> bool:
	var key := CryptoKey.new()
	if key.load(public_key_path, true) != OK:
		return false
	var digest := String(pack.get("sha256", ""))
	if digest.length() != 64 or not digest.is_valid_hex_number(false):
		return false
	return Crypto.new().verify(HashingContext.HASH_SHA256, digest.hex_decode(), Marshalls.base64_to_raw(String(pack.get("signature", ""))), key)

static func mount_installed(state_path: String = STATE_PATH, public_key_path: String = PUBLIC_KEY) -> Dictionary:
	if not project_contract_valid():
		return {}
	if not FileAccess.file_exists(state_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(state_path))
	if not parsed is Dictionary:
		return {}
	var packs: Array = parsed.get("packs", [])
	if packs.is_empty():
		return {}
	# Verify the complete set before mounting anything; never run a partial update.
	for entry in packs:
		if not entry is Dictionary:
			return {}
		var name := String(entry.get("filename", ""))
		var path := STORAGE.path_join(name)
		if name != name.get_file() or not name.ends_with(".pck") or not compatible(entry) or not authentic(entry, public_key_path):
			return {}
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != String(entry.sha256):
			return {}
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() != int(entry.get("size", 0)):
			return {}
	for entry in packs:
		if not ProjectSettings.load_resource_pack(STORAGE.path_join(String(entry.filename)), true):
			push_error("Unable to mount verified content pack: " + String(entry.filename))
			return {}
	print("CONTENT_BOOT_OK version=", parsed.get("content_version", ""))
	return parsed
