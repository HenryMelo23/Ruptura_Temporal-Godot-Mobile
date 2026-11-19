extends SceneTree

var game: Node
var failed := false

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		push_error("STARTUP_MEMORY_ORDER_FAIL " + label)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.agent_logs/startup_239_" + label + ".png")

func _run() -> void:
	game.set_process(false)
	var phase_key_total := 0
	var resident_phase_keys := 0
	for phase in range(1, 8):
		for phase_key in game.RuntimeAssetController.phase_keys(phase):
			phase_key_total += 1
			if game.textures.has(phase_key):
				resident_phase_keys += 1
	var lazy_gallery_keys: Array = game.lazy_texture_paths.keys().filter(func(key):
		var name := String(key)
		return name.begins_with("card_") or name.begins_with("manifestation_") or name.begins_with("aura_")
	)
	var resident_gallery_keys := lazy_gallery_keys.filter(func(key): return game.textures.has(key)).size()
	_check(resident_phase_keys == 0, "menu retained phase textures")
	_check(not lazy_gallery_keys.is_empty() and resident_gallery_keys == 0, "menu eagerly loaded gallery textures")
	game.player_nickname = ""
	game.mode = "nick_setup"
	game.startup_thanks_done = false
	game.startup_thanks_fading = false
	game.startup_thanks_teaser_available = true
	game.startup_thanks_timer = 0.0
	game._update_nickname_input_visibility()
	_check(not game.nickname_edit.visible and not game.nickname_edit.has_focus(), "name hidden during intro")
	game.nickname_edit.text = "ShouldNotSave"
	game._submit_player_nickname()
	_check(game.player_nickname == "", "submission blocked during intro")
	for index in range(1, 40):
		var texture: Texture2D = game._get_startup_thanks_frame_texture(index)
		_check(texture != null, "frame exists")
		_check(game.startup_thanks_frame_cache.size() <= 2, "bounded frame cache")
	game._update_startup_thanks(0.25)
	await _capture("intro")
	game._skip_startup_thanks()
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME * 0.5)
	_check(not game.nickname_edit.visible, "name hidden during skip fade")
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME)
	_check(game.nickname_edit.visible, "name shown after skip")
	_check(game.startup_thanks_frame_cache.is_empty(), "frame cache released")
	_check(game.startup_thanks_frame_view.texture == null, "frame reference released")
	_check(game.startup_thanks_audio_player == null or game.startup_thanks_audio_player.stream == null, "intro audio released")
	await _capture("name")
	game.startup_thanks_done = false
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game._update_nickname_input_visibility()
	game._update_startup_thanks(game._startup_thanks_duration() + 0.01)
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME + 0.01)
	_check(game.nickname_edit.visible, "name shown after natural finish")
	game.gfx_low_resource = false
	game._register_texture("map_phase_1", "res://assets/sprites/Fase1.png", true)
	_check(not game.textures.has("map_phase_1"), "full quality map lazy")
	_check(game._get_texture("map_phase_1") != null, "lazy map available")
	game._release_unused_lazy_maps("map_phase_2")
	_check(not game.textures.has("map_phase_1"), "inactive map released at full quality")
	_check(game.RuntimeAssetController.should_stream_phase_assets(true, false), "mobile full quality must stream phase assets")
	_check(game.RuntimeAssetController.should_stream_phase_assets(false, false), "desktop full quality must stream inactive phases")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.free()
	await process_frame
	if not failed:
		print("STARTUP_MEMORY_ORDER_OK natural=true skip=true cache_max=2 maps_full_quality=true phase_streaming=all_platforms menu_phase_resident=%d/%d menu_gallery_resident=%d/%d" % [resident_phase_keys, phase_key_total, resident_gallery_keys, lazy_gallery_keys.size()])
	quit(1 if failed else 0)
