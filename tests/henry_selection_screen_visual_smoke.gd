extends SceneTree

const OUTPUT := "res://.codex/henry_selection/"

var canvas: SubViewport
var game: Node
var failed := false
var captures := 0


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("HENRY_SELECTION_SCREEN_VISUAL_FAIL requires rendered frames")
		quit(1)
		return
	canvas = SubViewport.new()
	canvas.size = Vector2i(1280, 720)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	game = load("res://scenes/Main.tscn").instantiate()
	canvas.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	printerr("HENRY_SELECTION_SCREEN_VISUAL_FAIL " + message)


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.card_unlock_progress["umbra_victories"] = 1.0
	game.active_character_key = game.CHARACTER_HENRY
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.show_fps_counter = false

	game.mode = "mutation_select"
	game.selected_mutation = 0
	await _capture("mutation_incendiario_1280x720.png", Vector2i(1280, 720))
	_check(_choice_buttons_are_valid(3), "mutation choices are not all visible/touchable")
	_check(not game.buttons.has("henry_preview"), "preview button must not exist yet")
	_press_key(KEY_RIGHT)
	_check(game.selected_mutation == 1, "keyboard did not select the next mutation")
	await _capture("mutation_barometrico_1280x720.png", Vector2i(1280, 720))
	game._handle_character_selection_touch(Rect2(game.buttons["henry_choice_2"]).get_center())
	_check(game.selected_mutation == 2, "touch did not select Colosso D37")

	game.mode = "effect_select"
	game.selected_effect = 1
	await create_timer(0.12).timeout
	await _capture("effect_nimbo_transition_1280x720.png", Vector2i(1280, 720))
	_check(_choice_buttons_are_valid(3), "effect choices are not all visible/touchable")
	_press_key(KEY_LEFT)
	_check(game.selected_effect == 0, "keyboard did not select the previous effect")
	game.mode = "effect_select_mp"
	game.mp_local_ready = true
	_press_key(KEY_RIGHT)
	game._handle_character_selection_touch(Rect2(game.buttons["henry_choice_2"]).get_center())
	_check(game.selected_effect == 0, "ready multiplayer player changed Henry effect")
	game.mp_local_ready = false
	game.is_multiplayer = true
	game.player_nickname = "Henry local"
	game.selected_manifestation = game.HENRY_SELECTION_INDEX
	game.selected_aura = game.HENRY_SELECTION_INDEX
	game.selected_mutation = 1
	game.selected_effect = 2
	game.manifest_select_stage = game.MANIFEST_STAGE_MANIFESTATION
	game.manifest_scroll_pos = 1.0
	game.mode = "mutation_select_mp"
	game.mp_manifest_state_by_peer = {
		42: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 0, "aura": 1, "scroll": 1.0, "ready": true, "name": "Geovana"},
		77: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": game.HENRY_SELECTION_INDEX, "aura": game.HENRY_SELECTION_INDEX, "scroll": game._henry_mp_selection_wire_value(2, 1), "henry_mutation": 2, "henry_effect": 1, "ready": false, "name": "Henry remoto"}
	}
	await _capture("multiplayer_mutation_barometrico_1280x720.png", Vector2i(1280, 720))
	_check(_choice_buttons_are_valid(3), "multiplayer mutation carousel is not fully touchable")
	_check(game.buttons.has("mp_manifest_ready") and game.buttons.has("mp_manifest_start"), "Henry multiplayer screen lost Geovana team actions")
	_press_key(KEY_RIGHT)
	_check(game.selected_mutation == 2, "multiplayer keyboard did not move Henry mutation highlight")
	game.mode = "effect_select_mp"
	game.manifest_select_stage = game.MANIFEST_STAGE_AURA
	game.aura_scroll_pos = 2.0
	await _capture("multiplayer_effect_lastro_1280x720.png", Vector2i(1280, 720))
	_check(game.buttons.has("mp_manifest_back_manifestation") and game.buttons.has("henry_back"), "Henry multiplayer effect screen lost the shared back action")

	canvas.size = Vector2i(960, 540)
	game.mode = "mutation_select"
	game.selected_mutation = 2
	await _capture("mutation_colosso_960x540.png", Vector2i(960, 540))
	_check(_choice_buttons_are_valid(3), "mobile landscape mutation choices leave the viewport")
	game.mode = "effect_select"
	game.selected_effect = 2
	await create_timer(0.12).timeout
	await _capture("effect_lastro_960x540.png", Vector2i(960, 540))
	_check(_choice_buttons_are_valid(3), "mobile landscape effect choices leave the viewport")
	game.mode = "mutation_select_mp"
	game.manifest_select_stage = game.MANIFEST_STAGE_MANIFESTATION
	game.selected_mutation = 1
	game.manifest_scroll_pos = 1.0
	await _capture("multiplayer_mutation_barometrico_960x540.png", Vector2i(960, 540))
	_check(_multiplayer_choice_buttons_are_valid(3), "mobile multiplayer mutation carousel leaves the viewport")
	game.mode = "effect_select_mp"
	game.manifest_select_stage = game.MANIFEST_STAGE_AURA
	game.selected_effect = 2
	game.aura_scroll_pos = 2.0
	await _capture("multiplayer_effect_lastro_960x540.png", Vector2i(960, 540))
	_check(_multiplayer_choice_buttons_are_valid(3), "mobile multiplayer effect carousel leaves the viewport")

	print("HENRY_SELECTION_SCREEN_VISUAL_OK captures=%d desktop=1280x720 mobile=960x540 choices=3 keyboard=true touch=true preview_reserved=true multiplayer_surface=shared peer_highlight=visible output=%s" % [captures, ProjectSettings.globalize_path(OUTPUT)])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	game._handle_character_selection_key(event)


func _choice_buttons_are_valid(expected: int) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(canvas.size))
	for i in range(expected):
		var key := "henry_choice_%d" % i
		if not game.buttons.has(key):
			return false
		var rect := Rect2(game.buttons[key])
		if rect.size.x < 70.0 or rect.size.y < 100.0 or not viewport_rect.encloses(rect):
			return false
	return true


func _multiplayer_choice_buttons_are_valid(expected: int) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(canvas.size))
	for i in range(expected):
		var key := "henry_choice_%d" % i
		if not game.buttons.has(key):
			return false
		var rect := Rect2(game.buttons[key])
		if rect.size.x < 60.0 or rect.size.y < 78.0 or not viewport_rect.encloses(rect):
			return false
	return true


func _capture(file_name: String, expected_size: Vector2i) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	_check(image != null and not image.is_empty(), "invalid capture " + file_name)
	_check(image.get_size() == expected_size, "wrong capture size for " + file_name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_check(image.save_png(OUTPUT + file_name) == OK, "could not save " + file_name)
	captures += 1
