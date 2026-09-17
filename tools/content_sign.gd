extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: keygen PRIVATE_PATH | sign PRIVATE_PATH PACK_PATH")
		quit(1)
		return
	var key := CryptoKey.new()
	if args[0] == "keygen":
		if FileAccess.file_exists(args[1]):
			assert(key.load(args[1]) == OK)
		else:
			DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
			key = Crypto.new().generate_rsa(3072)
			assert(key.save(args[1]) == OK)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/updates"))
		assert(key.save("res://assets/updates/content_public.pem", true) == OK)
		print("CONTENT_KEY_READY")
	elif args[0] == "sign" and args.size() == 3:
		assert(key.load(args[1]) == OK)
		var digest := FileAccess.get_sha256(args[2])
		assert(digest.length() == 64)
		var signature := Crypto.new().sign(HashingContext.HASH_SHA256, digest.hex_decode(), key)
		var file := FileAccess.open(args[2] + ".sig", FileAccess.WRITE)
		file.store_string(Marshalls.raw_to_base64(signature))
		print("CONTENT_SIGNED ", args[2])
	elif args[0] == "verify" and args.size() == 3:
		assert(key.load(args[1], true) == OK)
		var digest := FileAccess.get_sha256(args[2])
		var signature := Marshalls.base64_to_raw(FileAccess.get_file_as_string(args[2] + ".sig").strip_edges())
		if not Crypto.new().verify(HashingContext.HASH_SHA256, digest.hex_decode(), signature, key):
			push_error("Invalid content signature")
			quit(1)
			return
		print("CONTENT_SIGNATURE_OK")
	else:
		quit(1)
		return
	quit(0)
