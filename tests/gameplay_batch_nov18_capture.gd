extends SceneTree

## Capturas do lote 2026-11-18 (desktop 1280x720 e mobile 800x360):
## carrossel com ALEATORIA (Geovana e Henry), atalhos da loja, oficina com
## fisica (barril chutado, Mercador cambaleando) e Espreitador camuflado.
## Saida: res://.codex/nov18/*.png

var game: Node
const OUT := "res://.codex/nov18"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func capture(label: String) -> void:
	# A tela de montagem anima a entrada por tempo real: espera ela assentar.
	for i in range(3):
		game.queue_redraw()
		await create_timer(0.35).timeout
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%dx%d.png" % [OUT, label, root.size.x, root.size.y]
	var err: int = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE ", path, " err=", err)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game._start_game()
	game.set_process(false)
	game.run_tutorial_enabled = false
	# Tamanho vem da linha de comando: --windowed --resolution 1280x720 / 800x360.
	var forced: Vector2i = DisplayServer.window_get_size()
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--capture-size="):
			var parts: PackedStringArray = String(arg).trim_prefix("--capture-size=").split("x")
			forced = Vector2i(int(parts[0]), int(parts[1]))
	for size in [forced]:
		root.size = size
		root.content_scale_size = size
		game.desktop_window_mode = game.DESKTOP_WINDOW_WINDOWED
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)
		await process_frame
		await _capture_carousels()
		await _capture_shop()
		await _capture_workshop()
		await _capture_stalker()
	print("GAMEPLAY_BATCH_NOV18_CAPTURE_DONE")
	quit(0)


func _capture_carousels() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "manifest"
	game.manifest_select_stage = game.MANIFEST_STAGE_MANIFESTATION
	game._clear_build_random()
	game._set_selected_manifestation(game._manifest_selection_index_for_slot(0, false), false)
	game._set_selected_manifestation(game.BUILD_RANDOM_INDEX, false)
	game.manifest_scroll_pos = float(game._manifest_selection_slot_for_index(game.selected_manifestation, false))
	await capture("1_manifest_random")
	game._resolve_build_random_pick(false)
	game.manifest_select_stage = game.MANIFEST_STAGE_AURA
	game._set_selected_aura(game.BUILD_RANDOM_INDEX, false)
	game.aura_scroll_pos = float(game._manifest_selection_slot_for_index(game.selected_aura, true))
	await capture("1_spectrum_random_hidden_manifest")
	game._clear_build_random()
	game.mode = "mutation_select"
	game.selected_mutation = 0
	game._step_henry_build_selection(false, -1)
	await capture("1_henry_mutation_random")


func _capture_shop() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game._reset_card_counts()
	game.shop_locked_slots.clear()
	game.cards_bought[game.CARD_ESCOLHA_ADIADA_ID] = 1
	game.cards_bought[game.CARD_CINZAS_ID] = 2
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
	game.score = 5000
	game.card_cost = 500
	game.shop_presentation.update(1.0)
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.is_gamepad_active = false
	await capture("2_shop_keyboard_hints")
	game.is_gamepad_active = true
	await capture("2_shop_gamepad_hints")
	game.is_gamepad_active = false
	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	await capture("2_shop_touch_hints")
	game.ui_platform_override = game.UI_PLATFORM_AUTO
	game.shop_selected = 0
	game._burn_shop_card(0)
	game.shop_presentation.update(10.0)
	await capture("3_shop_after_burn_refilled")
	game.shop_controller.finish()
	game.mode = "game"


func _capture_workshop() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	var dim: RTMerchantDimension = game._merchant_dimension()
	dim.enter()
	dim.talked_this_visit = true
	var barrel: Dictionary = {}
	for body in dim.physics.bodies:
		if String(body["name"]) == "crates" and bool(body["movable"]) and Vector2(body["pos"]).x > 900.0:
			barrel = body
	game.player_pos = Vector2(barrel["pos"]) + Vector2(-70, -10)
	game.player_pos = game._clamp_player_world(Vector2(barrel["pos"]) + Vector2(-30, 0))
	for i in range(8):
		dim.physics.update(1.0 / 30.0)
	game.camera_follow_initialized = false
	game._update_comfort_camera(0.016)
	await capture("7_workshop_crate_kicked")
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(90, -16)
	game.player_pos = game._clamp_player_world(RTMerchantDimension.MERCHANT_POS + Vector2(20, -16))
	dim.physics.merchant_lean_vel = 2.2
	for i in range(4):
		dim.physics.update(1.0 / 30.0)
	game.camera_follow_initialized = false
	game._update_comfort_camera(0.016)
	await capture("7_workshop_merchant_bumped")
	dim.leave(false)


func _capture_stalker() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.enemies.clear()
	game.time_alive = 400.0
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(360, -40))
	var hidden_one: Dictionary = game.enemies[-1]
	game._update_stalker(hidden_one, 0.016)
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(-180, 40))
	var shown: Dictionary = game.enemies[-1]
	game._update_stalker(shown, 0.016)
	game.camera_follow_initialized = false
	game._update_comfort_camera(0.016)
	await capture("8_stalker_camouflaged_right_revealed_left")
