extends SceneTree

## Capturas: selecao com botoes Aleatorio/Chips, popup de chips, fichas "?" no
## chao e o carrossel do Mercador Corrompido. Arg: --mobile

var game: Node
var prefix := "desk"


func _initialize() -> void:
	var mobile := OS.get_cmdline_user_args().has("--mobile")
	prefix = "mob" if mobile else "desk"
	root.size = Vector2i(844, 390) if mobile else Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _shot(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.agent_logs/chips/%s_%s.png" % [prefix, name]))


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	var chips: RTQuantumChipController = game._quantum_chips()
	chips.selected = {RTQuantumChipController.SEDENTA: true, RTQuantumChipController.CORRUPTOR: true}
	chips.random_mode = true
	if prefix == "mob":
		game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game.mode = "manifest"
	game.manifest_select_stage = game.MANIFEST_STAGE_MANIFESTATION
	await _shot("01_select_footer")
	RTQuantumChipUI.open = true
	await _shot("02_chip_popup")
	RTQuantumChipUI.open = false
	# Run com Corruptor no modo drop: fichas no chao.
	chips.random_mode = false
	game._set_run_mode_local(game.RUN_MODE_DROP)
	game.forced_initial_phase = 1
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 900.0
	game.enemies.clear()
	game.camera_follow_initialized = false
	for i in range(4):
		game._drop_mode().on_enemy_killed({"killed_by_peer_id": game._mp_unique_id(), "type": game.ENEMY_COMMON}, game.player_pos + Vector2.from_angle(float(i) * 1.5) * 150.0, 0.0)
	for k in range(6):
		game._update_arauto_card_drops(0.05)
		game.time_alive += 0.05
	await _shot("03_mystery_drops")
	chips.tokens = {"common": 2, "uncommon": 1, "rare": 1}
	game._corruptor_shop().open()
	for k in range(60):
		game.RuntimeAssetController.poll_registered_textures(game, 8, 8)
		await process_frame
	await _shot("04_corruptor_carousel")
	game._corruptor_shop().step(1)
	for k in range(30):
		game.RuntimeAssetController.poll_registered_textures(game, 8, 8)
		await process_frame
	await _shot("05_corruptor_step")
	print("QCHIP_VISUAL_DONE")
	quit(0)
